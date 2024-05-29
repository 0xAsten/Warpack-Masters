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
        assert(item.count == 13, 'total item count mismatch');

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        // mock player gold for testing
        let mut player_data = get!(world, alice, (Character));
        player_data.gold = 100;
        set!(world, (player_data));
        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 2;
        shop_data.item2 = 4;
        shop_data.item3 = 6;
        shop_data.item4 = 1;
        set!(world, (shop_data));

        actions_system.buy_item(2);
        // place a sword on (0,0)
        actions_system.place_item(1, 0, 0, 0);
        // (0,4) (0,5) (0,6) should be occupied
        let mut backpack_grid_data = get!(world, (alice, 0, 2), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(0,2) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 0, 1), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(0,1) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 0, 0), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(0,0) should be occupied');

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 1, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item id should equal 0');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 1, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 1), CharacterItemInventory);
        assert(invetoryItem.itemId == 2, 'item id should equal 2');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');

        actions_system.buy_item(4);
        // place a shield on (1,0)
        actions_system.place_item(1, 1, 0, 0);
        // (1,5) (1,6) (2,5) (2,6) should be occupied
        let mut backpack_grid_data = get!(world, (alice, 1, 0), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(1,0) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 1, 1), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(1,1) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 2, 0), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(2,0) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 2, 1), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(2,1) should be occupied');

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 1, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item id should equal 0');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 2, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 2), CharacterItemInventory);
        assert(invetoryItem.itemId == 4, 'item id should equal 4');
        assert(invetoryItem.position.x == 1, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');

        actions_system.buy_item(6);
        // place a potion on (1,2)
        actions_system.place_item(1, 1, 2, 0);
        // (1,4) should be occupied
        let mut backpack_grid_data = get!(world, (alice, 1, 2), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(1,2) should be occupied');

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 1, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item id should equal 0');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 3, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 3), CharacterItemInventory);
        assert(invetoryItem.itemId == 6, 'item id should equal 6');
        assert(invetoryItem.position.x == 1, 'x position mismatch');
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
        shop_data.item1 = 2;
        set!(world, (shop_data));

        actions_system.buy_item(2);
        // place a sword on (4,0)
        actions_system.place_item(1, 4, 0, 0);
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
        shop_data.item1 = 2;
        set!(world, (shop_data));

        actions_system.buy_item(2);
        // place a sword on (0,3)
        actions_system.place_item(1, 0, 3, 0);
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
        shop_data.item1 = 2;
        set!(world, (shop_data));

        actions_system.buy_item(2);
        // place a sword on (0,0) with rotation 30
        actions_system.place_item(1, 0, 0, 30);
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
        shop_data.item1 = 2;
        set!(world, (shop_data));

        actions_system.buy_item(2);
        // place a sword on (2,0) with rotation 90
        actions_system.place_item(1, 2, 0, 90);
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
        shop_data.item1 = 2;
        set!(world, (shop_data));

        actions_system.buy_item(2);
        // place a sword on (0,1)
        actions_system.place_item(1, 0, 1, 0);
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
        shop_data.item1 = 2;
        shop_data.item2 = 4;
        set!(world, (shop_data));

        actions_system.buy_item(2);
        // place a sword on (0,0)
        actions_system.place_item(1, 0, 0, 0);

        actions_system.buy_item(4);
        // try to place the shield on of the occupied grids
        // this will collide with grid (0,1)
        actions_system.place_item(1, 0, 1, 0);
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

        // place a sword on (0,0)
        actions_system.place_item(1, 0, 0, 0);
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
        shop_data.item1 = 2;
        set!(world, (shop_data));

        actions_system.buy_item(2);

        // place a sword on (0,0)
        actions_system.place_item(1, 0, 0, 0);
        // try to place the same sword on (1,0)
        actions_system.place_item(1, 1, 0, 0);
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
        shop_data.item1 = 1;
        shop_data.item2 = 2;
        shop_data.item3 = 3;
        shop_data.item4 = 1;
        set!(world, (shop_data));

        actions_system.buy_item(2);
        // place a sword on (2,0)
        actions_system.place_item(1, 0, 0, 270);
        // (0,0) (1,0) (2,0) should be occupied
        let mut backpack_grid_data = get!(world, (alice, 2, 0), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(2,0) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 1, 0), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(1,0) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 0, 0), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(0,0) should be occupied');
    }
}

