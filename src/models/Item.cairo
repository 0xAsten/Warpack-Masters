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
    cooldown: u8,
    rarity: u8,
    // Effects
    // activation 0 - passive, 1 - on start, 2 - on hit
    armor: usize,
    armorActivation: u8,
    regen: usize,
    regenActivation: u8,
    reflect: usize,
    reflectActivation: u8,
    poison: usize,
    poisonActivation: u8,
}

#[derive(Model, Drop, Serde)]
struct ItemsCounter {
    #[key]
    id: felt252,
    count: usize,
}
