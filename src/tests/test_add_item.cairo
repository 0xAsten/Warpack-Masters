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
                item_two_rarity
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
                item_three_rarity
            );

        let item = get!(world, ITEMS_COUNTER_ID, ItemsCounter);
        assert(item.count == 3, 'total item count mismatch');

        let item_one_data = get!(world, 1, (Item));
        assert(item_one_data.name == item_one_name, 'Item one name mismatch');
        assert(item_one_data.width == item_one_width, 'Item one width mismatch');
        assert(item_one_data.height == item_one_height, 'Item one height mismatch');
        assert(item_one_data.price == item_one_price, 'Item one price mismatch');
        assert(item_one_data.damage == item_one_damage, 'Item one damage mismatch');
        assert(item_one_data.armor == item_one_armor, 'Item one armor mismatch');
        assert(item_one_data.chance == item_one_chance, 'Item one chance mismatch');
        assert(item_one_data.heal == item_one_heal, 'Item one heal mismatch');
        assert(item_one_data.cooldown == item_one_cooldown, 'Item one cooldown mismatch');
        assert(item_one_data.rarity == item_one_rarity, 'Item one rarity mismatch');

        let item_two_data = get!(world, 2, (Item));
        assert(item_two_data.name == item_two_name, 'Item two name mismatch');
        assert(item_two_data.width == item_two_width, 'Item two width mismatch');
        assert(item_two_data.height == item_two_height, 'Item two height mismatch');
        assert(item_two_data.price == item_two_price, 'Item two price mismatch');
        assert(item_two_data.damage == item_two_damage, 'Item two damage mismatch');
        assert(item_two_data.armor == item_two_armor, 'Item two armor mismatch');
        assert(item_two_data.chance == item_two_chance, 'Item two chance mismatch');
        assert(item_two_data.heal == item_two_heal, 'Item two heal mismatch');
        assert(item_two_data.cooldown == item_two_cooldown, 'Item two cooldown mismatch');
        assert(item_two_data.rarity == item_two_rarity, 'Item two rarity mismatch');

        let item_three_data = get!(world, 3, (Item));
        assert(item_three_data.name == item_three_name, 'Item three name mismatch');
        assert(item_three_data.width == item_three_width, 'Item three width mismatch');
        assert(item_three_data.height == item_three_height, 'Item three height mismatch');
        assert(item_three_data.price == item_three_price, 'Item three price mismatch');
        assert(item_three_data.damage == item_three_damage, 'Item three damage mismatch');
        assert(item_three_data.armor == item_three_armor, 'Item three armor mismatch');
        assert(item_three_data.chance == item_three_chance, 'Item three chance mismatch');
        assert(item_three_data.heal == item_three_heal, 'Item three heal mismatch');
        assert(item_three_data.cooldown == item_three_cooldown, 'Item three cooldown mismatch');
        assert(item_three_data.rarity == item_three_rarity, 'Item three rarity mismatch');
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

        actions_system.add_item('Sword', 1, 3, 100, 10, 10, 5, 10, 5, 5);
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

        actions_system.add_item('Sword', 10, 3, 100, 10, 10, 5, 10, 5, 5);
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

        actions_system.add_item('Sword', 1, 8, 100, 10, 10, 5, 10, 5, 5);
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

        actions_system.add_item('Sword', 1, 3, 1, 10, 10, 5, 10, 5, 5);
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

        actions_system.add_item('Sword', 1, 3, 100, 10, 10, 5, 10, 5, 5);
    }
}

