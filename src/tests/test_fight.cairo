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
        models::backpack::{BackpackGrids}, models::Item::{Item, item, ItemsCounter},
        models::Character::{Character, character},
        models::CharacterItem::{
            Position, CharacterItemStorage, CharacterItemsStorageCounter, CharacterItemInventory,
            CharacterItemsInventoryCounter
        },
        models::DummyCharacter::{DummyCharacter, DummyCharacterCounter},
        models::DummyCharacterItem::{DummyCharacterItem, DummyCharacterItemsCounter},
        models::Shop::Shop, utils::{test_utils::{add_items}}
    };

    use warpack_masters::systems::actions::actions::ITEMS_COUNTER_ID;
    
    #[test]
    #[available_gas(3000000000000000)]
    fn test_dummy() {
        let alice = starknet::contract_address_const::<0x0>();
        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        actions_system.spawn('alice', WMClass::Warlock);
        actions_system.create_dummy();

        let char = get!(world, (alice), Character);
        let dummyChar = get!(world, (char.wins, 1), DummyCharacter);
        assert(dummyChar.level == char.wins, 'Should be equal');
        assert(dummyChar.name == 'alice', 'name should be alice');
        assert(dummyChar.wmClass == WMClass::Warlock, 'class should be Warlock');
        assert(dummyChar.health == char.health, 'health should be equal');
        assert(dummyChar.player == alice, 'player should be alice');
        assert(dummyChar.rating == char.rating, 'rating should be equal');
        assert(dummyChar.rating == 0, 'rating should be 0');

        let bob = starknet::contract_address_const::<0x1>();
        set_contract_address(bob);
        actions_system.spawn('bob', WMClass::Warlock);
        actions_system.create_dummy();

        actions_system.fight();

        let char = get!(world, (bob), Character);
        let dummyChar = get!(world, (0, 1), DummyCharacter);
        if char.wins == 1 {
            assert(dummyChar.rating == 0, 'rating should be 0');
            assert(char.rating == 25, 'rating should be 25')
        } else {
            assert(dummyChar.rating == 25, 'rating should be 25');
            assert(char.rating == 0, 'rating should be 0')
        }
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('only self dummy created', 'ENTRYPOINT_FAILED'))]
    fn test_only_self_dummy_created() {
        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        actions_system.spawn('alice', WMClass::Warlock);
        actions_system.create_dummy();
        actions_system.fight();
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_sort_array() {
        let alice = starknet::contract_address_const::<0x0>();
        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        actions_system.spawn('alice', WMClass::Warlock);

        let mut shop = get!(world, alice, (Shop));
        shop.item1 = 4;
        shop.item2 = 6;
        shop.item3 = 8;
        shop.item4 = 1;
        let mut char = get!(world, alice, (Character));
        char.gold = 100;
        set!(world, (shop, char));

        actions_system.buy_item(4);
        actions_system.place_item(2, 4, 2, 0);
        actions_system.buy_item(6);
        actions_system.place_item(2, 2, 2, 0);
        actions_system.buy_item(8);
        actions_system.place_item(2, 5, 2, 0);
        // actions_system.
        actions_system.create_dummy();

        let bob = starknet::contract_address_const::<0x1>();
        set_contract_address(bob);
        actions_system.spawn('bob', WMClass::Warlock);
        actions_system.create_dummy();
        actions_system.fight();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('dummy not created', 'ENTRYPOINT_FAILED'))]
    fn test_revert_dummy_not_created() {
        let alice = starknet::contract_address_const::<0x0>();
        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);

        actions_system.spawn('alice', WMClass::Warlock);
        actions_system.fight();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('dummy already created', 'ENTRYPOINT_FAILED'))]
    fn test_revert_dummy_already_created() {
        let alice = starknet::contract_address_const::<0x0>();
        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);

        actions_system.spawn('alice', WMClass::Warlock);
        actions_system.create_dummy();
        actions_system.create_dummy();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('dummy not created', 'ENTRYPOINT_FAILED'))]
    fn test_dummy_not_created() {
        starknet::contract_address_const::<0x0>();
        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        actions_system.spawn('alice', WMClass::Warlock);

        actions_system.fight();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('max loss reached', 'ENTRYPOINT_FAILED'))]
    fn test_max_loss_reached() {
        let alice = starknet::contract_address_const::<0x0>();
        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        actions_system.spawn('alice', WMClass::Warlock);

        let mut char = get!(world, (alice), Character);
        char.loss = 5;
        set!(world, (char));

        actions_system.create_dummy();
        actions_system.fight();
    }
}

