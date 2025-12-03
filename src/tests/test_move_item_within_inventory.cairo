#[cfg(test)]
mod tests {
    use core::array::{ArrayTrait, SpanTrait};
    use dojo::model::ModelStorage;
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{
        ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
        spawn_test_world,
    };
    use warpack_masters::constants::constants::ITEMS_COUNTER_ID;
    use warpack_masters::models::Character::{Character, WMClass, m_Character, m_CharacterName};
    use warpack_masters::models::CharacterItem::{
        InventoryItem, m_InventoryCounter, m_InventoryItem, m_StorageCounter, m_StorageItem,
    };
    use warpack_masters::models::Game::m_GameConfig;
    use warpack_masters::models::Item::{ItemsCounter, m_Item, m_ItemsCounter};
    use warpack_masters::models::Shop::{Shop, m_Shop};
    use warpack_masters::models::backpack::{BackpackGrids, m_BackpackGrids};
    use warpack_masters::systems::actions::{IActionsDispatcher, IActionsDispatcherTrait, actions};
    use warpack_masters::systems::item::{IItemDispatcher, item_system};
    use warpack_masters::systems::shop::{IShopDispatcher, IShopDispatcherTrait, shop_system};
    use warpack_masters::utils::test_utils::{add_items, setup_rebirth_fee_context};

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "Warpacks",
            resources: [
                TestResource::Model(m_BackpackGrids::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Item::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_ItemsCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_StorageItem::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_StorageCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_InventoryItem::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_InventoryCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Character::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterName::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Shop::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_GameConfig::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Contract(actions::TEST_CLASS_HASH),
                TestResource::Contract(item_system::TEST_CLASS_HASH),
                TestResource::Contract(shop_system::TEST_CLASS_HASH),
                TestResource::Event(actions::e_BuyItem::TEST_CLASS_HASH),
                TestResource::Event(actions::e_SellItem::TEST_CLASS_HASH),
            ]
                .span(),
        };

        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"Warpacks", @"actions")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
            ContractDefTrait::new(@"Warpacks", @"item_system")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
            ContractDefTrait::new(@"Warpacks", @"shop_system")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
        ]
            .span()
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_move_item_within_inventory() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = warpack_masters::utils::address::zero_address();

        add_items(ref item_system);
        let players = array![alice];
        setup_rebirth_fee_context(world, action_system.contract_address, players.span());
        let item: ItemsCounter = world.read_model(ITEMS_COUNTER_ID);
        assert(item.count == 34, 'total item count mismatch');

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // mock player gold for testing
        let mut player_data: Character = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword
        shop_data.item2 = 9; // shield
        shop_data.item3 = 8; // potion
        shop_data.item4 = 1;
        world.write_model(@shop_data);

        // Buy and place a sword initially at (4,2)
        action_system.move_item_from_shop_to_storage(7);
        action_system.move_item_from_storage_to_inventory(2, 4, 2, 0);

        // Verify initial placement
        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 2));
        assert(backpack_grid_data.occupied == true, '(4,2) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 3, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 7, 'item id mismatch');

        let inventoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(inventoryItem.itemId == 7, 'item id should equal 7');
        assert(inventoryItem.position.x == 4, 'x position mismatch');
        assert(inventoryItem.position.y == 2, 'y position mismatch');
        assert(inventoryItem.rotation == 0, 'rotation mismatch');

        // Now move the sword within inventory from (4,2) to (5,2)
        action_system.move_item_within_inventory(3, 5, 2, 0);

        // Verify old position is cleared
        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 2));
        assert(backpack_grid_data.occupied == false, '(4,2) should not be occupied');
        assert(backpack_grid_data.inventoryItemId == 0, 'inventory item id should be 0');
        assert(backpack_grid_data.itemId == 0, 'item id should be 0');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 3));
        assert(backpack_grid_data.occupied == false, '(4,3) should not be occupied');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 4));
        assert(backpack_grid_data.occupied == false, '(4,4) should not be occupied');

        // Verify new position is occupied
        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 5, 2));
        assert(backpack_grid_data.occupied == true, '(6,3) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 3, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 7, 'item id mismatch');
        assert(backpack_grid_data.isWeapon, 'isWeapon mismatch');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 5, 3));
        assert(backpack_grid_data.occupied == true, '(6,4) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 3, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 7, 'item id mismatch');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 5, 4));
        assert(backpack_grid_data.occupied == true, '(6,5) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 3, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 7, 'item id mismatch');

        // Verify inventory item has updated position
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(inventoryItem.itemId == 7, 'item id should equal 7');
        assert(inventoryItem.position.x == 5, 'x position mismatch');
        assert(inventoryItem.position.y == 2, 'y position mismatch');
        assert(inventoryItem.rotation == 0, 'rotation mismatch');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item out of bound for x', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_within_inventory_revert_x_out_of_range() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = warpack_masters::utils::address::zero_address();

        add_items(ref item_system);
        let players = array![alice];
        setup_rebirth_fee_context(world, action_system.contract_address, players.span());

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword
        world.write_model(@shop_data);

        action_system.move_item_from_shop_to_storage(7);
        action_system.move_item_from_storage_to_inventory(2, 4, 2, 0);

        // Try to move to x position that's out of range
        action_system.move_item_within_inventory(3, 10, 0, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item out of bound for y', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_within_inventory_revert_y_out_of_range() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = warpack_masters::utils::address::zero_address();

        add_items(ref item_system);
        let players = array![alice];
        setup_rebirth_fee_context(world, action_system.contract_address, players.span());

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword
        world.write_model(@shop_data);

        action_system.move_item_from_shop_to_storage(7);
        action_system.move_item_from_storage_to_inventory(2, 4, 2, 0);

        // Try to move to y position that's out of range
        action_system.move_item_within_inventory(3, 0, 12, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid rotation', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_within_inventory_revert_invalid_rotation() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = warpack_masters::utils::address::zero_address();

        add_items(ref item_system);
        let players = array![alice];
        setup_rebirth_fee_context(world, action_system.contract_address, players.span());

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword
        world.write_model(@shop_data);

        action_system.move_item_from_shop_to_storage(7);
        action_system.move_item_from_storage_to_inventory(2, 4, 2, 0);

        // Try to move with invalid rotation
        action_system.move_item_within_inventory(3, 2, 2, 30);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item out of bound for y', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_within_inventory_revert_y_OOB() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = warpack_masters::utils::address::zero_address();

        add_items(ref item_system);
        let players = array![alice];
        setup_rebirth_fee_context(world, action_system.contract_address, players.span());

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword (1x3 item)
        world.write_model(@shop_data);

        action_system.move_item_from_shop_to_storage(7);
        action_system.move_item_from_storage_to_inventory(2, 4, 2, 0);

        // Try to move sword to position where it would go out of bounds in y direction
        action_system.move_item_within_inventory(3, 0, 5, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('Already occupied', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_within_inventory_revert_occupied_grids() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = warpack_masters::utils::address::zero_address();

        add_items(ref item_system);
        let players = array![alice];
        setup_rebirth_fee_context(world, action_system.contract_address, players.span());

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword
        shop_data.item2 = 6; // shield
        world.write_model(@shop_data);

        action_system.move_item_from_shop_to_storage(7);
        action_system.move_item_from_storage_to_inventory(2, 4, 2, 0);

        action_system.move_item_from_shop_to_storage(6);
        action_system.move_item_from_storage_to_inventory(2, 2, 2, 0);

        // Try to move the sword to a position that would collide with the shield
        action_system.move_item_within_inventory(3, 2, 2, 90);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item not found', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_within_inventory_revert_item_not_found() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);

        // Try to move an item that doesn't exist in inventory
        action_system.move_item_within_inventory(5, 2, 2, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_move_item_within_inventory_with_rotation() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = warpack_masters::utils::address::zero_address();

        add_items(ref item_system);
        let players = array![alice];
        setup_rebirth_fee_context(world, action_system.contract_address, players.span());

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 6; // shield (2x2)
        world.write_model(@shop_data);

        action_system.move_item_from_shop_to_storage(6);
        // Place shield initially at (3,3) with rotation 0
        action_system.move_item_from_storage_to_inventory(2, 2, 2, 0);

        // Verify initial placement
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(inventoryItem.rotation == 0, 'initial rotation mismatch');

        // Move the shield to a new position with rotation 90
        action_system.move_item_within_inventory(3, 3, 2, 90);

        // Verify new placement with rotation
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(inventoryItem.itemId == 6, 'item id should equal 6');
        assert(inventoryItem.position.x == 3, 'x position mismatch');
        assert(inventoryItem.position.y == 2, 'y position mismatch');
        assert(inventoryItem.rotation == 90, 'rotation mismatch');

        // Verify the grids are occupied correctly for the rotated item
        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 3, 2));
        assert(backpack_grid_data.occupied == true, '(3,2) should be occupied');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 2));
        assert(backpack_grid_data.occupied == true, '(4,2) should be occupied');
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_move_item_within_inventory_with_plugins() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = warpack_masters::utils::address::zero_address();

        add_items(ref item_system);
        let players = array![alice];
        setup_rebirth_fee_context(world, action_system.contract_address, players.span());

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // mock player gold for testing
        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword weapon
        shop_data.item2 = 13; // poison plugin
        shop_data.item3 = 17; // PlagueFlower plugin
        shop_data.item4 = 1;
        world.write_model(@shop_data);

        // Place a plugin first
        action_system.move_item_from_shop_to_storage(13);
        action_system.move_item_from_storage_to_inventory(2, 3, 2, 0);

        // Place a weapon next to the plugin
        action_system.move_item_from_shop_to_storage(7);
        action_system.move_item_from_storage_to_inventory(2, 4, 2, 0);

        // Verify weapon has plugin attached
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 4));
        assert(inventoryItem.plugins.len() == 1, 'plugin length mismatch');
        assert(*inventoryItem.plugins.at(0) == (6, 100, 2), 'plugin data mismatch');

        // Move the weapon away from the plugin
        action_system.move_item_within_inventory(4, 5, 2, 0);

        // Verify weapon no longer has plugin attached
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 4));
        assert(inventoryItem.plugins.len() == 0, 'plugin should be removed');

        // Move the weapon back next to the plugin
        action_system.move_item_within_inventory(4, 4, 2, 0);

        // Verify weapon has plugin attached again
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 4));
        assert(inventoryItem.plugins.len() == 1, 'plugin length mismatch');
        assert(*inventoryItem.plugins.at(0) == (6, 100, 2), 'plugin data mismatch');

        // Add another plugin and test multiple plugins
        action_system.move_item_from_shop_to_storage(1);
        action_system.move_item_from_storage_to_inventory(2, 6, 2, 0);

        action_system.move_item_from_shop_to_storage(17);
        action_system.move_item_from_storage_to_inventory(2, 5, 2, 0);

        // Verify weapon now has both plugins
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 4));
        assert(inventoryItem.plugins.len() == 2, 'plugin length mismatch');
        assert(*inventoryItem.plugins.at(0) == (6, 100, 2), 'first plugin data mismatch');
        assert(*inventoryItem.plugins.at(1) == (6, 80, 3), 'second plugin data mismatch');
    }
}
