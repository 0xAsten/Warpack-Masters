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
        models::Item::{Item, item, ItemsCounter}, models::CharacterItem::{Position},
        utils::{test_utils::{add_items}}
    };

    use warpack_masters::systems::actions::actions::ITEMS_COUNTER_ID;
    use warpack_masters::{items};


    #[test]
    #[available_gas(3000000000000000)]
    fn test_add_item() {
        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        let item = get!(world, ITEMS_COUNTER_ID, ItemsCounter);
        assert(item.count == 13, 'total item count mismatch');

        let item_three_data = get!(world, 3, (Item));
        assert(item_three_data.id == items::item_three_id, 'I3 id mismatch');
        assert(item_three_data.name == items::item_three_name, 'I3 name mismatch');
        assert(item_three_data.itemType == items::item_three_itemType, 'I3 itemType mismatch');
        assert(item_three_data.width == items::item_three_width, 'I3 width mismatch');
        assert(item_three_data.height == items::item_three_height, 'I3 height mismatch');
        assert(item_three_data.price == items::item_three_price, 'I3 price mismatch');
        assert(item_three_data.damage == items::item_three_damage, 'I3 damage mismatch');
        assert(item_three_data.chance == items::item_three_chance, 'I3 chance mismatch');
        assert(item_three_data.cooldown == items::item_three_cooldown, 'I3 cooldown mismatch');
        assert(item_three_data.rarity == items::item_three_rarity, 'I3 rarity mismatch');
        assert(item_three_data.armor == items::item_three_armor, 'I3 armor mismatch');
        assert(
            item_three_data.armorActivation == items::item_three_armorActivation,
            'I3 armorActivation mismatch'
        );
        assert(item_three_data.regen == items::item_three_regen, 'I3 regen mismatch');
        assert(
            item_three_data.regenActivation == items::item_three_regenActivation,
            'I3 regenActivation mismatch'
        );
        assert(item_three_data.reflect == items::item_three_reflect, 'I3 reflect mismatch');
        assert(
            item_three_data.reflectActivation == items::item_three_reflectActivation,
            'I3 reflectActivation mismatch'
        );
        assert(item_three_data.poison == items::item_three_poison, 'I3 poison mismatch');
        assert(
            item_three_data.poisonActivation == items::item_three_poisonActivation,
            'I3 poisonActivation mismatch'
        );

        let item_six_data = get!(world, 6, (Item));
        assert(item_six_data.id == items::item_six_id, 'I6 id mismatch');
        assert(item_six_data.name == items::item_six_name, 'I6 name mismatch');
        assert(item_six_data.itemType == items::item_six_itemType, 'I6 itemType mismatch');
        assert(item_six_data.width == items::item_six_width, 'I6 width mismatch');
        assert(item_six_data.height == items::item_six_height, 'I6 height mismatch');
        assert(item_six_data.price == items::item_six_price, 'I6 price mismatch');
        assert(item_six_data.damage == items::item_six_damage, 'I6 damage mismatch');
        assert(item_six_data.chance == items::item_six_chance, 'I6 chance mismatch');
        assert(item_six_data.cooldown == items::item_six_cooldown, 'I6 cooldown mismatch');
        assert(item_six_data.rarity == items::item_six_rarity, 'I6 rarity mismatch');
        assert(item_six_data.armor == items::item_six_armor, 'I6 armor mismatch');
        assert(
            item_six_data.armorActivation == items::item_six_armorActivation,
            'I6 armorActivation mismatch'
        );
        assert(item_six_data.regen == items::item_six_regen, 'I6 regen mismatch');
        assert(
            item_six_data.regenActivation == items::item_six_regenActivation,
            'I6 regenActivation mismatch'
        );
        assert(item_six_data.reflect == items::item_six_reflect, 'I6 reflect mismatch');
        assert(
            item_six_data.reflectActivation == items::item_six_reflectActivation,
            'I6 reflectActivation mismatch'
        );
        assert(item_six_data.poison == items::item_six_poison, 'I6 poison mismatch');
        assert(
            item_six_data.poisonActivation == items::item_six_poisonActivation,
            'I6 poisonActivation mismatch'
        );

        let item_eleven_data = get!(world, 11, (Item));
        assert(item_eleven_data.id == items::item_eleven_id, 'I11 id mismatch');
        assert(item_eleven_data.name == items::item_eleven_name, 'I11 name mismatch');
        assert(item_eleven_data.itemType == items::item_eleven_itemType, 'I11 itemType mismatch');
        assert(item_eleven_data.width == items::item_eleven_width, 'I11 width mismatch');
        assert(item_eleven_data.height == items::item_eleven_height, 'I11 height mismatch');
        assert(item_eleven_data.price == items::item_eleven_price, 'I11 price mismatch');
        assert(item_eleven_data.damage == items::item_eleven_damage, 'I11 damage mismatch');
        assert(item_eleven_data.chance == items::item_eleven_chance, 'I11 chance mismatch');
        assert(item_eleven_data.cooldown == items::item_eleven_cooldown, 'I11 cooldown mismatch');
        assert(item_eleven_data.rarity == items::item_eleven_rarity, 'I11 rarity mismatch');
        assert(item_eleven_data.armor == items::item_eleven_armor, 'I11 armor mismatch');
        assert(
            item_eleven_data.armorActivation == items::item_eleven_armorActivation,
            'I11 armorActivation mismatch'
        );
        assert(item_eleven_data.regen == items::item_eleven_regen, 'I11 regen mismatch');
        assert(
            item_eleven_data.regenActivation == items::item_eleven_regenActivation,
            'I11 regenActivation mismatch'
        );
        assert(item_eleven_data.reflect == items::item_eleven_reflect, 'I11 reflect mismatch');
        assert(
            item_eleven_data.reflectActivation == items::item_eleven_reflectActivation,
            'I11 reflectActivation mismatch'
        );
        assert(item_eleven_data.poison == items::item_eleven_poison, 'I11 poison mismatch');
        assert(
            item_eleven_data.poisonActivation == items::item_eleven_poisonActivation,
            'I11 poisonActivation mismatch'
        );

        let item_twelve_data = get!(world, 12, (Item));
        assert(item_twelve_data.id == items::item_twelve_id, 'I12 id mismatch');
        assert(item_twelve_data.name == items::item_twelve_name, 'I12 name mismatch');
        assert(item_twelve_data.itemType == items::item_twelve_itemType, 'I12 itemType mismatch');
        assert(item_twelve_data.width == items::item_twelve_width, 'I12 width mismatch');
        assert(item_twelve_data.height == items::item_twelve_height, 'I12 height mismatch');
        assert(item_twelve_data.price == items::item_twelve_price, 'I12 price mismatch');
        assert(item_twelve_data.damage == items::item_twelve_damage, 'I12 damage mismatch');
        assert(item_twelve_data.chance == items::item_twelve_chance, 'I12 chance mismatch');
        assert(item_twelve_data.cooldown == items::item_twelve_cooldown, 'I12 cooldown mismatch');
        assert(item_twelve_data.rarity == items::item_twelve_rarity, 'I12 rarity mismatch');
        assert(item_twelve_data.armor == items::item_twelve_armor, 'I12 armor mismatch');
        assert(
            item_twelve_data.armorActivation == items::item_twelve_armorActivation,
            'I12 armorActivation mismatch'
        );
        assert(item_twelve_data.regen == items::item_twelve_regen, 'I12 regen mismatch');
        assert(
            item_twelve_data.regenActivation == items::item_twelve_regenActivation,
            'I12 regenActivation mismatch'
        );
        assert(item_twelve_data.reflect == items::item_twelve_reflect, 'I12 reflect mismatch');
        assert(
            item_twelve_data.reflectActivation == items::item_twelve_reflectActivation,
            'I12 reflectActivation mismatch'
        );
        assert(item_twelve_data.poison == items::item_twelve_poison, 'I12 poison mismatch');
        assert(
            item_twelve_data.poisonActivation == items::item_twelve_poisonActivation,
            'I12 poisonActivation mismatch'
        );
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('player not world owner', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_not_world_owner() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        set_contract_address(alice);

        actions_system
            .add_item(
                items::item_one_id,
                items::item_one_name,
                items::item_one_itemType,
                items::item_one_width,
                items::item_one_height,
                items::item_one_price,
                items::item_one_damage,
                items::item_one_chance,
                items::item_one_cooldown,
                items::item_one_rarity,
                items::item_one_armor,
                items::item_one_armorActivation,
                items::item_one_regen,
                items::item_one_regenActivation,
                items::item_one_reflect,
                items::item_one_reflectActivation,
                items::item_one_poison,
                items::item_one_poisonActivation,
            );
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('width not in range', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_width_not_in_range() {
        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system
            .add_item(
                items::item_one_id,
                items::item_one_name,
                items::item_one_itemType,
                10,
                items::item_one_height,
                items::item_one_price,
                items::item_one_damage,
                items::item_one_chance,
                items::item_one_cooldown,
                items::item_one_rarity,
                items::item_one_armor,
                items::item_one_armorActivation,
                items::item_one_regen,
                items::item_one_regenActivation,
                items::item_one_reflect,
                items::item_one_reflectActivation,
                items::item_one_poison,
                items::item_one_poisonActivation,
            );
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('height not in range', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_height_not_in_range() {
        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system
            .add_item(
                items::item_one_id,
                items::item_one_name,
                items::item_one_itemType,
                items::item_one_width,
                10,
                items::item_one_price,
                items::item_one_damage,
                items::item_one_chance,
                items::item_one_cooldown,
                items::item_one_rarity,
                items::item_one_armor,
                items::item_one_armorActivation,
                items::item_one_regen,
                items::item_one_regenActivation,
                items::item_one_reflect,
                items::item_one_reflectActivation,
                items::item_one_poison,
                items::item_one_poisonActivation,
            );
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('price must be greater than 0', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_price_not_valid() {
        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system
            .add_item(
                items::item_one_id,
                items::item_one_name,
                items::item_one_itemType,
                items::item_one_width,
                items::item_one_height,
                0,
                items::item_one_damage,
                items::item_one_chance,
                items::item_one_cooldown,
                items::item_one_rarity,
                items::item_one_armor,
                items::item_one_armorActivation,
                items::item_one_regen,
                items::item_one_regenActivation,
                items::item_one_reflect,
                items::item_one_reflectActivation,
                items::item_one_poison,
                items::item_one_poisonActivation,
            );
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('rarity not valid', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_invalid_rarity() {
        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system
            .add_item(
                items::item_one_id,
                items::item_one_name,
                items::item_one_itemType,
                items::item_one_width,
                items::item_one_height,
                items::item_one_price,
                items::item_one_damage,
                items::item_one_chance,
                items::item_one_cooldown,
                7,
                items::item_one_armor,
                items::item_one_armorActivation,
                items::item_one_regen,
                items::item_one_regenActivation,
                items::item_one_reflect,
                items::item_one_reflectActivation,
                items::item_one_poison,
                items::item_one_poisonActivation,
            );
    }
}

