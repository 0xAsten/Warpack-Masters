use starknet::ContractAddress;

#[derive(Model, Drop, Serde)]
#[dojo::model]
struct BattleLog {
    #[key]
    player: ContractAddress,
    #[key]
    id: usize,
    dummyCharLevel: usize,
    dummyCharId: usize,
    // dummy or player
    winner: felt252,
    seconds: u8
}


#[derive(Model, Drop, Serde)]
#[dojo::model]
struct BattleLogCounter {
    #[key]
    player: ContractAddress,
    count: usize,
}
