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
        models::Character::{Character, character, WMClass}, models::Shop::{Shop, shop}
    };

    use warpack_masters::systems::actions::actions::{ITEMS_COUNTER_ID, INIT_GOLD, STORAGE_FLAG};


    #[test]
    #[available_gas(3000000000000000)]
    fn test_buy_item() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            character_items_counter::TEST_CLASS_HASH,
            character_item::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        let item_one_name = 'Sword';
        let item_one_width = 1;
        let item_one_height = 3;
        let item_one_price = 2;
        let item_one_damage = 10;
        let item_one_armor = 10;
        let item_one_chance = 5;
        let item_one_cooldown = 10;
        let item_one_heal = 5;
        let item_one_rarity = 1;

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

        actions_system.spawn('Alice', WMClass::Warrior);
        actions_system.reroll_shop();

        actions_system.buy_item(1);

        let char_data = get!(world, alice, (Character));
        assert(char_data.gold == INIT_GOLD - item_one_price, 'gold value mismatch');

        let char_item_counter_data = get!(world, alice, (CharacterItemsCounter));
        assert(char_item_counter_data.count == 1, 'total item count mismatch');

        let char_item_data = get!(world, (alice, 1), (CharacterItem));
        assert(char_item_data.id == 1, 'id mismatch');
        assert(char_item_data.itemId == 1, 'item id mismatch');
        assert(char_item_data.where == 'storage', 'where mismatch');
        assert(char_item_data.position.x == STORAGE_FLAG, 'x position mismatch');
        assert(char_item_data.position.y == STORAGE_FLAG, 'y position mismatch');
        assert(char_item_data.rotation == 0, 'rotation mismatch');
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('Not enough gold', 'ENTRYPOINT_FAILED'))]
    fn test_buy_item_revert_not_enough_gold() {
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
        let item_one_rarity = 1;

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

        actions_system.spawn('Alice', WMClass::Warrior);
        actions_system.reroll_shop();

        actions_system.buy_item(1);
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item not on sale', 'ENTRYPOINT_FAILED'))]
    fn test_buy_item_revert_not_on_sale() {
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
        let item_one_rarity = 1;

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

        actions_system.spawn('Alice', WMClass::Warrior);

        actions_system.buy_item(1);
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item not on sale', 'ENTRYPOINT_FAILED'))]
    fn test_buy_item_revert_cannot_buy_multiple() {
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
        let item_one_rarity = 1;

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

        actions_system.spawn('Alice', WMClass::Warrior);
        actions_system.reroll_shop();

        let mut player_data = get!(world, alice, (Character));
        player_data.gold = 100;
        set!(world, (player_data));

        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 1;
        shop_data.item2 = 2;
        shop_data.item3 = 3;
        shop_data.item4 = 3;
        set!(world, (shop_data));

        actions_system.buy_item(1);
        actions_system.buy_item(1);
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid item_id', 'ENTRYPOINT_FAILED'))]
    fn test_buy_item_revert_invalid_item_id() {
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
        let item_one_rarity = 1;

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

        actions_system.spawn('Alice', WMClass::Warrior);
        actions_system.reroll_shop();

        let mut player_data = get!(world, alice, (Character));
        player_data.gold = 100;
        set!(world, (player_data));

        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 1;
        shop_data.item2 = 2;
        shop_data.item3 = 3;
        shop_data.item4 = 3;
        set!(world, (shop_data));

        actions_system.buy_item(1);
        actions_system.buy_item(0);
    }
}

