use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
struct Characters {
    #[key]
    player: ContractAddress,
    // must be less than 31 ASCII characters
    name: felt252,
    wmClass: WMClass,
    gold: u32,
    health: u32,
    wins: u32,
    loss: u32,
    rating: u32,
    totalWins: u32,
    totalLoss: u32,
    winStreak: u32,
    stamina: u8,
    birthCount: u32,
    updatedAt: u64
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
enum WMClass {
    Warrior,
    Warlock,
    Archer,
}

#[derive(Drop, Serde)]
#[dojo::model]
struct NameRecord {
    #[key]
    name: felt252,
    player: ContractAddress,
}

const PLAYER: felt252 = 'player';
const DUMMY: felt252 = 'dummy';