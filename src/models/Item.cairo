use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
struct Item {
    #[key]
    id: usize,
    name: felt252,
    // 1 - Melee Weapon, 2 - Ranged Weapon, 3 - Effect item, 4 - bag
    itemType: u8,
    // 0 - None, 1 - common, 2 - rare, 3 - legendary
    rarity: u8,
    width: usize,
    height: usize,
    price: usize,
    // 0 - None, 1 - Damage, 2 - Cleanse Poison, 3 - Armor, 4 - Regen, 5 - Reflect, 6 - Poison, 7 - Empower, 8 - Vampirism, 9 - Expand pack
    effectType: u8,
    effectStacks: u32,
    // 0 - In armory, 1 - On Start, 2 - On Hit, 3 - On Cooldown, 4 - On Attack
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
