pub mod constants {
    pub const GRID_X: u32 = 9;
    pub const GRID_Y: u32 = 7;
    pub const INIT_GOLD: u32 = 8;
    pub const INIT_HEALTH: u32 = 25;
    pub const INIT_STAMINA: u8 = 100;

    pub const ITEMS_COUNTER_ID: felt252 = 'ITEMS_COUNTER_ID';
    pub const STORAGE_FLAG: u32 = 999;

    // const EFFECT_ARMOR: felt252 = 'armor';
    // const EFFECT_REGEN: felt252 = 'regen';
    // const EFFECT_REFLECT: felt252 = 'reflect';
    // const EFFECT_EMPOWER: felt252 = 'empower';
    // const EFFECT_POISON: felt252 = 'poison';
    // const EFFECT_CLEANSE_POISON: felt252 = 'cleanse_poison';
    // const EFFECT_VAMPIRISM: felt252 = 'vampirism';

    pub const EFFECT_DAMAGE: u8 = 1;
    pub const EFFECT_CLEANSE_POISON: u8 = 2;
    pub const EFFECT_REGEN: u8 = 4;
    pub const EFFECT_REFLECT: u8 = 5;
    pub const EFFECT_POISON: u8 = 6;
    pub const EFFECT_VAMPIRISM: u8 = 8;

    pub const REBIRTH_FEE: u256 = 10000000000000000000;

    pub const GAME_CONFIG_ID: felt252 = 'GAME_CONFIG_ID';
}
