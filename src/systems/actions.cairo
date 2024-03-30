use starknet::ContractAddress;

#[starknet::interface]
trait IActions<TContractState> {
    fn spawn(ref self: TContractState);
    fn place_item(ref self: TContractState, item_id: u32, x: usize, y: usize, rotation: usize);
    fn add_item(
        ref self: TContractState,
        name: felt252,
        width: usize,
        height: usize,
        price: usize,
        damage: usize,
        armor: usize,
        chance: usize,
        cooldown: usize,
        heal: usize
    );
    fn is_world_owner(ref self: TContractState, caller: ContractAddress) -> bool;
}


#[dojo::contract]
mod actions {
    use super::IActions;

    use starknet::{ContractAddress, get_caller_address};
    use warpack_masters::models::{backpack::{Backpack, BackpackGrids, Grid, GridTrait}};
    use warpack_masters::models::{
        CharacterItem::{CharacterItem, CharacterItemsCounter, Position}, Item::{Item, ItemsCounter}
    };

    const GRID_X: usize = 9;
    const GRID_Y: usize = 7;

    const ITEMS_COUNTER_ID: felt252 = 'ITEMS_COUNTER_ID';

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
        fn spawn(ref self: ContractState) {
            let world = self.world_dispatcher.read();

            let player = get_caller_address();

            let player_exists = get!(world, player, (Backpack));
            assert(player_exists.grid.is_zero(), 'Player already exists');

            set!(world, (Backpack { player, grid: Grid { x: GRID_X, y: GRID_Y } },));

            emit!(world, Spawned { player: player });
        }

        fn add_item(
            ref self: ContractState,
            name: felt252,
            width: usize,
            height: usize,
            price: usize,
            damage: usize,
            armor: usize,
            chance: usize,
            cooldown: usize,
            heal: usize
        ) {
            let caller = get_caller_address();

            assert(self.is_world_owner(caller), 'caller not world owner');

            assert(width > 0 && width <= GRID_X, 'width not in range');
            assert(height > 0 && height <= GRID_Y, 'height not in range');

            let world = self.world_dispatcher.read();

            let mut counter = get!(world, ITEMS_COUNTER_ID, ItemsCounter);
            counter.count += 1;

            let item = Item {
                id: counter.count,
                name,
                width,
                height,
                price,
                damage,
                armor,
                chance,
                cooldown,
                heal,
            };

            set!(world, (counter, item));
        }

        fn place_item(ref self: ContractState, item_id: u32, x: usize, y: usize, rotation: usize) {
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

                assert(x_max < GRID_X, 'item out of bound for x');
                assert(y_max < GRID_Y, 'item out of bound for y');

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

                        let mut player_backpack_grid_data = get!(
                            world, (player, i, j), (BackpackGrids)
                        );
                        assert(!player_backpack_grid_data.occupied, 'Already occupied');

                        set!(world, (BackpackGrids { player: player, x: i, y: j, occupied: true }));
                        j += 1;
                    };
                    j = y;
                    i += 1;
                }
            }

            let mut char_items = get!(world, player, (CharacterItemsCounter));
            char_items.count += 1;
            set!(
                world,
                (CharacterItem {
                    player,
                    id: char_items.count,
                    itemId: item_id,
                    where: 'inventory',
                    position: Position { x, y },
                    rotation,
                })
            );
            set!(world, (char_items,));
        }

        fn is_world_owner(ref self: ContractState, caller: ContractAddress) -> bool {
            let world = self.world_dispatcher.read();

            // resource id of world is 0
            let is_owner = world.is_owner(caller, 0);

            is_owner
        }
    }
}
