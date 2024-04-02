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
            CharacterItemsCounter, character_items_counter, CharacterItem, character_item
        },
        models::Character::{Character, character, Class},
    };

    use warpack_masters::systems::actions::actions::{ITEMS_COUNTER_ID, INIT_GOLD, STORAGE_FLAG};
    use debug::PrintTrait;


    #[test]
    #[available_gas(3000000000000000)]
    fn test_buy_item() {
        let owner = starknet::contract_address_const::<0x0>();
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            character_items_counter::TEST_CLASS_HASH,
            character_item::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        let item_one_name = 'Sword';
        let item_one_width = 1;
        let item_one_height = 3;
        let item_one_price = 4;
        let item_one_damage = 10;
        let item_one_armor = 10;
        let item_one_chance = 5;
        let item_one_cooldown = 10;
        let item_one_heal = 5;
        let item_one_rarity = 5;

        let item_two_name = 'Shield';
        let item_two_width = 2;
        let item_two_height = 2;
        let item_two_price = 2;
        let item_two_damage = 0;
        let item_two_armor = 5;
        let item_two_chance = 5;
        let item_two_cooldown = 10;
        let item_two_heal = 5;
        let item_two_rarity = 5;

        actions_system
            .add_item(
                item_one_name,
                item_one_width,
                item_one_height,
                item_one_price,
                item_one_damage,
                item_one_armor,
                item_one_chance,
                item_one_cooldown,
                item_one_heal,
                item_one_rarity,
            );

        actions_system
            .add_item(
                item_two_name,
                item_two_width,
                item_two_height,
                item_two_price,
                item_two_damage,
                item_two_armor,
                item_two_chance,
                item_two_cooldown,
                item_two_heal,
                item_two_rarity
            );

        set_contract_address(alice);

        actions_system.spawn('Alice', Class::Warrior);

        actions_system.buy_item(1);
        let prev_char_data = get!(world, alice, (Character));

        actions_system.sell_item(1);
        let char_data = get!(world, alice, (Character));
        assert(
            char_data.gold == prev_char_data.gold + (item_one_price / 2),
            'sell one: gold value mismatch'
        );
        let char_item_counter_data = get!(world, alice, (CharacterItemsCounter));
        assert(char_item_counter_data.count == 0, 'sell one: itemcount mismatch');
        let char_item_data = get!(world, (alice, 1), (CharacterItem));
        assert(char_item_data.itemId == 0, 'sell one: item id mismatch');
        assert(char_item_data.where == '', 'sell one: where mismatch');
        assert(char_item_data.position.x == 0, 'sell one: x position mismatch');
        assert(char_item_data.position.y == 0, 'sell one: y position mismatch');
        assert(char_item_data.rotation == 0, 'sell one: rotation mismatch');

        actions_system.buy_item(2);
        let prev_char_data = get!(world, alice, (Character));

        actions_system.sell_item(1);
        let char_data = get!(world, alice, (Character));
        assert(
            char_data.gold == prev_char_data.gold + (item_two_price / 2),
            'sell two: gold value mismatch'
        );
        let char_item_counter_data = get!(world, alice, (CharacterItemsCounter));
        assert(char_item_counter_data.count == 0, 'sell two: itemcount mismatch');
        let char_item_data = get!(world, (alice, 1), (CharacterItem));
        assert(char_item_data.itemId == 0, 'sell two: item id mismatch');
        assert(char_item_data.where == '', 'sell two: where mismatch');
        assert(char_item_data.position.x == 0, 'sell two: x position mismatch');
        assert(char_item_data.position.y == 0, 'sell two: y position mismatch');
        assert(char_item_data.rotation == 0, 'sell two: rotation mismatch');
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item not owned', 'ENTRYPOINT_FAILED'))]
    fn test_edit_item_revert_item_not_owned() {
        let owner = starknet::contract_address_const::<0x0>();
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            character_items_counter::TEST_CLASS_HASH,
            character_item::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        let item_one_name = 'Sword';
        let item_one_width = 1;
        let item_one_height = 3;
        let item_one_price = INIT_GOLD + 10;
        let item_one_damage = 10;
        let item_one_armor = 10;
        let item_one_chance = 5;
        let item_one_cooldown = 10;
        let item_one_heal = 5;
        let item_one_rarity = 5;

        actions_system
            .add_item(
                item_one_name,
                item_one_width,
                item_one_height,
                item_one_price,
                item_one_damage,
                item_one_armor,
                item_one_chance,
                item_one_cooldown,
                item_one_heal,
                item_one_rarity,
            );

        set_contract_address(alice);

        actions_system.spawn('Alice', Class::Warrior);

        actions_system.sell_item(1);
    }
}

