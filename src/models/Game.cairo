use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
pub struct GameConfig {
    #[key]
    pub id: felt252,
    pub strk_address: ContractAddress,
}
