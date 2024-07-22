use starknet::ContractAddress;

#[dojo::interface]
trait IView {
    fn is_world_owner(ref world: IWorldDispatcher, player: ContractAddress) -> bool;
    fn is_item_owned(ref world: IWorldDispatcher, player: ContractAddress, id: usize) -> bool;
}

#[dojo::contract]
mod view {
    use super::{IView, ContractAddress};

    use warpack_masters::models::{CharacterItem::{CharacterItemStorage}};

    #[abi(embed_v0)]
    impl ViewImpl of IView<ContractState> {
        fn is_world_owner(ref world: IWorldDispatcher, player: ContractAddress) -> bool {
            // resource id of world is 0
            let is_owner = world.is_owner(player, 0);

            is_owner
        }

        fn is_item_owned(ref world: IWorldDispatcher, player: ContractAddress, id: usize) -> bool {
            let storageItem = get!(world, (player, id), (CharacterItemStorage));

            if storageItem.itemId == 0 {
                return false;
            }

            true
        }
    }
}
