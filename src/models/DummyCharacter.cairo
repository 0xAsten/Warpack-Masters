use starknet::ContractAddress;

use warpack_masters::models::Character::WMClass;

#[derive(Drop, Serde)]
#[dojo::model]
struct DummyCharacter {
    #[key]
    level: u32,
    #[key]
    id: u32,
    name: felt252,
    wmClass: WMClass,
    health: u32,
    player: ContractAddress,
    rating: u32,
    stamina: u8,
}

#[derive(Drop, Serde)]
#[dojo::model]
struct DummyCharacterCounter {
    #[key]
    level: u32,
    count: u32,
}
