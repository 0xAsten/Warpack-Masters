use starknet::ContractAddress;

use warpack_masters::models::Character::Class;

#[derive(Model, Drop, Serde)]
struct DummyCharacter {
    #[key]
    level: usize,
    #[key]
    id: u32,
    name: felt252,
    class: Class,
    health: usize,
}

#[derive(Model, Drop, Serde)]
struct DummyCharacterCounter {
    #[key]
    level: usize,
    count: usize,
}
