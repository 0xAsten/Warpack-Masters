use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct TokenRegistry {
    #[key]
    pub item_id: u32,
    pub token_address: ContractAddress,
    pub token_name: felt252,
    pub token_symbol: felt252,
    pub is_active: bool,
    pub total_supply: u256,
    pub created_at: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct TokenRegistryCounter {
    #[key]
    pub id: felt252,
    pub count: u32,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct BridgeDeposit {
    #[key]
    pub player: ContractAddress,
    #[key]
    pub deposit_id: u32,
    pub item_id: u32,
    pub storage_slot_id: u32,
    pub token_amount: u256,
    pub deposited_at: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct BridgeDepositCounter {
    #[key]
    pub player: ContractAddress,
    pub count: u32,
} 