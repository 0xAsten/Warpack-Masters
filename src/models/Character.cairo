use starknet::ContractAddress;

#[derive(Model, Drop, Serde)]
struct Character {
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
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
enum WMClass {
    Warrior,
    Warlock,
}

#[derive(Model, Drop, Serde)]
struct NameRecord {
    #[key]
    name: felt252,
    player: ContractAddress,
}
