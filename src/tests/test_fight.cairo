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
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait, WMClass}},
        models::backpack::{Backpack, backpack, BackpackGrids, Grid, GridTrait},
        models::Item::{Item, item, ItemsCounter}, models::Character::{Character, character},
        models::CharacterItem::{CharacterItem, Position, CharacterItemsCounter},
        models::DummyCharacter::{DummyCharacter, DummyCharacterCounter},
        models::DummyCharacterItem::{DummyCharacterItem, DummyCharacterItemsCounter},
        models::Shop::Shop,
    };

    use warpack_masters::systems::actions::actions::ITEMS_COUNTER_ID;

    #[test]
    #[available_gas(3000000000000000)]
    fn test_dummy() {
        let alice = starknet::contract_address_const::<0x0>();
        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn('alice', WMClass::Warlock);
        actions_system.create_dummy();
        actions_system.fight();

        let char = get!(world, (alice), Character);
        let dummyCharCounter = get!(world, (char.wins), DummyCharacterCounter);
        let dummyChar = get!(world, (char.wins, dummyCharCounter.count), DummyCharacter);
        let dummyCharItemsCounter = get!(
            world, (char.wins, dummyCharCounter.count), DummyCharacterItemsCounter
        );

        assert(char.dummied, 'dummied should be true');
        assert(char.wins == 0, 'wins count should be 0');
        assert(dummyCharCounter.count == 1, 'Should be 1');
        assert(dummyChar.level == char.wins, 'Should be equal');
        assert(dummyChar.id == dummyCharCounter.count, '');
        assert(dummyChar.name == 'alice', 'name should be alice');
        assert(dummyChar.wmClass == WMClass::Warlock, 'class should be Warlock');
        assert(dummyChar.health == char.health, 'health should be equal');
        assert(dummyCharItemsCounter.count == 0, 'Should be 0');
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_sort_array() {
        let alice = starknet::contract_address_const::<0x0>();
        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_item(ref actions_system);

        actions_system.spawn('alice', WMClass::Warlock);
        actions_system.reroll_shop();

        let mut shop = get!(world, alice, (Shop));
        shop.item1 = 1;
        shop.item2 = 2;
        shop.item3 = 3;
        let mut char = get!(world, alice, (Character));
        char.gold = 100;
        set!(world, (shop, char));

        actions_system.buy_item(1);
        actions_system.place_item(1, 0, 0, 0);
        actions_system.buy_item(2);
        actions_system.place_item(2, 1, 0, 0);
        actions_system.buy_item(3);
        actions_system.place_item(3, 1, 2, 0);
        // actions_system.
        actions_system.create_dummy();
        actions_system.fight();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('dummy not created', 'ENTRYPOINT_FAILED'))]
    fn test_revert_dummy_not_created() {
        let alice = starknet::contract_address_const::<0x0>();
        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        set_contract_address(alice);

        actions_system.spawn('alice', WMClass::Warlock);
        actions_system.fight();
    }


    fn add_item(ref actions_system: IActionsDispatcher) {
        let item_one_name = 'Sword';
        let item_one_width = 1;
        let item_one_height = 3;
        let item_one_price = 2;
        let item_one_damage = 10;
        let item_one_armor = 10;
        let item_one_chance = 5;
        let item_one_cooldown = 1;
        let item_one_heal = 5;
        let item_one_rarity = 1;

        let item_two_name = 'Shield';
        let item_two_width = 2;
        let item_two_height = 2;
        let item_two_price = 2;
        let item_two_damage = 0;
        let item_two_armor = 5;
        let item_two_chance = 5;
        let item_two_cooldown = 0;
        let item_two_heal = 5;
        let item_two_rarity = 1;

        let item_three_name = 'Potion';
        let item_three_width = 1;
        let item_three_height = 1;
        let item_three_price = 2;
        let item_three_damage = 0;
        let item_three_armor = 0;
        let item_three_chance = 5;
        let item_three_cooldown = 3;
        let item_three_heal = 15;
        let item_three_rarity = 3;

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

        actions_system
            .add_item(
                item_three_name,
                item_three_width,
                item_three_height,
                item_three_price,
                item_three_damage,
                item_three_armor,
                item_three_chance,
                item_three_cooldown,
                item_three_heal,
                item_three_rarity,
            );
    }
}

