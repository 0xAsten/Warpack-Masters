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
        models::CharacterItem::{CharacterItem, Position, CharacterItemsCounter},
        models::Character::{Character, character, Class}, models::Shop::{Shop, shop}
    };

    use warpack_masters::systems::actions::actions::ITEMS_COUNTER_ID;


    #[test]
    #[available_gas(3000000000000000)]
    fn test_place_item() {
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

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1, 'Weapon', '', 0, 0);
        actions_system.add_item('Shield', 2, 2, 2, 0, 5, 5, 10, 5, 1, 'Weapon', '', 0, 0);
        actions_system.add_item('Potion', 1, 1, 2, 0, 0, 5, 10, 15, 2, 'Buff', 'Health', 0, 2);

        let item = get!(world, ITEMS_COUNTER_ID, ItemsCounter);
        assert(item.count == 3, 'total item count mismatch');

        set_contract_address(alice);
        actions_system.spawn('Alice', Class::Warlock);
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
        // place a sword on (0,4)
        actions_system.place_item(1, 0, 4, 0);
        // (0,4) (0,5) (0,6) should be occupied
        let mut backpack_grid_data = get!(world, (alice, 0, 4), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(0,4) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 0, 5), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(0,5) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 0, 6), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(0,6) should be occupied');

        let mut characterItemsCounter = get!(world, alice, CharacterItemsCounter);
        let characterItem = get!(world, (alice, characterItemsCounter.count), CharacterItem);
        assert(characterItem.itemId == characterItemsCounter.count, 'item id should equal count');
        assert(characterItem.where == 'inventory', 'item should be in inventory');
        assert(characterItem.position.x == 0, 'x position mismatch');
        assert(characterItem.position.y == 4, 'y position mismatch');
        assert(characterItem.rotation == 0, 'rotation mismatch');

        actions_system.buy_item(2);
        // place a shield on (1,5)
        actions_system.place_item(2, 1, 5, 0);
        // (1,5) (1,6) (2,5) (2,6) should be occupied
        let mut backpack_grid_data = get!(world, (alice, 1, 5), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(1,5) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 1, 6), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(1,6) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 2, 5), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(2,5) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 2, 6), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(2,6) should be occupied');

        characterItemsCounter = get!(world, alice, CharacterItemsCounter);
        let characterItem = get!(world, (alice, characterItemsCounter.count), CharacterItem);
        assert(characterItem.itemId == characterItemsCounter.count, 'item id should equal count');
        assert(characterItem.where == 'inventory', 'item should be in inventory');
        assert(characterItem.position.x == 1, 'x position mismatch');
        assert(characterItem.position.y == 5, 'y position mismatch');
        assert(characterItem.rotation == 0, 'rotation mismatch');

        actions_system.buy_item(3);
        // place a potion on (1,4)
        actions_system.place_item(3, 1, 4, 0);
        // (1,4) should be occupied
        let mut backpack_grid_data = get!(world, (alice, 1, 4), BackpackGrids);
        assert(backpack_grid_data.occupied == true, '(1,4) should be occupied');

        characterItemsCounter = get!(world, alice, CharacterItemsCounter);
        let characterItem = get!(world, (alice, characterItemsCounter.count), CharacterItem);
        // assert(characterItem.itemId == characterItemsCounter.count, 'item id should equal count');
        assert(characterItem.where == 'inventory', 'item should be in inventory');
        assert(characterItem.position.x == 1, 'x position mismatch');
        assert(characterItem.position.y == 4, 'y position mismatch');
        assert(characterItem.rotation == 0, 'rotation mismatch');
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

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1, 'Weapon', '', 0, 0);

        set_contract_address(alice);
        actions_system.spawn('Alice', Class::Warlock);
        actions_system.reroll_shop();

        actions_system.buy_item(1);
        // place a sword on (10,0)
        actions_system.place_item(1, 10, 0, 0);
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

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1, 'Weapon', '', 0, 0);

        set_contract_address(alice);
        actions_system.spawn('Alice', Class::Warlock);
        actions_system.reroll_shop();

        actions_system.buy_item(1);
        // place a sword on (0,10)
        actions_system.place_item(1, 0, 10, 0);
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

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1, 'Weapon', '', 0, 0);

        set_contract_address(alice);
        actions_system.spawn('Alice', Class::Warlock);
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

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1, 'Weapon', '', 0, 0);

        set_contract_address(alice);
        actions_system.spawn('Alice', Class::Warlock);
        actions_system.reroll_shop();

        actions_system.buy_item(1);
        // place a sword on (8,6) with rotation 90
        actions_system.place_item(1, 8, 6, 90);
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

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1, 'Weapon', '', 0, 0);

        set_contract_address(alice);
        actions_system.spawn('Alice', Class::Warlock);
        actions_system.reroll_shop();

        actions_system.buy_item(1);
        // place a sword on (0,6)
        actions_system.place_item(1, 0, 6, 0);
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

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1, 'Weapon', '', 0, 0);
        actions_system.add_item('Shield', 2, 2, 2, 0, 5, 5, 10, 5, 1, 'Weapon', '', 0, 0);

        set_contract_address(alice);
        actions_system.spawn('Alice', Class::Warlock);
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
        actions_system.place_item(1, 0, 4, 0);

        actions_system.buy_item(2);
        // try to place the shield on of the occupied grids
        // this will collide with grid (0,4)
        actions_system.place_item(2, 0, 3, 0);
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

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1, 'Weapon', '', 0, 0);
        actions_system.add_item('Shield', 2, 2, 2, 0, 5, 5, 10, 5, 1, 'Weapon', '', 0, 0);

        set_contract_address(alice);
        actions_system.spawn('Alice', Class::Warlock);

        // place a sword on (0,4)
        actions_system.place_item(1, 0, 4, 0);
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

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1, 'Weapon', '', 0, 0);

        set_contract_address(alice);
        actions_system.spawn('Alice', Class::Warlock);
        actions_system.reroll_shop();

        actions_system.buy_item(1);

        // place a sword on (0,4)
        actions_system.place_item(1, 0, 4, 0);
        // try to place the same sword on (1,4)
        actions_system.place_item(1, 1, 4, 0);
    }
}

