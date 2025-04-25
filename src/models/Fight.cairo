use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::event(historical: true)]
pub struct BattleLogDetail {
    #[key]
    pub player: ContractAddress,
    #[key]
    pub battleLogId: u32,
    #[key]
    pub id: u8,
    pub whoTriggered: felt252,
    pub whichItem: u32,
    pub isDodged: bool,
    // // 0 - None, 1 - Damage, 2 - Cleanse Poison, 3 - Armor, 4 - Regen, 5 - Reflect, 6 - Poison, 7 - Empower, 8 - Vampirism, 9 - Expand pack
    pub effectType: u8,
    pub effectStacks: u32,
    pub player_remaining_health: u32,
    pub dummy_remaining_health: u32,
    pub player_stamina: u8,
    pub dummy_stamina: u8,
    // armor, regen, reflect, empower, poison, vampirism
    pub player_stacks: (u32, u32, u32, u32, u32, u32),
    pub dummy_stacks: (u32, u32, u32, u32, u32, u32),
}

#[derive(Copy, Drop, Serde)]
pub struct CharStatus {
    pub hp: u32,
    pub stamina: u8,
    pub armor: u32,
    pub regen: u32,
    pub reflect: u32,
    pub empower: u32,
    pub poison: u32,
    pub vampirism: u32,
}

#[derive(Drop, Serde)]
pub struct AttackStatus {
    pub player: ContractAddress,
    pub curr_item_belongs: felt252,
    pub curr_item_index: u32,
    pub item_type: u8,
    pub effect_type: u8,
    pub effect_stacks: u32,
    pub opponent: felt252,
    pub battleLogCounterCount: u32,
    pub rand: u32,
    pub char_health_flag: u32,
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct BattleLog {
    #[key]
    pub player: ContractAddress,
    #[key]
    pub id: u32,
    pub dummyLevel: u32,
    pub dummyCharId: u32,
    // Player/Dummy, itemId, itemType, effectType, chance, effectStacks, cooldown, energyCost, plugins
    pub sorted_items: Span<(felt252, u32, u8, u8, u32, u32, u8, u8, Span<(u8, u32, u32)>)>,
    pub items_length: u32,
    // armor, regen, reflect, empower, poison, vampirism
    pub player_buffs: Span<u32>,
    pub dummy_buffs: Span<u32>,
    pub player_on_hit_items: Span<(u8, u32, u32)>,
    pub dummy_on_hit_items: Span<(u8, u32, u32)>,
    // effectType, chance, effectStacks
    pub player_on_attack_items: Span<(u8, u32, u32)>,
    pub dummy_on_attack_items: Span<(u8, u32, u32)>,
    // dummy or player
    pub winner: felt252,
    pub seconds: u8
}


#[derive(Drop, Serde)]
#[dojo::model]
pub struct BattleLogCounter {
    #[key]
    pub player: ContractAddress,
    pub count: u32,
}
