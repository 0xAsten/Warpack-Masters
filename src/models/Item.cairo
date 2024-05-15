use starknet::ContractAddress;


#[derive(Model, Drop, Serde)]
struct Item {
    #[key]
    id: usize,
    name: felt252,
    // 1.Melee 2.Ranged
    weaponType: u8,
    width: usize,
    height: usize,
    price: usize,
    // Base damage
    damage: usize,
    // Accuracy to trigger
    chance: usize,
    // item reuse time
    cooldown: usize,
    rarity: usize,
    armor: usize,
    heal: usize,
    reflect: usize,
    poison: usize,
}

#[derive(Model, Drop, Serde)]
struct ItemsCounter {
    #[key]
    id: felt252,
    count: usize,
}
