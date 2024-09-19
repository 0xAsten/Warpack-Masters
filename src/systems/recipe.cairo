#[dojo::interface]
trait IRecipe {
    fn add_recipe(
        ref world: IWorldDispatcher, item1_id: u32, item2_id: u32, result_item_id: u32
    );
    fn craft_item(
        ref world: IWorldDispatcher, storage_item_id1: u32, storage_item_id2: u32
    );
}

#[dojo::contract]
mod recipe_system {
    use super::{IRecipe};

    use starknet::{get_caller_address, get_block_timestamp};
    use warpack_masters::models::{
        CharacterItem::CharacterItemStorage,
        Item::Item,
        Recipe::Recipe,
    };

    use warpack_masters::systems::view::view::ViewImpl;

    #[abi(embed_v0)]
    impl RecipeImpl of IRecipe<ContractState> {
        fn add_recipe(
            ref world: IWorldDispatcher, item1_id: u32, item2_id: u32, result_item_id: u32
        ) {
            let player = get_caller_address();
            assert(ViewImpl::is_world_owner(world, player), 'player not world owner');

            let item1 = get!(world, item1_id, Item);
            assert(item1.height != 0, 'item1 does not exist');
            let item2 = get!(world, item2_id, Item);
            assert(item2.height != 0, 'item2 does not exist');

            // make constructor
            let result_item = get!(world, result_item_id, Item);
            assert(result_item.height != 0, 'result item does not exist');

            set!(world, Recipe {
                    item1_id,
                    item2_id,
                    result_item_id,
                }
            );

            if item1_id != item2_id {
                set!(world, Recipe {
                        item1_id: item2_id,
                        item2_id: item1_id,
                        result_item_id,
                    }
                );
            }
        }

        fn craft_item(
            ref world: IWorldDispatcher, storage_item_id1: u32, storage_item_id2: u32
        ) {
            let player = get_caller_address();

            let mut storageItem1 = get!(world, (player, storage_item_id1), (CharacterItemStorage));
            assert(storageItem1.itemId != 0, 'item not owned');

            let mut storageItem2 = get!(world, (player, storage_item_id2), (CharacterItemStorage));
            assert(storageItem2.itemId != 0, 'item not owned');

            let recipe = get!(world, (storageItem1.itemId, storageItem2.itemId), (Recipe));
            assert(recipe.result_item_id != 0, 'No valid recipe found');

            storageItem1.itemId = recipe.result_item_id;
            storageItem2.itemId = 0;
            set!(world, (storageItem1, storageItem2));
        }
    }
}
