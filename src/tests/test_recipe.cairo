#[cfg(test)]
mod tests {
    use core::starknet::contract_address::ContractAddress;
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::{set_contract_address, set_block_timestamp};

    use dojo::model::{Model, ModelTest, ModelIndex, ModelEntityTest};
    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::utils::test::{spawn_test_world, deploy_contract};

    use warpack_masters::{
        systems::{recipe::{recipe_system, IRecipeDispatcher, IRecipeDispatcherTrait}},
        systems::{item::{item_system, IItemDispatcher, IItemDispatcherTrait}},
        models::Item::{Item, item, ItemsCounter, items_counter},
        models::CharacterItem::{
            Position, CharacterItemStorage, character_item_storage
        },
        models::Recipe::{Recipe, recipe},
        utils::test_utils::add_items
    };

    fn get_systems(
        world: IWorldDispatcher
    ) -> (ContractAddress, IItemDispatcher, ContractAddress, IRecipeDispatcher) {
        let item_system_address = world.deploy_contract('salt1', item_system::TEST_CLASS_HASH.try_into().unwrap());
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        world.grant_writer(Model::<Item>::selector(), item_system_address);
        world.grant_writer(Model::<ItemsCounter>::selector(), item_system_address);


        let recipe_system_address = world
            .deploy_contract('salt2', recipe_system::TEST_CLASS_HASH.try_into().unwrap());
        let mut recipe_system = IRecipeDispatcher { contract_address: recipe_system_address };

        world.grant_writer(Model::<CharacterItemStorage>::selector(), recipe_system_address);
        world.grant_writer(Model::<Item>::selector(), recipe_system_address);
        world.grant_writer(Model::<Recipe>::selector(), recipe_system_address);

        (item_system_address, item_system, recipe_system_address, recipe_system)
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_add_recipe() {
        let world = spawn_test_world!();
        let (_, mut item_system, _, mut recipe_system) = get_systems(world);

        add_items(ref item_system);

        recipe_system.add_recipe(1, 2, 3);

        let recipe = get!(world, (1, 2), Recipe);
        assert_eq!(recipe.item1_id, 1);
        assert_eq!(recipe.item2_id, 2);
        assert_eq!(recipe.result_item_id, 3);

        let recipe = get!(world, (2, 1), Recipe);
        assert_eq!(recipe.item1_id, 2);
        assert_eq!(recipe.item2_id, 1);
        assert_eq!(recipe.result_item_id, 3);
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_add_recipe_with_same_item_id() {
        let world = spawn_test_world!();
        let (_, mut item_system, _, mut recipe_system) = get_systems(world);

        add_items(ref item_system);

        recipe_system.add_recipe(1, 1, 2);

        let recipe = get!(world, (1, 1), Recipe);
        assert_eq!(recipe.item1_id, 1);
        assert_eq!(recipe.item2_id, 1);
        assert_eq!(recipe.result_item_id, 2);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('player not world owner', 'ENTRYPOINT_FAILED'))]
    fn test_add_recipe_without_permission() {
        let world = spawn_test_world!();
        let (_, mut item_system, _, mut recipe_system) = get_systems(world);

        add_items(ref item_system);

        let alice = starknet::contract_address_const::<0x1>();
        set_contract_address(alice);
        recipe_system.add_recipe(1, 2, 3);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item1 does not exist', 'ENTRYPOINT_FAILED'))]
    fn test_add_recipe_item1_doesnt_exists() {
        let world = spawn_test_world!();
        let (_, mut item_system, _, mut recipe_system) = get_systems(world);

        add_items(ref item_system);

        recipe_system.add_recipe(100, 2, 3);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item2 does not exist', 'ENTRYPOINT_FAILED'))]
    fn test_add_recipe_item2_doesnt_exists() {
        let world = spawn_test_world!();
        let (_, mut item_system, _, mut recipe_system) = get_systems(world);

        add_items(ref item_system);

        recipe_system.add_recipe(1, 200, 3);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('result item does not exist', 'ENTRYPOINT_FAILED'))]
    fn test_add_recipe_result_doesnt_exists() {
        let world = spawn_test_world!();
        let (_, mut item_system, _, mut recipe_system) = get_systems(world);

        add_items(ref item_system);

        recipe_system.add_recipe(1, 2, 300);
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_craft_item() {
        let world = spawn_test_world!();
        let (_, mut item_system, _, mut recipe_system) = get_systems(world);

        add_items(ref item_system);

        recipe_system.add_recipe(1, 2, 3);

        let alice = starknet::contract_address_const::<0x1>();
        set!(world, CharacterItemStorage { player: alice, id: 1, itemId: 1});
        set!(world, CharacterItemStorage { player: alice, id: 2, itemId: 2});

        set_contract_address(alice);
        recipe_system.craft_item(1, 2);

        let item_at_1 = get!(world, (alice, 1), CharacterItemStorage);
        assert_eq!(item_at_1.itemId, 3);
        let item_at_2 = get!(world, (alice, 2), CharacterItemStorage);
        assert_eq!(item_at_2.itemId, 0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('No valid recipe found', 'ENTRYPOINT_FAILED'))]
    fn test_no_valid_recipe_found() {
        let world = spawn_test_world!();
        let (_, mut item_system, _, mut recipe_system) = get_systems(world);

        add_items(ref item_system);

        let alice = starknet::contract_address_const::<0x1>();
        set!(world, CharacterItemStorage { player: alice, id: 1, itemId: 1});
        set!(world, CharacterItemStorage { player: alice, id: 2, itemId: 2});

        set_contract_address(alice);
        recipe_system.craft_item(1, 2);
    }
}