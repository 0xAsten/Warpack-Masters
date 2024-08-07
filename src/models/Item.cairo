use starknet::ContractAddress;


#[derive(Drop, Serde)]
#[dojo::model]
struct Item {
    #[key]
    id: usize,
    name: felt252,
    // 1 - Melee Weapon, 2 - Ranged Weapon, 3 - Gear, 4 - Backpack
    itemType: u8,
    width: usize,
    height: usize,
    price: usize,
    // Base damage
    damage: usize,
    cleansePoison: usize,
    // Accuracy to trigger
    chance: usize,
    // item reuse time
    cooldown: u8,
    rarity: u8,
    // Effects
    // activation 0 - passive, 1 - on start, 2 - on hit, 3 - on cooldown, 4 - on attack
    armor: usize,
    armorActivation: u8,
    regen: usize,
    regenActivation: u8,
    reflect: usize,
    reflectActivation: u8,
    poison: usize,
    poisonActivation: u8,
    empower: usize,
    empowerActivation: u8,
}

#[derive(Drop, Serde)]
#[dojo::model]
struct ItemsCounter {
    #[key]
    id: felt252,
    count: usize,
}
