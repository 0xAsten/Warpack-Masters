use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::event(historical: true)]
struct BattleLogDetail {
    #[key]
    player: ContractAddress,
    #[key]
    battleLogId: u32,
    #[key]
    id: u8,
    whoTriggered: felt252,
    whichItem: u32,
    isDodged: bool,
    // // 0 - None, 1 - Damage, 2 - Cleanse Poison, 3 - Armor, 4 - Regen, 5 - Reflect, 6 - Poison, 7 - Empower, 8 - Vampirism, 9 - Expand pack
    effectType: u8,
    effectStacks: u32,
    player_remaining_health: u32,
    dummy_remaining_health: u32,
    player_stamina: u8,
    dummy_stamina: u8,
    // armor, regen, reflect, empower, poison, vampirism
    player_stacks: (u32, u32, u32, u32, u32, u32),
    dummy_stacks: (u32, u32, u32, u32, u32, u32),
}

#[derive(Copy, Drop, Serde)]
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
struct AttackStatus {
    player: ContractAddress,
    curr_item_belongs: felt252,
    curr_item_index: u32,
    item_type: u8,
    effect_type: u8,
    effect_stacks: u32,
    opponent: felt252,
    battleLogCounterCount: u32,
    rand: u32,
    char_health_flag: u32,
}

#[derive(Drop, Serde)]
#[dojo::model]
struct BattleLog {
    #[key]
    player: ContractAddress,
    #[key]
    id: u32,
    dummyLevel: u32,
    dummyCharId: u32,
    // Player/Dummy, itemId, itemType, effectType, chance, effectStacks, cooldown, energyCost, plugins
    sorted_items: Span<(felt252, u32, u8, u8, u32, u32, u8, u8, Span<(u8, u32, u32)>)>,
    items_length: u32,
    // armor, regen, reflect, empower, poison, vampirism
    player_buffs: Span<u32>,
    dummy_buffs: Span<u32>,
    player_on_hit_items: Span<(u8, u32, u32)>,
    dummy_on_hit_items: Span<(u8, u32, u32)>,
    // effectType, chance, effectStacks
    player_on_attack_items: Span<(u8, u32, u32)>,
    dummy_on_attack_items: Span<(u8, u32, u32)>,
    // dummy or player
    winner: felt252,
    seconds: u8
}


#[derive(Drop, Serde)]
#[dojo::model]
struct BattleLogCounter {
    #[key]
    player: ContractAddress,
    count: u32,
}
