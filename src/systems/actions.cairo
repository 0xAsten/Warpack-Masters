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
    use super::{IActions, WMClass};
    use starknet::ContractAddress;

    use starknet::{get_caller_address, get_block_timestamp};
    use warpack_masters::models::{backpack::{BackpackGrids}};
    use warpack_masters::models::{
        CharacterItem::{
            Position, CharacterItemsStorageCounter, CharacterItemStorage, CharacterItemInventory,
            CharacterItemsInventoryCounter
        },
        Item::Item,
        Character::{Characters, NameRecord},
        Shop::Shop,
        Fight::{BattleLog, BattleLogCounter}
    };

    use warpack_masters::items::{Backpack, Pack};
    use warpack_masters::constants::constants::{GRID_X, GRID_Y, INIT_GOLD, INIT_HEALTH, INIT_STAMINA};

    // use debug::PrintTrait;

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
                inventoryItem.plugins = array![];

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
                                player: player, x: i, y: j, enabled: false, occupied: false, itemId: 0, inventoryItemId: 0, isWeapon: false, isPlugin: false
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

            // check if the player has fought the matching battle
            let mut battleLogCounter = get!(world, player, (BattleLogCounter));
            let latestBattleLog = get!(world, (player, battleLogCounter.count), BattleLog);
            assert(battleLogCounter.count == 0 || latestBattleLog.winner != 0, 'battle not fought');

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

            assert(item.width > 0 && item.height > 0, 'invalid item dimensions');

            let itemHeight = item.height;
            let itemWidth = item.width;
            let isWeapon = if item.itemType == 1 || item.itemType == 2 {
                true
            } else {
                false
            };

            // put into inventory
            let mut inventoryCounter = get!(world, player, (CharacterItemsInventoryCounter));
            let mut count = inventoryCounter.count;

            let mut inventoryItem = CharacterItemInventory {
                player,
                id: 0,
                itemId: itemId,
                position: Position { x, y },
                rotation: rotation,
                plugins: array![],
            };

            loop {
                if count == 0 {
                    break;
                }

                let currentInventoryItem = get!(world, (player, count), (CharacterItemInventory));
                if currentInventoryItem.itemId == 0 {
                    inventoryItem.id = count;
                    break;
                }

                count -= 1;
            };

            if count == 0 {
                inventoryCounter.count += 1;
                inventoryItem.id = inventoryCounter.count;
            }

            let mut xMax = 0;
            let mut yMax = 0;

            
            if rotation == 0 || rotation == 180 {
                // only check grids which are above the starting (x,y)
                xMax = x + itemWidth - 1;
                yMax = y + itemHeight - 1;
            } else if rotation == 90 || rotation == 270 {
                // only check grids which are to the right of the starting (x,y)
                //item_h becomes item_w and vice versa
                xMax = x + itemHeight - 1;
                yMax = y + itemWidth - 1;
            } else {
                assert(false, 'invalid rotation');
            }

            assert(xMax < GRID_X, 'item out of bound for x');
            assert(yMax < GRID_Y, 'item out of bound for y');

            let mut i = x;
            let mut j = y;
            let mut isHandled: Felt252Dict<bool> = Default::default();
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
                                player: player, x: i, y: j, enabled: true, occupied: false, itemId: 0, inventoryItemId: 0, isWeapon: false, isPlugin: false
                            })
                        );
                    } else {
                        assert(playerBackpackGrids.enabled, 'Grid not enabled');
                        assert(!playerBackpackGrids.occupied, 'Already occupied');
                        set!(
                            world,
                            (BackpackGrids {
                                player: player, x: i, y: j, enabled: true, occupied: true, itemId: itemId, inventoryItemId: inventoryItem.id, isWeapon: isWeapon, isPlugin: item.isPlugin
                            })
                        );

                        // to check around if it is a weapon or plugin
                        if isWeapon || item.isPlugin {
                            // left
                            if i > 0 && i == x {
                                let grid = get!(world, (player, i - 1, j), (BackpackGrids));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin = get!(world, grid.itemId, (Item));
                                        inventoryItem.plugins.append((plugin.effectType, plugin.chance, plugin.effectStacks));
                                    } else if item.isPlugin && grid.isWeapon {
                                        let mut weapon = get!(world, (player, grid.inventoryItemId), (CharacterItemInventory));
                                        weapon.plugins.append((item.effectType, item.chance, item.effectStacks));
                                        set!(world, (weapon));
                                    }
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            // top
                            if j < GRID_Y - 1 && j == yMax {
                                let grid = get!(world, (player, i, j + 1), (BackpackGrids));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin = get!(world, grid.itemId, (Item));
                                        inventoryItem.plugins.append((plugin.effectType, plugin.chance, plugin.effectStacks));
                                    } else if item.isPlugin && grid.isWeapon {
                                        let mut weapon = get!(world, (player, grid.inventoryItemId), (CharacterItemInventory));
                                        weapon.plugins.append((item.effectType, item.chance, item.effectStacks));
                                        set!(world, (weapon));
                                    }
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            // right
                            if i < GRID_X - 1 && i == xMax {
                                let grid = get!(world, (player, i + 1, j), (BackpackGrids));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin = get!(world, grid.itemId, (Item));
                                        inventoryItem.plugins.append((plugin.effectType, plugin.chance, plugin.effectStacks));
                                    } else if item.isPlugin && grid.isWeapon {
                                        let mut weapon = get!(world, (player, grid.inventoryItemId), (CharacterItemInventory));
                                        weapon.plugins.append((item.effectType, item.chance, item.effectStacks));
                                        set!(world, (weapon));
                                    }
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            // bottom
                            if j > 0 && j == y {
                                let grid = get!(world, (player, i, j - 1), (BackpackGrids));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin = get!(world, grid.itemId, (Item));
                                        inventoryItem.plugins.append((plugin.effectType, plugin.chance, plugin.effectStacks));
                                    } else if item.isPlugin && grid.isWeapon {
                                        let mut weapon = get!(world, (player, grid.inventoryItemId), (CharacterItemInventory));
                                        weapon.plugins.append((item.effectType, item.chance, item.effectStacks));
                                        set!(world, (weapon));
                                    }
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }   
                            }
                        }
                    }

                    j += 1;
                };
                j = y;
                i += 1;
            };

            storageItem.itemId = 0;
            set!(
                world,
                (
                    inventoryItem,
                    inventoryCounter,
                    storageItem,
                )
            );
        }

        fn undo_place_item(ref world: IWorldDispatcher, inventory_item_id: u32) {
            let player = get_caller_address();

            // check if the player has fought the matching battle
            let mut battleLogCounter = get!(world, player, (BattleLogCounter));
            let latestBattleLog = get!(world, (player, battleLogCounter.count), BattleLog);
            assert(battleLogCounter.count == 0 || latestBattleLog.winner != 0, 'battle not fought');

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

            let isWeapon = if item.itemType == 1 || item.itemType == 2 {
                true
            } else {
                false
            };

            let mut xMax = 0;
            let mut yMax = 0;

            if rotation == 0 || rotation == 180 {
                // only check grids which are above the starting (x,y)
                xMax = x + itemWidth - 1;
                yMax = y + itemHeight - 1;
            } else if rotation == 90 || rotation == 270 {
                // only check grids which are to the right of the starting (x,y)
                //item_h becomes item_w and vice versa
                xMax = x + itemHeight - 1;
                yMax = y + itemWidth - 1;
            } else {
                assert(false, 'invalid rotation');
            }

            let mut i = x;
            let mut j = y;
            let mut isHandled: Felt252Dict<bool> = Default::default();
            loop {
                if i > xMax {
                    break;
                }
                loop {
                    if j > yMax {
                        break;
                    }

                    let mut playerBackpackGrids = get!(world, (player, i, j), (BackpackGrids));
                    if item.itemType == 4 {
                        assert(!playerBackpackGrids.occupied, 'Already occupied');
                        playerBackpackGrids.enabled = false;
                        set!(
                            world,
                            (playerBackpackGrids)
                        );
                    } else {
                        assert(playerBackpackGrids.enabled, 'Grid not enabled');
                        assert(playerBackpackGrids.occupied, 'Grid not occupied');
                        assert(playerBackpackGrids.inventoryItemId == inventory_item_id, 'Invalid inventory item id');
                        assert(playerBackpackGrids.itemId == itemId, 'Invalid item id');
                        assert(playerBackpackGrids.isWeapon == isWeapon, 'Invalid item type');
                        assert(playerBackpackGrids.isPlugin == item.isPlugin, 'Is not aligned with plugin');

                        playerBackpackGrids.occupied = false;
                        playerBackpackGrids.itemId = 0;
                        playerBackpackGrids.inventoryItemId = 0;
                        playerBackpackGrids.isWeapon = false;
                        playerBackpackGrids.isPlugin = false;
                        set!(
                            world,
                            (playerBackpackGrids)
                        );

                        // to check around if it is a plugin
                        if item.isPlugin {
                            // left
                            if i > 0 && i == x {
                                let grid = get!(world, (player, i - 1, j), (BackpackGrids));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let mut weapon = get!(world, (player, grid.inventoryItemId), (CharacterItemInventory));
                                    let mut k = 0;
                                    let plugins = weapon.plugins;
                                    let mut newPlugins = array![];
                                    loop {
                                        if k >= plugins.len() {
                                            break;
                                        }
                                        if *plugins.at(k) == (item.effectType, item.chance, item.effectStacks) {
                                            k += 1;
                                            continue;
                                        }
                                        newPlugins.append(*plugins.at(k));
                                        k += 1;
                                    };
                                    weapon.plugins = newPlugins;
                                    set!(world, (weapon));
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            // top
                            if j < GRID_Y - 1 && j == yMax {
                                let grid = get!(world, (player, i, j + 1), (BackpackGrids));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let mut weapon = get!(world, (player, grid.inventoryItemId), (CharacterItemInventory));
                                    let mut k = 0;
                                    let plugins = weapon.plugins;
                                    let mut newPlugins = array![];
                                    loop {
                                        if k >= plugins.len() {
                                            break;
                                        }
                                        if *plugins.at(k) == (item.effectType, item.chance, item.effectStacks) {
                                            k += 1;
                                            continue;
                                        }
                                        newPlugins.append(*plugins.at(k));
                                        k += 1;
                                    };
                                    weapon.plugins = newPlugins;
                                    set!(world, (weapon));
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            // right
                            if i < GRID_X - 1 && i == xMax {
                                let grid = get!(world, (player, i + 1, j), (BackpackGrids));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let mut weapon = get!(world, (player, grid.inventoryItemId), (CharacterItemInventory));
                                    let mut k = 0;
                                    let plugins = weapon.plugins;
                                    let mut newPlugins = array![];
                                    loop {
                                        if k >= plugins.len() {
                                            break;
                                        }
                                        if *plugins.at(k) == (item.effectType, item.chance, item.effectStacks) {
                                            k += 1;
                                            continue;
                                        }
                                        newPlugins.append(*plugins.at(k));
                                        k += 1;
                                    };
                                    weapon.plugins = newPlugins;
                                    set!(world, (weapon));
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            // bottom
                            if j > 0 && j == y {
                                let grid = get!(world, (player, i, j - 1), (BackpackGrids));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let mut weapon = get!(world, (player, grid.inventoryItemId), (CharacterItemInventory));
                                    let mut k = 0;
                                    let plugins = weapon.plugins;
                                    let mut newPlugins = array![];
                                    loop {
                                        if k >= plugins.len() {
                                            break;
                                        }
                                        if *plugins.at(k) == (item.effectType, item.chance, item.effectStacks) {
                                            k += 1;
                                            continue;
                                        }
                                        newPlugins.append(*plugins.at(k));
                                        k += 1;
                                    };
                                    weapon.plugins = newPlugins;
                                    set!(world, (weapon));
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                        }
                    }

                    j += 1;
                };
                j = y;
                i += 1;
            };
        

            let mut storageCounter = get!(world, player, (CharacterItemsStorageCounter));
            let mut count = storageCounter.count;
            loop {
                if count == 0 {
                    break;
                }

                let mut storageItem = get!(world, (player, count), (CharacterItemStorage));
                if storageItem.itemId == 0 {
                    storageItem.itemId = itemId;
                    set!(world, (storageItem));
                    break;
                }

                count -= 1;
            };

            if count == 0 {
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
            inventoryItem.plugins = array![];
            set!(world, (inventoryItem));
        }
    }
}
