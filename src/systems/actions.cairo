use starknet::ContractAddress;
use warpack_masters::models::Character::WMClass;

#[dojo::interface]
trait IActions {
    fn spawn(
        ref world: IWorldDispatcher,
        name: felt252,
        wmClass: WMClass,
    );
    fn rebirth(
        ref world: IWorldDispatcher,
        name: felt252,
        wmClass: WMClass,
    );
    fn place_item(
        ref world: IWorldDispatcher, storage_item_id: u32, x: usize, y: usize, rotation: usize
    );
    fn undo_place_item(ref world: IWorldDispatcher, inventory_item_id: u32);
}

// TODO: rename the count filed in counter model

#[dojo::contract]
mod actions {
    use super::{IActions, ContractAddress, WMClass};

    use starknet::{get_caller_address, get_block_timestamp};
    use warpack_masters::models::{backpack::{BackpackGrids}};
    use warpack_masters::models::{
        CharacterItem::{
            Position, CharacterItemsStorageCounter, CharacterItemStorage, CharacterItemInventory,
            CharacterItemsInventoryCounter
        },
        Item::Item,
        Character::{Character, NameRecord},
        Shop::Shop
    };

    use warpack_masters::items::{Backpack, Pack};
    use warpack_masters::constants::constants::{GRID_X, GRID_Y, INIT_GOLD, INIT_HEALTH};

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn spawn(
            ref world: IWorldDispatcher,
            name: felt252,
            wmClass: WMClass,
        ) {
            let player = get_caller_address();

            assert(name != '', 'name cannot be empty');

            let nameRecord = get!(world, name, NameRecord);
            assert(
                nameRecord.player == starknet::contract_address_const::<0>()
                    || nameRecord.player == player,
                'name already exists'
            );

            set!(world, (NameRecord { name, player }));

            let player_exists = get!(world, player, (Character));
            assert(player_exists.name == '', 'player already exists');

            // Default the player has 2 Backpacks
            // Must add two backpack items when setup the game
            let item = get!(world, Backpack::id, (Item));
            assert(item.itemType == 4, 'Invalid item type');
            let item = get!(world, Pack::id, (Item));
            assert(item.itemType == 4, 'Invalid item type');

            set!(
                world,
                (
                    CharacterItemStorage { player, id: 1, itemId: Backpack::id },
                    CharacterItemStorage { player, id: 2, itemId: Pack::id },
                    CharacterItemsStorageCounter { player, count: 2 },
                )
            );

            self.place_item(1, 4, 2, 0);
            self.place_item(2, 2, 2, 0);

            // keep the previous rating, totalWins and totalLoss during rebirth
            let prev_rating = player_exists.rating;
            let prev_total_wins = player_exists.totalWins;
            let prev_total_loss = player_exists.totalLoss;
            let prev_birth_count = player_exists.birthCount;
            let updatedAt = get_block_timestamp();

            // add one gold for reroll shop
            set!(
                world,
                (
                    Character {
                        player,
                        name,
                        wmClass,
                        gold: INIT_GOLD + 1,
                        health: INIT_HEALTH,
                        wins: 0,
                        loss: 0,
                        dummied: false,
                        rating: prev_rating,
                        totalWins: prev_total_wins,
                        totalLoss: prev_total_loss,
                        winStreak: 0,
                        birthCount: prev_birth_count + 1,
                        updatedAt,
                    }
                )
            );
        }


        fn rebirth(
            ref world: IWorldDispatcher,
            name: felt252,
            wmClass: WMClass,
        ) {
            let player = get_caller_address();

            let mut char = get!(world, player, (Character));

            assert(char.loss >= 5, 'loss not reached');

            // To allow others to use the player's privous name
            // if char.name != name {
            //     let mut nameRecord = get!(world, char.name, NameRecord);
            //     nameRecord.player = starknet::contract_address_const::<0>();
            //     set!(world, (nameRecord));
            // }

            // required to calling spawn doesn't fail
            char.name = '';

            let mut inventoryItemsCounter = get!(world, player, (CharacterItemsInventoryCounter));
            let mut count = inventoryItemsCounter.count;

            loop {
                if count == 0 {
                    break;
                }

                let mut inventoryItem = get!(world, (player, count), (CharacterItemInventory));

                inventoryItem.itemId = 0;
                inventoryItem.position.x = 0;
                inventoryItem.position.y = 0;
                inventoryItem.rotation = 0;

                set!(world, (inventoryItem));

                count -= 1;
            };

            let mut storageItemsCounter = get!(world, player, (CharacterItemsStorageCounter));
            let mut count = storageItemsCounter.count;

            loop {
                if count == 0 {
                    break;
                }

                let mut storageItem = get!(world, (player, count), (CharacterItemStorage));

                storageItem.itemId = 0;

                set!(world, (storageItem));

                count -= 1;
            };

            // clear BackpackGrids
            let mut i = 0;
            let mut j = 0;
            loop {
                if i >= GRID_X {
                    break;
                }
                loop {
                    if j >= GRID_Y {
                        break;
                    }

                    let player_backpack_grid_data = get!(world, (player, i, j), (BackpackGrids));

                    if player_backpack_grid_data.occupied || player_backpack_grid_data.enabled {
                        set!(
                            world,
                            (BackpackGrids {
                                player: player, x: i, y: j, enabled: false, occupied: false
                            })
                        );
                    }
                    j += 1;
                };
                j = 0;
                i += 1;
            };

            // clear shop
            let mut shop = get!(world, player, (Shop));
            shop.item1 = 0;
            shop.item2 = 0;
            shop.item3 = 0;
            shop.item4 = 0;

            inventoryItemsCounter.count = 0;
            storageItemsCounter.count = 0;
            set!(world, (char, shop, inventoryItemsCounter, storageItemsCounter));

            self.spawn(name, wmClass);
        }

        fn place_item(
            ref world: IWorldDispatcher, storage_item_id: u32, x: usize, y: usize, rotation: usize
        ) {
            let player = get_caller_address();

            assert(x < GRID_X, 'x out of range');
            assert(y < GRID_Y, 'y out of range');
            assert(
                rotation == 0 || rotation == 90 || rotation == 180 || rotation == 270,
                'invalid rotation'
            );

            let mut storageItem = get!(world, (player, storage_item_id), (CharacterItemStorage));

            assert(storageItem.itemId != 0, 'item not owned');

            let itemId = storageItem.itemId;
            let item = get!(world, itemId, (Item));

            let itemHeight = item.height;
            let itemWidth = item.width;

            let playerBackpackGrids = get!(world, (player, x, y), (BackpackGrids));

            // if the item is 1x1, occupy the empty grid
            if itemHeight == 1 && itemWidth == 1 {
                if item.itemType == 4 {
                    assert(!playerBackpackGrids.enabled, 'Already enabled');
                    set!(
                        world,
                        (BackpackGrids {
                            player: player, x: x, y: y, enabled: true, occupied: false
                        })
                    );
                } else {
                    assert(playerBackpackGrids.enabled, 'Grid not enabled');
                    assert(!playerBackpackGrids.occupied, 'Already occupied');
                    set!(
                        world,
                        (BackpackGrids {
                            player: player, x: x, y: y, enabled: true, occupied: true
                        })
                    );
                }
            } else {
                let mut xMax = 0;
                let mut yMax = 0;

                // only check grids which are above the starting (x,y)
                if rotation == 0 || rotation == 180 {
                    xMax = x + itemWidth - 1;
                    yMax = y + itemHeight - 1;
                }

                // only check grids which are to the right of the starting (x,y)
                if rotation == 90 || rotation == 270 {
                    //item_h becomes item_w and vice versa
                    xMax = x + itemHeight - 1;
                    yMax = y + itemWidth - 1;
                }

                assert(xMax < GRID_X, 'item out of bound for x');
                assert(yMax < GRID_Y, 'item out of bound for y');

                let mut i = x;
                let mut j = y;
                loop {
                    if i > xMax {
                        break;
                    }
                    loop {
                        if j > yMax {
                            break;
                        }

                        let playerBackpackGrids = get!(world, (player, i, j), (BackpackGrids));
                        if item.itemType == 4 {
                            assert(!playerBackpackGrids.enabled, 'Already enabled');
                            set!(
                                world,
                                (BackpackGrids {
                                    player: player, x: i, y: j, enabled: true, occupied: false
                                })
                            );
                        } else {
                            assert(playerBackpackGrids.enabled, 'Grid not enabled');
                            assert(!playerBackpackGrids.occupied, 'Already occupied');
                            set!(
                                world,
                                (BackpackGrids {
                                    player: player, x: i, y: j, enabled: true, occupied: true
                                })
                            );
                        }

                        j += 1;
                    };
                    j = y;
                    i += 1;
                }
            }

            let mut inventoryCounter = get!(world, player, (CharacterItemsInventoryCounter));
            let mut count = inventoryCounter.count;
            let mut isUpdated = false;
            loop {
                if count == 0 {
                    break;
                }

                let mut inventoryItem = get!(world, (player, count), (CharacterItemInventory));
                if inventoryItem.itemId == 0 {
                    inventoryItem.itemId = itemId;
                    inventoryItem.position = Position { x, y };
                    inventoryItem.rotation = rotation;
                    isUpdated = true;
                    set!(world, (inventoryItem));
                    break;
                }

                count -= 1;
            };

            if isUpdated == false {
                inventoryCounter.count += 1;
                set!(
                    world,
                    (
                        CharacterItemInventory {
                            player,
                            id: inventoryCounter.count,
                            itemId: itemId,
                            position: Position { x, y },
                            rotation,
                        },
                        CharacterItemsInventoryCounter { player, count: inventoryCounter.count },
                    )
                );
            }

            storageItem.itemId = 0;
            set!(world, (storageItem));
        }

        fn undo_place_item(ref world: IWorldDispatcher, inventory_item_id: u32) {
            let player = get_caller_address();

            let mut inventoryItem = get!(
                world, (player, inventory_item_id), (CharacterItemInventory)
            );
            let itemId = inventoryItem.itemId;
            assert(itemId != 0, 'invalid inventory item id');
            let item = get!(world, itemId, (Item));

            let x = inventoryItem.position.x;
            let y = inventoryItem.position.y;
            let rotation = inventoryItem.rotation;
            let itemHeight = item.height;
            let itemWidth = item.width;

            let playerBackpackGrids = get!(world, (player, x, y), (BackpackGrids));
            if itemHeight == 1 && itemWidth == 1 {
                if item.itemType == 4 {
                    assert(!playerBackpackGrids.occupied, 'Already occupied');
                    set!(
                        world,
                        (BackpackGrids {
                            player: player, x: x, y: y, enabled: false, occupied: false
                        })
                    );
                } else {
                    set!(
                        world,
                        (BackpackGrids {
                            player: player, x: x, y: y, enabled: true, occupied: false
                        })
                    );
                }
            } else {
                let mut xMax = 0;
                let mut yMax = 0;

                // only check grids which are above the starting (x,y)
                if rotation == 0 || rotation == 180 {
                    xMax = x + itemWidth - 1;
                    yMax = y + itemHeight - 1;
                }

                // only check grids which are to the right of the starting (x,y)
                if rotation == 90 || rotation == 270 {
                    //item_h becomes item_w and vice versa
                    xMax = x + itemHeight - 1;
                    yMax = y + itemWidth - 1;
                }

                let mut i = x;
                let mut j = y;
                loop {
                    if i > xMax {
                        break;
                    }
                    loop {
                        if j > yMax {
                            break;
                        }

                        let playerBackpackGrids = get!(world, (player, i, j), (BackpackGrids));
                        if item.itemType == 4 {
                            assert(!playerBackpackGrids.occupied, 'Already occupied');
                            set!(
                                world,
                                (BackpackGrids {
                                    player: player, x: i, y: j, enabled: false, occupied: false
                                })
                            );
                        } else {
                            set!(
                                world,
                                (BackpackGrids {
                                    player: player, x: i, y: j, enabled: true, occupied: false
                                })
                            );
                        }

                        j += 1;
                    };
                    j = y;
                    i += 1;
                }
            }

            let mut storageCounter = get!(world, player, (CharacterItemsStorageCounter));
            let mut count = storageCounter.count;
            let mut isUpdated = false;
            loop {
                if count == 0 {
                    break;
                }

                let mut storageItem = get!(world, (player, count), (CharacterItemStorage));
                if storageItem.itemId == 0 {
                    storageItem.itemId = itemId;
                    isUpdated = true;
                    set!(world, (storageItem));
                    break;
                }

                count -= 1;
            };

            if isUpdated == false {
                storageCounter.count += 1;
                set!(
                    world,
                    (
                        CharacterItemStorage { player, id: storageCounter.count, itemId: itemId, },
                        CharacterItemsStorageCounter { player, count: storageCounter.count },
                    )
                );
            }

            inventoryItem.itemId = 0;
            inventoryItem.position.x = 0;
            inventoryItem.position.y = 0;
            inventoryItem.rotation = 0;
            set!(world, (inventoryItem));
        }
    }
}
