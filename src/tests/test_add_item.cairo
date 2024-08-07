#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_contract_address;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::utils::test::{spawn_test_world, deploy_contract};

    // import test utils
    use warpack_masters::{
        systems::{item::{item_system, IItemDispatcher, IItemDispatcherTrait}},
        models::Item::{Item, item, ItemsCounter, items_counter}, utils::{test_utils::{add_items}}
    };

    use warpack_masters::constants::constants::ITEMS_COUNTER_ID;
    use warpack_masters::{items};


    #[test]
    #[available_gas(3000000000000000)]
    fn test_add_item() {
        let mut models = array![item::TEST_CLASS_HASH, items_counter::TEST_CLASS_HASH];

        let world = spawn_test_world("Warpacks", models);

        let item_system_address = world
            .deploy_contract(
                'salt1', item_system::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        add_items(ref item_system);

        let item = get!(world, ITEMS_COUNTER_ID, ItemsCounter);
        assert(item.count == 16, 'total item count mismatch');

        let item_three_data = get!(world, 6, (Item));
        assert(item_three_data.id == items::Dagger::id, 'I3 id mismatch');
        assert(item_three_data.name == items::Dagger::name, 'I3 name mismatch');
        assert(item_three_data.itemType == items::Dagger::itemType, 'I3 itemType mismatch');
        assert(item_three_data.width == items::Dagger::width, 'I3 width mismatch');
        assert(item_three_data.height == items::Dagger::height, 'I3 height mismatch');
        assert(item_three_data.price == items::Dagger::price, 'I3 price mismatch');
        assert(item_three_data.damage == items::Dagger::damage, 'I3 damage mismatch');
        assert(item_three_data.chance == items::Dagger::chance, 'I3 chance mismatch');
        assert(item_three_data.cooldown == items::Dagger::cooldown, 'I3 cooldown mismatch');
        assert(item_three_data.rarity == items::Dagger::rarity, 'I3 rarity mismatch');
        assert(item_three_data.armor == items::Dagger::armor, 'I3 armor mismatch');
        assert(
            item_three_data.armorActivation == items::Dagger::armorActivation,
            'I3 armorActivation mismatch'
        );
        assert(item_three_data.regen == items::Dagger::regen, 'I3 regen mismatch');
        assert(
            item_three_data.regenActivation == items::Dagger::regenActivation,
            'I3 regenActivation mismatch'
        );
        assert(item_three_data.reflect == items::Dagger::reflect, 'I3 reflect mismatch');
        assert(
            item_three_data.reflectActivation == items::Dagger::reflectActivation,
            'I3 reflectActivation mismatch'
        );
        assert(item_three_data.poison == items::Dagger::poison, 'I3 poison mismatch');
        assert(
            item_three_data.poisonActivation == items::Dagger::poisonActivation,
            'I3 poisonActivation mismatch'
        );

        let item_six_data = get!(world, 6, (Item));
        assert(item_six_data.id == items::Dagger::id, 'I6 id mismatch');
        assert(item_six_data.name == items::Dagger::name, 'I6 name mismatch');
        assert(item_six_data.itemType == items::Dagger::itemType, 'I6 itemType mismatch');
        assert(item_six_data.width == items::Dagger::width, 'I6 width mismatch');
        assert(item_six_data.height == items::Dagger::height, 'I6 height mismatch');
        assert(item_six_data.price == items::Dagger::price, 'I6 price mismatch');
        assert(item_six_data.damage == items::Dagger::damage, 'I6 damage mismatch');
        assert(item_six_data.chance == items::Dagger::chance, 'I6 chance mismatch');
        assert(item_six_data.cooldown == items::Dagger::cooldown, 'I6 cooldown mismatch');
        assert(item_six_data.rarity == items::Dagger::rarity, 'I6 rarity mismatch');
        assert(item_six_data.armor == items::Dagger::armor, 'I6 armor mismatch');
        assert(
            item_six_data.armorActivation == items::Dagger::armorActivation,
            'I6 armorActivation mismatch'
        );
        assert(item_six_data.regen == items::Dagger::regen, 'I6 regen mismatch');
        assert(
            item_six_data.regenActivation == items::Dagger::regenActivation,
            'I6 regenActivation mismatch'
        );
        assert(item_six_data.reflect == items::Dagger::reflect, 'I6 reflect mismatch');
        assert(
            item_six_data.reflectActivation == items::Dagger::reflectActivation,
            'I6 reflectActivation mismatch'
        );
        assert(item_six_data.poison == items::Dagger::poison, 'I6 poison mismatch');
        assert(
            item_six_data.poisonActivation == items::Dagger::poisonActivation,
            'I6 poisonActivation mismatch'
        );

        let item_eleven_data = get!(world, 14, (Item));
        assert(item_eleven_data.id == items::AugmentedSword::id, 'I11 id mismatch');
        assert(item_eleven_data.name == items::AugmentedSword::name, 'I11 name mismatch');
        assert(
            item_eleven_data.itemType == items::AugmentedSword::itemType, 'I11 itemType mismatch'
        );
        assert(item_eleven_data.width == items::AugmentedSword::width, 'I11 width mismatch');
        assert(item_eleven_data.height == items::AugmentedSword::height, 'I11 height mismatch');
        assert(item_eleven_data.price == items::AugmentedSword::price, 'I11 price mismatch');
        assert(item_eleven_data.damage == items::AugmentedSword::damage, 'I11 damage mismatch');
        assert(item_eleven_data.chance == items::AugmentedSword::chance, 'I11 chance mismatch');
        assert(
            item_eleven_data.cooldown == items::AugmentedSword::cooldown, 'I11 cooldown mismatch'
        );
        assert(item_eleven_data.rarity == items::AugmentedSword::rarity, 'I11 rarity mismatch');
        assert(item_eleven_data.armor == items::AugmentedSword::armor, 'I11 armor mismatch');
        assert(
            item_eleven_data.armorActivation == items::AugmentedSword::armorActivation,
            'I11 armorActivation mismatch'
        );
        assert(item_eleven_data.regen == items::AugmentedSword::regen, 'I11 regen mismatch');
        assert(
            item_eleven_data.regenActivation == items::AugmentedSword::regenActivation,
            'I11 regenActivation mismatch'
        );
        assert(item_eleven_data.reflect == items::AugmentedSword::reflect, 'I11 reflect mismatch');
        assert(
            item_eleven_data.reflectActivation == items::AugmentedSword::reflectActivation,
            'I11 reflectActivation mismatch'
        );
        assert(item_eleven_data.poison == items::AugmentedSword::poison, 'I11 poison mismatch');
        assert(
            item_eleven_data.poisonActivation == items::AugmentedSword::poisonActivation,
            'I11 poisonActivation mismatch'
        );

        let item_twelve_data = get!(world, 15, (Item));
        assert(item_twelve_data.id == items::AugmentedDagger::id, 'I12 id mismatch');
        assert(item_twelve_data.name == items::AugmentedDagger::name, 'I12 name mismatch');
        assert(
            item_twelve_data.itemType == items::AugmentedDagger::itemType, 'I12 itemType mismatch'
        );
        assert(item_twelve_data.width == items::AugmentedDagger::width, 'I12 width mismatch');
        assert(item_twelve_data.height == items::AugmentedDagger::height, 'I12 height mismatch');
        assert(item_twelve_data.price == items::AugmentedDagger::price, 'I12 price mismatch');
        assert(item_twelve_data.damage == items::AugmentedDagger::damage, 'I12 damage mismatch');
        assert(item_twelve_data.chance == items::AugmentedDagger::chance, 'I12 chance mismatch');
        assert(
            item_twelve_data.cooldown == items::AugmentedDagger::cooldown, 'I12 cooldown mismatch'
        );
        assert(item_twelve_data.rarity == items::AugmentedDagger::rarity, 'I12 rarity mismatch');
        assert(item_twelve_data.armor == items::AugmentedDagger::armor, 'I12 armor mismatch');
        assert(
            item_twelve_data.armorActivation == items::AugmentedDagger::armorActivation,
            'I12 armorActivation mismatch'
        );
        assert(item_twelve_data.regen == items::AugmentedDagger::regen, 'I12 regen mismatch');
        assert(
            item_twelve_data.regenActivation == items::AugmentedDagger::regenActivation,
            'I12 regenActivation mismatch'
        );
        assert(item_twelve_data.reflect == items::AugmentedDagger::reflect, 'I12 reflect mismatch');
        assert(
            item_twelve_data.reflectActivation == items::AugmentedDagger::reflectActivation,
            'I12 reflectActivation mismatch'
        );
        assert(item_twelve_data.poison == items::AugmentedDagger::poison, 'I12 poison mismatch');
        assert(
            item_twelve_data.poisonActivation == items::AugmentedDagger::poisonActivation,
            'I12 poisonActivation mismatch'
        );
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('player not world owner', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_not_world_owner() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![item::TEST_CLASS_HASH, items_counter::TEST_CLASS_HASH];

        let world = spawn_test_world("Warpacks", models);

        let item_system_address = world
            .deploy_contract(
                'salt1', item_system::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        add_items(ref item_system);

        set_contract_address(alice);

        item_system
            .add_item(
                items::Backpack::id,
                items::Backpack::name,
                items::Backpack::itemType,
                items::Backpack::width,
                items::Backpack::height,
                items::Backpack::price,
                items::Backpack::damage,
                items::Backpack::cleansePoison,
                items::Backpack::chance,
                items::Backpack::cooldown,
                items::Backpack::rarity,
                items::Backpack::armor,
                items::Backpack::armorActivation,
                items::Backpack::regen,
                items::Backpack::regenActivation,
                items::Backpack::reflect,
                items::Backpack::reflectActivation,
                items::Backpack::poison,
                items::Backpack::poisonActivation,
                items::Backpack::empower,
                items::Backpack::empowerActivation,
            );
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('width not in range', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_width_not_in_range() {
        let mut models = array![item::TEST_CLASS_HASH, items_counter::TEST_CLASS_HASH];

        let world = spawn_test_world("Warpacks", models);

        let item_system_address = world
            .deploy_contract(
                'salt1', item_system::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        item_system
            .add_item(
                items::Backpack::id,
                items::Backpack::name,
                items::Backpack::itemType,
                10,
                items::Backpack::height,
                items::Backpack::price,
                items::Backpack::damage,
                items::Backpack::cleansePoison,
                items::Backpack::chance,
                items::Backpack::cooldown,
                items::Backpack::rarity,
                items::Backpack::armor,
                items::Backpack::armorActivation,
                items::Backpack::regen,
                items::Backpack::regenActivation,
                items::Backpack::reflect,
                items::Backpack::reflectActivation,
                items::Backpack::poison,
                items::Backpack::poisonActivation,
                items::Backpack::empower,
                items::Backpack::empowerActivation,
            );
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('height not in range', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_height_not_in_range() {
        let mut models = array![item::TEST_CLASS_HASH, items_counter::TEST_CLASS_HASH];

        let world = spawn_test_world("Warpacks", models);

        let item_system_address = world
            .deploy_contract(
                'salt1', item_system::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        item_system
            .add_item(
                items::Backpack::id,
                items::Backpack::name,
                items::Backpack::itemType,
                items::Backpack::width,
                10,
                items::Backpack::price,
                items::Backpack::damage,
                items::Backpack::cleansePoison,
                items::Backpack::chance,
                items::Backpack::cooldown,
                items::Backpack::rarity,
                items::Backpack::armor,
                items::Backpack::armorActivation,
                items::Backpack::regen,
                items::Backpack::regenActivation,
                items::Backpack::reflect,
                items::Backpack::reflectActivation,
                items::Backpack::poison,
                items::Backpack::poisonActivation,
                items::Backpack::empower,
                items::Backpack::empowerActivation,
            );
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('price must be greater than 0', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_price_not_valid() {
        let mut models = array![item::TEST_CLASS_HASH, items_counter::TEST_CLASS_HASH];

        let world = spawn_test_world("Warpacks", models);

        let item_system_address = world
            .deploy_contract(
                'salt1', item_system::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        item_system
            .add_item(
                items::Backpack::id,
                items::Backpack::name,
                items::Backpack::itemType,
                items::Backpack::width,
                items::Backpack::height,
                0,
                items::Backpack::damage,
                items::Backpack::cleansePoison,
                items::Backpack::chance,
                items::Backpack::cooldown,
                items::Backpack::rarity,
                items::Backpack::armor,
                items::Backpack::armorActivation,
                items::Backpack::regen,
                items::Backpack::regenActivation,
                items::Backpack::reflect,
                items::Backpack::reflectActivation,
                items::Backpack::poison,
                items::Backpack::poisonActivation,
                items::Backpack::empower,
                items::Backpack::empowerActivation,
            );
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('rarity not valid', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_invalid_rarity() {
        let mut models = array![item::TEST_CLASS_HASH, items_counter::TEST_CLASS_HASH];

        let world = spawn_test_world("Warpacks", models);

        let item_system_address = world
            .deploy_contract(
                'salt1', item_system::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        item_system
            .add_item(
                items::Backpack::id,
                items::Backpack::name,
                items::Backpack::itemType,
                items::Backpack::width,
                items::Backpack::height,
                items::Backpack::price,
                items::Backpack::damage,
                items::Backpack::cleansePoison,
                items::Backpack::chance,
                items::Backpack::cooldown,
                7,
                items::Backpack::armor,
                items::Backpack::armorActivation,
                items::Backpack::regen,
                items::Backpack::regenActivation,
                items::Backpack::reflect,
                items::Backpack::reflectActivation,
                items::Backpack::poison,
                items::Backpack::poisonActivation,
                items::Backpack::empower,
                items::Backpack::empowerActivation,
            );
    }
}

