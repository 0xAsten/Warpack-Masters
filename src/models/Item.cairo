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
    rarity: usize,
}

#[derive(Model, Drop, Serde)]
struct ItemsCounter {
    #[key]
    id: felt252,
    count: usize,
}
