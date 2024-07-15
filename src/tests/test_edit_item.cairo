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
        models::backpack::{BackpackGrids}, models::Item::{Item, item, ItemsCounter},
        models::CharacterItem::{Position}, utils::{test_utils::{add_items}}
    };

    use warpack_masters::systems::actions::actions::ITEMS_COUNTER_ID;


    #[test]
    #[available_gas(3000000000000000)]
    fn test_edit_item() {
        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        let item_one_new_name: felt252 = 'New Dagger';
        let item_one_new_itemType: felt252 = 2;
        let item_one_new_width: felt252 = 2;
        let item_one_new_height: felt252 = 1;
        let item_one_new_price: felt252 = 4;
        let item_one_new_damage: felt252 = 2;
        let item_one_new_cleansePoison: felt252 = 2;
        let item_one_new_chance: felt252 = 100;
        let item_one_new_cooldown: felt252 = 5;
        let item_one_new_rarity: felt252 = 2;
        let item_one_new_armor: felt252 = 1;
        let item_one_new_armorActivation: felt252 = 1;
        let item_one_new_regen: felt252 = 1;
        let item_one_new_regenActivation: felt252 = 1;
        let item_one_new_reflect: felt252 = 2;
        let item_one_new_reflectActivation: felt252 = 2;
        let item_one_new_poison: felt252 = 3;
        let item_one_new_poisonActivation: felt252 = 3;
        let item_one_new_empower: felt252 = 1;
        let item_one_new_empowerActivation: felt252 = 1;

        actions_system.edit_item(1, 0, item_one_new_name);
        actions_system.edit_item(1, 1, item_one_new_itemType);
        actions_system.edit_item(1, 2, item_one_new_width);
        actions_system.edit_item(1, 3, item_one_new_height);
        actions_system.edit_item(1, 4, item_one_new_price);
        actions_system.edit_item(1, 5, item_one_new_damage);
        actions_system.edit_item(1, 6, item_one_new_cleansePoison);
        actions_system.edit_item(1, 7, item_one_new_chance);
        actions_system.edit_item(1, 8, item_one_new_cooldown);
        actions_system.edit_item(1, 9, item_one_new_rarity);
        actions_system.edit_item(1, 10, item_one_new_armor);
        actions_system.edit_item(1, 11, item_one_new_armorActivation);
        actions_system.edit_item(1, 12, item_one_new_regen);
        actions_system.edit_item(1, 13, item_one_new_regenActivation);
        actions_system.edit_item(1, 14, item_one_new_reflect);
        actions_system.edit_item(1, 15, item_one_new_reflectActivation);
        actions_system.edit_item(1, 16, item_one_new_poison);
        actions_system.edit_item(1, 17, item_one_new_poisonActivation);
        actions_system.edit_item(1, 18, item_one_new_empower);
        actions_system.edit_item(1, 19, item_one_new_empowerActivation);

        let item_one_data = get!(world, 1, (Item));
        assert(item_one_data.name == item_one_new_name, 'I1 name mismatch');
        assert(item_one_data.itemType.into() == item_one_new_itemType, 'I1 itemType mismatch');
        assert(item_one_data.width.into() == item_one_new_width, 'I1 width mismatch');
        assert(item_one_data.height.into() == item_one_new_height, 'I1 height mismatch');
        assert(item_one_data.price.into() == item_one_new_price, 'I1 price mismatch');
        assert(item_one_data.damage.into() == item_one_new_damage, 'I1 damage mismatch');
        assert(
            item_one_data.cleansePoison.into() == item_one_new_cleansePoison,
            'I1 cleansePoison mismatch'
        );
        assert(item_one_data.chance.into() == item_one_new_chance, 'I1 chance mismatch');
        assert(item_one_data.cooldown.into() == item_one_new_cooldown, 'I1 cooldown mismatch');
        assert(item_one_data.rarity.into() == item_one_new_rarity, 'I1 rarity mismatch');
        assert(item_one_data.armor.into() == item_one_new_armor, 'I1 armor mismatch');
        assert(
            item_one_data.armorActivation.into() == item_one_new_armorActivation,
            'I1 armorActivation mismatch'
        );
        assert(item_one_data.regen.into() == item_one_new_regen, 'I1 regen mismatch');
        assert(
            item_one_data.regenActivation.into() == item_one_new_regenActivation,
            'I1 regenActivation mismatch'
        );
        assert(item_one_data.reflect.into() == item_one_new_reflect, 'I1 reflect mismatch');
        assert(
            item_one_data.reflectActivation.into() == item_one_new_reflectActivation,
            'I1 reflectActivation mismatch'
        );
        assert(item_one_data.poison.into() == item_one_new_poison, 'I1 poison mismatch');
        assert(
            item_one_data.poisonActivation.into() == item_one_new_poisonActivation,
            'I1 poisonActivation mismatch'
        );
        assert(item_one_data.empower.into() == item_one_new_empower, 'I1 empower mismatch');
        assert(
            item_one_data.empowerActivation.into() == item_one_new_empowerActivation,
            'I1 empowerActivation mismatch'
        );
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('player not world owner', 'ENTRYPOINT_FAILED'))]
    fn test_edit_item_revert_not_world_owner() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);

        actions_system.edit_item(1, 1, 4);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('new_width not in range', 'ENTRYPOINT_FAILED'))]
    fn test_edit_item_revert_width_not_in_range() {
        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        actions_system.edit_item(1, 2, 10);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('new_height not in range', 'ENTRYPOINT_FAILED'))]
    fn test_edit_item_revert_height_not_in_range() {
        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        actions_system.edit_item(1, 3, 10);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('new_price must be > 0', 'ENTRYPOINT_FAILED'))]
    fn test_edit_item_revert_price_not_valid() {
        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        actions_system.edit_item(1, 4, 0);
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('new_rarity not valid', 'ENTRYPOINT_FAILED'))]
    fn test_edit_item_revert_invalid_rarity() {
        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        actions_system.edit_item(1, 9, 9);
    }
}

