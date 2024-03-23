#[starknet::interface]
trait IActions<TContractState> {
    fn spawn(self: @TContractState);
}

#[dojo::contract]
mod actions {
    use super::IActions;

    use starknet::{ContractAddress, get_caller_address};
    use dojo_starter::models::{backpack::{Backpack}};

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Spawned: Spawned,
    }

    // declaring custom event struct
    #[derive(Drop, starknet::Event)]
    struct Spawned {
        player: ContractAddress,
        gridSize: u8
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn spawn(self: @ContractState) {
            let world = self.world_dispatcher.read();

            let player = get_caller_address();

            let backpack = get!(world, player, (Backpack));

            set!(world, (Backpack { player, gridSize: 10 },));

            emit!(world, Spawned { player: player, gridSize: 10 });
        }
    }
}
