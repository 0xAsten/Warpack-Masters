#[cfg(test)]
mod tests {
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
        systems::storage_bridge::{storage_bridge, IStorageBridgeDispatcher, IStorageBridgeDispatcherTrait}
    };

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "Warpacks", 
            resources: [
                TestResource::Model(m_Item::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemStorage::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemsStorageCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Contract(storage_bridge::TEST_CLASS_HASH),
            ].span()
        };
        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"Warpacks", @"storage_bridge")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
        ].span()
    }

    #[test]
    #[available_gas(30000000)]
    fn test_get_storage_item_count() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"storage_bridge").unwrap();
        let storage_bridge = IStorageBridgeDispatcher { contract_address };

        let player = contract_address_const::<0x123>();

        // Setup test data
        let storage_counter = CharacterItemsStorageCounter {
            player,
            count: 3,
        };
        world.write_model(@storage_counter);

        // Storage slot 1: Item ID 1 (Sword)
        let storage_1 = CharacterItemStorage {
            player,
            id: 1,
            itemId: 1,
        };
        world.write_model(@storage_1);

        // Storage slot 2: Item ID 1 (Another Sword)
        let storage_2 = CharacterItemStorage {
            player,
            id: 2,
            itemId: 1,
        };
        world.write_model(@storage_2);

        // Storage slot 3: Item ID 2 (Shield)
        let storage_3 = CharacterItemStorage {
            player,
            id: 3,
            itemId: 2,
        };
        world.write_model(@storage_3);

        // Test counting items
        let sword_count = storage_bridge.get_storage_item_count(player, 1);
        assert(sword_count == 2, 'Should have 2 swords');

        let shield_count = storage_bridge.get_storage_item_count(player, 2);
        assert(shield_count == 1, 'Should have 1 shield');

        let nonexistent_count = storage_bridge.get_storage_item_count(player, 99);
        assert(nonexistent_count == 0, 'Should have 0 nonexistent items');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_get_all_storage_items() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"storage_bridge").unwrap();
        let storage_bridge = IStorageBridgeDispatcher { contract_address };

        let player = contract_address_const::<0x123>();

        // Setup test data
        let storage_counter = CharacterItemsStorageCounter {
            player,
            count: 2,
        };
        world.write_model(@storage_counter);

        let storage_1 = CharacterItemStorage {
            player,
            id: 1,
            itemId: 5,
        };
        world.write_model(@storage_1);

        let storage_2 = CharacterItemStorage {
            player,
            id: 2,
            itemId: 10,
        };
        world.write_model(@storage_2);

        // Test getting all storage items
        let all_items = storage_bridge.get_all_storage_items(player);
        
        assert(all_items.len() == 2, 'Should have 2 storage slots');
        
        let (storage_id_1, item_id_1) = *all_items.at(0);
        assert(storage_id_1 == 1, 'First storage ID should be 1');
        assert(item_id_1 == 5, 'First item ID should be 5');

        let (storage_id_2, item_id_2) = *all_items.at(1);
        assert(storage_id_2 == 2, 'Second storage ID should be 2');
        assert(item_id_2 == 10, 'Second item ID should be 10');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_get_token_address_for_item() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"storage_bridge").unwrap();
        let storage_bridge = IStorageBridgeDispatcher { contract_address };

        // Test getting token address for item without token (should return zero)
        let token_address = storage_bridge.get_token_address_for_item(1);
        assert(token_address == contract_address_const::<0>(), 'Should return zero address');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_empty_storage_scenarios() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"storage_bridge").unwrap();
        let storage_bridge = IStorageBridgeDispatcher { contract_address };

        let player = contract_address_const::<0x123>();

        // Setup empty storage
        let storage_counter = CharacterItemsStorageCounter {
            player,
            count: 0,
        };
        world.write_model(@storage_counter);

        // Test with completely empty storage
        let empty_count = storage_bridge.get_storage_item_count(player, 1);
        assert(empty_count == 0, 'Empty storage should return 0');

        let empty_items = storage_bridge.get_all_storage_items(player);
        assert(empty_items.len() == 0, 'Empty storage returns empty');

        let empty_summary = storage_bridge.get_player_storage_summary(player);
        assert(empty_summary.len() == 0, 'Empty storage summary empty');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_storage_with_empty_slots() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"storage_bridge").unwrap();
        let storage_bridge = IStorageBridgeDispatcher { contract_address };

        let player = contract_address_const::<0x123>();

        // Setup storage with some empty slots (itemId = 0)
        let storage_counter = CharacterItemsStorageCounter {
            player,
            count: 4,
        };
        world.write_model(@storage_counter);

        // Slot 1: Item
        let storage_1 = CharacterItemStorage {
            player,
            id: 1,
            itemId: 5,
        };
        world.write_model(@storage_1);

        // Slot 2: Empty (itemId = 0)
        let storage_2 = CharacterItemStorage {
            player,
            id: 2,
            itemId: 0,
        };
        world.write_model(@storage_2);

        // Slot 3: Item
        let storage_3 = CharacterItemStorage {
            player,
            id: 3,
            itemId: 7,
        };
        world.write_model(@storage_3);

        // Slot 4: Empty (itemId = 0)
        let storage_4 = CharacterItemStorage {
            player,
            id: 4,
            itemId: 0,
        };
        world.write_model(@storage_4);

        // Test counting - should ignore empty slots
        let count_5 = storage_bridge.get_storage_item_count(player, 5);
        assert(count_5 == 1, 'Should count 1 item of type 5');

        let count_7 = storage_bridge.get_storage_item_count(player, 7);
        assert(count_7 == 1, 'Should count 1 item of type 7');

        let count_0 = storage_bridge.get_storage_item_count(player, 0);
        assert(count_0 == 0, 'Should not count empty slots');

        // Test get_all_storage_items - should include empty slots
        let all_items = storage_bridge.get_all_storage_items(player);
        assert(all_items.len() == 4, 'Should return all 4 slots');
        
        let (_, item_id_2) = *all_items.at(1);
        assert(item_id_2 == 0, 'Second slot should be empty');

        // Test summary - should only include non-empty items
        let summary = storage_bridge.get_player_storage_summary(player);
        assert(summary.len() == 2, 'Summary has 2 item types');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_large_storage_collection() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"storage_bridge").unwrap();
        let storage_bridge = IStorageBridgeDispatcher { contract_address };

        let player = contract_address_const::<0x123>();

        // Setup larger storage (10 items)
        let storage_counter = CharacterItemsStorageCounter {
            player,
            count: 10,
        };
        world.write_model(@storage_counter);

        // Create pattern: 3 swords, 2 shields, 3 potions, 2 empty slots
        let mut i = 1;
        loop {
            if i > 10 {
                break;
            }

            let item_id = if i <= 3 {
                1 // Sword
            } else if i <= 5 {
                2 // Shield  
            } else if i <= 8 {
                3 // Potion
            } else {
                0 // Empty
            };

            let storage_item = CharacterItemStorage {
                player,
                id: i,
                itemId: item_id,
            };
            world.write_model(@storage_item);

            i += 1;
        };

        // Test counting with larger collection
        let sword_count = storage_bridge.get_storage_item_count(player, 1);
        assert(sword_count == 3, 'Should have 3 swords');

        let shield_count = storage_bridge.get_storage_item_count(player, 2);
        assert(shield_count == 2, 'Should have 2 shields');

        let potion_count = storage_bridge.get_storage_item_count(player, 3);
        assert(potion_count == 3, 'Should have 3 potions');

        // Test all items
        let all_items = storage_bridge.get_all_storage_items(player);
        assert(all_items.len() == 10, 'Should have 10 total slots');

        // Test summary
        let summary = storage_bridge.get_player_storage_summary(player);
        assert(summary.len() == 3, 'Should have 3 unique item types');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_duplicate_item_counting() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"storage_bridge").unwrap();
        let storage_bridge = IStorageBridgeDispatcher { contract_address };

        let player = contract_address_const::<0x123>();

        // Setup storage with many duplicates of same item
        let storage_counter = CharacterItemsStorageCounter {
            player,
            count: 5,
        };
        world.write_model(@storage_counter);

        // All slots have the same item type
        let mut i = 1;
        loop {
            if i > 5 {
                break;
            }

            let storage_item = CharacterItemStorage {
                player,
                id: i,
                itemId: 42, // All same item type
            };
            world.write_model(@storage_item);

            i += 1;
        };

        // Test counting many duplicates
        let count = storage_bridge.get_storage_item_count(player, 42);
        assert(count == 5, 'Should count all 5 duplicates');

        // Test summary with duplicates
        let summary = storage_bridge.get_player_storage_summary(player);
        assert(summary.len() == 1, 'Should have 1 unique item type');
        
        let (item_id, count, _) = *summary.at(0);
        assert(item_id == 42, 'Item ID should be 42');
        assert(count == 5, 'Count should be 5');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_nonexistent_player_storage() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"storage_bridge").unwrap();
        let storage_bridge = IStorageBridgeDispatcher { contract_address };

        let nonexistent_player = contract_address_const::<0x999>();

        // Test with player who has no storage initialized
        let count = storage_bridge.get_storage_item_count(nonexistent_player, 1);
        assert(count == 0, 'Nonexistent player has 0 items');

        let all_items = storage_bridge.get_all_storage_items(nonexistent_player);
        assert(all_items.len() == 0, 'Nonexistent player empty');

        let summary = storage_bridge.get_player_storage_summary(nonexistent_player);
        assert(summary.len() == 0, 'Nonexistent summary empty');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_boundary_conditions() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"storage_bridge").unwrap();
        let storage_bridge = IStorageBridgeDispatcher { contract_address };

        let player = contract_address_const::<0x123>();

        // Test with item ID 0 (should be treated as empty)
        let count_zero = storage_bridge.get_storage_item_count(player, 0);
        assert(count_zero == 0, 'Item ID 0 should return 0 count');

        // Test with very high item IDs
        let count_high = storage_bridge.get_storage_item_count(player, 999999);
        assert(count_high == 0, 'High item ID returns 0 count');

        // Test token address for boundary values
        let token_zero = storage_bridge.get_token_address_for_item(0);
        assert(token_zero == contract_address_const::<0>(), 'Item 0 returns zero address');

        let token_high = storage_bridge.get_token_address_for_item(999999);
        assert(token_high == contract_address_const::<0>(), 'High item returns zero');
    }
} 