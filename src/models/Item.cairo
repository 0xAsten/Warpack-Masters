#[derive(Drop, Serde)]
#[dojo::model]
pub struct Item {
    #[key]
    pub id: u32,
    pub name: ByteArray,
    // 1 - Melee Weapon, 2 - Ranged Weapon, 3 - Effect item, 4 - bag
    pub itemType: u8,
    // 0 - None, 1 - common, 2 - rare, 3 - legendary
    pub rarity: u8,
    pub width: u32,
    pub height: u32,
    pub price: u32,
    // 0 - None, 1 - Damage, 2 - Cleanse Poison, 3 - Armor, 4 - Regen, 5 - Reflect, 6 - Poison, 7 - Empower, 8 - Vampirism, 9 - Expand pack
    pub effectType: u8,
    pub effectStacks: u32,
    // 0 - In armory, 1 - On Start, 2 - On Hit, 3 - On Cooldown, 4 - On Attack
    pub effectActivationType: u8,
    // Accuracy to trigger
    pub chance: u32,
    // item reuse time
    pub cooldown: u8,
    pub energyCost: u8,
    pub isPlugin: bool,
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct ItemsCounter {
    #[key]
    pub id: felt252,
    pub count: u32,
}
