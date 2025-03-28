use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
struct GameConfig {
    #[key]
    id: felt252,
    strk_address: ContractAddress,
}
