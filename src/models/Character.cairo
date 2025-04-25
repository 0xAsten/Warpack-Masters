use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
pub struct Characters {
    #[key]
    pub player: ContractAddress,
    // must be less than 31 ASCII characters
    pub name: felt252,
    pub wmClass: WMClass,
    pub gold: u32,
    pub health: u32,
    pub wins: u32,
    pub loss: u32,
    pub rating: u32,
    pub totalWins: u32,
    pub totalLoss: u32,
    pub winStreak: u32,
    pub stamina: u8,
    pub birthCount: u32,
    pub updatedAt: u64
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum WMClass {
    Warrior,
    Warlock,
    Archer,
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct NameRecord {
    #[key]
    pub name: felt252,
    pub player: ContractAddress,
}

pub const PLAYER: felt252 = 'player';
pub const DUMMY: felt252 = 'dummy';