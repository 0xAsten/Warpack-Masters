#[starknet::interface]
pub trait IRecipe<T> {
    fn add_recipe(
        ref self: T, item_ids: Array<u32>, item_amounts: Array<u32>, result_item_id: u32
    );
}

#[dojo::contract]
mod recipe_system {
    use super::{IRecipe};

    use starknet::{get_caller_address};
    use warpack_masters::models::{
        Item::Item,
        Recipe::{RecipeV2, RecipesCounter},
    };
    use warpack_masters::constants::constants::{RECIPES_COUNTER_ID};

    use dojo::model::{ModelStorage};
    use dojo::world::{IWorldDispatcherTrait};

    #[abi(embed_v0)]
    impl RecipeImpl of IRecipe<ContractState> {
    fn add_recipe(
            ref self: ContractState, item_ids: Array<u32>, item_amounts: Array<u32>, result_item_id: u32
        ) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();
            assert(world.dispatcher.is_owner(0, player), 'player not world owner');

            let item_ids_len = item_ids.len();
            assert(item_ids_len > 0, 'must have at least one item');
            assert(item_ids_len == item_amounts.len(), 'must the same length');

            for i in 0..item_ids_len {
                let item_id = *item_ids[i];
                let item_amount = *item_amounts[i];
                assert(item_amount > 0, 'amount must be greater than 0');

                let item: Item = world.read_model(item_id);
                assert(item.enabled, 'item is not enabled');
            };

            let result_item: Item = world.read_model(result_item_id);
            assert(result_item.enabled, 'result item is not enabled');

            let mut recipes_counter: RecipesCounter = world.read_model(RECIPES_COUNTER_ID);
            let new_id = recipes_counter.count + 1;
            recipes_counter.count = new_id;

            world.write_model(@RecipeV2 {
                id: new_id,
                item_ids,
                item_amounts,
                result_item_id,
                enabled: true,
            });

            world.write_model(@recipes_counter);
        }
    }
}
