#[dojo::contract]
mod config_system {
    use dojo::model::ModelStorage;
    use dojo::world::IWorldDispatcherTrait;
    use starknet::{ContractAddress, get_caller_address};
    use warpack_masters::constants::constants::{GAME_CONFIG_ID, REBIRTH_FEE};
    use warpack_masters::models::Game::GameConfig;


    fn dojo_init(ref self: ContractState, contract_address: ContractAddress) {
        let mut world = self.world(@"Warpacks");

        world
            .write_model(
                @GameConfig {
                    id: GAME_CONFIG_ID,
                    strk_address: contract_address,
                    rebirth_fee: REBIRTH_FEE,
                },
            );
    }

    fn set_rebirth_fee(ref self: ContractState, rebirth_fee: u256) {
        let mut world = self.world(@"Warpacks");

        let caller = get_caller_address();
        assert(world.dispatcher.is_owner(0, caller), 'caller not world owner');

        let mut gameConfig: GameConfig = world.read_model(GAME_CONFIG_ID);
        gameConfig.rebirth_fee = rebirth_fee;
        world.write_model(@gameConfig);
    }
}
