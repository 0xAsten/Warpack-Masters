use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct GameConfig {
    #[key]
    pub id: felt252,
    pub strk_address: ContractAddress,
    pub rebirth_fee: u256,
}
