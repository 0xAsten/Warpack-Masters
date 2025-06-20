#[cfg(test)]
mod integration_tests {
    use starknet::testing::{set_contract_address};
    use starknet::{ContractAddress, contract_address_const};

    use dojo::model::{ModelStorage};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef, WorldStorageTestTrait};

    use warpack_masters::{
        models::Item::{Item, m_Item},
        models::CharacterItem::{
            CharacterItemStorage, CharacterItemsStorageCounter,
            m_CharacterItemStorage, m_CharacterItemsStorageCounter
        },
        models::TokenRegistry::{TokenRegistry, m_TokenRegistry},
        models::backpack::{BridgeDeposit, m_BridgeDeposit},
        systems::storage_bridge::{storage_bridge, IStorageBridgeDispatcher, IStorageBridgeDispatcherTrait},
        systems::token_factory::{token_factory, ITokenFactoryDispatcher, ITokenFactoryDispatcherTrait},
    };

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "Warpacks", 
            resources: [
                TestResource::Model(m_Item::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemStorage::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemsStorageCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_TokenRegistry::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_BridgeDeposit::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Contract(storage_bridge::TEST_CLASS_HASH),
                TestResource::Contract(token_factory::TEST_CLASS_HASH),
            ].span()
        };
        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"Warpacks", @"storage_bridge")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
            ContractDefTrait::new(@"Warpacks", @"token_factory")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
        ].span()
    }

    #[test]
    #[available_gas(50000000)]
    fn test_integration_create_token_and_deposit() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (storage_bridge_address, _) = world.dns(@"storage_bridge").unwrap();
        let storage_bridge = IStorageBridgeDispatcher { contract_address: storage_bridge_address };

        let (token_factory_address, _) = world.dns(@"token_factory").unwrap();
        let token_factory = ITokenFactoryDispatcher { contract_address: token_factory_address };

        let player = contract_address_const::<0x123>();

        // Setup test item
        let item = Item {
            id: 1,
            name: 'Sword',
            itemType: 1,
            rarity: 1,
            width: 1,
            height: 1,
            price: 100,
            effectType: 0,
            effectStacks: 0,
            effectActivationType: 0,
            chance: 50,
            cooldown: 0,
            energyCost: 0,
            isPlugin: false,
        };
        world.write_model(@item);

        // Setup player storage with 3 swords
        let storage_counter = CharacterItemsStorageCounter { player, count: 3, };
        world.write_model(@storage_counter);

        let storage_1 = CharacterItemStorage { player, id: 1, itemId: 1, };
        world.write_model(@storage_1);
        let storage_2 = CharacterItemStorage { player, id: 2, itemId: 1, };
        world.write_model(@storage_2);
        let storage_3 = CharacterItemStorage { player, id: 3, itemId: 1, };
        world.write_model(@storage_3);

        // Step 1: Create token for item through token factory
        let token_address = token_factory.create_token_for_item(1, "Sword Token", "SWORD");
        assert(token_address != contract_address_const::<0>(), 'Token should be created');

        // Verify token was registered
        let registered_address = token_factory.get_token_address(1);
        assert(registered_address == token_address, 'Token address should match');

        // Step 2: Verify storage bridge can find the token
        let bridge_token_address = storage_bridge.get_token_address_for_item(1);
        assert(bridge_token_address == token_address, 'Bridge should find same token');

        // Step 3: Check player storage summary
        let storage_summary = storage_bridge.get_player_storage_summary(player);
        assert(storage_summary.len() == 1, 'Should have 1 item type');
        
        let (item_id, count, summary_token_address) = *storage_summary.at(0);
        assert(item_id == 1, 'Item ID should be 1');
        assert(count == 3, 'Should have 3 swords');
        assert(summary_token_address == token_address, 'Summary token addr match');
    }

    #[test]
    #[available_gas(50000000)]
    fn test_integration_deposit_item_with_token_creation() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (storage_bridge_address, _) = world.dns(@"storage_bridge").unwrap();
        let storage_bridge = IStorageBridgeDispatcher { contract_address: storage_bridge_address };

        let (token_factory_address, _) = world.dns(@"token_factory").unwrap();
        let token_factory = ITokenFactoryDispatcher { contract_address: token_factory_address };

        let player = contract_address_const::<0x123>();
        set_contract_address(player);

        // Setup test item
        let item = Item {
            id: 1,
            name: 'Sword',
            itemType: 1,
            rarity: 1,
            width: 1,
            height: 1,
            price: 100,
            effectType: 0,
            effectStacks: 0,
            effectActivationType: 0,
            chance: 50,
            cooldown: 0,
            energyCost: 0,
            isPlugin: false,
        };
        world.write_model(@item);

        // Setup player storage with 2 swords
        let storage_counter = CharacterItemsStorageCounter { player, count: 2, };
        world.write_model(@storage_counter);

        let storage_1 = CharacterItemStorage { player, id: 1, itemId: 1, };
        world.write_model(@storage_1);
        let storage_2 = CharacterItemStorage { player, id: 2, itemId: 1, };
        world.write_model(@storage_2);

        // Step 1: Create token first
        let _token_address = token_factory.create_token_for_item(1, "Sword Token", "SWORD");

        // Step 2: Deposit 1 sword (should create tokens)
        let tokens_minted = storage_bridge.deposit_item(1, 1);
        assert(tokens_minted == 1, 'Should mint 1 token');

        // Step 3: Verify storage was updated (1 sword removed)
        let remaining_count = storage_bridge.get_storage_item_count(player, 1);
        assert(remaining_count == 1, 'Should have 1 sword left');

        // Step 4: Verify storage slots (first slot should be empty now)
        let all_items = storage_bridge.get_all_storage_items(player);
        assert(all_items.len() == 1, 'Should have 1 non-empty slot');
        
        let (storage_id, item_id) = *all_items.at(0);
        assert(storage_id == 2, 'Remaining item in slot 2');
        assert(item_id == 1, 'Should still be sword');
    }



    #[test]
    #[available_gas(30000000)]
    fn test_integration_token_lookup_consistency() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (storage_bridge_address, _) = world.dns(@"storage_bridge").unwrap();
        let storage_bridge = IStorageBridgeDispatcher { contract_address: storage_bridge_address };

        let (token_factory_address, _) = world.dns(@"token_factory").unwrap();
        let token_factory = ITokenFactoryDispatcher { contract_address: token_factory_address };

        // Setup test item
        let item = Item {
            id: 1,
            name: 'Sword',
            itemType: 1,
            rarity: 1,
            width: 1,
            height: 1,
            price: 100,
            effectType: 0,
            effectStacks: 0,
            effectActivationType: 0,
            chance: 50,
            cooldown: 0,
            energyCost: 0,
            isPlugin: false,
        };
        world.write_model(@item);

        // Before token creation - both should return zero
        let factory_address_before = token_factory.get_token_address(1);
        let bridge_address_before = storage_bridge.get_token_address_for_item(1);
        assert(factory_address_before == contract_address_const::<0>(), 'Factory return zero before');
        assert(bridge_address_before == contract_address_const::<0>(), 'Bridge return zero before');

        // Create token
        let token_address = token_factory.create_token_for_item(1, "Sword Token", "SWORD");

        // After token creation - both should return same address
        let factory_address_after = token_factory.get_token_address(1);
        let bridge_address_after = storage_bridge.get_token_address_for_item(1);
        assert(factory_address_after == token_address, 'Factory return token addr');
        assert(bridge_address_after == token_address, 'Bridge return token addr');
        assert(factory_address_after == bridge_address_after, 'Both return same address');
    }

    #[test]
    #[should_panic(expected: ('Insufficient items in storage',))]
    #[available_gas(30000000)]
    fn test_integration_deposit_insufficient_items() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (storage_bridge_address, _) = world.dns(@"storage_bridge").unwrap();
        let storage_bridge = IStorageBridgeDispatcher { contract_address: storage_bridge_address };

        let (token_factory_address, _) = world.dns(@"token_factory").unwrap();
        let token_factory = ITokenFactoryDispatcher { contract_address: token_factory_address };

        let player = contract_address_const::<0x123>();
        set_contract_address(player);

        // Setup test item
        let item = Item {
            id: 1,
            name: 'Sword',
            itemType: 1,
            rarity: 1,
            width: 1,
            height: 1,
            price: 100,
            effectType: 0,
            effectStacks: 0,
            effectActivationType: 0,
            chance: 50,
            cooldown: 0,
            energyCost: 0,
            isPlugin: false,
        };
        world.write_model(@item);

        // Setup player storage with only 1 sword
        let storage_counter = CharacterItemsStorageCounter { player, count: 1, };
        world.write_model(@storage_counter);
        let storage_1 = CharacterItemStorage { player, id: 1, itemId: 1, };
        world.write_model(@storage_1);

        // Create token
        token_factory.create_token_for_item(1, "Sword Token", "SWORD");

        // Try to deposit 2 swords when only 1 is available - should panic
        storage_bridge.deposit_item(1, 2);
    }

    #[test]
    #[should_panic(expected: ('No token exists for item',))]
    #[available_gas(30000000)]
    fn test_integration_deposit_without_token() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (storage_bridge_address, _) = world.dns(@"storage_bridge").unwrap();
        let storage_bridge = IStorageBridgeDispatcher { contract_address: storage_bridge_address };

        let player = contract_address_const::<0x123>();
        set_contract_address(player);

        // Setup test item
        let item = Item {
            id: 1,
            name: 'Sword',
            itemType: 1,
            rarity: 1,
            width: 1,
            height: 1,
            price: 100,
            effectType: 0,
            effectStacks: 0,
            effectActivationType: 0,
            chance: 50,
            cooldown: 0,
            energyCost: 0,
            isPlugin: false,
        };
        world.write_model(@item);

        // Setup player storage
        let storage_counter = CharacterItemsStorageCounter { player, count: 1, };
        world.write_model(@storage_counter);
        let storage_1 = CharacterItemStorage { player, id: 1, itemId: 1, };
        world.write_model(@storage_1);

        // Try to deposit without creating token first - should panic
        storage_bridge.deposit_item(1, 1);
    }
} 