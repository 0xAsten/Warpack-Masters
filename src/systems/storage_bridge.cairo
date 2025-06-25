#[starknet::interface]
pub trait IStorageBridge<TContractState> {
    fn deposit_item(ref self: TContractState, storage_item_id: u32);
    fn withdraw_item(ref self: TContractState, item_id: u32);
}

#[dojo::contract]
pub mod storage_bridge {
    use super::{IStorageBridge};
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    use starknet::{ContractAddress, get_caller_address, contract_address_const, get_contract_address};
    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;
    use warpack_masters::models::{
        TokenRegistry::{TokenRegistry},
        CharacterItem::{CharacterItemStorage, CharacterItemsStorageCounter},
        Item::{Item},
    };

    #[derive(Copy, Drop, Serde)]
    #[dojo::event(historical: true)]
    struct DepositItem {
        #[key]
        player: ContractAddress,
        itemId: u32,
        tokenAmount: u256,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event(historical: true)]
    struct WithdrawItem {
        #[key]
        player: ContractAddress,
        itemId: u32,
        tokenAmount: u256,
    }

    #[abi(embed_v0)]
    impl StorageBridgeImpl of IStorageBridge<ContractState> {
        // Convert storage item to token
        fn deposit_item(ref self: ContractState, storage_item_id: u32) {
            let mut world = self.world(@"Warpacks");
            let caller = get_caller_address();
            
            // Verify the storage item exists and belongs to the player
            let storage_item: CharacterItemStorage = world.read_model((caller, storage_item_id));
            assert(storage_item.itemId != 0, 'Storage item does not exist');
            
            let item_id = storage_item.itemId;
            
            // Get item details to verify it exists
            let item: Item = world.read_model(item_id);
            assert(item.itemType != 0, 'Item does not exist');

            // Remove the item from player's storage
            self._remove_items_from_storage(caller, storage_item_id);
                       
            // Get the token address for this item
            let registry: TokenRegistry = world.read_model(item_id);
            assert(registry.token_address != contract_address_const::<0>(), 'Token not registered');
            assert(registry.is_active, 'Token not active');
            
            // Transfer tokens to the player
            let token_amount = 1 * 1_000_000_000_000_000_000;
            let token_contract = IERC20Dispatcher { contract_address: registry.token_address };
            token_contract.transfer(caller, token_amount);

            world.emit_event(@DepositItem {
                player: caller,
                itemId: item_id,
                tokenAmount: token_amount,
            });
        }
        
        // Convert token to storage item
        fn withdraw_item(ref self: ContractState, item_id: u32) {
            let mut world = self.world(@"Warpacks");
            let caller = get_caller_address();

            // Verify item exists
            let item: Item = world.read_model(item_id);
            assert(item.itemType != 0, 'Item does not exist');
            
            // Get the token address for this item
            let registry: TokenRegistry = world.read_model(item_id);
            assert(registry.token_address != contract_address_const::<0>(), 'Token not registered');
            assert(registry.is_active, 'Token not active');
            
            let token_amount = 1 * 1_000_000_000_000_000_000;
            let token_contract = IERC20Dispatcher { contract_address: registry.token_address };
            token_contract.transfer_from(caller, get_contract_address(), token_amount);
            
            // Add items to player's storage
            self._add_items_to_storage(caller, item_id);

            world.emit_event(@WithdrawItem {
                player: caller,
                itemId: item_id,
                tokenAmount: token_amount,
            });
        }
    }
    
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _remove_items_from_storage(ref self: ContractState, player: ContractAddress, storage_item_id: u32) {
            let mut world = self.world(@"Warpacks");
            
            let mut storage_item: CharacterItemStorage = world.read_model((player, storage_item_id));
            storage_item.itemId = 0;
            world.write_model(@storage_item);
        }
        
        fn _add_items_to_storage(ref self: ContractState, player: ContractAddress, item_id: u32) {
            let mut world = self.world(@"Warpacks");
            
            let mut storageCounter: CharacterItemsStorageCounter = world.read_model(player);
            let mut count = storageCounter.count;
            
            loop {
                if count == 0 {
                    break;
                }

                let mut storageItem: CharacterItemStorage = world.read_model((player, count));
                if storageItem.itemId == 0 {
                    storageItem.itemId = item_id;
                    world.write_model(@storageItem);
                    break;
                }

                count -= 1;
            };

            if count == 0 {
                storageCounter.count += 1;
                world.write_model(@CharacterItemStorage { player, id: storageCounter.count, itemId: item_id, });
                world.write_model(@CharacterItemsStorageCounter { player, count: storageCounter.count });
            }
        }
    }
} 