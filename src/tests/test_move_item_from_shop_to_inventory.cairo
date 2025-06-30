#[cfg(test)]
mod tests {
    use dojo::model::{ModelStorage};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef, WorldStorageTestTrait};

    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        systems::{item::{item_system, IItemDispatcher}},
        systems::{shop::{shop_system, IShopDispatcher, IShopDispatcherTrait}},
        models::backpack::{BackpackGrids, m_BackpackGrids},
        models::Item::{m_Item, ItemsCounter, m_ItemsCounter},
        models::CharacterItem::{
            m_CharacterItemStorage,
            m_CharacterItemsStorageCounter, CharacterItemInventory, m_CharacterItemInventory,
            CharacterItemsInventoryCounter, m_CharacterItemsInventoryCounter
        },
        models::Character::{Characters, m_Characters, m_NameRecord, WMClass},
        models::Shop::{Shop, m_Shop}, utils::{test_utils::{add_items}}
    };

    use warpack_masters::constants::constants::{ITEMS_COUNTER_ID};

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "Warpacks", 
            resources: [
                TestResource::Model(m_BackpackGrids::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Item::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_ItemsCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemStorage::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemsStorageCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemInventory::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemsInventoryCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Characters::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_NameRecord::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Shop::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Contract(actions::TEST_CLASS_HASH),
                TestResource::Contract(item_system::TEST_CLASS_HASH),
                TestResource::Contract(shop_system::TEST_CLASS_HASH),
                TestResource::Event(actions::e_BuyItem::TEST_CLASS_HASH),
                TestResource::Event(actions::e_SellItem::TEST_CLASS_HASH),
            ].span()
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
        ].span()
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_move_item_from_shop_to_inventory_sword() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();

        add_items(ref item_system);
        let item: ItemsCounter = world.read_model(ITEMS_COUNTER_ID); 
        assert(item.count == 34, 'total item count mismatch');

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // mock player gold for testing
        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword (3x1)
        shop_data.item2 = 0;
        shop_data.item3 = 0;
        shop_data.item4 = 0;
        world.write_model(@shop_data);

        // Buy and place sword directly in inventory at (4,2) with rotation 0
        action_system.move_item_from_shop_to_inventory(7, 4, 2, 0);

        // Verify sword is placed correctly in inventory - occupies (4,2), (4,3), (4,4)
        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 2));
        assert(backpack_grid_data.occupied == true, '(4,2) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 3, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 7, 'item id mismatch');
        assert(backpack_grid_data.isWeapon, 'isWeapon mismatch');
        assert(!backpack_grid_data.isPlugin, 'isPlugin mismatch');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 3));
        assert(backpack_grid_data.occupied == true, '(4,3) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 3, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 7, 'item id mismatch');
        assert(backpack_grid_data.isWeapon, 'isWeapon mismatch');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 4));
        assert(backpack_grid_data.occupied == true, '(4,4) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 3, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 7, 'item id mismatch');
        assert(backpack_grid_data.isWeapon, 'isWeapon mismatch');

        // Verify inventory item is created correctly
        let inventoryItemCounter: CharacterItemsInventoryCounter = world.read_model(alice);
        assert(inventoryItemCounter.count == 3, 'inventory item count mismatch');

        let inventoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(inventoryItem.itemId == 7, 'item id should equal 7');
        assert(inventoryItem.position.x == 4, 'x position mismatch');
        assert(inventoryItem.position.y == 2, 'y position mismatch');
        assert(inventoryItem.rotation == 0, 'rotation mismatch');
        assert(inventoryItem.plugins.len() == 0, 'plugin length mismatch');

        // Verify item is removed from shop
        let shop_data: Shop = world.read_model(alice);
        assert(shop_data.item1 == 0, 'should be removed from shop');

        // Verify gold is deducted
        let player_data: Characters = world.read_model(alice);
        assert(player_data.gold == 98, 'gold should be deducted'); // 100 - 2 (sword price)
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_move_item_from_shop_to_inventory_shield() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // mock player gold for testing
        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item2 = 9; // shield (2x2)
        world.write_model(@shop_data);

        // Buy and place shield directly in inventory at (2,2) with rotation 0
        action_system.move_item_from_shop_to_inventory(9, 2, 2, 0);

        // Verify shield is placed correctly - occupies (2,2), (3,2), (2,3), (3,3)
        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 2, 2));
        assert(backpack_grid_data.occupied == true, '(2,2) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 3, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 9, 'item id mismatch');
        assert(!backpack_grid_data.isWeapon, 'isWeapon mismatch');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 3, 2));
        assert(backpack_grid_data.occupied == true, '(3,2) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 3, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 9, 'item id mismatch');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 2, 3));
        assert(backpack_grid_data.occupied == true, '(2,3) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 3, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 9, 'item id mismatch');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 3, 3));
        assert(backpack_grid_data.occupied == true, '(3,3) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 3, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 9, 'item id mismatch');

        // Verify inventory item is created correctly
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(inventoryItem.itemId == 9, 'item id should equal 9');
        assert(inventoryItem.position.x == 2, 'x position mismatch');
        assert(inventoryItem.position.y == 2, 'y position mismatch');
        assert(inventoryItem.rotation == 0, 'rotation mismatch');
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_move_item_from_shop_to_inventory_potion() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // mock player gold for testing
        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item3 = 8; // potion (1x1)
        world.write_model(@shop_data);

        // Buy and place potion directly in inventory at (5,2)
        action_system.move_item_from_shop_to_inventory(8, 5, 2, 0);

        // Verify potion is placed correctly - occupies only (5,2)
        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 5, 2));
        assert(backpack_grid_data.occupied == true, '(5,2) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 3, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 8, 'item id mismatch');
        assert(!backpack_grid_data.isWeapon, 'isWeapon mismatch');
        assert(!backpack_grid_data.isPlugin, 'isPlugin mismatch');

        // Verify inventory item is created correctly
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(inventoryItem.itemId == 8, 'item id should equal 8');
        assert(inventoryItem.position.x == 5, 'x position mismatch');
        assert(inventoryItem.position.y == 2, 'y position mismatch');
        assert(inventoryItem.rotation == 0, 'rotation mismatch');
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_move_item_from_shop_to_inventory_with_rotation_90() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // mock player gold for testing
        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword (3x1 becomes 1x3 when rotated 90)
        world.write_model(@shop_data);

        // Buy and place sword with 90 degree rotation at (3,2)
        action_system.move_item_from_shop_to_inventory(7, 3, 2, 90);

        // With 90 degree rotation, sword (3x1) becomes (1x3) and occupies (3,2), (4,2), (5,2)
        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 3, 2));
        assert(backpack_grid_data.occupied == true, '(3,2) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 3, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 7, 'item id mismatch');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 2));
        assert(backpack_grid_data.occupied == true, '(4,2) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 3, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 7, 'item id mismatch');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 5, 2));
        assert(backpack_grid_data.occupied == true, '(5,2) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 3, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 7, 'item id mismatch');

        // Verify inventory item has correct rotation
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(inventoryItem.rotation == 90, 'rotation mismatch');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item out of bound for x', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_shop_to_inventory_revert_x_out_of_range() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword
        world.write_model(@shop_data);

        // Try to place at invalid x coordinate (10 is out of range)
        action_system.move_item_from_shop_to_inventory(7, 10, 2, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item out of bound for y', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_shop_to_inventory_revert_y_out_of_range() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword
        world.write_model(@shop_data);

        // Try to place at invalid y coordinate (10 is out of range)
        action_system.move_item_from_shop_to_inventory(7, 4, 10, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid rotation', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_shop_to_inventory_revert_invalid_rotation() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword
        world.write_model(@shop_data);

        // Try to place with invalid rotation (45 is not valid)
        action_system.move_item_from_shop_to_inventory(7, 4, 2, 45);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item not on sale', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_shop_to_inventory_revert_item_not_in_shop() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // Don't put any items in shop, leave it empty
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 0;
        shop_data.item2 = 0;
        shop_data.item3 = 0;
        shop_data.item4 = 0;
        world.write_model(@shop_data);

        // Try to buy item that's not in shop
        action_system.move_item_from_shop_to_inventory(7, 4, 2, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('Not enough gold', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_shop_to_inventory_revert_not_enough_gold() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // Set player gold to 0
        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 0;
        world.write_model(@player_data);

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword costs 5 gold
        world.write_model(@shop_data);

        // Try to buy item without enough gold
        action_system.move_item_from_shop_to_inventory(7, 4, 2, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('Already occupied', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_shop_to_inventory_revert_grid_occupied() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // mock player gold for testing
        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword
        shop_data.item2 = 8; // potion
        world.write_model(@shop_data);

        // Place first item
        action_system.move_item_from_shop_to_inventory(7, 4, 2, 0); // sword at (4,2) occupies (4,2), (4,3), (4,4)

        // Reset shop to allow buying another item
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 8; // potion
        world.write_model(@shop_data);

        // Try to place second item at overlapping position
        action_system.move_item_from_shop_to_inventory(8, 4, 2, 0); // Should fail because (4,2) is occupied
    }

    
} 