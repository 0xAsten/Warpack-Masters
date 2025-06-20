use starknet::{ContractAddress, get_caller_address, contract_address_const};

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
    fn deposit_item(ref self: TContractState, item_id: u32, quantity: u32) -> u256;
    fn withdraw_item(ref self: TContractState, item_id: u32, token_amount: u256) -> u32;
}

#[dojo::contract]
pub mod storage_bridge {
    use super::{IStorageBridge, IERC20Dispatcher, IERC20DispatcherTrait, IERC20ExtendedDispatcher, IERC20ExtendedDispatcherTrait};
    use starknet::{ContractAddress, get_caller_address, contract_address_const};
    use dojo::model::{ModelStorage};
    use warpack_masters::models::{
        TokenRegistry::{TokenRegistry},
        backpack::{BridgeDeposit},
    };

    #[abi(embed_v0)]
    impl StorageBridgeImpl of IStorageBridge<ContractState> {
        fn deposit_item(ref self: ContractState, item_id: u32, quantity: u32) -> u256 {
            let mut world = self.world(@"warpack_masters");
            let caller = get_caller_address();
            
            // Verify caller has the item in sufficient quantity
            // TODO: Add proper item ownership verification
            // For now, we'll assume the caller owns the items
            
            // Get the token address for this item
            let registry: TokenRegistry = world.read_model(item_id);
            assert(registry.token_address != contract_address_const::<0>(), 'Token not registered');
            assert(registry.is_active, 'Token not active');
            
            // Calculate token amount (1:1 ratio for now, could be configurable)
            let token_amount: u256 = quantity.into();
            
            // Remove item from player's inventory
            // TODO: Implement proper item removal logic
            // This would interact with the Character/CharacterItem models
            
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
            let world = self.world(@"warpack_masters");
            let caller = get_caller_address();
            
            // Get the token address for this item
            let registry: TokenRegistry = world.read_model(item_id);
            assert(registry.token_address != contract_address_const::<0>(), 'Token not registered');
            assert(registry.is_active, 'Token not active');
            
            // Verify caller has sufficient tokens
            let token_contract = IERC20Dispatcher { contract_address: registry.token_address };
            let balance = token_contract.balance_of(caller);
            assert(balance >= token_amount, 'Insufficient token balance');
            
            // Calculate item quantity (1:1 ratio for now)
            let quantity: u32 = token_amount.try_into().unwrap();
            
            // Burn the tokens
            let extended_token = IERC20ExtendedDispatcher { contract_address: registry.token_address };
            extended_token.burn_from(caller, token_amount);
            
            // Add item to player's inventory
            // TODO: Implement proper item addition logic
            // This would interact with the Character/CharacterItem models
            
            quantity
        }
    }
} 