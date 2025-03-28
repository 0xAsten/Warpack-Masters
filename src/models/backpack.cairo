use starknet::ContractAddress;


#[derive(Drop, Serde)]
#[dojo::model]
struct BackpackGrids {
    #[key]
    player: ContractAddress,
    #[key]
    x: u32,
    #[key]
    y: u32,
    enabled: bool,
    occupied: bool,
    inventoryItemId: u32,
    itemId: u32,
    isWeapon: bool,
    isPlugin: bool,
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
