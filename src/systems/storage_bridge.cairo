use starknet::{ContractAddress};

// Import standard ERC-20 interface
#[starknet::interface]
pub trait IERC20<TContractState> {
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
}

#[starknet::interface]
pub trait IERC20Extended<TContractState> {
    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn burn_from(ref self: TContractState, account: ContractAddress, amount: u256);
}

#[starknet::interface]
pub trait IStorageBridge<TContractState> {
    fn deposit_item(ref self: TContractState, storage_item_id: u32, quantity: u32) -> u256;
    fn withdraw_item(ref self: TContractState, item_id: u32, token_amount: u256) -> u32;
    fn get_storage_item_count(self: @TContractState, player: ContractAddress, item_id: u32) -> u32;
    
    // New functions for better multi-item support
    fn get_player_storage_summary(self: @TContractState, player: ContractAddress) -> Array<(u32, u32, ContractAddress)>; // (item_id, count, token_address)
    fn get_token_address_for_item(self: @TContractState, item_id: u32) -> ContractAddress;
    fn get_all_storage_items(self: @TContractState, player: ContractAddress) -> Array<(u32, u32)>; // (storage_id, item_id)
    fn batch_deposit_items(ref self: TContractState, deposits: Array<(u32, u32)>) -> Array<u256>; // (storage_item_id, quantity) -> token_amounts
}

#[dojo::contract]
pub mod storage_bridge {
    use super::{IStorageBridge, IERC20Dispatcher, IERC20DispatcherTrait, IERC20ExtendedDispatcher, IERC20ExtendedDispatcherTrait};
    use starknet::{ContractAddress, get_caller_address, contract_address_const};
    use dojo::model::{ModelStorage};
    use warpack_masters::models::{
        TokenRegistry::{TokenRegistry},
        backpack::{BridgeDeposit},
        CharacterItem::{CharacterItemStorage, CharacterItemsStorageCounter},
        Item::{Item},
    };

    #[abi(embed_v0)]
    impl StorageBridgeImpl of IStorageBridge<ContractState> {
        fn deposit_item(ref self: ContractState, storage_item_id: u32, quantity: u32) -> u256 {
            let mut world = self.world(@"Warpacks");
            let caller = get_caller_address();
            
            // Verify the storage item exists and belongs to the player
            let storage_item: CharacterItemStorage = world.read_model((caller, storage_item_id));
            assert(storage_item.itemId != 0, 'Storage item does not exist');
            
            let item_id = storage_item.itemId;
            
            // Get item details to verify it exists
            let item: Item = world.read_model(item_id);
            assert(item.id != 0, 'Item does not exist');
            
            // Count how many of this item type the player has in storage
            let available_quantity = self.get_storage_item_count(caller, item_id);
            assert(available_quantity >= quantity, 'Insufficient items in storage');
            
            // Get the token address for this item
            let registry: TokenRegistry = world.read_model(item_id);
            assert(registry.token_address != contract_address_const::<0>(), 'Token not registered');
            assert(registry.is_active, 'Token not active');
            
            // Calculate token amount (1:1 ratio for now, could be configurable)
            let token_amount: u256 = quantity.into();
            
            // Remove items from player's storage
            self._remove_items_from_storage(caller, item_id, quantity);
            
            // Mint tokens to the player
            let token_contract = IERC20ExtendedDispatcher { contract_address: registry.token_address };
            token_contract.mint(caller, token_amount);
            
            // Record the deposit
            let deposit = BridgeDeposit {
                player: caller,
                item_id,
                quantity,
                token_amount,
                token_address: registry.token_address,
                timestamp: starknet::get_block_timestamp(),
            };
            
            world.write_model(@deposit);
            
            token_amount
        }
        
        fn withdraw_item(ref self: ContractState, item_id: u32, token_amount: u256) -> u32 {
            let mut world = self.world(@"Warpacks");
            let caller = get_caller_address();
            
            // Get the token address for this item
            let registry: TokenRegistry = world.read_model(item_id);
            assert(registry.token_address != contract_address_const::<0>(), 'Token not registered');
            assert(registry.is_active, 'Token not active');
            
            // Verify item exists
            let item: Item = world.read_model(item_id);
            assert(item.id != 0, 'Item does not exist');
            
            // Verify caller has sufficient tokens
            let token_contract = IERC20Dispatcher { contract_address: registry.token_address };
            let balance = token_contract.balance_of(caller);
            assert(balance >= token_amount, 'Insufficient token balance');
            
            // Calculate item quantity (1:1 ratio for now)
            let quantity: u32 = token_amount.try_into().unwrap();
            assert(quantity > 0, 'Invalid quantity');
            
            // Burn the tokens
            let extended_token = IERC20ExtendedDispatcher { contract_address: registry.token_address };
            extended_token.burn_from(caller, token_amount);
            
            // Add items to player's storage
            self._add_items_to_storage(caller, item_id, quantity);
            
            // Record the withdrawal (negative quantity to indicate withdrawal)
            let deposit = BridgeDeposit {
                player: caller,
                item_id,
                quantity: 0, // Mark as withdrawal
                token_amount,
                token_address: registry.token_address,
                timestamp: starknet::get_block_timestamp(),
            };
            
            world.write_model(@deposit);
            
            quantity
        }
        
        fn get_storage_item_count(self: @ContractState, player: ContractAddress, item_id: u32) -> u32 {
            let world = self.world(@"Warpacks");
            
            let storage_counter: CharacterItemsStorageCounter = world.read_model(player);
            let mut count = 0;
            let mut i = 1;
            
            // Don't count empty slots (itemId = 0)
            if item_id == 0 {
                return 0;
            }
            
            loop {
                if i > storage_counter.count {
                    break;
                }
                
                let storage_item: CharacterItemStorage = world.read_model((player, i));
                if storage_item.itemId == item_id {
                    count += 1;
                }
                
                i += 1;
            };
            
            count
        }
        
        fn get_player_storage_summary(self: @ContractState, player: ContractAddress) -> Array<(u32, u32, ContractAddress)> {
            let world = self.world(@"Warpacks");
            let storage_counter: CharacterItemsStorageCounter = world.read_model(player);
            
            let mut item_counts: Array<(u32, u32)> = array![];
            let mut result: Array<(u32, u32, ContractAddress)> = array![];
            let mut i = 1;
            
            // First pass: collect all unique item IDs and count them
            loop {
                if i > storage_counter.count {
                    break;
                }
                
                let storage_item: CharacterItemStorage = world.read_model((player, i));
                if storage_item.itemId != 0 {
                    // Check if we already have this item_id in our array
                    let mut found = false;
                    let mut j = 0;
                    let mut updated_counts: Array<(u32, u32)> = array![];
                    
                    loop {
                        if j >= item_counts.len() {
                            break;
                        }
                        
                        let (item_id, count) = *item_counts.at(j);
                        if item_id == storage_item.itemId {
                            updated_counts.append((item_id, count + 1));
                            found = true;
                        } else {
                            updated_counts.append((item_id, count));
                        }
                        
                        j += 1;
                    };
                    
                    if !found {
                        updated_counts.append((storage_item.itemId, 1));
                    }
                    
                    item_counts = updated_counts;
                }
                
                i += 1;
            };
            
            // Second pass: get token addresses for each unique item
            let mut k = 0;
            loop {
                if k >= item_counts.len() {
                    break;
                }
                
                let (item_id, count) = *item_counts.at(k);
                let registry: TokenRegistry = world.read_model(item_id);
                let token_address = if registry.is_active {
                    registry.token_address
                } else {
                    contract_address_const::<0>()
                };
                
                result.append((item_id, count, token_address));
                k += 1;
            };
            
            result
        }
        
        fn get_token_address_for_item(self: @ContractState, item_id: u32) -> ContractAddress {
            let world = self.world(@"Warpacks");
            let registry: TokenRegistry = world.read_model(item_id);
            
            if registry.is_active && registry.token_address != contract_address_const::<0>() {
                registry.token_address
            } else {
                contract_address_const::<0>()
            }
        }
        
        fn get_all_storage_items(self: @ContractState, player: ContractAddress) -> Array<(u32, u32)> {
            let world = self.world(@"Warpacks");
            let storage_counter: CharacterItemsStorageCounter = world.read_model(player);
            let mut result: Array<(u32, u32)> = array![];
            let mut i = 1;
            
            loop {
                if i > storage_counter.count {
                    break;
                }
                
                let storage_item: CharacterItemStorage = world.read_model((player, i));
                result.append((i, storage_item.itemId)); // (storage_id, item_id)
                
                i += 1;
            };
            
            result
        }
        
        fn batch_deposit_items(ref self: ContractState, deposits: Array<(u32, u32)>) -> Array<u256> {
            let mut result: Array<u256> = array![];
            let mut i = 0;
            
            loop {
                if i >= deposits.len() {
                    break;
                }
                
                let (storage_item_id, quantity) = *deposits.at(i);
                let token_amount = self.deposit_item(storage_item_id, quantity);
                result.append(token_amount);
                
                i += 1;
            };
            
            result
        }
    }
    
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _remove_items_from_storage(ref self: ContractState, player: ContractAddress, item_id: u32, quantity: u32) {
            let mut world = self.world(@"Warpacks");
            
            let storage_counter: CharacterItemsStorageCounter = world.read_model(player);
            let mut removed = 0;
            let mut i = 1;
            
            loop {
                if i > storage_counter.count || removed >= quantity {
                    break;
                }
                
                let mut storage_item: CharacterItemStorage = world.read_model((player, i));
                if storage_item.itemId == item_id {
                    // Remove this item by setting itemId to 0
                    storage_item.itemId = 0;
                    world.write_model(@storage_item);
                    removed += 1;
                }
                
                i += 1;
            };
            
            assert(removed == quantity, 'Failed to remove all items');
        }
        
        fn _add_items_to_storage(ref self: ContractState, player: ContractAddress, item_id: u32, quantity: u32) {
            let mut world = self.world(@"Warpacks");
            
            let mut storage_counter: CharacterItemsStorageCounter = world.read_model(player);
            let mut added = 0;
            let mut i = 1;
            
            // First, try to fill empty slots
            loop {
                if i > storage_counter.count || added >= quantity {
                    break;
                }
                
                let mut storage_item: CharacterItemStorage = world.read_model((player, i));
                if storage_item.itemId == 0 {
                    // Fill this empty slot
                    storage_item.itemId = item_id;
                    world.write_model(@storage_item);
                    added += 1;
                }
                
                i += 1;
            };
            
            // If we still need to add more items, create new storage slots
            loop {
                if added >= quantity {
                    break;
                }
                
                storage_counter.count += 1;
                let new_storage_item = CharacterItemStorage {
                    player,
                    id: storage_counter.count,
                    itemId: item_id,
                };
                
                world.write_model(@new_storage_item);
                added += 1;
            };
            
            // Update the storage counter if we added new slots
            world.write_model(@storage_counter);
        }
    }
} 