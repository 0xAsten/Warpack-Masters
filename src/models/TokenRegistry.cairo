use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct TokenRegistry {
    #[key]
    pub item_id: u32,
    pub name: ByteArray,
    pub symbol: ByteArray,
    pub token_address: ContractAddress,
    pub is_active: bool,
} 