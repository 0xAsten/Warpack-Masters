use starknet::ContractAddress;

#[derive(Model, Drop, Serde)]
struct Backpack {
    #[key]
    player: ContractAddress,
    grid: Grid,
}

#[derive(Copy, Drop, Serde, Introspect)]
struct Grid {
    x: usize,
    y: usize
}

trait GridTrait {
    fn is_zero(self: Grid) -> bool;
}

impl GridImpl of GridTrait {
    fn is_zero(self: Grid) -> bool {
        if self.x == 0 || self.y == 0 {
            return true;
        }
        false
    }
}

#[derive(Model, Drop, Serde)]
struct BackpackGrids {
    #[key]
    player: ContractAddress,
    #[key]
    x: usize,
    #[key]
    y: usize,
    occupied: bool,
}

#[cfg(test)]
mod tests {
    use super::{Backpack, Grid, GridTrait, BackpackGrids};

    #[test]
    #[available_gas(100000)]
    fn test_grid_is_zero() {
        let grid = Grid { x: 0, y: 10 };
        assert(grid.is_zero(), 'not zero');
    }

    #[test]
    #[available_gas(100000)]
    fn test_grids_occupy() {
        let player = starknet::contract_address_const::<0x0>();
        let backpack_grids = BackpackGrids { player: player, x: 0, y: 0, occupied: true, };
        assert(backpack_grids.occupied, 'not occupy');
    }

    #[test]
    #[available_gas(100000)]
    fn test_grids_not_occupy() {
        let player = starknet::contract_address_const::<0x0>();
        let backpack_grids = BackpackGrids { player: player, x: 0, y: 0, occupied: false, };
        assert(!backpack_grids.occupied, 'occupy');
    }
}
