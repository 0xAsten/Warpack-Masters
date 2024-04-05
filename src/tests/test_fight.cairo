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
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait, Class}},
        models::backpack::{Backpack, backpack, BackpackGrids, Grid, GridTrait},
        models::Item::{Item, item, ItemsCounter}, models::Character::{Character},
        models::CharacterItem::{CharacterItem, Position, CharacterItemsCounter},
        models::DummyCharacter::{DummyCharacter, DummyCharacterCounter},
        models::DummyCharacterItem::{DummyCharacterItem, DummyCharacterItemsCounter},
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

        actions_system.spawn('alice', Class::Warlock);
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
        assert(dummyChar.class == Class::Warlock, 'class should be Warlock');
        assert(dummyChar.health == char.health, 'health should be equal');
        assert(dummyCharItemsCounter.count == 0, 'Should be 0');
    }
}

