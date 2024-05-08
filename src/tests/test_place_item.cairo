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
        models::backpack::{Backpack, backpack, BackpackGrids, Grid, GridTrait},
        models::Item::{Item, item, ItemsCounter},
        models::CharacterItem::{
            CharacterItem, CharacterItemStorage, CharacterItemsStorageCounter,
            CharacterItemInventory, CharacterItemsInventoryCounter, CharacterItemsCounter, Position
        },
        models::Character::{Character, character, WMClass}, models::Shop::{Shop, shop}
    };

    use warpack_masters::systems::actions::actions::ITEMS_COUNTER_ID;

    #[test]
    #[available_gas(3000000000000000)]
    fn test_place_item() {
        // Error codes
        // SC_B_PI-1 : storage count mismatch before place item 1
        // IC_B_PI-1 : inventory count mismatch before place item 1
        // SC_A_PI-1 : storage count mismatch after place item 1
        // IC_A_PI-1 : inventory count mismatch after place item 1

        // SC_B_PI-2 : storage count mismatch before place item 2
        // IC_B_PI-2 : inventory count mismatch before place item 2
        // SC_A_PI-2 : storage count mismatch after place item 2
        // IC_A_PI-2 : inventory count mismatch after place item 2

        // SC_B_PI-3 : storage count mismatch before place item 3
        // IC_B_PI-3 : inventory count mismatch before place item 3
        // SC_A_PI-3 : storage count mismatch after place item 3
        // IC_A_PI-3 : inventory count mismatch after place item 3

        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1);
        actions_system.add_item('Shield', 2, 2, 2, 0, 5, 5, 10, 5, 1);
        actions_system.add_item('Potion', 1, 1, 2, 0, 0, 5, 10, 15, 2);

        let item = get!(world, ITEMS_COUNTER_ID, ItemsCounter);
        assert(item.count == 3, 'total item count mismatch');

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        // mock player gold for testing
        let mut player_data = get!(world, alice, (Character));
        player_data.gold = 100;
        set!(world, (player_data));
        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 1;
        shop_data.item2 = 2;
        shop_data.item3 = 3;
        shop_data.item4 = 1;
        set!(world, (shop_data));

        actions_system.buy_item(1);

        let mut charItemsStorageCounter = get!(world, alice, CharacterItemsStorageCounter);
        let mut charItemsInventoryCounter = get!(world, alice, CharacterItemsInventoryCounter);

        //before place item storage count should be 1 and inventory count should be 0
        assert(charItemsStorageCounter.count == 1, 'SC_B_PI-1');
        assert(charItemsInventoryCounter.count == 0, 'IC_B_PI-1');

        // place a sword on (0,4)
        actions_system.place_item(1, 0, 0, 0);
        // (0,4) (0,5) (0,6) should be occupied
        let mut backpack_grid_data = get!(world, (alice, 0, 2), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(0,2) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 0, 1), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(0,1) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 0, 0), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(0,0) should be occupied');

        let mut characterItemsCounter = get!(world, alice, CharacterItemsCounter);

        let characterItem = get!(world, (alice, characterItemsCounter.count), CharacterItem);
        charItemsStorageCounter = get!(world, alice, CharacterItemsStorageCounter);
        charItemsInventoryCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(characterItem.itemId == characterItemsCounter.count, 'item id should equal count');
        assert(characterItem.id == 1, 'id mismatch');
        assert(characterItem.storage_id == 0, 'storage_id mismatch');
        assert(
            characterItem.inventory_id == charItemsInventoryCounter.count, 'inventory_id mismatch'
        );
        assert(characterItem.where == 'inventory', 'item should be in inventory');
        assert(characterItem.position.x == 0, 'x position mismatch');
        assert(characterItem.position.y == 0, 'y position mismatch');
        assert(characterItem.rotation == 0, 'rotation mismatch');

        //after place item storage count should be 0 and inventory count should be 1
        assert(charItemsStorageCounter.count == 0, 'SC_A_PI-1');
        assert(charItemsInventoryCounter.count == 1, 'IC_A_PI-1');

        actions_system.buy_item(2);

        charItemsStorageCounter = get!(world, alice, CharacterItemsStorageCounter);
        charItemsInventoryCounter = get!(world, alice, CharacterItemsInventoryCounter);

        //before place item storage count should be 1 and inventory count should be 1
        assert(charItemsStorageCounter.count == 1, 'SC_B_PI-2');
        assert(charItemsInventoryCounter.count == 1, 'IC_B_PI-2');

        // place a shield on (1,5)
        actions_system.place_item(2, 1, 0, 0);
        // (1,5) (1,6) (2,5) (2,6) should be occupied
        let mut backpack_grid_data = get!(world, (alice, 1, 0), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(1,0) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 1, 1), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(1,1) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 2, 0), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(2,0) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 2, 1), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(2,1) should be occupied');

        characterItemsCounter = get!(world, alice, CharacterItemsCounter);
        let characterItem = get!(world, (alice, characterItemsCounter.count), CharacterItem);
        charItemsStorageCounter = get!(world, alice, CharacterItemsStorageCounter);
        charItemsInventoryCounter = get!(world, alice, CharacterItemsInventoryCounter);

        assert(characterItem.itemId == characterItemsCounter.count, 'item id should equal count');
        assert(characterItem.id == 2, 'id mismatch');
        assert(characterItem.storage_id == 0, 'storage_id mismatch');
        assert(
            characterItem.inventory_id == charItemsInventoryCounter.count, 'inventory_id mismatch'
        );
        assert(characterItem.where == 'inventory', 'item should be in inventory');
        assert(characterItem.position.x == 1, 'x position mismatch');
        assert(characterItem.position.y == 0, 'y position mismatch');
        assert(characterItem.rotation == 0, 'rotation mismatch');

        //after place item storage count should be 0 and inventory count should be 2
        assert(charItemsStorageCounter.count == 0, 'SC_A_PI-2');
        assert(charItemsInventoryCounter.count == 2, 'IC_A_PI-2');

        actions_system.buy_item(3);

        charItemsStorageCounter = get!(world, alice, CharacterItemsStorageCounter);
        charItemsInventoryCounter = get!(world, alice, CharacterItemsInventoryCounter);

        //before place item storage count should be 1 and inventory count should be 2
        assert(charItemsStorageCounter.count == 1, 'SC_B_PI-3');
        assert(charItemsInventoryCounter.count == 2, 'IC_B_PI-3');

        // place a potion on (1,4)
        actions_system.place_item(3, 1, 2, 0);
        // (1,4) should be occupied
        let mut backpack_grid_data = get!(world, (alice, 1, 2), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(1,2) should be occupied');

        characterItemsCounter = get!(world, alice, CharacterItemsCounter);
        let characterItem = get!(world, (alice, characterItemsCounter.count), CharacterItem);
        charItemsStorageCounter = get!(world, alice, CharacterItemsStorageCounter);
        charItemsInventoryCounter = get!(world, alice, CharacterItemsInventoryCounter);

        assert(characterItem.itemId == characterItemsCounter.count, 'item id should equal count');
        assert(characterItem.id == 3, 'id mismatch');
        assert(characterItem.storage_id == 0, 'storage_id mismatch');
        assert(
            characterItem.inventory_id == charItemsInventoryCounter.count, 'inventory_id mismatch'
        );
        assert(characterItem.where == 'inventory', 'item should be in inventory');
        assert(characterItem.position.x == 1, 'x position mismatch');
        assert(characterItem.position.y == 2, 'y position mismatch');
        assert(characterItem.rotation == 0, 'rotation mismatch');

        //after place item storage count should be 0 and inventory count should be 3
        assert(charItemsStorageCounter.count == 0, 'SC_A_PI-3');
        assert(charItemsInventoryCounter.count == 3, 'IC_A_PI-3');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('x out of range', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_x_out_of_range() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH, character::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        actions_system.buy_item(1);
        // place a sword on (10,0)
        actions_system.place_item(1, 4, 0, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('y out of range', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_y_out_of_range() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH, character::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        actions_system.buy_item(1);
        // place a sword on (0,10)
        actions_system.place_item(1, 0, 3, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid rotation', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_invalid_rotation() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH, character::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        actions_system.buy_item(1);
        // place a sword on (0,0) with rotation 30
        actions_system.place_item(1, 0, 0, 30);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item out of bound for x', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_x_OOB() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH, character::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        actions_system.buy_item(1);
        // place a sword on (8,6) with rotation 90
        actions_system.place_item(1, 2, 0, 90);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item out of bound for y', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_y_OOB() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH, character::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        actions_system.buy_item(1);
        // place a sword on (0,6)
        actions_system.place_item(1, 0, 1, 0);
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('Already occupied', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_occupied_grids() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH, character::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1);
        actions_system.add_item('Shield', 2, 2, 2, 0, 5, 5, 10, 5, 1);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 1;
        shop_data.item2 = 2;
        shop_data.item3 = 1;
        shop_data.item4 = 2;
        set!(world, (shop_data));

        actions_system.buy_item(1);
        // place a sword on (0,4)
        actions_system.place_item(1, 0, 0, 0);

        actions_system.buy_item(2);
        // try to place the shield on of the occupied grids
        // this will collide with grid (0,4)
        actions_system.place_item(2, 0, 1, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item not owned by the player', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_item_not_owned() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH, character::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1);
        actions_system.add_item('Shield', 2, 2, 2, 0, 5, 5, 10, 5, 1);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);

        // place a sword on (0,4)
        actions_system.place_item(1, 0, 0, 0);
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item already placed', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_item_not_already_placed() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH, character::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        actions_system.reroll_shop();

        actions_system.buy_item(1);

        // place a sword on (0,4)
        actions_system.place_item(1, 0, 0, 0);
        // try to place the same sword on (1,4)
        actions_system.place_item(1, 1, 0, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_place_item_with_rotation() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1);
        actions_system.add_item('Shield', 2, 2, 2, 0, 5, 5, 10, 5, 1);
        actions_system.add_item('Potion', 1, 1, 2, 0, 0, 5, 10, 15, 2);

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

        actions_system.buy_item(1);
        // place a sword on (0,4)
        actions_system.place_item(1, 0, 0, 270);
        // (0,4) (0,5) (0,6) should be occupied
        let mut backpack_grid_data = get!(world, (alice, 2, 0), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(2,0) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 1, 0), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(1,0) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 0, 0), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(0,0) should be occupied');
    }
}

