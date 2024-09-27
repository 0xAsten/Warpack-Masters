use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
#[dojo::event]
struct BattleLogDetail {
    #[key]
    player: ContractAddress,
    #[key]
    battleLogId: usize,
    #[key]
    id: usize,
    whoTriggered: felt252,
    whichItem: usize,
    isDodged: bool,
    // // 0 - None, 1 - Damage, 2 - Cleanse Poison, 3 - Armor, 4 - Regen, 5 - Reflect, 6 - Poison, 7 - Empower, 8 - Vampirism, 9 - Expand pack
    effectType: u8,
    effectStacks: u32,
    player_remaining_health: usize,
    dummy_remaining_health: usize,
    player_stamina: u8,
    dummy_stamina: u8,
    // armor, regen, reflect, empower, poison, vampirism
    player_stacks: (u32, u32, u32, u32, u32, u32),
    dummy_stacks: (u32, u32, u32, u32, u32, u32),
}

#[derive(Drop, Serde)]
struct CharStatus {
    hp: u32,
    stamina: u8,
    armor: u32,
    regen: u32,
    reflect: u32,
    empower: u32,
    poison: u32,
    vampirism: u32,
}

#[derive(Drop, Serde)]
#[dojo::model]
struct BattleLog {
    #[key]
    player: ContractAddress,
    #[key]
    id: usize,
    dummyLevel: usize,
    dummyCharId: usize,
    // Player/Dummy, itemId, itemType, effectType, chance, effectStacks, cooldown, energyCost, plugins
    sorted_items: Span<(felt252, u32, u8, u8, u32, u32, u8, u8, Span<(u8, usize, usize)>)>,
    items_length: usize,
    // armor, regen, reflect, empower, poison, vampirism
    char_buffs: Span<u32>,
    dummy_buffs: Span<u32>,
    char_on_hit_items: Span<(u8, usize, usize)>,
    dummy_on_hit_items: Span<(u8, usize, usize)>,
    // effectType, chance, effectStacks
    char_on_attack_items: Span<(u8, usize, usize)>,
    dummy_on_attack_items: Span<(u8, usize, usize)>,
    // dummy or player
    winner: felt252,
    seconds: u8
}


#[derive(Drop, Serde)]
#[dojo::model]
struct BattleLogCounter {
    #[key]
    player: ContractAddress,
    count: usize,
}
