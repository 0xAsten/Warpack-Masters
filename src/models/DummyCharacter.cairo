use starknet::ContractAddress;

use warpack_masters::models::Character::WMClass;

#[derive(Drop, Serde)]
#[dojo::model]
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
    stamina: u8,
}

#[derive(Drop, Serde)]
#[dojo::model]
struct DummyCharacterCounter {
    #[key]
    level: usize,
    count: usize,
}
