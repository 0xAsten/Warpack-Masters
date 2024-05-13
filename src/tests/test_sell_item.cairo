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
        models::CharacterItem::{CharacterItemStorage, CharacterItemsStorageCounter},
        models::Character::{Character, character, WMClass}, models::Shop::{Shop, shop}
    };

    use warpack_masters::systems::actions::actions::{ITEMS_COUNTER_ID, INIT_GOLD, STORAGE_FLAG};


    #[test]
    #[available_gas(3000000000000000)]
    fn test_sell_item() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        let item_one_name = 'Sword';
        let item_one_width = 1;
        let item_one_height = 3;
        let item_one_price = 3;
        let item_one_damage = 10;
        let item_one_armor = 10;
        let item_one_chance = 5;
        let item_one_cooldown = 10;
        let item_one_heal = 5;
        let item_one_rarity = 1;

        let item_two_name = 'Shield';
        let item_two_width = 2;
        let item_two_height = 2;
        let item_two_price = 1;
        let item_two_damage = 0;
        let item_two_armor = 5;
        let item_two_chance = 5;
        let item_two_cooldown = 10;
        let item_two_heal = 5;
        let item_two_rarity = 1;

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
                item_two_rarity,
            );

        set_contract_address(alice);

        actions_system.spawn('Alice', WMClass::Warrior);
        let mut char = get!(world, alice, (Character));
        char.gold = 100;
        set!(world, (char));
        actions_system.reroll_shop();

        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 1;
        shop_data.item2 = 2;
        shop_data.item3 = 1;
        shop_data.item4 = 2;
        set!(world, (shop_data));

        actions_system.buy_item(1);
        let storageItemCount = get!(world, (alice), (CharacterItemsStorageCounter));
        assert(storageItemCount.count == 1, 'storage count mismatch');

        let prev_char_data = get!(world, alice, (Character));

        actions_system.sell_item(1);
        let storageItemCount = get!(world, (alice), (CharacterItemsStorageCounter));
        assert(storageItemCount.count == 1, 'storage count mismatch');

        let char_data = get!(world, alice, (Character));
        assert(
            char_data.gold == prev_char_data.gold + (item_one_price / 2),
            'sell one: gold value mismatch'
        );

        let storageItem = get!(world, (alice, 1), (CharacterItemStorage));
        assert(storageItem.itemId == 0, 'sell one: item id mismatch');

        actions_system.buy_item(2);
        let storageItemCount = get!(world, (alice), (CharacterItemsStorageCounter));
        assert(storageItemCount.count == 1, 'storage count mismatch');

        let prev_char_data = get!(world, alice, (Character));

        actions_system.sell_item(1);
        let storageItemCount = get!(world, (alice), (CharacterItemsStorageCounter));
        assert(storageItemCount.count == 1, 'storage count mismatch');

        let char_data = get!(world, alice, (Character));
        assert(
            char_data.gold == prev_char_data.gold + (item_two_price / 2),
            'sell two: gold value mismatch'
        );

        let storageItem = get!(world, (alice, 1), (CharacterItemStorage));
        assert(storageItem.itemId == 0, 'item id mismatch');

        let storageItem = get!(world, (alice, 2), (CharacterItemStorage));
        assert(storageItem.itemId == 0, 'item id mismatch');

        actions_system.buy_item(1);
        actions_system.buy_item(2);

        let mut shop_data = get!(world, alice, (Shop));
        assert(shop_data.item1 == 0, 'shop item mismatch');
        assert(shop_data.item2 == 0, 'shop item mismatch');
        assert(shop_data.item3 == 0, 'shop item mismatch');
        assert(shop_data.item4 == 0, 'shop item mismatch');
        shop_data.item1 = 1;
        shop_data.item2 = 2;
        shop_data.item3 = 1;
        shop_data.item4 = 2;
        set!(world, (shop_data));

        actions_system.buy_item(2);

        let storageItemCount = get!(world, (alice), (CharacterItemsStorageCounter));
        assert(storageItemCount.count == 3, 'storage count mismatch');

        actions_system.sell_item(2);
        let storageItemCount = get!(world, (alice), (CharacterItemsStorageCounter));
        assert(storageItemCount.count == 3, 'storage count mismatch');

        let storageItem = get!(world, (alice, 1), (CharacterItemStorage));
        assert(storageItem.itemId == 1, 'item id mismatch');
        let storageItem = get!(world, (alice, 2), (CharacterItemStorage));
        assert(storageItem.itemId == 0, 'item id mismatch');
        let storageItem = get!(world, (alice, 3), (CharacterItemStorage));
        assert(storageItem.itemId == 2, 'item id mismatch');

        actions_system.buy_item(1);
        let storageItemCount = get!(world, (alice), (CharacterItemsStorageCounter));
        assert(storageItemCount.count == 3, 'storage count mismatch');

        let storageItem = get!(world, (alice, 1), (CharacterItemStorage));
        assert(storageItem.itemId == 1, 'item id mismatch');
        let storageItem = get!(world, (alice, 2), (CharacterItemStorage));
        assert(storageItem.itemId == 1, 'item id mismatch');
        let storageItem = get!(world, (alice, 3), (CharacterItemStorage));
        assert(storageItem.itemId == 2, 'item id mismatch');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid item_id', 'ENTRYPOINT_FAILED'))]
    fn test_sell_item_with_item_id_0() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH, character::TEST_CLASS_HASH, item::TEST_CLASS_HASH,
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
        actions_system.sell_item(0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid item_id', 'ENTRYPOINT_FAILED'))]
    fn test_sell_item_invalid_item_id() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH, character::TEST_CLASS_HASH, item::TEST_CLASS_HASH,
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
        actions_system.sell_item(2);
    }
}

