use starknet::ContractAddress;


#[derive(Drop, Serde)]
#[dojo::model]
pub struct BackpackGrids {
    #[key]
    pub player: ContractAddress,
    #[key]
    pub x: u32,
    #[key]
    pub y: u32,
    pub enabled: bool,
    pub occupied: bool,
    pub inventoryItemId: u32,
    pub itemId: u32,
    pub isWeapon: bool,
    pub isPlugin: bool,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct BridgeDeposit {
    #[key]
    pub player: ContractAddress,
    #[key]
    pub item_id: u32,
    pub quantity: u32,
    pub token_amount: u256,
    pub token_address: ContractAddress,
    pub timestamp: u64,
}

#[cfg(test)]
mod tests {
    use super::{BackpackGrids};

    #[test]
    #[available_gas(100000)]
    fn test_grids_occupy() {
        let player = starknet::contract_address_const::<0x0>();
        let backpack_grids = BackpackGrids {
            player: player, x: 0, y: 0, enabled: true, occupied: true, inventoryItemId: 0, itemId: 0, isWeapon: false, isPlugin: false,
        };
        assert(backpack_grids.occupied, 'not occupy');
    }

    #[test]
    #[available_gas(100000)]
    fn test_grids_not_occupy() {
        let player = starknet::contract_address_const::<0x0>();
        let backpack_grids = BackpackGrids {
            player: player, x: 0, y: 0, enabled: true, occupied: false, inventoryItemId: 0, itemId: 0, isWeapon: false, isPlugin: false,
        };
        assert(!backpack_grids.occupied, 'occupy');
    }
}
