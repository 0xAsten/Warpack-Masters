#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_contract_address;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    // import test utils
    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::backpack::{BackpackGrids}, models::Item::{Item, item, ItemsCounter},
        models::CharacterItem::{
            Position, CharacterItemStorage, CharacterItemsStorageCounter, CharacterItemInventory,
            CharacterItemsInventoryCounter
        },
        models::Character::{Character, character, WMClass}, models::Shop::{Shop, shop},
        utils::{test_utils::{add_items}}
    };

    use warpack_masters::systems::actions::actions::ITEMS_COUNTER_ID;

    #[test]
    #[available_gas(3000000000000000)]
    fn test_place_item() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        let item = get!(world, ITEMS_COUNTER_ID, ItemsCounter);
        assert(item.count == 16, 'total item count mismatch');

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        // mock player gold for testing
        let mut player_data = get!(world, alice, (Character));
        player_data.gold = 100;
        set!(world, (player_data));
        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 7;
        shop_data.item2 = 9;
        shop_data.item3 = 8;
        shop_data.item4 = 1;
        set!(world, (shop_data));

        actions_system.buy_item(7);
        // place a sword on (4,2)
        actions_system.place_item(2, 4, 2, 0);
        // (4,2) (4,3) (4,4) should be occupied
        let mut backpack_grid_data = get!(world, (alice, 4, 2), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(4,2) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 4, 3), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(4,3) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 4, 4), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(4,4) should be occupied');

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item id should equal 0');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 3, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 3), CharacterItemInventory);
        assert(invetoryItem.itemId == 7, 'item id should equal 7');
        assert(invetoryItem.position.x == 4, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');

        actions_system.buy_item(9);
        // place a shield on (2,2)
        actions_system.place_item(2, 2, 2, 0);
        // (2,2) (3,2) (2,3) (3,3) should be occupied
        let mut backpack_grid_data = get!(world, (alice, 2, 2), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(2,2) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 3, 2), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(3,2) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 2, 3), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(2,3) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 3, 3), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(3,3) should be occupied');

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item id should equal 0');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 4, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 4), CharacterItemInventory);
        assert(invetoryItem.itemId == 9, 'item id should equal 4');
        assert(invetoryItem.position.x == 2, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');

        actions_system.buy_item(8);
        // place a potion on (5,2)
        actions_system.place_item(2, 5, 2, 0);
        // (5,2) should be occupied
        let mut backpack_grid_data = get!(world, (alice, 5, 2), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(5,2) should be occupied');

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item id should equal 0');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 5, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 5), CharacterItemInventory);
        assert(invetoryItem.itemId == 8, 'item id should equal 6');
        assert(invetoryItem.position.x == 5, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('x out of range', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_x_out_of_range() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();
        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 4;
        set!(world, (shop_data));

        actions_system.buy_item(4);
        // place a sword on (10,0)
        actions_system.place_item(2, 10, 0, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('y out of range', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_y_out_of_range() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 4;
        set!(world, (shop_data));

        actions_system.buy_item(4);
        // place a sword on (0,12)
        actions_system.place_item(2, 0, 12, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid rotation', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_invalid_rotation() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 4;
        set!(world, (shop_data));

        actions_system.buy_item(4);
        // place a sword on (2,2) with rotation 30
        actions_system.place_item(2, 0, 0, 30);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item out of bound for x', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_x_OOB() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 6;
        set!(world, (shop_data));

        actions_system.buy_item(6);
        // place a sword on (8,6) with rotation 90
        actions_system.place_item(2, 8, 6, 90);
    }
    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item out of bound for y', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_y_OOB() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 7;
        set!(world, (shop_data));

        actions_system.buy_item(7);
        // place a sword on (0,5)
        actions_system.place_item(2, 0, 5, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('Already occupied', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_occupied_grids() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 5;
        shop_data.item2 = 6;
        set!(world, (shop_data));

        actions_system.buy_item(5);
        // place a sword on (4,2)
        actions_system.place_item(2, 4, 2, 0);

        actions_system.buy_item(6);
        // try to place the shield on of the occupied grids
        // this will collide with grid (4,2)
        actions_system.place_item(2, 3, 2, 90);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item not owned', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_item_not_owned() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);

        // place a sword on (2,2)
        actions_system.place_item(2, 2, 2, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item not owned', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_item_not_already_placed() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 5;
        set!(world, (shop_data));

        actions_system.buy_item(5);

        // place a sword on (4,2)
        actions_system.place_item(2, 4, 2, 0);
        // try to place the same sword on (5,2)
        actions_system.place_item(2, 5, 2, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_place_item_with_rotation() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        let mut player_data = get!(world, alice, (Character));
        player_data.gold = 100;
        set!(world, (player_data));

        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 4;
        shop_data.item2 = 6;
        shop_data.item3 = 8;
        shop_data.item4 = 1;
        set!(world, (shop_data));

        actions_system.buy_item(6);
        // place a sword on (3,3)
        actions_system.place_item(2, 3, 3, 270);
        // (3,3) (4,3) (5,3) should be occupied
        let mut backpack_grid_data = get!(world, (alice, 3, 3), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(3,3) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 4, 3), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(4,3) should be occupied');

        let invetoryItem = get!(world, (alice, 3), CharacterItemInventory);
        assert(invetoryItem.itemId == 6, 'item id should equal 6');
        assert(invetoryItem.position.x == 3, 'x position mismatch');
        assert(invetoryItem.position.y == 3, 'y position mismatch');
        assert(invetoryItem.rotation == 270, 'rotation mismatch');
    }
}

