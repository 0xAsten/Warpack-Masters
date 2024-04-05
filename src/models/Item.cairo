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
    // Weapon, Buff, Debuff
    item_type: felt252,
    // Health, Damage, Chance
    stat_affected: felt252,
    // For buffs and debuffs
    percentage: usize,
    // start_of_round, end_of_round, on_hit, on_attack, none
    trigger_type: felt252
}

#[derive(Model, Drop, Serde)]
struct ItemsCounter {
    #[key]
    id: felt252,
    count: usize,
}
