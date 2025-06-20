use starknet::{ContractAddress, ClassHash, contract_address_const};

// Standard ERC-20 interface that Ekubo expects
#[starknet::interface]
pub trait IERC20<TContractState> {
    fn total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn decimals(self: @TContractState) -> u8;
}

#[starknet::interface]
pub trait ITokenFactory<TContractState> {
    fn create_token_for_item(ref self: TContractState, item_id: u32, name: ByteArray, symbol: ByteArray) -> ContractAddress;
    fn get_token_address(self: @TContractState, item_id: u32) -> ContractAddress;
    fn set_erc20_class_hash(ref self: TContractState, class_hash: ClassHash);
}

#[dojo::contract]
pub mod token_factory {
    use super::ITokenFactory;
    use starknet::{
        ContractAddress, ClassHash, get_contract_address, contract_address_const,
        syscalls::deploy_syscall
    };
    use dojo::model::{ModelStorage};
    
    use warpack_masters::models::{
        TokenRegistry::{TokenRegistry},
    };

    #[abi(embed_v0)]
    impl TokenFactoryImpl of ITokenFactory<ContractState> {
        fn create_token_for_item(ref self: ContractState, item_id: u32, name: ByteArray, symbol: ByteArray) -> ContractAddress {
            let mut world = self.world(@"warpack_masters");
            
            // Check if token already exists
            let existing_registry: TokenRegistry = world.read_model(item_id);
            assert(existing_registry.token_address == contract_address_const::<0>(), 'Token already exists');
            
            // Get the stored class hash for ERC-20 tokens
            let config_registry: TokenRegistry = world.read_model(0);
            assert(config_registry.token_address != contract_address_const::<0>(), 'ERC20 class hash not set');
            
            // Convert the stored address back to class hash
            let class_hash_felt: felt252 = config_registry.token_address.into();
            let class_hash: ClassHash = class_hash_felt.try_into().unwrap();
            
            // Deploy the ERC-20 token contract
            let mut constructor_calldata = ArrayTrait::new();
            name.serialize(ref constructor_calldata);
            symbol.serialize(ref constructor_calldata);
            18_u8.serialize(ref constructor_calldata); // decimals
            0_u256.serialize(ref constructor_calldata); // initial_supply
            get_contract_address().serialize(ref constructor_calldata); // recipient (this contract)
            
            let (token_address, _) = deploy_syscall(
                class_hash,
                item_id.into(), // salt
                constructor_calldata.span(),
                false
            ).unwrap();
            
            // Register the token
            let token_registry = TokenRegistry {
                item_id,
                token_address,
                is_active: true,
            };
            
            world.write_model(@token_registry);
            
            token_address
        }
        
        fn get_token_address(self: @ContractState, item_id: u32) -> ContractAddress {
            let world = self.world(@"warpack_masters");
            let registry: TokenRegistry = world.read_model(item_id);
            registry.token_address
        }
        
        fn set_erc20_class_hash(ref self: ContractState, class_hash: ClassHash) {
            let mut world = self.world(@"warpack_masters");
            
            // Store class hash as a special config entry with item_id = 0
            // Convert ClassHash to ContractAddress for storage
            let class_hash_felt: felt252 = class_hash.into();
            let class_hash_as_address: ContractAddress = class_hash_felt.try_into().unwrap();
            
            let config_registry = TokenRegistry {
                item_id: 0,
                token_address: class_hash_as_address,
                is_active: true,
            };
            
            world.write_model(@config_registry);
        }
    }
} 