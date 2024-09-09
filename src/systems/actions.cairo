use starknet::ContractAddress;
use warpack_masters::models::Character::WMClass;

use warpack_masters::prdefined_dummies::PredefinedItem;

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
    fn add_receipt(
        ref world: IWorldDispatcher, item1_id: u32, item2_id: u32, result_item_id: u32
    );
    fn craft_item(
        ref world: IWorldDispatcher, item1_id: u32, item2_id: u32
    );
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
            CharacterItemsInventoryCounter, are_items_nearby
        },
        Item::Item,
        Character::{Characters, NameRecord},
        Receipt::Receipt,
        Shop::Shop
    };

    use warpack_masters::items::{Backpack, Pack};
    use warpack_masters::constants::constants::{GRID_X, GRID_Y, INIT_GOLD, INIT_HEALTH, INIT_STAMINA};

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

            let player_exists = get!(world, player, (Characters));
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
                    Characters {
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
                        stamina: INIT_STAMINA,
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

            let mut char = get!(world, player, (Characters));

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

        fn add_receipt(
            ref world: IWorldDispatcher, item1_id: u32, item2_id: u32, result_item_id: u32
        ) {
            let item1 = get!(world, item1_id, Item);
            assert!(item1.height != 0, "Item1 does not exist or is invalid");
            let item2 = get!(world, item2_id, Item);
            assert!(item2.height != 0, "Item2 does not exist or is invalid");
            // make constructor
            let result_item = get!(world, result_item_id, Item);
            assert!(result_item.height != 0, "Result item does not exist or is invalid");
    
    
            let receipt = Receipt {
                item1_id,
                item2_id,
                result_item_id,
            };
            set!(world, (receipt));
        }

        fn craft_item(
            ref world: IWorldDispatcher, item1_id: u32, item2_id: u32
        ) {
            let player = get_caller_address();

            let mut item1_position = Position { x: 0, y: 0 };
            let mut item2_position = Position { x: 0, y: 0 };
            let mut item1_rotation = 0;
            let mut item2_rotation = 0;
            let mut item1_width = 0;
            let mut item1_height = 0;
            let mut item2_width = 0;
            let mut item2_height = 0;

            let mut found_item1 = false;
            let mut found_item2 = false;

            let mut inventory_counter = get!(world, player, (CharacterItemsInventoryCounter));
            let mut count = inventory_counter.count;

            // Search for the items in the player's inventory
            loop {
                if count == 0 {
                    break;
                }

                let inventory_item = get!(world, (player, count), (CharacterItemInventory));

                if inventory_item.itemId == item1_id && inventory_item.itemId != 0 {
                    item1_position = inventory_item.position;
                    item1_rotation = inventory_item.rotation;
                    let item1_data = get!(world, item1_id, (Item));
                    item1_width = item1_data.width;
                    item1_height = item1_data.height;
                    found_item1 = true;
                } else if inventory_item.itemId == item2_id && inventory_item.itemId != 0 {
                    item2_position = inventory_item.position;
                    item2_rotation = inventory_item.rotation;
                    let item2_data = get!(world, item2_id, (Item));
                    item2_width = item2_data.width;
                    item2_height = item2_data.height;
                    found_item2 = true;
                }

                if found_item1 && found_item2 {
                    break;
                }

                count -= 1;
            };

            assert!(found_item1, "Item1 not found or invalid in inventory");
            assert!(found_item2, "Item2 not found or invalid in inventory");

            assert!(
                are_items_nearby(item1_position, item1_width, item1_height, item1_rotation, item2_position, item2_width, item2_height, item2_rotation),
                "Items are not nearby"
            );

            let receipt = get!(world, (item1_id, item2_id), (Receipt));
            assert!(receipt.result_item_id != 0, "No valid receipt found for these items");

            self.undo_place_item(item1_id);
            self.undo_place_item(item2_id);

            let new_item_id = receipt.result_item_id;
            let new_item = get!(world, new_item_id, Item);
            let new_item_width = new_item.width;
            let new_item_height = new_item.height;

            let mut position_x = item1_position.x;
            let mut position_y = item1_position.y;
            let mut rotation = item1_rotation;

            // Check if the new item can fit in the position of the first item
            if new_item_width > item1_width || new_item_height > item1_height {
                // If it doesn't fit, try the position of the second item
                position_x = item2_position.x;
                position_y = item2_position.y;
                rotation = item2_rotation;
            }

            // remove previous items
            let mut storageItem1 = get!(world, (player, item1_id), (CharacterItemStorage));
            let mut storageItem2 = get!(world, (player, item2_id), (CharacterItemStorage));
            storageItem1.itemId = 0;
            storageItem2.itemId = 0;
            set!(world, (storageItem1, storageItem2));

            // add new crafted item
            let mut storageCounter = get!(world, player, (CharacterItemsStorageCounter));
            let mut count = storageCounter.count;
            let mut isUpdated = false;
            loop {
                if count == 0 {
                    break;
                }

                let mut storageItem = get!(world, (player, count), (CharacterItemStorage));
                if storageItem.itemId == 0 {
                    storageItem.itemId = new_item_id;
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
                        CharacterItemStorage { player, id: storageCounter.count, itemId: new_item_id, },
                        CharacterItemsStorageCounter { player, count: storageCounter.count },
                    )
                );
            }

            // place item
            self.place_item(new_item_id, position_x, position_y, rotation);
        }
    }
}
