#[dojo::contract]
mod config_system {
    use warpack_masters::constants::constants::GAME_CONFIG_ID;
    use warpack_masters::models::Game::GameConfig;

    use dojo::model::{ModelStorage};

    fn dojo_init(ref self: ContractState, contract_address: starknet::ContractAddress) {
        let mut world = self.world(@"Warpacks");
        
        world.write_model(@GameConfig {
            id: GAME_CONFIG_ID,
            strk_address: contract_address,
        });
    }
}