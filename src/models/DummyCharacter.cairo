use starknet::ContractAddress;

use warpack_masters::models::Character::WMClass;

#[derive(Drop, Serde)]
#[dojo::model]
pub struct DummyCharacter {
    #[key]
    pub level: u32,
    #[key]
    pub id: u32,
    pub name: felt252,
    pub wmClass: WMClass,
    pub health: u32,
    pub player: ContractAddress,
    pub rating: u32,
    pub stamina: u8,
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct DummyCharacterCounter {
    #[key]
    pub level: u32,
    pub count: u32,
}
