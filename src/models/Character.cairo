use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
struct Characters {
    #[key]
    player: ContractAddress,
    // must be less than 31 ASCII characters
    name: felt252,
    wmClass: WMClass,
    gold: usize,
    health: usize,
    wins: usize,
    loss: usize,
    dummied: bool,
    rating: usize,
    totalWins: usize,
    totalLoss: usize,
    winStreak: usize,
    stamina: u8,
    vampirism: usize,
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
