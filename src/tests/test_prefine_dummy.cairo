#[cfg(test)]
mod tests {
    use core::option::OptionTrait;
    use core::array::ArrayTrait;
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_contract_address;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::utils::test::{spawn_test_world, deploy_contract};

    // import test utils
    use warpack_masters::{
        systems::{dummy::{dummy_system, IDummyDispatcher, IDummyDispatcherTrait}},
        systems::{item::{item_system, IItemDispatcher, IItemDispatcherTrait}},
        models::backpack::{BackpackGrids, backpack_grids},
        models::Character::{NameRecord, name_record, WMClass}, models::CharacterItem::{Position},
        models::DummyCharacter::{
            DummyCharacter, dummy_character, DummyCharacterCounter, dummy_character_counter
        },
        models::DummyCharacterItem::{
            DummyCharacterItem, dummy_character_item, DummyCharacterItemsCounter,
            dummy_character_items_counter
        },
        models::Item::{Item, item, ItemsCounter, items_counter}, utils::{test_utils::{add_items}}
    };

    use warpack_masters::prdefined_dummies::{PredefinedItem, Dummy0, Dummy1};

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('player not world owner', 'ENTRYPOINT_FAILED'))]
    fn test_prefine_dummy_non_admin() {
        let alice = starknet::contract_address_const::<0x1>();

        let mut models = array![
            backpack_grids::TEST_CLASS_HASH,
            name_record::TEST_CLASS_HASH,
            dummy_character::TEST_CLASS_HASH,
            dummy_character_counter::TEST_CLASS_HASH,
            dummy_character_item::TEST_CLASS_HASH,
            dummy_character_items_counter::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            items_counter::TEST_CLASS_HASH,
        ];

        let world = spawn_test_world("Warpacks", models);

        let dummy_system_address = world
            .deploy_contract(
                'salt1', dummy_system::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut dummy_system = IDummyDispatcher { contract_address: dummy_system_address };

        let item_system_address = world
            .deploy_contract(
                'salt2', item_system::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        add_items(ref item_system);

        set_contract_address(alice);

        dummy_system.prefine_dummy(0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_prefine_dummy() {
        let mut models = array![
            backpack_grids::TEST_CLASS_HASH,
            name_record::TEST_CLASS_HASH,
            dummy_character::TEST_CLASS_HASH,
            dummy_character_counter::TEST_CLASS_HASH,
            dummy_character_item::TEST_CLASS_HASH,
            dummy_character_items_counter::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            items_counter::TEST_CLASS_HASH,
        ];

        let world = spawn_test_world("Warpacks", models);

        let dummy_system_address = world
            .deploy_contract(
                'salt1', dummy_system::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut dummy_system = IDummyDispatcher { contract_address: dummy_system_address };

        let item_system_address = world
            .deploy_contract(
                'salt2', item_system::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        add_items(ref item_system);

        let mut level = 0;
        dummy_system.prefine_dummy(level);

        let dummyCharCounter = get!(world, level, DummyCharacterCounter);
        assert(dummyCharCounter.count == 1, 'Should be equal 1');

        let dummyChar = get!(world, (level, 1), DummyCharacter);
        assert(dummyChar.level == level, 'Should be equal 0');
        assert(dummyChar.id == 1, 'Should be equal 1');
        assert(dummyChar.name == Dummy0::name, 'Should be equal Dummy0::name');
        let mut dummyClassNo: u8 = 0;
        match dummyChar.wmClass {
            WMClass::Warrior => { dummyClassNo = 0; },
            WMClass::Warlock => { dummyClassNo = 1; },
            WMClass::Archer => { dummyClassNo = 2; }
        }
        assert(dummyClassNo == Dummy0::wmClass, 'Should be equal Dummy0::wmClass');
        assert(dummyChar.health == Dummy0::health, 'Should be equal Dummy0::health');
        assert(
            dummyChar.player == starknet::contract_address_const::<0x1>(), 'Should be equal 0x0'
        );
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

