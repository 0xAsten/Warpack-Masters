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
        models::CharacterItem::{CharacterItem, Position, CharacterItemsCounter}
    };

    use warpack_masters::systems::actions::actions::ITEMS_COUNTER_ID;


    #[test]
    #[available_gas(3000000000000000)]
    fn test_edit_item() {
        let owner = starknet::contract_address_const::<0x0>();

        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        let item_one_name: felt252 = 'Sword';
        let item_one_width = 1;
        let item_one_height = 3;
        let item_one_price = 100;
        let item_one_damage = 10;
        let item_one_armor = 10;
        let item_one_chance = 5;
        let item_one_cooldown = 10;
        let item_one_heal = 5;
        let item_one_rarity = 1;
        let item_one_item_type = 'Weapon';
        let item_one_stat_affected = '';
        let item_one_percentage = 0;
        let item_one_trigger_type = 0;

        let item_one_new_name: felt252 = 'Wood Sword';
        let item_one_new_price: felt252 = 70;

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
                item_one_item_type,
                item_one_stat_affected,
                item_one_percentage,
                item_one_trigger_type
            );

        actions_system.edit_item(1, 0, item_one_new_name);

        let item_one_data = get!(world, 1, (Item));
        assert(item_one_data.name == item_one_new_name, 'Item 1 name mismatch');
        assert(item_one_data.width == item_one_width, 'Item 1 width mismatch');
        assert(item_one_data.height == item_one_height, 'Item 1 height mismatch');
        assert(item_one_data.price == item_one_price, 'Item 1 price mismatch');
        assert(item_one_data.damage == item_one_damage, 'Item 1 damage mismatch');
        assert(item_one_data.armor == item_one_armor, 'Item 1 armor mismatch');
        assert(item_one_data.chance == item_one_chance, 'Item 1 chance mismatch');
        assert(item_one_data.heal == item_one_heal, 'Item 1 heal mismatch');
        assert(item_one_data.cooldown == item_one_cooldown, 'Item 1 cooldown mismatch');
        assert(item_one_data.rarity == item_one_rarity, 'Item 1 rarity mismatch');
        assert(item_one_data.item_type == item_one_item_type, 'Item 1 item_type mismatch');
        assert(
            item_one_data.stat_affected == item_one_stat_affected, 'Item 1 stat_affected mismatch'
        );
        assert(item_one_data.percentage == item_one_percentage, 'Item 1 percentage mismatch');
        assert(item_one_data.trigger_type == item_one_trigger_type, 'Item 1 trigger_type mismatch');

        actions_system.edit_item(1, 3, item_one_new_price);

        let item_one_data = get!(world, 1, (Item));

        assert(item_one_data.name == item_one_new_name, 'Item 1 name mismatch');
        assert(item_one_data.width == item_one_width, 'Item 1 width mismatch');
        assert(item_one_data.height == item_one_height, 'Item 1 height mismatch');
        assert(item_one_data.price.into() == item_one_new_price, 'Item 1 price mismatch');
        assert(item_one_data.damage == item_one_damage, 'Item 1 damage mismatch');
        assert(item_one_data.armor == item_one_armor, 'Item 1 armor mismatch');
        assert(item_one_data.chance == item_one_chance, 'Item 1 chance mismatch');
        assert(item_one_data.heal == item_one_heal, 'Item 1 heal mismatch');
        assert(item_one_data.cooldown == item_one_cooldown, 'Item 1 cooldown mismatch');
        assert(item_one_data.rarity == item_one_rarity, 'Item 1 rarity mismatch');
        assert(item_one_data.item_type == item_one_item_type, 'Item 1 item_type mismatch');
        assert(
            item_one_data.stat_affected == item_one_stat_affected, 'Item 1 stat_affected mismatch'
        );
        assert(item_one_data.percentage == item_one_percentage, 'Item 1 percentage mismatch');
        assert(item_one_data.trigger_type == item_one_trigger_type, 'Item 1 trigger_type mismatch');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('caller not world owner', 'ENTRYPOINT_FAILED'))]
    fn test_edit_item_revert_not_world_owner() {
        let owner = starknet::contract_address_const::<0x0>();
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        set_contract_address(alice);

        actions_system.edit_item(1, 1, 4);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('new_width not in range', 'ENTRYPOINT_FAILED'))]
    fn test_edit_item_revert_width_not_in_range() {
        let owner = starknet::contract_address_const::<0x0>();

        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.edit_item(1, 1, 10);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('new_height not in range', 'ENTRYPOINT_FAILED'))]
    fn test_edit_item_revert_height_not_in_range() {
        let owner = starknet::contract_address_const::<0x0>();

        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.edit_item(1, 2, 10);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('new_price must be > 1', 'ENTRYPOINT_FAILED'))]
    fn test_edit_item_revert_price_not_valid() {
        let owner = starknet::contract_address_const::<0x0>();

        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.edit_item(1, 3, 1);
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('new_rarity not valid', 'ENTRYPOINT_FAILED'))]
    fn test_edit_item_revert_invalid_rarity() {
        let owner = starknet::contract_address_const::<0x0>();

        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.edit_item(1, 9, 9);
    }
}

