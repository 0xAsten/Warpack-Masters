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
        assert(item.count == 34, 'total item count mismatch');

        let item_six_data = get!(world, 6, (Item));
        assert(item_six_data.id == items::Dagger::id, 'I6 id mismatch');
        assert(item_six_data.name == items::Dagger::name, 'I6 name mismatch');
        assert(item_six_data.itemType == items::Dagger::itemType, 'I6 itemType mismatch');
        assert(item_six_data.rarity == items::Dagger::rarity, 'I6 rarity mismatch');
        assert(item_six_data.width == items::Dagger::width, 'I6 width mismatch');
        assert(item_six_data.height == items::Dagger::height, 'I6 height mismatch');
        assert(item_six_data.price == items::Dagger::price, 'I6 price mismatch');
        assert(item_six_data.effectType == items::Dagger::effectType, 'I6 effectType mismatch');
        assert(item_six_data.effectStacks == items::Dagger::effectStacks, 'I6 effectStacks mismatch');
        assert(item_six_data.effectActivationType == items::Dagger::effectActivationType, 'ActivationType mismatch');
        assert(item_six_data.chance == items::Dagger::chance, 'I6 chance mismatch');
        assert(item_six_data.cooldown == items::Dagger::cooldown, 'I6 cooldown mismatch');
        assert(item_six_data.energyCost == items::Dagger::energyCost, 'I6 energyCost mismatch');
        assert(item_six_data.isPlugin == items::Dagger::isPlugin, 'I6 isPlugin mismatch');

        let item_nine_data = get!(world, 9, (Item));
        assert(item_nine_data.id == items::Shield::id, 'I9 id mismatch');
        assert(item_nine_data.name == items::Shield::name, 'I9 name mismatch');
        assert(item_nine_data.itemType == items::Shield::itemType, 'I9 itemType mismatch');
        assert(item_nine_data.rarity == items::Shield::rarity, 'I9 rarity mismatch');
        assert(item_nine_data.width == items::Shield::width, 'I9 width mismatch');
        assert(item_nine_data.height == items::Shield::height, 'I9 height mismatch');
        assert(item_nine_data.price == items::Shield::price, 'I9 price mismatch');
        assert(item_nine_data.effectType == items::Shield::effectType, 'I9 effectType mismatch');
        assert(item_nine_data.effectStacks == items::Shield::effectStacks, 'I9 effectStacks mismatch');
        assert(item_nine_data.effectActivationType == items::Shield::effectActivationType, 'ActivationType mismatch');
        assert(item_nine_data.chance == items::Shield::chance, 'I9 chance mismatch');
        assert(item_nine_data.cooldown == items::Shield::cooldown, 'I9 cooldown mismatch');
        assert(item_nine_data.energyCost == items::Shield::energyCost, 'I9 energyCost mismatch');
        assert(item_nine_data.isPlugin == items::Shield::isPlugin, 'I9 isPlugin mismatch');

        let item_eleven_data = get!(world, 11, (Item));
        assert(item_eleven_data.id == items::HealingPotion::id, 'I11 id mismatch');
        assert(item_eleven_data.name == items::HealingPotion::name, 'I11 name mismatch');
        assert(item_eleven_data.itemType == items::HealingPotion::itemType, 'I11 itemType mismatch');
        assert(item_eleven_data.rarity == items::HealingPotion::rarity, 'I11 rarity mismatch');
        assert(item_eleven_data.width == items::HealingPotion::width, 'I11 width mismatch');
        assert(item_eleven_data.height == items::HealingPotion::height, 'I11 height mismatch');
        assert(item_eleven_data.price == items::HealingPotion::price, 'I11 price mismatch');
        assert(item_eleven_data.effectType == items::HealingPotion::effectType, 'I11 effectType mismatch');
        assert(item_eleven_data.effectStacks == items::HealingPotion::effectStacks, 'I11 effectStacks mismatch');
        assert(item_eleven_data.effectActivationType == items::HealingPotion::effectActivationType, 'ActivationType mismatch');
        assert(item_eleven_data.chance == items::HealingPotion::chance, 'I11 chance mismatch');
        assert(item_eleven_data.cooldown == items::HealingPotion::cooldown, 'I11 cooldown mismatch');
        assert(item_eleven_data.energyCost == items::HealingPotion::energyCost, 'I11 energyCost mismatch');
        assert(item_eleven_data.isPlugin == items::HealingPotion::isPlugin, 'I11 isPlugin mismatch');

        let item_fifteen_data = get!(world, 15, (Item));
        assert(item_fifteen_data.id == items::AugmentedDagger::id, 'I15 id mismatch');
        assert(item_fifteen_data.name == items::AugmentedDagger::name, 'I15 name mismatch');
        assert(item_fifteen_data.itemType == items::AugmentedDagger::itemType, 'I15 itemType mismatch');
        assert(item_fifteen_data.rarity == items::AugmentedDagger::rarity, 'I15 rarity mismatch');
        assert(item_fifteen_data.width == items::AugmentedDagger::width, 'I15 width mismatch');
        assert(item_fifteen_data.height == items::AugmentedDagger::height, 'I15 height mismatch');
        assert(item_fifteen_data.price == items::AugmentedDagger::price, 'I15 price mismatch');
        assert(item_fifteen_data.effectType == items::AugmentedDagger::effectType, 'I15 effectType mismatch');
        assert(item_fifteen_data.effectStacks == items::AugmentedDagger::effectStacks, 'I15 effectStacks mismatch');
        assert(item_fifteen_data.effectActivationType == items::AugmentedDagger::effectActivationType, 'ActivationType mismatch');
        assert(item_fifteen_data.chance == items::AugmentedDagger::chance, 'I15 chance mismatch');
        assert(item_fifteen_data.cooldown == items::AugmentedDagger::cooldown, 'I15 cooldown mismatch');
        assert(item_fifteen_data.energyCost == items::AugmentedDagger::energyCost, 'I15 energyCost mismatch');
        assert(item_fifteen_data.isPlugin == items::AugmentedDagger::isPlugin, 'I15 isPlugin mismatch');
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
                items::Backpack::rarity,
                items::Backpack::width,
                items::Backpack::height,
                items::Backpack::price,
                items::Backpack::effectType,
                items::Backpack::effectStacks,
                items::Backpack::effectActivationType,
                items::Backpack::chance,
                items::Backpack::cooldown,
                items::Backpack::energyCost,
                items::Backpack::isPlugin
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
                items::Backpack::rarity,
                10,
                items::Backpack::height,
                items::Backpack::price,
                items::Backpack::effectType,
                items::Backpack::effectStacks,
                items::Backpack::effectActivationType,
                items::Backpack::chance,
                items::Backpack::cooldown,
                items::Backpack::energyCost,
                items::Backpack::isPlugin
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
                items::Backpack::rarity,
                items::Backpack::width,
                10,
                items::Backpack::price,
                items::Backpack::effectType,
                items::Backpack::effectStacks,
                items::Backpack::effectActivationType,
                items::Backpack::chance,
                items::Backpack::cooldown,
                items::Backpack::energyCost,
                items::Backpack::isPlugin
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
                items::Backpack::rarity,
                items::Backpack::width,
                items::Backpack::height,
                0,
                items::Backpack::effectType,
                items::Backpack::effectStacks,
                items::Backpack::effectActivationType,
                items::Backpack::chance,
                items::Backpack::cooldown,
                items::Backpack::energyCost,
                items::Backpack::isPlugin
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
                7,
                items::Backpack::width,
                items::Backpack::height,
                items::Backpack::price,
                items::Backpack::effectType,
                items::Backpack::effectStacks,
                items::Backpack::effectActivationType,
                items::Backpack::chance,
                items::Backpack::cooldown,
                items::Backpack::energyCost,
                items::Backpack::isPlugin
            );
    }
}

