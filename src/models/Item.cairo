use starknet::ContractAddress;


#[derive(Model, Drop, Serde)]
struct Item {
    #[key]
    id: usize,
    name: felt252,
    width: usize,
    height: usize,
    price: usize,
    damage: usize,
    armor: usize,
    chance: usize,
    cooldown: usize,
    heal: usize,
}
