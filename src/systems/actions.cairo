#[starknet::interface]
trait IActions<TContractState> {
    fn spawn(self: @TContractState);
    fn place_item(self: @TContractState, item_id: u32, x: usize, y: usize, rotation: usize);
}


#[dojo::contract]
mod actions {
    use super::IActions;

    use starknet::{ContractAddress, get_caller_address};
    use dojo_starter::models::{backpack::{Backpack, BackpackGrids, Grid, GridTrait}};
    use dojo_starter::models::{CharacterItem::{CharacterItem, CharacterItemsCounter}};

    const GRID_X: usize = 9;
    const GRID_Y: usize = 7;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Spawned: Spawned,
    }

    // declaring custom event struct
    #[derive(Drop, starknet::Event)]
    struct Spawned {
        player: ContractAddress,
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn spawn(self: @ContractState) {
            let world = self.world_dispatcher.read();

            let player = get_caller_address();

            let player_exists = get!(world, player, (Backpack));
            assert(player_exists.grid.is_zero(), 'Player already exists');

            set!(world, (Backpack { player, grid: Grid { x: GRID_X, y: GRID_Y } },));

            emit!(world, Spawned { player: player });
        }

        fn place_item(self: @TContractState, item_id: u32, x: usize, y: usize, rotation: usize) {
            let world = self.world_dispatcher.read();

            let player = get_caller_address();

            assert(x <= GRID_X, 'x out of range');
            assert(y <= GRID_Y, 'y out of range');
            assert(
                rotation == 0 || rotation == 90 || rotation == 180 || rotation == 270,
                'invalid rotation'
            );

            let item = get!(world, item_id, (Item));

            let item_h = item.height;
            let item_w = item.width;

            assert(x + item_w <= GRID_X, 'item out of bound for x');
            assert(y + item_h <= GRID_Y, 'item out of bound for y');

            let mut player_backpack_grids = get!(world, (player, x, y), (BackpackGrids));

            assert(!player_backpack_grids.occupied, 'Already occupied');

            // if the item is 1x1, occupy the empty grid
            if item_h == 1 && item_w == 1 {
                set!(world, (BackpackGrids { player: player, x: x, y: y, occupied: true }));
            } else {
                let mut x_max = 0;
                let mut y_max = 0;

                // only check grids which are above the starting (x,y)
                if rotation == 0 || rotation == 180 {
                    x_max = x + item_w - 1;
                    y_max = y + item_h - 1;
                }

                // only check grids which are to the right of the starting (x,y)
                if rotation == 90 || rotation == 270 {
                    //item_h becomes item_w and vice versa
                    x_max = x + item_h - 1;
                    y_max = y + item_w - 1;
                }

                let mut i = x;
                let mut j = y;
                loop {
                    if i > x_max {
                        break;
                    }
                    loop {
                        if j > y_max {
                            break;
                        }
                        set!(world, (BackpackGrids { player: player, x: i, y: j, occupied: true }));
                        j += 1;
                    };
                    i += 1;
                }
            }

            let mut char_items = get!(world, player, (CharacterItemsCounter));
            char_items.count += 1;
            set!(world, (CharacterItemsCounter { player, count: char_items.count }));

            set!(
                world,
                (CharacterItem {
                    player,
                    id: char_items.count,
                    itemId: item_id,
                    where: 'inventory',
                    position: (x, y),
                    rotation,
                })
            );
        }
    }
}
