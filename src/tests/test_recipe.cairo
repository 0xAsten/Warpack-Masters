#[cfg(test)]
mod tests {
    use core::starknet::contract_address::ContractAddress;
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::{set_contract_address, set_block_timestamp};

    use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef, WorldStorageTestTrait};

    use warpack_masters::{
        systems::{recipe::{recipe_system, IRecipeDispatcher, IRecipeDispatcherTrait}},
        systems::{item::{item_system, IItemDispatcher, IItemDispatcherTrait}},
        models::Item::{Item, m_Item, ItemsCounter, m_ItemsCounter},
        models::CharacterItem::{
            Position, CharacterItemStorage, m_CharacterItemStorage
        },
        models::Recipe::{Recipe, m_Recipe},
        utils::test_utils::add_items
    };

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "Warpacks", 
            resources: [
                TestResource::Model(m_Item::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_ItemsCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemStorage::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Recipe::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Contract(item_system::TEST_CLASS_HASH),
                TestResource::Contract(recipe_system::TEST_CLASS_HASH),
            ].span()
        };
        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"Warpacks", @"item_system")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
            ContractDefTrait::new(@"Warpacks", @"recipe_system")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
        ].span()
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_add_recipe() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"recipe_system").unwrap();
        let mut recipe_system = IRecipeDispatcher { contract_address };

        add_items(ref item_system);

        recipe_system.add_recipe(1, 2, 3);

        let recipe: Recipe = world.read_model((1, 2));
        assert(recipe.item1_id == 1, 'wrong item1_id');
        assert(recipe.item2_id == 2, 'wrong item2_id');
        assert(recipe.result_item_id == 3, 'wrong result_item_id');

        let recipe: Recipe = world.read_model((2, 1));
        assert(recipe.item1_id == 2, 'wrong item1_id');
        assert(recipe.item2_id == 1, 'wrong item2_id');
        assert(recipe.result_item_id == 3, 'wrong result_item_id');
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_add_recipe_with_same_item_id() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"recipe_system").unwrap();
        let mut recipe_system = IRecipeDispatcher { contract_address };

        add_items(ref item_system);

        recipe_system.add_recipe(1, 1, 2);

        let recipe: Recipe = world.read_model((1, 1));
        assert(recipe.item1_id == 1, 'wrong item1_id');
        assert(recipe.item2_id == 1, 'wrong item2_id');
        assert(recipe.result_item_id == 2, 'wrong result_item_id');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('player not world owner', 'ENTRYPOINT_FAILED'))]
    fn test_add_recipe_without_permission() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"recipe_system").unwrap();
        let mut recipe_system = IRecipeDispatcher { contract_address };

        add_items(ref item_system);

        let alice = starknet::contract_address_const::<0x1>();
        set_contract_address(alice);
        recipe_system.add_recipe(1, 2, 3);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item1 does not exist', 'ENTRYPOINT_FAILED'))]
    fn test_add_recipe_item1_doesnt_exists() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"recipe_system").unwrap();
        let mut recipe_system = IRecipeDispatcher { contract_address };

        add_items(ref item_system);

        recipe_system.add_recipe(100, 2, 3);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item2 does not exist', 'ENTRYPOINT_FAILED'))]
    fn test_add_recipe_item2_doesnt_exists() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"recipe_system").unwrap();
        let mut recipe_system = IRecipeDispatcher { contract_address };

        add_items(ref item_system);

        recipe_system.add_recipe(1, 200, 3);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('result item does not exist', 'ENTRYPOINT_FAILED'))]
    fn test_add_recipe_result_doesnt_exists() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"recipe_system").unwrap();
        let mut recipe_system = IRecipeDispatcher { contract_address };

        add_items(ref item_system);

        recipe_system.add_recipe(1, 2, 300);
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_craft_item() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"recipe_system").unwrap();
        let mut recipe_system = IRecipeDispatcher { contract_address };

        add_items(ref item_system);

        recipe_system.add_recipe(1, 2, 3);

        let alice = starknet::contract_address_const::<0x1>();
        world.write_model(@CharacterItemStorage { player: alice, id: 1, itemId: 1});
        world.write_model(@CharacterItemStorage { player: alice, id: 2, itemId: 2});

        set_contract_address(alice);
        recipe_system.craft_item(1, 2);

        let item_at_1: CharacterItemStorage = world.read_model((alice, 1));
        assert(item_at_1.itemId == 3, 'wrong itemId at (alice, 1)');
        let item_at_2: CharacterItemStorage = world.read_model((alice, 2));
        assert(item_at_2.itemId == 0, 'wrong itemId at (alice, 2)');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('No valid recipe found', 'ENTRYPOINT_FAILED'))]
    fn test_no_valid_recipe_found() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"recipe_system").unwrap();
        let mut recipe_system = IRecipeDispatcher { contract_address };

        add_items(ref item_system);

        let alice = starknet::contract_address_const::<0x1>();
        world.write_model(@CharacterItemStorage { player: alice, id: 1, itemId: 1});
        world.write_model(@CharacterItemStorage { player: alice, id: 2, itemId: 2});

        set_contract_address(alice);
        recipe_system.craft_item(1, 2);
    }
}