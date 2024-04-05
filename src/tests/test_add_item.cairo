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
    fn test_add_item() {
        let owner = starknet::contract_address_const::<0x0>();

        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        let item_one_name = 'Sword';
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

        let item_two_name = 'Shield';
        let item_two_width = 2;
        let item_two_height = 2;
        let item_two_price = 50;
        let item_two_damage = 0;
        let item_two_armor = 5;
        let item_two_chance = 5;
        let item_two_cooldown = 10;
        let item_two_heal = 5;
        let item_two_rarity = 1;
        let item_two_item_type = 'Weapon';
        let item_two_stat_affected = '';
        let item_two_percentage = 0;
        let item_two_trigger_type = 0;

        let item_three_name = 'Potion';
        let item_three_width = 1;
        let item_three_height = 1;
        let item_three_price = 20;
        let item_three_damage = 0;
        let item_three_armor = 0;
        let item_three_chance = 5;
        let item_three_cooldown = 10;
        let item_three_heal = 15;
        let item_three_rarity = 3;
        let item_three_item_type = 'Buff';
        let item_three_stat_affected = 'Health';
        let item_three_percentage = 0;
        let item_three_trigger_type = 2;

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
                item_two_item_type,
                item_two_stat_affected,
                item_two_percentage,
                item_two_trigger_type
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
                item_three_item_type,
                item_three_stat_affected,
                item_three_percentage,
                item_three_trigger_type
            );

        let item = get!(world, ITEMS_COUNTER_ID, ItemsCounter);
        assert(item.count == 3, 'total item count mismatch');

        let item_one_data = get!(world, 1, (Item));
        assert(item_one_data.name == item_one_name, 'Item 1 name mismatch');
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

        let item_two_data = get!(world, 2, (Item));
        assert(item_two_data.name == item_two_name, 'Item 2 name mismatch');
        assert(item_two_data.width == item_two_width, 'Item 2 width mismatch');
        assert(item_two_data.height == item_two_height, 'Item 2 height mismatch');
        assert(item_two_data.price == item_two_price, 'Item 2 price mismatch');
        assert(item_two_data.damage == item_two_damage, 'Item 2 damage mismatch');
        assert(item_two_data.armor == item_two_armor, 'Item 2 armor mismatch');
        assert(item_two_data.chance == item_two_chance, 'Item 2 chance mismatch');
        assert(item_two_data.heal == item_two_heal, 'Item 2 heal mismatch');
        assert(item_two_data.cooldown == item_two_cooldown, 'Item 2 cooldown mismatch');
        assert(item_two_data.rarity == item_two_rarity, 'Item 2 rarity mismatch');
        assert(item_two_data.item_type == item_two_item_type, 'Item 2 item_type mismatch');
        assert(
            item_two_data.stat_affected == item_two_stat_affected, 'Item 2 stat_affected mismatch'
        );
        assert(item_two_data.percentage == item_two_percentage, 'Item 2 percentage mismatch');
        assert(item_two_data.trigger_type == item_two_trigger_type, 'Item 2 trigger_type mismatch');

        let item_three_data = get!(world, 3, (Item));
        assert(item_three_data.name == item_three_name, 'Item 3 name mismatch');
        assert(item_three_data.width == item_three_width, 'Item 3 width mismatch');
        assert(item_three_data.height == item_three_height, 'Item 3 height mismatch');
        assert(item_three_data.price == item_three_price, 'Item 3 price mismatch');
        assert(item_three_data.damage == item_three_damage, 'Item 3 damage mismatch');
        assert(item_three_data.armor == item_three_armor, 'Item 3 armor mismatch');
        assert(item_three_data.chance == item_three_chance, 'Item 3 chance mismatch');
        assert(item_three_data.heal == item_three_heal, 'Item 3 heal mismatch');
        assert(item_three_data.cooldown == item_three_cooldown, 'Item 3 cooldown mismatch');
        assert(item_three_data.rarity == item_three_rarity, 'Item 3 rarity mismatch');
        assert(item_three_data.item_type == item_three_item_type, 'Item 3 item_type mismatch');
        assert(
            item_three_data.stat_affected == item_three_stat_affected,
            'Item 3 stat_affected mismatch'
        );
        assert(item_three_data.percentage == item_three_percentage, 'Item 3 percentage mismatch');
        assert(
            item_three_data.trigger_type == item_three_trigger_type, 'Item 3 trigger_type mismatch'
        );
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('caller not world owner', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_not_world_owner() {
        let owner = starknet::contract_address_const::<0x0>();
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        set_contract_address(alice);

        actions_system.add_item('Sword', 1, 3, 100, 10, 10, 5, 10, 5, 5, 'Weapon', '', 0, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('width not in range', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_width_not_in_range() {
        let owner = starknet::contract_address_const::<0x0>();

        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 10, 3, 100, 10, 10, 5, 10, 5, 5, 'Weapon', '', 0, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('height not in range', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_height_not_in_range() {
        let owner = starknet::contract_address_const::<0x0>();

        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 1, 8, 100, 10, 10, 5, 10, 5, 5, 'Weapon', '', 0, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('price must be greater than 1', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_price_not_valid() {
        let owner = starknet::contract_address_const::<0x0>();

        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 1, 3, 1, 10, 10, 5, 10, 5, 5, 'Weapon', '', 0, 0);
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('rarity not valid', 'ENTRYPOINT_FAILED'))]
    fn test_add_item_revert_invalid_rarity() {
        let owner = starknet::contract_address_const::<0x0>();

        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 1, 3, 100, 10, 10, 5, 10, 5, 5, 'Weapon', '', 0, 0);
    }
}

