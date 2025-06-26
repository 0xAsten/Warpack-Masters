use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
pub struct Shop {
    #[key]
    pub player: ContractAddress,
    pub item1: u32,
    pub item2: u32,
    pub item3: u32,
    pub item4: u32,
    pub free_rerolls: u32,
    pub rerolls_since_fight: u32,
}
