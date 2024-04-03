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

    use warpack_masters::systems::actions::actions::{ITEMS_COUNTER_ID, STORAGE_FLAG};


    #[test]
    #[available_gas(3000000000000000)]
    fn test_undo_place_item() {
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

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 9);
        actions_system.add_item('Shield', 2, 2, 2, 0, 5, 5, 10, 5, 9);
        actions_system.add_item('Potion', 1, 1, 2, 0, 0, 5, 10, 15, 9);

        set_contract_address(alice);
        actions_system.spawn('Alice', Class::Warlock);
        // mock player gold for testing
        let mut player_data = get!(world, alice, (Character));
        player_data.gold = 100;
        set!(world, (player_data));
        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 1;
        shop_data.item2 = 2;
        shop_data.item3 = 1;
        shop_data.item4 = 3;
        set!(world, (shop_data));

        actions_system.buy_item(1);
        // place a sword on (0,4)
        actions_system.place_item(1, 0, 4, 0);

        actions_system.undo_place_item(1);

        let characterItem = get!(world, (alice, 1), CharacterItem);
        assert(characterItem.where == 'storage', 'item should be in storage');
        assert(characterItem.position.x == STORAGE_FLAG, 'x position not STORAGE_FLAG');
        assert(characterItem.position.y == STORAGE_FLAG, 'y position not STORAGE_FLAG');
        assert(characterItem.rotation == 0, 'rotation mismatch');

        let mut backpack_grid_data = get!(world, (alice, 0, 4), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(0,4) should not be occupied');
        let mut backpack_grid_data = get!(world, (alice, 0, 5), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(0,5) should not be occupied');
        let mut backpack_grid_data = get!(world, (alice, 0, 6), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(0,6) should not be occupied');

        actions_system.buy_item(2);
        // place a shield on (1,5)
        actions_system.place_item(2, 1, 5, 0);

        actions_system.undo_place_item(2);

        let characterItem = get!(world, (alice, 2), CharacterItem);
        assert(characterItem.where == 'storage', 'item should be in storage');
        assert(characterItem.position.x == STORAGE_FLAG, 'x position not STORAGE_FLAG');
        assert(characterItem.position.y == STORAGE_FLAG, 'y position not STORAGE_FLAG');
        assert(characterItem.rotation == 0, 'rotation mismatch');

        let mut backpack_grid_data = get!(world, (alice, 1, 5), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(1,5) should not be occupied');
        let mut backpack_grid_data = get!(world, (alice, 1, 6), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(1,6) should not be occupied');
        let mut backpack_grid_data = get!(world, (alice, 2, 5), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(2,5) should not be occupied');
        let mut backpack_grid_data = get!(world, (alice, 2, 6), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(2,6) should not be occupied');

        actions_system.buy_item(3);
        // place a potion on (1,4)
        actions_system.place_item(3, 1, 4, 0);

        actions_system.undo_place_item(3);
        let characterItem = get!(world, (alice, 3), CharacterItem);
        assert(characterItem.where == 'storage', 'item should be in storage');
        assert(characterItem.position.x == STORAGE_FLAG, 'x position not STORAGE_FLAG');
        assert(characterItem.position.y == STORAGE_FLAG, 'y position not STORAGE_FLAG');
        assert(characterItem.rotation == 0, 'rotation mismatch');

        let mut backpack_grid_data = get!(world, (alice, 1, 4), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(1,4) should be occupied');
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item not in inventory', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_not_in_inventory() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH, character::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 1, 3, 100, 10, 10, 5, 10, 5, 9);

        set_contract_address(alice);
        actions_system.spawn('Alice', Class::Warlock);

        actions_system.undo_place_item(1);
    }
}

