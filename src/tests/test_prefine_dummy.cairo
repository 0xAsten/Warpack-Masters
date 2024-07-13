#[cfg(test)]
mod tests {
    use core::option::OptionTrait;
use core::array::ArrayTrait;
use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_contract_address;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    // import test utils
    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::Character::{WMClass},
        models::DummyCharacter::{DummyCharacter, DummyCharacterCounter},
        models::DummyCharacterItem::{DummyCharacterItem, DummyCharacterItemsCounter},
        utils::{test_utils::{add_items}}
    };

    use warpack_masters::prdefined_dummies::{PredefinedItem, Dummy0, Dummy1};

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('player not world owner', 'ENTRYPOINT_FAILED'))]
    fn test_prefine_dummy_non_admin() {
        let mut models = array![];
        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };
        add_items(ref actions_system);

        let alice = starknet::contract_address_const::<0x1>();
        set_contract_address(alice);

        actions_system.prefine_dummy(0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_prefine_dummy() {
        let mut models = array![];
        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };
        add_items(ref actions_system);

        let mut level = 0;
        actions_system.prefine_dummy(level);

        let dummyCharCounter = get!(world, level, DummyCharacterCounter);
        assert(dummyCharCounter.count == 1, 'Should be equal 1');

        let dummyChar = get!(world, (level, 1), DummyCharacter);
        assert(dummyChar.level == level, 'Should be equal 0');
        assert(dummyChar.id == 1, 'Should be equal 1');
        assert(dummyChar.name == Dummy0::name, 'Should be equal Dummy0::name');
        let mut dummyClassNo: u8 = 0;
        match dummyChar.wmClass {
            WMClass::Warrior => {
                dummyClassNo = 0;
            },
            WMClass::Warlock => {
                dummyClassNo = 1;
            },
        }
        assert(dummyClassNo == Dummy0::wmClass, 'Should be equal Dummy0::wmClass');
        assert(dummyChar.health == Dummy0::health, 'Should be equal Dummy0::health');
        assert(dummyChar.player == starknet::contract_address_const::<0x0>(), 'Should be equal 0x0');
        assert(dummyChar.rating == 0, 'Should be equal 0');

        let dummyCharItemsCounter = get!(world, (level, dummyChar.id), DummyCharacterItemsCounter);
        let mut items = Dummy0::get_items();
        assert(dummyCharItemsCounter.count == items.len(), 'Should be equal items length');

        let mut i = 1;
        loop {
            if items.len() == 0 {
                break;
            }
            let item = items.pop_front().unwrap();
            let dummyCharItem = get!(world, (level, dummyChar.id, i), DummyCharacterItem);

            assert(dummyCharItem.itemId == item.itemId, 'Should be equal item.itemId');
            assert(dummyCharItem.position.x == item.position.x, 'Should be equal item.position.x');
            assert(dummyCharItem.position.y == item.position.y, 'Should be equal item.position.y');
            assert(dummyCharItem.rotation == item.rotation, 'Should be equal item.rotation');
            i += 1;
        }
    } 
}

