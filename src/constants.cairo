mod constants {
    const GRID_X: usize = 9;
    const GRID_Y: usize = 7;
    const INIT_GOLD: usize = 8;
    const INIT_HEALTH: usize = 25;
    const INIT_STAMINA: u8 = 100;

    const ITEMS_COUNTER_ID: felt252 = 'ITEMS_COUNTER_ID';
    const STORAGE_FLAG: usize = 999;

    const EFFECT_ARMOR: felt252 = 'armor';
    const EFFECT_REGEN: felt252 = 'regen';
    const EFFECT_REFLECT: felt252 = 'reflect';
    const EFFECT_EMPOWER: felt252 = 'empower';
    const EFFECT_POISON: felt252 = 'poison';
    const EFFECT_CLEANSE_POISON: felt252 = 'cleanse_poison';
    const EFFECT_VAMPIRISM: felt252 = 'vampirism';
}
