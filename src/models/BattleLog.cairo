use starknet::ContractAddress;

#[derive(Model, Drop, Serde)]
struct BattleLog {
    #[key]
    player: ContractAddress,
    #[key]
    id: usize,
    dummyCharLevel: usize,
    dummyCharId: usize,
    winner: felt252,
}


#[derive(Model, Drop, Serde)]
struct BattleLogCounter {
    #[key]
    player: ContractAddress,
    count: usize,
}


#[derive(Model, Drop, Serde)]
struct BattleLogDetail {
    #[key]
    player: ContractAddress,
    #[key]
    battleLogId: usize,
    #[key]
    id: usize,
    whoTriggered: felt252,
    whichItem: usize,
    damageCaused: usize,
    selfHeal: usize,
    isDodged: bool,
    healFailed: bool,
}

#[derive(Model, Drop, Serde)]
struct BattleLogDetailCounter {
    #[key]
    player: ContractAddress,
    #[key]
    battleLogId: usize,
    count: usize,
}
