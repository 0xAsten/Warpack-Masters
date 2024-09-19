#[cfg(test)]
mod tests {
    use core::starknet::contract_address::ContractAddress;
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_contract_address;

    use dojo::model::{Model, ModelTest, ModelIndex, ModelEntityTest};
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


    fn get_systems(world: IWorldDispatcher) -> (ContractAddress, IItemDispatcher,) {
        let item_system_address = world
            .deploy_contract('salt1', item_system::TEST_CLASS_HASH.try_into().unwrap());
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        world.grant_writer(Model::<Item>::selector(), item_system_address);
        world.grant_writer(Model::<ItemsCounter>::selector(), item_system_address);

        (item_system_address, item_system,)
    }


    #[test]
    #[available_gas(3000000000000000)]
    fn test_add_item() {
        let world = spawn_test_world!();
        let (_, mut item_system,) = get_systems(world);

        add_items(ref item_system);

        let item = get!(world, ITEMS_COUNTER_ID, ItemsCounter);
        assert(item.count == 16, 'total item count mismatch');

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
        assert(item_six_data.energyCost == items::Dagger::energyCost, 'I6 energyCost mismatch');

        let item_nine_data = get!(world, 9, (Item));
        assert(item_nine_data.id == items::Shield::id, 'I9 id mismatch');
        assert(item_nine_data.name == items::Shield::name, 'I9 name mismatch');
        assert(item_nine_data.itemType == items::Shield::itemType, 'I9 itemType mismatch');
        assert(item_nine_data.width == items::Shield::width, 'I9 width mismatch');
        assert(item_nine_data.height == items::Shield::height, 'I9 height mismatch');
        assert(item_nine_data.price == items::Shield::price, 'I9 price mismatch');
        assert(item_nine_data.damage == items::Shield::damage, 'I9 damage mismatch');
        assert(item_nine_data.chance == items::Shield::chance, 'I9 chance mismatch');
        assert(item_nine_data.cooldown == items::Shield::cooldown, 'I9 cooldown mismatch');
        assert(item_nine_data.rarity == items::Shield::rarity, 'I9 rarity mismatch');
        assert(item_nine_data.armor == items::Shield::armor, 'I9 armor mismatch');
        assert(
            item_nine_data.armorActivation == items::Shield::armorActivation,
            'I9 armorActivation mismatch'
        );
        assert(item_nine_data.regen == items::Shield::regen, 'I9 regen mismatch');
        assert(
            item_nine_data.regenActivation == items::Shield::regenActivation,
            'I9 regenActivation mismatch'
        );
        assert(item_nine_data.reflect == items::Shield::reflect, 'I9 reflect mismatch');
        assert(
            item_nine_data.reflectActivation == items::Shield::reflectActivation,
            'I9 reflectActivation mismatch'
        );
        assert(item_nine_data.poison == items::Shield::poison, 'I9 poison mismatch');
        assert(
            item_nine_data.poisonActivation == items::Shield::poisonActivation,
            'I9 poisonActivation mismatch'
        );
        assert(item_nine_data.energyCost == items::Shield::energyCost, 'I9 energyCost mismatch');

        let item_eleven_data = get!(world, 11, (Item));
        assert(item_eleven_data.id == items::HealingPotion::id, 'I11 id mismatch');
        assert(item_eleven_data.name == items::HealingPotion::name, 'I11 name mismatch');
        assert(
            item_eleven_data.itemType == items::HealingPotion::itemType, 'I11 itemType mismatch'
        );
        assert(item_eleven_data.width == items::HealingPotion::width, 'I11 width mismatch');
        assert(item_eleven_data.height == items::HealingPotion::height, 'I11 height mismatch');
        assert(item_eleven_data.price == items::HealingPotion::price, 'I11 price mismatch');
        assert(item_eleven_data.damage == items::HealingPotion::damage, 'I11 damage mismatch');
        assert(item_eleven_data.chance == items::HealingPotion::chance, 'I11 chance mismatch');
        assert(
            item_eleven_data.cooldown == items::HealingPotion::cooldown, 'I11 cooldown mismatch'
        );
        assert(item_eleven_data.rarity == items::HealingPotion::rarity, 'I11 rarity mismatch');
        assert(item_eleven_data.armor == items::HealingPotion::armor, 'I11 armor mismatch');
        assert(
            item_eleven_data.armorActivation == items::HealingPotion::armorActivation,
            'I11 armorActivation mismatch'
        );
        assert(item_eleven_data.regen == items::HealingPotion::regen, 'I11 regen mismatch');
        assert(
            item_eleven_data.regenActivation == items::HealingPotion::regenActivation,
            'I11 regenActivation mismatch'
        );
        assert(item_eleven_data.reflect == items::HealingPotion::reflect, 'I11 reflect mismatch');
        assert(
            item_eleven_data.reflectActivation == items::HealingPotion::reflectActivation,
            'I11 reflectActivation mismatch'
        );
        assert(item_eleven_data.poison == items::HealingPotion::poison, 'I11 poison mismatch');
        assert(
            item_eleven_data.poisonActivation == items::HealingPotion::poisonActivation,
            'I11 poisonActivation mismatch'
        );
        assert(
            item_eleven_data.energyCost == items::HealingPotion::energyCost,
            'I11 energyCost mismatch'
        );

        let item_fifteen_data = get!(world, 15, (Item));
        assert(item_fifteen_data.id == items::AugmentedDagger::id, 'I15 id mismatch');
        assert(item_fifteen_data.name == items::AugmentedDagger::name, 'I15 name mismatch');
        assert(
            item_fifteen_data.itemType == items::AugmentedDagger::itemType, 'I15 itemType mismatch'
        );
        assert(item_fifteen_data.width == items::AugmentedDagger::width, 'I15 width mismatch');
        assert(item_fifteen_data.height == items::AugmentedDagger::height, 'I15 height mismatch');
        assert(item_fifteen_data.price == items::AugmentedDagger::price, 'I15 price mismatch');
        assert(item_fifteen_data.damage == items::AugmentedDagger::damage, 'I15 damage mismatch');
        assert(item_fifteen_data.chance == items::AugmentedDagger::chance, 'I15 chance mismatch');
        assert(
            item_fifteen_data.cooldown == items::AugmentedDagger::cooldown, 'I15 cooldown mismatch'
        );
        assert(item_fifteen_data.rarity == items::AugmentedDagger::rarity, 'I15 rarity mismatch');
        assert(item_fifteen_data.armor == items::AugmentedDagger::armor, 'I15 armor mismatch');
        assert(
            item_fifteen_data.armorActivation == items::AugmentedDagger::armorActivation,
            'I15 armorActivation mismatch'
        );
        assert(item_fifteen_data.regen == items::AugmentedDagger::regen, 'I15 regen mismatch');
        assert(
            item_fifteen_data.regenActivation == items::AugmentedDagger::regenActivation,
            'I15 regenActivation mismatch'
        );
        assert(
            item_fifteen_data.reflect == items::AugmentedDagger::reflect, 'I15 reflect mismatch'
        );
        assert(
            item_fifteen_data.reflectActivation == items::AugmentedDagger::reflectActivation,
            'I15 reflectActivation mismatch'
        );
        assert(item_fifteen_data.poison == items::AugmentedDagger::poison, 'I15 poison mismatch');
        assert(
            item_fifteen_data.poisonActivation == items::AugmentedDagger::poisonActivation,
            'I15 poisonActivation mismatch'
        );
        assert(
            item_fifteen_data.energyCost == items::AugmentedDagger::energyCost,
            'I15 energyCost mismatch'
        );
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('player not world owner', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_not_world_owner() {
        let alice = starknet::contract_address_const::<0x1337>();

        let world = spawn_test_world!();
        let (_, mut item_system,) = get_systems(world);

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
                items::Backpack::vampirism,
                items::Backpack::vampirismActivation,
                items::Backpack::energyCost
            );
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('width not in range', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_width_not_in_range() {
        let world = spawn_test_world!();
        let (_, mut item_system,) = get_systems(world);

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
                items::Backpack::vampirism,
                items::Backpack::vampirismActivation,
                items::Backpack::energyCost
            );
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('height not in range', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_height_not_in_range() {
        let world = spawn_test_world!();
        let (_, mut item_system,) = get_systems(world);

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
                items::Backpack::vampirism,
                items::Backpack::vampirismActivation,
                items::Backpack::energyCost
            );
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('price must be greater than 0', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_price_not_valid() {
        let world = spawn_test_world!();
        let (_, mut item_system,) = get_systems(world);

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
                items::Backpack::vampirism,
                items::Backpack::vampirismActivation,
                items::Backpack::energyCost
            );
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('rarity not valid', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_invalid_rarity() {
        let world = spawn_test_world!();
        let (_, mut item_system,) = get_systems(world);

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
                items::Backpack::vampirism,
                items::Backpack::vampirismActivation,
                items::Backpack::energyCost
            );
    }
}

