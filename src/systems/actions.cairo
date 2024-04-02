use warpack_masters::models::Character::Class;

use starknet::ContractAddress;

#[starknet::interface]
trait IActions<TContractState> {
    fn spawn(ref self: TContractState, name: felt252, class: Class);
    fn place_item(
        ref self: TContractState, char_item_counter_id: u32, x: usize, y: usize, rotation: usize
    );
    fn undo_place_item(ref self: TContractState, char_item_counter_id: u32);
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
        heal: usize,
        rarity: usize,
    );
    fn edit_item(ref self: TContractState, item_id: u32, item_key: felt252, item_value: felt252);
    fn buy_item(ref self: TContractState, item_id: u32);
    fn sell_item(ref self: TContractState, char_item_counter_id: u32);
    fn is_world_owner(self: @TContractState, caller: ContractAddress) -> bool;
    fn is_item_owned(self: @TContractState, caller: ContractAddress, id: usize) -> bool;
}


#[dojo::contract]
mod actions {
    use super::IActions;

    use starknet::{ContractAddress, get_caller_address};
    use warpack_masters::models::{backpack::{Backpack, BackpackGrids, Grid, GridTrait}};
    use warpack_masters::models::{
        CharacterItem::{CharacterItem, CharacterItemsCounter, Position}, Item::{Item, ItemsCounter}
    };
    use warpack_masters::models::Character::{Character, Class};

    const GRID_X: usize = 9;
    const GRID_Y: usize = 7;
    const INIT_GOLD: usize = 4;
    const INIT_HEALTH: usize = 25;

    const ITEMS_COUNTER_ID: felt252 = 'ITEMS_COUNTER_ID';

    const STORAGE_FLAG: usize = 999;

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
        fn spawn(ref self: ContractState, name: felt252, class: Class) {
            let world = self.world_dispatcher.read();

            let player = get_caller_address();

            let player_exists = get!(world, player, (Backpack));
            assert(player_exists.grid.is_zero(), 'Player already exists');

            set!(world, (Backpack { player, grid: Grid { x: GRID_X, y: GRID_Y } },));
            set!(world, (Character { player, name, class, gold: INIT_GOLD, health: INIT_HEALTH }));

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
            heal: usize,
            rarity: usize,
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
                rarity
            };

            set!(world, (counter, item));
        }

        fn edit_item(
            ref self: ContractState, item_id: u32, item_key: felt252, item_value: felt252
        ) {
            let caller = get_caller_address();

            assert(self.is_world_owner(caller), 'caller not world owner');

            let world = self.world_dispatcher.read();

            let mut item_data = get!(world, item_id, (Item));

            match item_key {
                // name
                0 => {
                    item_data.name = item_value;
                    set!(world, (item_data,));
                },
                // width
                1 => {
                    let new_width: usize = item_value.try_into().unwrap();
                    assert(new_width > 0 && new_width <= GRID_X, 'new_width not in range');

                    item_data.width = new_width;
                    set!(world, (item_data,));
                },
                // height
                2 => {
                    let new_height: usize = item_value.try_into().unwrap();
                    assert(new_height > 0 && new_height <= GRID_X, 'new_height not in range');

                    item_data.height = new_height;
                    set!(world, (item_data,));
                },
                // price
                3 => {
                    let new_price: usize = item_value.try_into().unwrap();

                    item_data.price = new_price;
                    set!(world, (item_data,));
                },
                // damage
                4 => {
                    let new_damage: usize = item_value.try_into().unwrap();

                    item_data.damage = new_damage;
                    set!(world, (item_data,));
                },
                // armor
                5 => {
                    let new_armor: usize = item_value.try_into().unwrap();

                    item_data.armor = new_armor;
                    set!(world, (item_data,));
                },
                // chance
                6 => {
                    let new_chance: usize = item_value.try_into().unwrap();

                    item_data.chance = new_chance;
                    set!(world, (item_data,));
                },
                // cooldown
                7 => {
                    let new_cooldown: usize = item_value.try_into().unwrap();

                    item_data.cooldown = new_cooldown;
                    set!(world, (item_data,));
                },
                // heal
                8 => {
                    let new_heal: usize = item_value.try_into().unwrap();

                    item_data.heal = new_heal;
                    set!(world, (item_data,));
                },
                // rarity
                9 => {
                    let new_rarity: usize = item_value.try_into().unwrap();

                    item_data.rarity = new_rarity;
                    set!(world, (item_data,));
                },
                _ => { panic!("Invalid item_key: {}", item_key); }
            }
        }


        fn place_item(
            ref self: ContractState, char_item_counter_id: u32, x: usize, y: usize, rotation: usize
        ) {
            let world = self.world_dispatcher.read();

            let player = get_caller_address();

            assert(x <= GRID_X, 'x out of range');
            assert(y <= GRID_Y, 'y out of range');
            assert(
                rotation == 0 || rotation == 90 || rotation == 180 || rotation == 270,
                'invalid rotation'
            );

            assert(self.is_item_owned(player, char_item_counter_id), '');

            let char_item_data = get!(world, (player, char_item_counter_id), (CharacterItem));
            let item_id = char_item_data.itemId;
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


        fn undo_place_item(ref self: ContractState, char_item_counter_id: u32) {
            let world = self.world_dispatcher.read();

            let player = get_caller_address();

            let mut char_item_data = get!(world, (player, char_item_counter_id), (CharacterItem));
            let item_id = char_item_data.itemId;
            let item = get!(world, item_id, (Item));

            assert(char_item_data.where == 'inventory', 'item not in inventory');

            let x = char_item_data.position.x;
            let y = char_item_data.position.y;
            let rotation = char_item_data.rotation;
            let item_h = item.height;
            let item_w = item.width;

            char_item_data.where = 'storage';
            char_item_data.position.x = STORAGE_FLAG;
            char_item_data.position.y = STORAGE_FLAG;
            char_item_data.rotation = 0;

            if item_h == 1 && item_w == 1 {
                set!(world, (BackpackGrids { player: player, x: x, y: y, occupied: false }));
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

                        set!(
                            world, (BackpackGrids { player: player, x: i, y: j, occupied: false })
                        );
                        j += 1;
                    };
                    j = y;
                    i += 1;
                }
            }

            set!(world, (char_item_data));
        }


        fn buy_item(ref self: ContractState, item_id: u32) {
            let world = self.world_dispatcher.read();

            let player = get_caller_address();
            let item = get!(world, item_id, (Item));
            let mut player_char = get!(world, player, (Character));

            assert(player_char.gold >= item.price, 'Not enough gold');
            player_char.gold -= item.price;

            let mut char_items_counter = get!(world, player, (CharacterItemsCounter));
            char_items_counter.count += 1;

            let char_item = CharacterItem {
                player,
                id: char_items_counter.count,
                itemId: item_id,
                where: 'storage',
                position: Position { x: STORAGE_FLAG, y: STORAGE_FLAG },
                rotation: 0,
            };

            set!(world, (player_char, char_items_counter, char_item));
        }


        fn sell_item(ref self: ContractState, char_item_counter_id: u32) {
            let world = self.world_dispatcher.read();

            let player = get_caller_address();

            let mut char_item_data = get!(world, (player, char_item_counter_id), (CharacterItem));
            let item_id = char_item_data.itemId;
            let mut item = get!(world, item_id, (Item));
            let mut player_char = get!(world, player, (Character));

            assert(char_item_data.where != '', 'item not owned');

            let item_price = item.price;
            let sell_price = item_price / 2;

            char_item_data.itemId = 0;
            char_item_data.where = '';
            char_item_data.position.x = STORAGE_FLAG;
            char_item_data.position.y = STORAGE_FLAG;
            char_item_data.rotation = 0;

            player_char.gold += sell_price;

            set!(world, (char_item_data, player_char));
        }


        fn is_world_owner(self: @ContractState, caller: ContractAddress) -> bool {
            let world = self.world_dispatcher.read();

            // resource id of world is 0
            let is_owner = world.is_owner(caller, 0);

            is_owner
        }

        fn is_item_owned(self: @ContractState, caller: ContractAddress, id: usize) -> bool {
            let world = self.world_dispatcher.read();

            let char_item_data = get!(world, (caller, id), (CharacterItem));

            // item is not in inventory or storage
            assert(char_item_data.where != '', 'item not owned by the player');

            // if the item is in inventory, it is already placed
            assert(char_item_data.where != 'inventory', 'item already placed');

            if char_item_data.where == 'storage' {
                return true;
            }

            false
        }
    }
}
