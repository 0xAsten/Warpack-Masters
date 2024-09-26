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
    item_ids: Span<u32>,
    belongs_tos: Span<felt252>,
    items_length: usize,
    char_buffs: Span<u32>,
    dummy_buffs: Span<u32>,
    char_on_hit_items: Span<(felt252, usize, usize)>,
    dummy_on_hit_items: Span<(felt252, usize, usize)>,
    char_on_attack_items: Span<(felt252, usize, usize)>,
    dummy_on_attack_items: Span<(felt252, usize, usize)>,
    nearby_item_effects: Span<(usize, usize)>,
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
