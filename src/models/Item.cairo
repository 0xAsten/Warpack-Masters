use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
struct Item {
    #[key]
    id: usize,
    name: felt252,
    // 1 - Melee Weapon, 2 - Ranged Weapon, 3 - Gear, 4 - Backpack
    itemType: u8,
    rarity: u8,
    width: usize,
    height: usize,
    price: usize,
    // 0 - None, 1 - Damage, 2 - Cleanse Poison, 3 - Armor, 4 - Regen, 5 - Reflect, 6 - Poison, 7 - Empower, 8 - Vampirism
    effectType: u8,
    effectStacks: u32,
    // 0 - Passive, 1 - On Start, 2 - On Hit, 3 - On Cooldown, 4 - On Attack
    effectActivationType: u8,
    // Accuracy to trigger
    chance: usize,
    // item reuse time
    cooldown: u8,
    energyCost: u8,
    isPlugin: bool,
}

#[derive(Drop, Serde)]
#[dojo::model]
struct ItemsCounter {
    #[key]
    id: felt252,
    count: usize,
}
