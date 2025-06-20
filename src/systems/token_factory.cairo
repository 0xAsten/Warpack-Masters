use starknet::ContractAddress;

#[starknet::interface]
pub trait ITokenFactory<T> {
    fn create_token_for_item(ref self: T, item_id: u32) -> ContractAddress;
    fn get_token_address(self: @T, item_id: u32) -> ContractAddress;
    fn is_token_registered(self: @T, item_id: u32) -> bool;
}

#[dojo::contract]
pub mod token_factory_system {
    use super::{ITokenFactory, ContractAddress};
    use starknet::{get_caller_address, get_block_timestamp, deploy_syscall, ClassHash};
    use warpack_masters::models::{
        TokenRegistry::{TokenRegistry, TokenRegistryCounter},
        Item::{Item}
    };
    use warpack_masters::systems::token::{ItemTokenContract};
    use warpack_masters::constants::constants::{ITEMS_COUNTER_ID};
    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event(historical: true)]
    struct TokenCreated {
        #[key]
        item_id: u32,
        token_address: ContractAddress,
        creator: ContractAddress,
        token_name: felt252,
        token_symbol: felt252,
    }

    #[abi(embed_v0)]
    impl TokenFactoryImpl of ITokenFactory<ContractState> {
        fn create_token_for_item(ref self: ContractState, item_id: u32) -> ContractAddress {
            let mut world = self.world_default();

            // Validate item exists
            let item: Item = world.read_model(item_id);
            assert(item.id != 0, 'Item does not exist');

            // Check if token already exists
            let existing_registry: TokenRegistry = world.read_model(item_id);
            assert(existing_registry.item_id == 0, 'Token already exists');

            let caller = get_caller_address();

            // Generate token name and symbol from item name
            let token_name = item.name;
            // Create a simple symbol by prefixing with 'WP'
            let token_symbol = item.name; // In production, you'd want better symbol generation

            // Deploy the token contract
            // NOTE: You'll need to provide the actual class hash of your deployed ItemTokenContract
            // This is typically obtained when you declare the contract
            let token_class_hash: ClassHash = get_token_contract_class_hash(); // Helper function needed
            
            let mut constructor_calldata = array![];
            constructor_calldata.append(token_name);
            constructor_calldata.append(token_symbol);
            constructor_calldata.append(caller.into()); // minter address (should be storage bridge)
            constructor_calldata.append(item_id.into());

            let (token_address, _) = deploy_syscall(
                token_class_hash,
                0, // salt - you might want to use item_id for uniqueness
                constructor_calldata.span(),
                false // deploy_from_zero
            ).expect('Token deployment failed');

            // Register the token
            let token_registry = TokenRegistry {
                item_id,
                token_address,
                token_name,
                token_symbol,
                is_active: true,
                total_supply: 0,
                created_at: get_block_timestamp(),
            };

            world.write_model(@token_registry);

            // Update counter
            let mut counter: TokenRegistryCounter = world.read_model(ITEMS_COUNTER_ID);
            counter.count += 1;
            world.write_model(@counter);

            // Emit event
            world.emit_event(@TokenCreated {
                item_id,
                token_address,
                creator: caller,
                token_name,
                token_symbol,
            });

            token_address
        }

        fn get_token_address(self: @ContractState, item_id: u32) -> ContractAddress {
            let world = self.world_default();
            let registry: TokenRegistry = world.read_model(item_id);
            assert(registry.item_id != 0, 'Token not registered');
            registry.token_address
        }

        fn is_token_registered(self: @ContractState, item_id: u32) -> bool {
            let world = self.world_default();
            let registry: TokenRegistry = world.read_model(item_id);
            registry.item_id != 0 && registry.is_active
        }
    }

    // Helper function to get the token contract class hash
    // You'll need to implement this based on how you deploy/declare contracts
    fn get_token_contract_class_hash() -> ClassHash {
        // TODO: Replace with actual class hash of deployed ItemTokenContract
        // This should be obtained when you declare the contract
        // Example: starknet::class_hash::class_hash_const::<0x...actual_hash...>()
        
        // For now, return a placeholder - you MUST replace this before deployment
        starknet::class_hash::class_hash_const::<0x1>()
    }
} 