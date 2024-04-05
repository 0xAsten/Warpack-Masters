use starknet::ContractAddress;

#[derive(Model, Drop, Serde)]
struct Character {
    #[key]
    player: ContractAddress,
    // must be less than 31 ASCII characters
    name: felt252,
    class: Class,
    gold: usize,
    health: usize,
    wins: usize,
    loss: usize
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
enum Class {
    Warrior,
    Warlock,
}

