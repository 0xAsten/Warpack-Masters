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
            CharacterItemStorage, m_CharacterItemStorage, CharacterItemsStorageCounter,
            m_CharacterItemsStorageCounter, CharacterItemInventory, m_CharacterItemInventory,
            CharacterItemsInventoryCounter, m_CharacterItemsInventoryCounter
        },
        models::Character::{Characters, m_Characters, m_NameRecord, WMClass},
        models::Shop::{Shop, m_Shop}, utils::{test_utils::{add_items}}
    };

    use warpack_masters::constants::constants::ITEMS_COUNTER_ID;

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
                TestResource::Event(shop_system::e_BuyItem::TEST_CLASS_HASH),
                TestResource::Event(shop_system::e_SellItem::TEST_CLASS_HASH),
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
    fn test_move_item_from_storage_to_inventory() {
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
        shop_data.item1 = 7;
        shop_data.item2 = 9;
        shop_data.item3 = 8;
        shop_data.item4 = 1;
        world.write_model(@shop_data);

        shop_system.buy_item(7);
        // place a sword on (4,2)
        action_system.move_item_from_storage_to_inventory(2, 4, 2, 0);
        // (4,2) (4,3) (4,4) should be occupied
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
        assert(!backpack_grid_data.isPlugin, 'isPlugin mismatch');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 4));
        assert(backpack_grid_data.occupied == true, '(4,4) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 3, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 7, 'item id mismatch');
        assert(backpack_grid_data.isWeapon, 'isWeapon mismatch');
        assert(!backpack_grid_data.isPlugin, 'isPlugin mismatch');

        let storageItemCounter: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');

        let storageItem: CharacterItemStorage =  world.read_model((alice, 2));
        assert(storageItem.itemId == 0, 'item id should equal 0');

        let inventoryItemCounter: CharacterItemsInventoryCounter = world.read_model(alice);
        assert(inventoryItemCounter.count == 3, 'inventory item count mismatch');

        let invetoryItem: CharacterItemInventory =  world.read_model((alice, 3));
        assert(invetoryItem.itemId == 7, 'item id should equal 7');
        assert(invetoryItem.position.x == 4, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugin length mismatch');

        shop_system.buy_item(9);
        // place a shield on (2,2)
        action_system.move_item_from_storage_to_inventory(2, 2, 2, 0);
        // (2,2) (3,2) (2,3) (3,3) should be occupied
        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 2, 2));
        assert(backpack_grid_data.occupied == true, '(2,2) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 4, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 9, 'item id mismatch');
        assert(!backpack_grid_data.isWeapon, 'isWeapon mismatch');
        assert(!backpack_grid_data.isPlugin, 'isPlugin mismatch');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 3, 2));
        assert(backpack_grid_data.occupied == true, '(3,2) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 4, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 9, 'item id mismatch');
        assert(!backpack_grid_data.isWeapon, 'isWeapon mismatch');
        assert(!backpack_grid_data.isPlugin, 'isPlugin mismatch');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 2, 3));
        assert(backpack_grid_data.occupied == true, '(2,3) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 4, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 9, 'item id mismatch');
        assert(!backpack_grid_data.isWeapon, 'isWeapon mismatch');
        assert(!backpack_grid_data.isPlugin, 'isPlugin mismatch');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 3, 3));
        assert(backpack_grid_data.occupied == true, '(3,3) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 4, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 9, 'item id mismatch');
        assert(!backpack_grid_data.isWeapon, 'isWeapon mismatch');
        assert(!backpack_grid_data.isPlugin, 'isPlugin mismatch');

        let storageItemCounter: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');

        let storageItem: CharacterItemStorage =  world.read_model((alice, 2));
        assert(storageItem.itemId == 0, 'item id should equal 0');

        let inventoryItemCounter: CharacterItemsInventoryCounter = world.read_model(alice);
        assert(inventoryItemCounter.count == 4, 'inventory item count mismatch');

        let invetoryItem: CharacterItemInventory =  world.read_model((alice, 4));
        assert(invetoryItem.itemId == 9, 'item id should equal 4');
        assert(invetoryItem.position.x == 2, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugin length mismatch');

        shop_system.buy_item(8);
        // place a potion on (5,2)
        action_system.move_item_from_storage_to_inventory(2, 5, 2, 0);
        // (5,2) should be occupied
        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 5, 2));
        assert(backpack_grid_data.occupied == true, '(5,2) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 5, 'inventory item id mismatch');
        assert(backpack_grid_data.itemId == 8, 'item id mismatch');
        assert(!backpack_grid_data.isWeapon, 'isWeapon mismatch');
        assert(!backpack_grid_data.isPlugin, 'isPlugin mismatch');

        let storageItemCounter: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');

        let storageItem: CharacterItemStorage =  world.read_model((alice, 2));
        assert(storageItem.itemId == 0, 'item id should equal 0');

        let inventoryItemCounter: CharacterItemsInventoryCounter = world.read_model(alice);
        assert(inventoryItemCounter.count == 5, 'inventory item count mismatch');

        let invetoryItem: CharacterItemInventory =  world.read_model((alice, 5));
        assert(invetoryItem.itemId == 8, 'item id should equal 6');
        assert(invetoryItem.position.x == 5, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugin length mismatch');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('x out of range', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_storage_to_inventory_revert_x_out_of_range() {
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
        shop_data.item1 = 4;
        world.write_model(@shop_data);

        shop_system.buy_item(4);
        // place a sword on (10,0)
        action_system.move_item_from_storage_to_inventory(2, 10, 0, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('y out of range', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_storage_to_inventory_revert_y_out_of_range() {
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
        shop_data.item1 = 4;
        world.write_model(@shop_data);

        shop_system.buy_item(4);
        // place a sword on (0,12)
        action_system.move_item_from_storage_to_inventory(2, 0, 12, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid rotation', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_storage_to_inventory_revert_invalid_rotation() {
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
        shop_data.item1 = 4;
        world.write_model(@shop_data);

        shop_system.buy_item(4);
        // place a sword on (2,2) with rotation 30
        action_system.move_item_from_storage_to_inventory(2, 0, 0, 30);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item out of bound for x', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_storage_to_inventory_revert_x_OOB() {
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
        shop_data.item1 = 6;
        world.write_model(@shop_data);

        shop_system.buy_item(6);
        // place a sword on (8,6) with rotation 90
        action_system.move_item_from_storage_to_inventory(2, 8, 6, 90);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item out of bound for y', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_storage_to_inventory_revert_y_OOB() {
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
        shop_data.item1 = 7;
        world.write_model(@shop_data);

        shop_system.buy_item(7);
        // place a sword on (0,5)
        action_system.move_item_from_storage_to_inventory(2, 0, 5, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('Already occupied', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_storage_to_inventory_revert_occupied_grids() {
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
        shop_data.item1 = 5;
        shop_data.item2 = 6;
        world.write_model(@shop_data);

        shop_system.buy_item(5);
        // place a sword on (4,2)
        action_system.move_item_from_storage_to_inventory(2, 4, 2, 0);

        shop_system.buy_item(6);
        // try to place the shield on of the occupied grids
        // this will collide with grid (4,2)
        action_system.move_item_from_storage_to_inventory(2, 3, 2, 90);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item not found', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_storage_to_inventory_revert_item_not_owned() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);

        // place a sword on (2,2)
        action_system.move_item_from_storage_to_inventory(2, 2, 2, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item not found', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_storage_to_inventory_revert_item_not_already_placed() {
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
        shop_data.item1 = 5;
        world.write_model(@shop_data);

        shop_system.buy_item(5);

        // place a sword on (4,2)
        action_system.move_item_from_storage_to_inventory(2, 4, 2, 0);
        // try to place the same sword on (5,2)
        action_system.move_item_from_storage_to_inventory(2, 5, 2, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_move_item_from_storage_to_inventory_with_rotation() {
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

        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 4;
        shop_data.item2 = 6;
        shop_data.item3 = 8;
        shop_data.item4 = 1;
        world.write_model(@shop_data);

        shop_system.buy_item(6);
        // place a sword on (3,3)
        action_system.move_item_from_storage_to_inventory(2, 3, 3, 270);
        // (3,3) (4,3) (5,3) should be occupied
        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 3, 3));
        assert(backpack_grid_data.occupied == true, '(3,3) should be occupied');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 3));
        assert(backpack_grid_data.occupied == true, '(4,3) should be occupied');

        let inventoryItem: CharacterItemInventory =  world.read_model((alice, 3));
        assert(inventoryItem.itemId == 6, 'item id should equal 6');
        assert(inventoryItem.position.x == 3, 'x position mismatch');
        assert(inventoryItem.position.y == 3, 'y position mismatch');
        assert(inventoryItem.rotation == 270, 'rotation mismatch');
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_move_item_from_storage_to_inventory_with_plugins_check() {
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
        shop_data.item1 = 7; // sword weapon
        shop_data.item2 = 13; // poison plugin
        shop_data.item3 = 17; // PlagueFlower plugin
        shop_data.item4 = 1;
        world.write_model(@shop_data);

        shop_system.buy_item(13);
        action_system.move_item_from_storage_to_inventory(2, 5, 2, 0);
        // (5, 2) should be occupied
        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 5, 2));
        assert(backpack_grid_data.isPlugin, 'isPlugin mismatch');
        let inventoryItem: CharacterItemInventory =  world.read_model((alice, 3));
        assert(inventoryItem.plugins.len() == 0, 'plugin length mismatch');

        shop_system.buy_item(7);
        // place a sword on (4,2)
        action_system.move_item_from_storage_to_inventory(2, 4, 2, 0);
        // (4,2) (4,3) (4,4) should be occupied
        let inventoryItem: CharacterItemInventory =  world.read_model((alice, 4));
        assert(inventoryItem.plugins.len() == 1, 'plugin length mismatch');
        assert(*inventoryItem.plugins.at(0) == (6, 100, 2), 'plugin length mismatch');
        
        shop_system.buy_item(17);
        action_system.move_item_from_storage_to_inventory(2, 2, 2, 0);
        let inventoryItem: CharacterItemInventory =  world.read_model((alice, 5));
        assert(inventoryItem.plugins.len() == 0, 'plugin length mismatch');

        let inventoryItem: CharacterItemInventory =  world.read_model((alice, 4));
        assert(inventoryItem.plugins.len() == 2, 'plugin length mismatch');
        assert(*inventoryItem.plugins.at(0) == (6, 100, 2), 'plugin length mismatch');
        assert(*inventoryItem.plugins.at(1) == (6, 80, 3), 'plugin length mismatch');
    }
}

