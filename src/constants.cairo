mod constants {
    const GRID_X: u32 = 9;
    const GRID_Y: u32 = 7;
    const INIT_GOLD: u32 = 8;
    const INIT_HEALTH: u32 = 25;
    const INIT_STAMINA: u8 = 100;

    const ITEMS_COUNTER_ID: felt252 = 'ITEMS_COUNTER_ID';
    const STORAGE_FLAG: u32 = 999;

    // const EFFECT_ARMOR: felt252 = 'armor';
    // const EFFECT_REGEN: felt252 = 'regen';
    // const EFFECT_REFLECT: felt252 = 'reflect';
    // const EFFECT_EMPOWER: felt252 = 'empower';
    // const EFFECT_POISON: felt252 = 'poison';
    // const EFFECT_CLEANSE_POISON: felt252 = 'cleanse_poison';
    // const EFFECT_VAMPIRISM: felt252 = 'vampirism';

    const EFFECT_DAMAGE: u8 = 1;
    const EFFECT_CLEANSE_POISON: u8 = 2;
    const EFFECT_REGEN: u8 = 4;
    const EFFECT_REFLECT: u8 = 5;
    const EFFECT_POISON: u8 = 6;
    const EFFECT_VAMPIRISM: u8 = 8;
}
