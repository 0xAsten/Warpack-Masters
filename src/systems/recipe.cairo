#[starknet::interface]
trait IRecipe<T> {
    fn add_recipe(
        ref self: T, item1_id: u32, item2_id: u32, result_item_id: u32
    );
    fn craft_item(
        ref self: T, storage_item_id1: u32, storage_item_id2: u32
    );
}

#[dojo::contract]
mod recipe_system {
    use super::{IRecipe};

    use starknet::{get_caller_address};
    use warpack_masters::models::{
        CharacterItem::CharacterItemStorage,
        Item::Item,
        Recipe::Recipe,
    };

    use dojo::model::{ModelStorage};
    use dojo::world::{IWorldDispatcherTrait};

    #[abi(embed_v0)]
    impl RecipeImpl of IRecipe<ContractState> {
    fn add_recipe(
            ref self: ContractState, item1_id: u32, item2_id: u32, result_item_id: u32
        ) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();
            assert(world.dispatcher.is_owner(0, player), 'player not world owner');

            let item1: Item = world.read_model(item1_id);
            assert(item1.height != 0, 'item1 does not exist');
            let item2: Item = world.read_model(item2_id);
            assert(item2.height != 0, 'item2 does not exist');

            // make constructor
            let result_item: Item = world.read_model(result_item_id);
            assert(result_item.height != 0, 'result item does not exist');

            world.write_model(@Recipe {
                item1_id,
                item2_id,
                result_item_id,
            });

            if item1_id != item2_id {
                world.write_model(@Recipe {
                    item1_id: item2_id,
                    item2_id: item1_id,
                    result_item_id,
                });
            }
        }

        fn craft_item(
            ref self: ContractState, storage_item_id1: u32, storage_item_id2: u32
        ) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            let mut storageItem1: CharacterItemStorage = world.read_model((player, storage_item_id1));
            assert(storageItem1.itemId != 0, 'item not owned');

            let mut storageItem2: CharacterItemStorage = world.read_model((player, storage_item_id2));
            assert(storageItem2.itemId != 0, 'item not owned');

            let recipe: Recipe = world.read_model((storageItem1.itemId, storageItem2.itemId));
            assert(recipe.result_item_id != 0, 'No valid recipe found');

            storageItem1.itemId = recipe.result_item_id;
            storageItem2.itemId = 0;
            world.write_model(@storageItem1);
            world.write_model(@storageItem2);
        }
    }
}
