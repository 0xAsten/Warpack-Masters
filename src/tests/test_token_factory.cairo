#[cfg(test)]
mod tests {
    use starknet::{ContractAddress, contract_address_const};
    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDefTrait};

    use warpack_masters::models::{
        Item::{Item, m_Item},
        TokenRegistry::{TokenRegistry, TokenRegistryCounter, m_TokenRegistry, m_TokenRegistryCounter}
    };
    use warpack_masters::systems::token_factory::{
        token_factory_system, ITokenFactoryDispatcher, ITokenFactoryDispatcherTrait
    };
    use warpack_masters::constants::constants::{ITEMS_COUNTER_ID};

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "Warpacks",
            resources: [
                TestResource::Model(m_Item::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_TokenRegistry::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_TokenRegistryCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Contract(token_factory_system::TEST_CLASS_HASH),
            ].span()
        };
        ndef
    }

    #[test]
    fn test_create_token_for_item() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());

        // Create a test item
        let item = Item {
            id: 1,
            name: 'TestSword',
            itemType: 1,
            width: 1,
            height: 1,
            price: 100,
            damage: 10,
            cleansePoison: 0,
            chance: 50,
            cooldown: 0,
            energyCost: 0,
            armorBonus: 0,
        };
        world.write_model_test(@item);

        // Initialize counter
        let counter = TokenRegistryCounter {
            id: ITEMS_COUNTER_ID,
            count: 0,
        };
        world.write_model_test(@counter);

        // Deploy token factory system
        let token_factory_address = world.deploy_contract(
            'salt1', token_factory_system::TEST_CLASS_HASH
        );
        let token_factory = ITokenFactoryDispatcher { contract_address: token_factory_address };

        // Test creating token for item
        let token_address = token_factory.create_token_for_item(1);
        
        // Verify token was registered
        assert(token_factory.is_token_registered(1), 'Token should be registered');
        assert(token_factory.get_token_address(1) == token_address, 'Token address mismatch');

        // Verify registry was created
        let registry: TokenRegistry = world.read_model(1);
        assert(registry.item_id == 1, 'Registry item_id mismatch');
        assert(registry.token_address == token_address, 'Registry address mismatch');
        assert(registry.is_active, 'Token should be active');
        assert(registry.token_name == 'TestSword', 'Token name mismatch');
    }

    #[test]
    #[should_panic(expected: ('Item does not exist',))]
    fn test_create_token_for_nonexistent_item() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());

        let token_factory_address = world.deploy_contract(
            'salt1', token_factory_system::TEST_CLASS_HASH
        );
        let token_factory = ITokenFactoryDispatcher { contract_address: token_factory_address };

        // Try to create token for non-existent item
        token_factory.create_token_for_item(999);
    }

    #[test]
    #[should_panic(expected: ('Token already exists',))]
    fn test_create_duplicate_token() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());

        // Create a test item
        let item = Item {
            id: 1,
            name: 'TestSword',
            itemType: 1,
            width: 1,
            height: 1,
            price: 100,
            damage: 10,
            cleansePoison: 0,
            chance: 50,
            cooldown: 0,
            energyCost: 0,
            armorBonus: 0,
        };
        world.write_model_test(@item);

        // Initialize counter
        let counter = TokenRegistryCounter {
            id: ITEMS_COUNTER_ID,
            count: 0,
        };
        world.write_model_test(@counter);

        let token_factory_address = world.deploy_contract(
            'salt1', token_factory_system::TEST_CLASS_HASH
        );
        let token_factory = ITokenFactoryDispatcher { contract_address: token_factory_address };

        // Create token first time
        token_factory.create_token_for_item(1);
        
        // Try to create again - should panic
        token_factory.create_token_for_item(1);
    }

    #[test]
    fn test_token_registration_queries() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());

        let token_factory_address = world.deploy_contract(
            'salt1', token_factory_system::TEST_CLASS_HASH
        );
        let token_factory = ITokenFactoryDispatcher { contract_address: token_factory_address };

        // Test with non-registered item
        assert(!token_factory.is_token_registered(1), 'Should not be registered');

        // Create item and token
        let item = Item {
            id: 1,
            name: 'TestSword',
            itemType: 1,
            width: 1,
            height: 1,
            price: 100,
            damage: 10,
            cleansePoison: 0,
            chance: 50,
            cooldown: 0,
            energyCost: 0,
            armorBonus: 0,
        };
        world.write_model_test(@item);

        let counter = TokenRegistryCounter {
            id: ITEMS_COUNTER_ID,
            count: 0,
        };
        world.write_model_test(@counter);

        let token_address = token_factory.create_token_for_item(1);

        // Test queries after registration
        assert(token_factory.is_token_registered(1), 'Should be registered');
        assert(token_factory.get_token_address(1) == token_address, 'Address should match');
    }
} 