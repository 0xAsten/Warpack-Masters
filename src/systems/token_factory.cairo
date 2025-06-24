use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
pub trait ITokenFactory<TContractState> {
    fn create_token_for_item(ref self: TContractState, item_id: u32, name: ByteArray, symbol: ByteArray, owner: ContractAddress, erc20_class_hash: ClassHash) -> ContractAddress;
    fn get_token_address(self: @TContractState, item_id: u32) -> ContractAddress;
}

#[dojo::contract]
pub mod token_factory {
    use super::ITokenFactory;
    use starknet::{
        ContractAddress, contract_address_const,
        syscalls::deploy_syscall, get_caller_address, ClassHash
    };
    use dojo::model::{ModelStorage};
    
    use warpack_masters::models::{
        TokenRegistry::{TokenRegistry},
        Item::Item,
    };

    use warpack_masters::constants::constants::{TOKEN_SUPPLY_BASE};

    use dojo::world::{IWorldDispatcherTrait};

    #[abi(embed_v0)]
    impl TokenFactoryImpl of ITokenFactory<ContractState> {
        fn create_token_for_item(ref self: ContractState, item_id: u32, name: ByteArray, symbol: ByteArray, owner: ContractAddress, erc20_class_hash: ClassHash) -> ContractAddress {
            let mut world = self.world(@"Warpacks");

            let caller = get_caller_address();
            assert(world.dispatcher.is_owner(0, caller), 'caller not world owner');

            // check if item is valid
            let item: Item = world.read_model(item_id);
            assert(item.name == name, 'Item name does not match');
            
            // Check if token already exists
            let existing_registry: TokenRegistry = world.read_model(item_id);
            assert(existing_registry.token_address == contract_address_const::<0>(), 'Token already exists');
                        
            // Deploy the ERC-20 token contract
            let mut constructor_calldata = ArrayTrait::new();
            name.serialize(ref constructor_calldata);
            symbol.serialize(ref constructor_calldata);
            TOKEN_SUPPLY_BASE.serialize(ref constructor_calldata); // 10M tokens with 18 decimals
            owner.serialize(ref constructor_calldata); // recipient
            owner.serialize(ref constructor_calldata); // owner
            
            let (token_address, _) = deploy_syscall(
                erc20_class_hash,
                0, // salt
                constructor_calldata.span(),
                false
            ).unwrap();
            
            // Register the token
            let token_registry = TokenRegistry {
                item_id,
                name,
                symbol,
                token_address,
                is_active: true,
            };
            
            world.write_model(@token_registry);
            
            token_address
        }
        
        fn get_token_address(self: @ContractState, item_id: u32) -> ContractAddress {
            let world = self.world(@"Warpacks");
            let registry: TokenRegistry = world.read_model(item_id);
            registry.token_address
        }
    }
} 