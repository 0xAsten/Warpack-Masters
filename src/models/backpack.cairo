use starknet::ContractAddress;

#[derive(Model, Drop, Serde)]
struct Backpack {
    #[key]
    player: ContractAddress,
    grid: Grid,
}

#[derive(Copy, Drop, Serde, Introspect)]
struct Grid {
    x: u32,
    y: u32
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

#[cfg(test)]
mod tests {
    use super::{Backpack, Grid, GridTrait};

    #[test]
    #[available_gas(100000)]
    fn test_grid_is_zero() {
        let grid = Grid { x: 0, y: 10 };
        assert(grid.is_zero(), 'not zero');
    }
}
