use starknet::ContractAddress;


#[derive(Model, Drop, Serde)]
struct Item {
    #[key]
    id: usize,
    name: felt252,
    width: usize,
    height: usize,
    price: usize,
    // Base damage
    damage: usize,
    // Base armour
    armor: usize,
    // Accuracy to trigger
    chance: usize,
    // item reuse time
    cooldown: usize,
    // base heal
    heal: usize,
    rarity: usize,
}

#[derive(Model, Drop, Serde)]
struct ItemsCounter {
    #[key]
    id: felt252,
    count: usize,
}
