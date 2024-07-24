use starknet::ContractAddress;

#[dojo::contract]
mod view {
    use starknet::ContractAddress;

    use warpack_masters::models::{CharacterItem::{CharacterItemStorage}};

    #[generate_trait]
    impl ViewImpl of ViewTrait {
        fn is_world_owner(world: IWorldDispatcher, player: ContractAddress) -> bool {
            // resource id of world is 0
            let is_owner = world.is_owner(player, 0);

            is_owner
        }

        fn is_item_owned(world: IWorldDispatcher, player: ContractAddress, id: usize) -> bool {
            let storageItem = get!(world, (player, id), (CharacterItemStorage));

            if storageItem.itemId == 0 {
                return false;
            }

            true
        }
    }
}
