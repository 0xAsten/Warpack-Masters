use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
struct BattleLog {
    #[key]
    player: ContractAddress,
    #[key]
    id: usize,
    dummyLevel: usize,
    dummyCharId: usize,
    // Player/Dummy, itemId, effectType, chance, effectStacks, energyCost, plugins
    sorted_items: Span<(felt252, u32, u8, u32, u32, u8, Span<(u8, usize, usize)>)>,
    items_length: usize,
    char_buffs: Span<u32>,
    dummy_buffs: Span<u32>,
    char_on_hit_items: Span<(u8, usize, usize)>,
    dummy_on_hit_items: Span<(u8, usize, usize)>,
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
