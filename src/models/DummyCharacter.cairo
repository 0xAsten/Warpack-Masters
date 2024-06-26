use starknet::ContractAddress;

use warpack_masters::models::Character::WMClass;

#[derive(Model, Drop, Serde)]
struct DummyCharacter {
    #[key]
    level: usize,
    #[key]
    id: u32,
    name: felt252,
    wmClass: WMClass,
    health: usize,
    player: ContractAddress,
    rating: usize,
}

#[derive(Model, Drop, Serde)]
struct DummyCharacterCounter {
    #[key]
    level: usize,
    count: usize,
}
