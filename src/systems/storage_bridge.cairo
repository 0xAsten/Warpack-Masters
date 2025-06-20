use starknet::ContractAddress;

#[starknet::interface]
pub trait IStorageBridge<T> {
    fn deposit_item_for_tokens(ref self: T, storage_slot_id: u32);
    fn withdraw_tokens_for_item(ref self: T, item_id: u32, token_amount: u256);
    fn get_deposited_amount(self: @T, player: ContractAddress, item_id: u32) -> u256;
    fn get_token_balance(self: @T, player: ContractAddress, item_id: u32) -> u256;
}

#[dojo::contract]
pub mod storage_bridge_system {
    use super::{IStorageBridge, ContractAddress};
    use starknet::{get_caller_address, get_block_timestamp};
    use warpack_masters::models::{
        CharacterItem::{CharacterItemStorage, CharacterItemsStorageCounter},
        TokenRegistry::{TokenRegistry, BridgeDeposit, BridgeDepositCounter},
        Item::{Item}
    };
    use warpack_masters::systems::token::{
        IERC20Dispatcher, IERC20DispatcherTrait, 
        ItemTokenDispatcher, ItemTokenDispatcherTrait
    };
    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event(historical: true)]
    struct ItemDeposited {
        #[key]
        player: ContractAddress,
        item_id: u32,
        storage_slot_id: u32,
        token_amount: u256,
        token_address: ContractAddress,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event(historical: true)]
    struct ItemWithdrawn {
        #[key]
        player: ContractAddress,
        item_id: u32,
        token_amount: u256,
        new_storage_slot_id: u32,
        token_address: ContractAddress,
    }

    #[abi(embed_v0)]
    impl StorageBridgeImpl of IStorageBridge<ContractState> {
        fn deposit_item_for_tokens(ref self: ContractState, storage_slot_id: u32) {
            let mut world = self.world(@"warpack_masters");

            let player = get_caller_address();

            // Validate storage slot ownership and get item
            let mut storage_item: CharacterItemStorage = world.read_model((player, storage_slot_id));
            assert(storage_item.itemId != 0, 'Storage slot is empty');

            let item_id = storage_item.itemId;

            // Get item details to validate
            let item: Item = world.read_model(item_id);
            assert(item.id != 0, 'Item does not exist');

            // Get token address for this item
            let token_registry: TokenRegistry = world.read_model(item_id);
            assert(token_registry.item_id != 0, 'Token not registered for item');
            assert(token_registry.is_active, 'Token is not active');

            // Remove item from storage
            storage_item.itemId = 0;
            world.write_model(@storage_item);

            // Mint 1 token (items are 1:1 with tokens)
            let token_amount: u256 = 1;
            let token_dispatcher = ItemTokenDispatcher { contract_address: token_registry.token_address };
            token_dispatcher.mint(player, token_amount);

            // Record the deposit
            let mut deposit_counter: BridgeDepositCounter = world.read_model(player);
            deposit_counter.count += 1;
            
            let bridge_deposit = BridgeDeposit {
                player,
                deposit_id: deposit_counter.count,
                item_id,
                storage_slot_id,
                token_amount,
                deposited_at: get_block_timestamp(),
            };

            world.write_model(@bridge_deposit);
            world.write_model(@deposit_counter);

            // Emit event
            world.emit_event(@ItemDeposited {
                player,
                item_id,
                storage_slot_id,
                token_amount,
                token_address: token_registry.token_address,
            });
        }

        fn withdraw_tokens_for_item(ref self: ContractState, item_id: u32, token_amount: u256) {
            let mut world = self.world(@"warpack_masters");

            let player = get_caller_address();

            // Validate item exists
            let item: Item = world.read_model(item_id);
            assert(item.id != 0, 'Item does not exist');

            // Get token address for this item
            let token_registry: TokenRegistry = world.read_model(item_id);
            assert(token_registry.item_id != 0, 'Token not registered for item');
            assert(token_registry.is_active, 'Token is not active');

            // Check if player has enough tokens using standard ERC-20 interface
            let erc20_dispatcher = IERC20Dispatcher { contract_address: token_registry.token_address };
            let player_balance = erc20_dispatcher.balance_of(player);
            assert(player_balance >= token_amount, 'Insufficient token balance');

            // Burn the tokens
            let token_dispatcher = ItemTokenDispatcher { contract_address: token_registry.token_address };
            token_dispatcher.burn(player, token_amount);

            // Add items back to storage
            let mut storage_counter: CharacterItemsStorageCounter = world.read_model(player);
            let mut items_added = 0;
            let mut new_storage_slot_id = 0;

            // Add each token as an individual item (since tokens represent individual items)
            loop {
                if items_added >= token_amount {
                    break;
                }

                // Find next available storage slot or create new one
                storage_counter.count += 1;
                new_storage_slot_id = storage_counter.count;

                let new_storage_item = CharacterItemStorage {
                    player,
                    id: new_storage_slot_id,
                    itemId: item_id,
                };

                world.write_model(@new_storage_item);
                items_added += 1;
            };

            world.write_model(@storage_counter);

            // Emit event
            world.emit_event(@ItemWithdrawn {
                player,
                item_id,
                token_amount,
                new_storage_slot_id,
                token_address: token_registry.token_address,
            });
        }

        fn get_deposited_amount(self: @ContractState, player: ContractAddress, item_id: u32) -> u256 {
            let world = self.world(@"warpack_masters");
            
            // Get token registry
            let token_registry: TokenRegistry = world.read_model(item_id);
            if token_registry.item_id == 0 {
                return 0;
            }

            // Get player's token balance using standard ERC-20 interface
            let erc20_dispatcher = IERC20Dispatcher { contract_address: token_registry.token_address };
            erc20_dispatcher.balance_of(player)
        }

        fn get_token_balance(self: @ContractState, player: ContractAddress, item_id: u32) -> u256 {
            // Same as get_deposited_amount for simplicity
            self.get_deposited_amount(player, item_id)
        }
    }
} 