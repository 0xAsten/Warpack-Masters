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

            assert!(x <= GRID_X, "x out of range");
            assert!(y <= GRID_Y, "y out of range");
            assert!(
                rotation == 0 || rotation == 90 || rotation == 180 || rotation == 270,
                "invalid rotation"
            );

            let item = get!(world, item_id, (Item));

            let item_h = item.height;
            let item_w = item.width;

            let mut i = 0;
            let mut j = 0;

            let mut player_backpack_grids = get!(world, (player, x, y), (BackpackGrids));

            assert!(player_backpack_grids.occupied, "Already occupied");

            if rotation == 0 {
                loop {
                    i += 1;

                    if i >= item_h {
                        break;
                    }

                    let mut player_backpack_grids = get!(
                        world, (player, x, y + i), (BackpackGrids)
                    );

                    assert!(!player_backpack_grids.occupied, "Grid Occupied at ({}, {})", x, y + i);

                    set!(world, (BackpackGrids { x: x, y: y + i, occupied: true }))
                };

                loop {
                    j += 1;

                    if j >= item_w {
                        break;
                    }

                    let mut player_backpack_grids = get!(
                        world, (player, x + j, y), (BackpackGrids)
                    );

                    assert!(!player_backpack_grids.occupied, "Grid Occupied at ({}, {})", x + j);

                    set!(world, (BackpackGrids { x: x, y: y + i, occupied: true }))
                };
            }

            if rotation == 180 {
                loop {
                    i += 1;

                    if i >= item_h {
                        break;
                    }

                    let mut player_backpack_grids = get!(
                        world, (player, x, y - i), (BackpackGrids)
                    );

                    assert!(!player_backpack_grids.occupied, "Grid Occupied at ({}, {})", x, y - i);

                    set!(world, (BackpackGrids { x: x, y: y - i, occupied: true }))
                };

                loop {
                    j += 1;

                    if j >= item_w {
                        break;
                    }

                    let mut player_backpack_grids = get!(
                        world, (player, x - j, y), (BackpackGrids)
                    );

                    assert!(!player_backpack_grids.occupied, "Grid Occupied at ({}, {})", x - j, y);

                    set!(world, (BackpackGrids { x: x - j, y: y, occupied: true }))
                };
            }

            if rotation == 90 {
                loop {
                    i += 1;

                    if i >= item_h {
                        break;
                    }

                    let mut player_backpack_grids = get!(
                        world, (player, x + i, y), (BackpackGrids)
                    );

                    assert!(!player_backpack_grids.occupied, "Grid Occupied at ({}, {})", x + i, y);

                    set!(world, (BackpackGrids { x: x + i, y: y, occupied: true }))
                };

                loop {
                    j += 1;

                    if j >= item_w {
                        break;
                    }

                    let mut player_backpack_grids = get!(
                        world, (player, x, y + j), (BackpackGrids)
                    );

                    assert!(!player_backpack_grids.occupied, "Grid Occupied at ({}, {})", x, y + j);

                    set!(world, (BackpackGrids { x: x, y: y + j, occupied: true }))
                };
            }

            if rotation == 270 {
                loop {
                    i += 1;

                    if i >= item_h {
                        break;
                    }

                    let mut player_backpack_grids = get!(
                        world, (player, x - i, y), (BackpackGrids)
                    );

                    assert!(!player_backpack_grids.occupied, "Grid Occupied at ({}, {})", x - 1, y);

                    set!(world, (BackpackGrids { x: x - i, y: y, occupied: true }))
                };

                loop {
                    j += 1;

                    if j >= item_w {
                        break;
                    }

                    let mut player_backpack_grids = get!(
                        world, (player, x, y - j), (BackpackGrids)
                    );

                    assert!(!player_backpack_grids.occupied, "Grid Occupied at ({}, {})", x, y - j);

                    set!(world, (BackpackGrids { x: x, y: y - j, occupied: true }))
                };
            }

            let mut char_items_count = get!(world, player, (CharacterItemsCounter));
            char_items_count += 1;
            set!(world, player, (CharacterItemsCounter { player, count: char_items_count }));

            set!(
                world,
                (player, char_items_count),
                (CharacterItem {
                    player, id: char_items_count, itemId: item_id, where: 'inventory', rotation,
                })
            );
        }
    }
}
