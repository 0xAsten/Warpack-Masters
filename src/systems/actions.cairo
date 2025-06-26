use warpack_masters::models::Character::WMClass;
use starknet::{ContractAddress, get_caller_address};
use crate::constants::{GRID_X, GRID_Y};
use crate::models::{
    Character, CharacterItem, DummyCharacter, DummyCharacterItem, Fight, Shop, Item, Game, backpack
};
use warpack_masters::models::{
    CharacterItem::{
        Position, CharacterItemsStorageCounter, CharacterItemStorage, CharacterItemInventory,
        CharacterItemsInventoryCounter
    },
    Item::Item,
    Character::{Characters, NameRecord},
    Shop::Shop,
    Fight::{BattleLog, BattleLogCounter},
    Game::GameConfig
};
use warpack_masters::utils::random::{pseudo_seed, random};
use warpack_masters::constants::constants::{ITEMS_COUNTER_ID};
use warpack_masters::models::Item::{ItemsCounter};

// Enum for different types of inventory updates
#[derive(Drop, Serde)]
enum InventoryUpdate {
    Move: (u32, u32, u32, u32), // (inventory_item_id, x, y, rotation)
    BuyAndPlace: (u32, u32, u32, u32), // (item_id, x, y, rotation)
    SellFromInventory: u32, // inventory_item_id
    SellFromStorage: u32, // storage_item_id
    PlaceFromStorage: (u32, u32, u32, u32), // (storage_item_id, x, y, rotation)
}

#[starknet::interface]
pub trait IActions<T> {
    fn spawn(
        ref self: T,
        name: felt252,
        wmClass: WMClass,
    );
    fn rebirth(
        ref self: T,
    );
    fn place_item(
        ref self: T, storage_item_id: u32, x: u32, y: u32, rotation: u32
    );
    fn undo_place_item(ref self: T, inventory_item_id: u32);
    fn get_balance(self: @T) -> u256;
    fn withdraw_strk(ref self: T, amount: u256);
    fn buy_and_place_item(ref self: T, item_id: u32, x: u32, y: u32, rotation: u32);
    fn move_item(ref self: T, inventory_item_id: u32, x: u32, y: u32, rotation: u32);
    fn sell_from_inventory(ref self: T, inventory_item_id: u32);
    fn batch_update_inventory(ref self: T, updates: Array<InventoryUpdate>);
    fn initialize_shop(ref self: T);
    fn give_free_shop_reroll(ref self: T);
    fn generate_shop_items_internal(self: @T, wins: u32) -> (u32, u32, u32, u32);
}

// TODO: rename the count filed in counter model

#[dojo::contract]
mod actions {
    use super::{IActions, WMClass};
    use starknet::ContractAddress;
    use core::dict::Felt252Dict;
    use core::bytes_31::bytes31;

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
        Fight::{BattleLog, BattleLogCounter},
        Game::GameConfig
    };

    use warpack_masters::items::{Backpack, Pack};
    use warpack_masters::constants::constants::{GRID_X, GRID_Y, INIT_GOLD, INIT_HEALTH, INIT_STAMINA, REBIRTH_FEE, GAME_CONFIG_ID};

    use dojo::model::{ModelStorage};

    use warpack_masters::externals::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    use dojo::world::{IWorldDispatcherTrait};


    // use debug::PrintTrait;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ItemSold {
        #[key]
        pub player: ContractAddress,
        pub item_id: u32,
        pub price: u16
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct InventoryBatchUpdated {
        #[key]
        pub player: ContractAddress,
        pub updates_count: u32
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn spawn(
            ref self: ContractState,
            name: felt252,
            wmClass: WMClass,
        ) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            let name_bytes: bytes31 = name.try_into().unwrap();

            let mut len = 0;
            loop {
                if name_bytes.at(len) == 0 {
                    break;
                }
                len += 1;
            };
            assert(len <= 12 && len > 3, 'name size is invalid');

            let nameRecord: NameRecord = world.read_model(name);
            assert(
                nameRecord.player == starknet::contract_address_const::<0>()
                    || nameRecord.player == player,
                'name already exists'
            );

            world.write_model(@NameRecord { name, player });

            let player_exists: Characters = world.read_model(player);
            assert(player_exists.name == '', 'player already exists');

            // Default the player has 2 Backpacks
            // Must add two backpack items when setup the game
            let item: Item = world.read_model(Backpack::id);
            assert(item.itemType == 4, 'Invalid item type');
            let item: Item = world.read_model(Pack::id);
            assert(item.itemType == 4, 'Invalid item type');

            world.write_model(@CharacterItemStorage { player, id: 1, itemId: Backpack::id });
            world.write_model(@CharacterItemStorage { player, id: 2, itemId: Pack::id });
            world.write_model(@CharacterItemsStorageCounter { player, count: 2 });

            self.place_item(1, 4, 2, 0);
            self.place_item(2, 2, 2, 0);

            // keep the previous rating, totalWins and totalLoss during rebirth
            let prev_rating = player_exists.rating;
            let prev_total_wins = player_exists.totalWins;
            let prev_total_loss = player_exists.totalLoss;
            let prev_birth_count = player_exists.birthCount;
            let updatedAt = get_block_timestamp();

            // add one gold for reroll shop
            world.write_model(@Characters { 
                player,
                name,
                wmClass,
                gold: INIT_GOLD + 1,
                health: INIT_HEALTH,
                wins: 0,
                loss: 0,
                rating: prev_rating,
                totalWins: prev_total_wins,
                totalLoss: prev_total_loss,
                winStreak: 0,
                birthCount: prev_birth_count + 1,
                stamina: INIT_STAMINA,
                updatedAt, 
            });

            // Initialize shop with items and 1 free reroll
            self.initialize_shop();
        }

        fn rebirth(
            ref self: ContractState,
        ) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            let mut char: Characters = world.read_model(player);

            assert(char.loss >= 5, 'loss not reached');
            
            let gameConfig: GameConfig = world.read_model(GAME_CONFIG_ID);
            let STRK_ADDRESS: ContractAddress = gameConfig.strk_address;
            IERC20Dispatcher { contract_address: STRK_ADDRESS }
                .transfer_from(player, starknet::get_contract_address(), REBIRTH_FEE);

            let prev_name = char.name;
            // required to calling spawn doesn't fail
            char.name = '';

            let mut inventoryItemsCounter: CharacterItemsInventoryCounter = world.read_model(player);
            let mut count = inventoryItemsCounter.count;

            loop {
                if count == 0 {
                    break;
                }

                let mut inventoryItem: CharacterItemInventory = world.read_model((player, count));

                inventoryItem.itemId = 0;
                inventoryItem.position.x = 0;
                inventoryItem.position.y = 0;
                inventoryItem.rotation = 0;
                inventoryItem.plugins = array![];
                
                world.write_model(@inventoryItem);

                count -= 1;
            };

            let mut storageItemsCounter: CharacterItemsStorageCounter = world.read_model(player);
            let mut count = storageItemsCounter.count;

            loop {
                if count == 0 {
                    break;
                }

                let mut storageItem: CharacterItemStorage = world.read_model((player, count));

                storageItem.itemId = 0;

                world.write_model(@storageItem);

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

                    let player_backpack_grid_data: BackpackGrids = world.read_model((player, i, j));

                    if player_backpack_grid_data.occupied || player_backpack_grid_data.enabled {
                        world.write_model(@BackpackGrids {
                            player: player, x: i, y: j, enabled: false, occupied: false, itemId: 0, inventoryItemId: 0, isWeapon: false, isPlugin: false
                        });
                    }
                    j += 1;
                };
                j = 0;
                i += 1;
            };

            // clear shop
            let mut shop: Shop = world.read_model(player);
            shop.item1 = 0;
            shop.item2 = 0;
            shop.item3 = 0;
            shop.item4 = 0;
            shop.free_rerolls = 0;
            shop.rerolls_since_fight = 0;

            inventoryItemsCounter.count = 0;
            storageItemsCounter.count = 0;

            world.write_model(@char);
            world.write_model(@shop);
            world.write_model(@inventoryItemsCounter);
            world.write_model(@storageItemsCounter);

            self.spawn(prev_name, char.wmClass);
        }

        fn withdraw_strk(ref self: ContractState, amount: u256) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();
            assert(world.dispatcher.is_owner(0, player), 'player not world owner');

            let gameConfig: GameConfig = world.read_model(GAME_CONFIG_ID);
            let STRK_ADDRESS: ContractAddress = gameConfig.strk_address;
            IERC20Dispatcher { contract_address: STRK_ADDRESS }
                .transfer(player, amount);
        }

        fn get_balance(self: @ContractState) -> u256 {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            let gameConfig: GameConfig = world.read_model(GAME_CONFIG_ID);
            let STRK_ADDRESS: ContractAddress = gameConfig.strk_address;
            return IERC20Dispatcher { contract_address: STRK_ADDRESS }
                .balance_of(player);
        }
        
        fn place_item(
            ref self: ContractState, storage_item_id: u32, x: u32, y: u32, rotation: u32
        ) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            // check if the player has fought the matching battle
            let mut battleLogCounter: BattleLogCounter = world.read_model(player);
            let mut latestBattleLog: BattleLog = world.read_model((player, battleLogCounter.count));
            assert(battleLogCounter.count == 0 || latestBattleLog.winner != 0, 'battle not fought');

            assert(x < GRID_X, 'x out of range');
            assert(y < GRID_Y, 'y out of range');
            assert(
                rotation == 0 || rotation == 90 || rotation == 180 || rotation == 270,
                'invalid rotation'
            );

            let mut storageItem: CharacterItemStorage = world.read_model((player, storage_item_id));

            assert(storageItem.itemId != 0, 'item not owned');

            let itemId = storageItem.itemId;
            let item: Item = world.read_model(itemId);

            assert(item.width > 0 && item.height > 0, 'invalid item dimensions');

            let itemHeight = item.height;
            let itemWidth = item.width;
            let isWeapon = if item.itemType == 1 || item.itemType == 2 {
                true
            } else {
                false
            };

            // put into inventory
            let mut inventoryCounter: CharacterItemsInventoryCounter = world.read_model(player);
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

                let currentInventoryItem: CharacterItemInventory = world.read_model((player, count));
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

                    let playerBackpackGrids: BackpackGrids = world.read_model((player, i, j));
                    if item.itemType == 4 {
                        assert(!playerBackpackGrids.enabled, 'Already enabled');
                        world.write_model(@BackpackGrids {
                            player: player, x: i, y: j, enabled: true, occupied: false, itemId: 0, inventoryItemId: 0, isWeapon: false, isPlugin: false
                        });
                    } else {
                        assert(playerBackpackGrids.enabled, 'Grid not enabled');
                        assert(!playerBackpackGrids.occupied, 'Already occupied');
                        world.write_model(@BackpackGrids {
                            player: player, x: i, y: j, enabled: true, occupied: true, itemId: itemId, inventoryItemId: inventoryItem.id, isWeapon: isWeapon, isPlugin: item.isPlugin
                        });

                        // to check around if it is a weapon or plugin
                        if isWeapon || item.isPlugin {
                            // left
                            if i > 0 && i == x {
                                let grid: BackpackGrids = world.read_model((player, i - 1, j));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin: Item = world.read_model(grid.itemId);
                                        inventoryItem.plugins.append((plugin.effectType, plugin.chance, plugin.effectStacks));
                                    } else if item.isPlugin && grid.isWeapon {
                                        let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
                                        weapon.plugins.append((item.effectType, item.chance, item.effectStacks));
                                        world.write_model(@weapon);
                                    }
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            // top
                            if j < GRID_Y - 1 && j == yMax {
                                let grid: BackpackGrids = world.read_model((player, i, j + 1));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin: Item = world.read_model(grid.itemId);
                                        inventoryItem.plugins.append((plugin.effectType, plugin.chance, plugin.effectStacks));
                                    } else if item.isPlugin && grid.isWeapon {
                                        let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
                                        weapon.plugins.append((item.effectType, item.chance, item.effectStacks));
                                        world.write_model(@weapon);
                                    }
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            // right
                            if i < GRID_X - 1 && i == xMax {
                                let grid: BackpackGrids = world.read_model((player, i + 1, j));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin: Item = world.read_model(grid.itemId);
                                        inventoryItem.plugins.append((plugin.effectType, plugin.chance, plugin.effectStacks));
                                    } else if item.isPlugin && grid.isWeapon {
                                        let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
                                        weapon.plugins.append((item.effectType, item.chance, item.effectStacks));
                                        world.write_model(@weapon);
                                    }
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            // bottom
                            if j > 0 && j == y {
                                let grid: BackpackGrids = world.read_model((player, i, j - 1));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin: Item = world.read_model(grid.itemId);
                                        inventoryItem.plugins.append((plugin.effectType, plugin.chance, plugin.effectStacks));
                                    } else if item.isPlugin && grid.isWeapon {
                                        let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
                                        weapon.plugins.append((item.effectType, item.chance, item.effectStacks));
                                        world.write_model(@weapon);
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
            world.write_model(@inventoryItem);
            world.write_model(@inventoryCounter);
            world.write_model(@storageItem);
        }

        fn undo_place_item(ref self: ContractState, inventory_item_id: u32) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            // check if the player has fought the matching battle
            let mut battleLogCounter: BattleLogCounter = world.read_model(player);
            let latestBattleLog: BattleLog = world.read_model((player, battleLogCounter.count));
            assert(battleLogCounter.count == 0 || latestBattleLog.winner != 0, 'battle not fought');

            let mut inventoryItem: CharacterItemInventory = world.read_model((player, inventory_item_id));
            let itemId = inventoryItem.itemId;
            assert(itemId != 0, 'invalid inventory item id');
            let item: Item = world.read_model(itemId);

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

                    let mut playerBackpackGrids: BackpackGrids = world.read_model((player, i, j));
                    if item.itemType == 4 {
                        assert(!playerBackpackGrids.occupied, 'Already occupied');
                        playerBackpackGrids.enabled = false;
                        world.write_model(@playerBackpackGrids);
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
                        world.write_model(@playerBackpackGrids);

                        // to check around if it is a plugin
                        if item.isPlugin {
                            // left
                            if i > 0 && i == x {
                                let grid: BackpackGrids = world.read_model((player, i - 1, j));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
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
                                    world.write_model(@weapon);
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            // top
                            if j < GRID_Y - 1 && j == yMax {
                                let grid: BackpackGrids = world.read_model((player, i, j + 1));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
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
                                    world.write_model(@weapon);
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            // right
                            if i < GRID_X - 1 && i == xMax {
                                let grid: BackpackGrids = world.read_model((player, i + 1, j));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
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
                                    world.write_model(@weapon);
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            // bottom
                            if j > 0 && j == y {
                                let grid: BackpackGrids = world.read_model((player, i, j - 1));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
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
                                    world.write_model(@weapon);
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
        
            let mut storageCounter: CharacterItemsStorageCounter = world.read_model(player);
            let mut count = storageCounter.count;
            loop {
                if count == 0 {
                    break;
                }

                let mut storageItem: CharacterItemStorage = world.read_model((player, count));
                if storageItem.itemId == 0 {
                    storageItem.itemId = itemId;
                    world.write_model(@storageItem);
                    break;
                }

                count -= 1;
            };

            if count == 0 {
                storageCounter.count += 1;
                world.write_model(@CharacterItemStorage { player, id: storageCounter.count, itemId: itemId, });
                world.write_model(@CharacterItemsStorageCounter { player, count: storageCounter.count });
            }

            inventoryItem.itemId = 0;
            inventoryItem.position.x = 0;
            inventoryItem.position.y = 0;
            inventoryItem.rotation = 0;
            inventoryItem.plugins = array![];
            world.write_model(@inventoryItem);
        }

        fn buy_and_place_item(ref self: ContractState, item_id: u32, x: u32, y: u32, rotation: u32) {
            let mut world = self.world(@"Warpacks");
            let player = get_caller_address();

            // Validate input parameters
            assert(item_id != 0, 'invalid item_id');
            assert(x < GRID_X, 'x out of range');
            assert(y < GRID_Y, 'y out of range');
            assert(
                rotation == 0 || rotation == 90 || rotation == 180 || rotation == 270,
                'invalid rotation'
            );

            // Check if the player has fought the matching battle
            let mut battleLogCounter: BattleLogCounter = world.read_model(player);
            let mut latestBattleLog: BattleLog = world.read_model((player, battleLogCounter.count));
            assert(battleLogCounter.count == 0 || latestBattleLog.winner != 0, 'battle not fought');

            // 1. Validate purchase
            let mut shop_data: Shop = world.read_model(player);
            assert(
                shop_data.item1 == item_id
                    || shop_data.item2 == item_id
                    || shop_data.item3 == item_id
                    || shop_data.item4 == item_id,
                'item not on sale'
            );

            let item: Item = world.read_model(item_id);
            let mut player_char: Characters = world.read_model(player);
            assert(player_char.gold >= item.price, 'Insufficient gold');

            // 2. Validate placement
            assert(item.width > 0 && item.height > 0, 'invalid item dimensions');

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
                xMax = x + itemWidth - 1;
                yMax = y + itemHeight - 1;
            } else if rotation == 90 || rotation == 270 {
                xMax = x + itemHeight - 1;
                yMax = y + itemWidth - 1;
            } else {
                assert(false, 'invalid rotation');
            }

            assert(xMax < GRID_X, 'item out of bound for x');
            assert(yMax < GRID_Y, 'item out of bound for y');

            // Check all grid positions are available
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

                    let playerBackpackGrids: BackpackGrids = world.read_model((player, i, j));
                    if item.itemType == 4 {
                        assert(!playerBackpackGrids.enabled, 'Already enabled');
                    } else {
                        assert(playerBackpackGrids.enabled, 'Grid not enabled');
                        assert(!playerBackpackGrids.occupied, 'Already occupied');
                    }

                    j += 1;
                };
                j = y;
                i += 1;
            };

            // 3. Perform all updates atomically
            // Deduct gold
            player_char.gold -= item.price;

            // Remove item from shop
            if shop_data.item1 == item_id {
                shop_data.item1 = 0;
            } else if shop_data.item2 == item_id {
                shop_data.item2 = 0;
            } else if shop_data.item3 == item_id {
                shop_data.item3 = 0;
            } else if shop_data.item4 == item_id {
                shop_data.item4 = 0;
            }

            // Find or create inventory slot
            let mut inventoryCounter: CharacterItemsInventoryCounter = world.read_model(player);
            let mut count = inventoryCounter.count;

            let mut inventoryItem = CharacterItemInventory {
                player,
                id: 0,
                itemId: item_id,
                position: Position { x, y },
                rotation: rotation,
                plugins: array![],
            };

            loop {
                if count == 0 {
                    break;
                }

                let currentInventoryItem: CharacterItemInventory = world.read_model((player, count));
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

            // Place item in grid
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

                    if item.itemType == 4 {
                        world.write_model(@BackpackGrids {
                            player: player, x: i, y: j, enabled: true, occupied: false, itemId: 0, inventoryItemId: 0, isWeapon: false, isPlugin: false
                        });
                    } else {
                        world.write_model(@BackpackGrids {
                            player: player, x: i, y: j, enabled: true, occupied: true, itemId: item_id, inventoryItemId: inventoryItem.id, isWeapon: isWeapon, isPlugin: item.isPlugin
                        });

                        // Handle weapon/plugin interactions
                        if isWeapon || item.isPlugin {
                            // Check adjacent cells for plugins/weapons
                            if i > 0 && i == x {
                                let grid: BackpackGrids = world.read_model((player, i - 1, j));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin: Item = world.read_model(grid.itemId);
                                        inventoryItem.plugins.append((plugin.effectType, plugin.chance, plugin.effectStacks));
                                    } else if item.isPlugin && grid.isWeapon {
                                        let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
                                        weapon.plugins.append((item.effectType, item.chance, item.effectStacks));
                                        world.write_model(@weapon);
                                    }
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            if j < GRID_Y - 1 && j == yMax {
                                let grid: BackpackGrids = world.read_model((player, i, j + 1));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin: Item = world.read_model(grid.itemId);
                                        inventoryItem.plugins.append((plugin.effectType, plugin.chance, plugin.effectStacks));
                                    } else if item.isPlugin && grid.isWeapon {
                                        let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
                                        weapon.plugins.append((item.effectType, item.chance, item.effectStacks));
                                        world.write_model(@weapon);
                                    }
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            if i < GRID_X - 1 && i == xMax {
                                let grid: BackpackGrids = world.read_model((player, i + 1, j));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin: Item = world.read_model(grid.itemId);
                                        inventoryItem.plugins.append((plugin.effectType, plugin.chance, plugin.effectStacks));
                                    } else if item.isPlugin && grid.isWeapon {
                                        let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
                                        weapon.plugins.append((item.effectType, item.chance, item.effectStacks));
                                        world.write_model(@weapon);
                                    }
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            if j > 0 && j == y {
                                let grid: BackpackGrids = world.read_model((player, i, j - 1));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin: Item = world.read_model(grid.itemId);
                                        inventoryItem.plugins.append((plugin.effectType, plugin.chance, plugin.effectStacks));
                                    } else if item.isPlugin && grid.isWeapon {
                                        let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
                                        weapon.plugins.append((item.effectType, item.chance, item.effectStacks));
                                        world.write_model(@weapon);
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

            // Write all changes
            world.write_model(@inventoryItem);
            world.write_model(@inventoryCounter);
            world.write_model(@player_char);
            world.write_model(@shop_data);
        }

        fn move_item(ref self: ContractState, inventory_item_id: u32, x: u32, y: u32, rotation: u32) {
            let mut world = self.world(@"Warpacks");
            let player = get_caller_address();

            // Validate input parameters
            assert(x < GRID_X, 'x out of range');
            assert(y < GRID_Y, 'y out of range');
            assert(
                rotation == 0 || rotation == 90 || rotation == 180 || rotation == 270,
                'invalid rotation'
            );

            // Check if the player has fought the matching battle
            let mut battleLogCounter: BattleLogCounter = world.read_model(player);
            let mut latestBattleLog: BattleLog = world.read_model((player, battleLogCounter.count));
            assert(battleLogCounter.count == 0 || latestBattleLog.winner != 0, 'battle not fought');

            let mut inventoryItem: CharacterItemInventory = world.read_model((player, inventory_item_id));
            assert(inventoryItem.itemId != 0, 'item not owned');

            let itemId = inventoryItem.itemId;
            let item: Item = world.read_model(itemId);
            
            let oldX = inventoryItem.position.x;
            let oldY = inventoryItem.position.y;
            let oldRotation = inventoryItem.rotation;

            // If position and rotation are the same, do nothing
            if oldX == x && oldY == y && oldRotation == rotation {
                return;
            }

            assert(item.width > 0 && item.height > 0, 'invalid item dimensions');

            let itemHeight = item.height;
            let itemWidth = item.width;
            let isWeapon = if item.itemType == 1 || item.itemType == 2 {
                true
            } else {
                false
            };

            // Calculate old grid bounds
            let mut oldXMax = 0;
            let mut oldYMax = 0;

            if oldRotation == 0 || oldRotation == 180 {
                oldXMax = oldX + itemWidth - 1;
                oldYMax = oldY + itemHeight - 1;
            } else if oldRotation == 90 || oldRotation == 270 {
                oldXMax = oldX + itemHeight - 1;
                oldYMax = oldY + itemWidth - 1;
            }

            // Calculate new grid bounds
            let mut newXMax = 0;
            let mut newYMax = 0;

            if rotation == 0 || rotation == 180 {
                newXMax = x + itemWidth - 1;
                newYMax = y + itemHeight - 1;
            } else if rotation == 90 || rotation == 270 {
                newXMax = x + itemHeight - 1;
                newYMax = y + itemWidth - 1;
            } else {
                assert(false, 'invalid rotation');
            }

            assert(newXMax < GRID_X, 'item out of bound for x');
            assert(newYMax < GRID_Y, 'item out of bound for y');

            // Check if new position is available (excluding current item's position)
            let mut i = x;
            let mut j = y;
            loop {
                if i > newXMax {
                    break;
                }
                loop {
                    if j > newYMax {
                        break;
                    }

                    let playerBackpackGrids: BackpackGrids = world.read_model((player, i, j));
                    if item.itemType == 4 {
                        assert(!playerBackpackGrids.enabled, 'Already enabled');
                    } else {
                        assert(playerBackpackGrids.enabled, 'Grid not enabled');
                        // Only check occupation if this grid is not part of the current item
                        let isOldPosition = i >= oldX && i <= oldXMax && j >= oldY && j <= oldYMax;
                        if !isOldPosition {
                            assert(!playerBackpackGrids.occupied, 'Already occupied');
                        }
                    }

                    j += 1;
                };
                j = y;
                i += 1;
            };

            // Remove item from old position
            let mut i = oldX;
            let mut j = oldY;
            let mut isHandled: Felt252Dict<bool> = Default::default();
            loop {
                if i > oldXMax {
                    break;
                }
                loop {
                    if j > oldYMax {
                        break;
                    }

                    let mut playerBackpackGrids: BackpackGrids = world.read_model((player, i, j));
                    if item.itemType == 4 {
                        playerBackpackGrids.enabled = false;
                        world.write_model(@playerBackpackGrids);
                    } else {
                        playerBackpackGrids.occupied = false;
                        playerBackpackGrids.itemId = 0;
                        playerBackpackGrids.inventoryItemId = 0;
                        playerBackpackGrids.isWeapon = false;
                        playerBackpackGrids.isPlugin = false;
                        world.write_model(@playerBackpackGrids);

                        // Remove plugin effects when moving
                        if item.isPlugin {
                            if i > 0 && i == oldX {
                                let grid: BackpackGrids = world.read_model((player, i - 1, j));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
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
                                    world.write_model(@weapon);
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            if j < GRID_Y - 1 && j == oldYMax {
                                let grid: BackpackGrids = world.read_model((player, i, j + 1));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
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
                                    world.write_model(@weapon);
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            if i < GRID_X - 1 && i == oldXMax {
                                let grid: BackpackGrids = world.read_model((player, i + 1, j));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
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
                                    world.write_model(@weapon);
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            if j > 0 && j == oldY {
                                let grid: BackpackGrids = world.read_model((player, i, j - 1));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
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
                                    world.write_model(@weapon);
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                        }
                    }

                    j += 1;
                };
                j = oldY;
                i += 1;
            };

            // Clear plugins for weapons when moving
            if isWeapon {
                inventoryItem.plugins = array![];
            }

            // Update inventory item position and rotation
            inventoryItem.position.x = x;
            inventoryItem.position.y = y;
            inventoryItem.rotation = rotation;

            // Place item in new position
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

                    if item.itemType == 4 {
                        world.write_model(@BackpackGrids {
                            player: player, x: i, y: j, enabled: true, occupied: false, itemId: 0, inventoryItemId: 0, isWeapon: false, isPlugin: false
                        });
                    } else {
                        world.write_model(@BackpackGrids {
                            player: player, x: i, y: j, enabled: true, occupied: true, itemId: itemId, inventoryItemId: inventory_item_id, isWeapon: isWeapon, isPlugin: item.isPlugin
                        });

                        // Handle weapon/plugin interactions in new position
                        if isWeapon || item.isPlugin {
                            if i > 0 && i == x {
                                let grid: BackpackGrids = world.read_model((player, i - 1, j));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin: Item = world.read_model(grid.itemId);
                                        inventoryItem.plugins.append((plugin.effectType, plugin.chance, plugin.effectStacks));
                                    } else if item.isPlugin && grid.isWeapon {
                                        let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
                                        weapon.plugins.append((item.effectType, item.chance, item.effectStacks));
                                        world.write_model(@weapon);
                                    }
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            if j < GRID_Y - 1 && j == newYMax {
                                let grid: BackpackGrids = world.read_model((player, i, j + 1));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin: Item = world.read_model(grid.itemId);
                                        inventoryItem.plugins.append((plugin.effectType, plugin.chance, plugin.effectStacks));
                                    } else if item.isPlugin && grid.isWeapon {
                                        let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
                                        weapon.plugins.append((item.effectType, item.chance, item.effectStacks));
                                        world.write_model(@weapon);
                                    }
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            if i < GRID_X - 1 && i == xMax {
                                let grid: BackpackGrids = world.read_model((player, i + 1, j));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin: Item = world.read_model(grid.itemId);
                                        inventoryItem.plugins.append((plugin.effectType, plugin.chance, plugin.effectStacks));
                                    } else if item.isPlugin && grid.isWeapon {
                                        let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
                                        weapon.plugins.append((item.effectType, item.chance, item.effectStacks));
                                        world.write_model(@weapon);
                                    }
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            if j > 0 && j == y {
                                let grid: BackpackGrids = world.read_model((player, i, j - 1));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin: Item = world.read_model(grid.itemId);
                                        inventoryItem.plugins.append((plugin.effectType, plugin.chance, plugin.effectStacks));
                                    } else if item.isPlugin && grid.isWeapon {
                                        let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
                                        weapon.plugins.append((item.effectType, item.chance, item.effectStacks));
                                        world.write_model(@weapon);
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

            world.write_model(@inventoryItem);
        }

        fn sell_from_inventory(ref self: ContractState, inventory_item_id: u32) {
            let mut world = self.world(@"Warpacks");
            let player = get_caller_address();

            // Check if the player has fought the matching battle
            let mut battleLogCounter: BattleLogCounter = world.read_model(player);
            let mut latestBattleLog: BattleLog = world.read_model((player, battleLogCounter.count));
            assert(battleLogCounter.count == 0 || latestBattleLog.winner != 0, 'battle not fought');

            let mut inventoryItem: CharacterItemInventory = world.read_model((player, inventory_item_id));
            let itemId = inventoryItem.itemId;
            assert(itemId != 0, 'item not owned');

            let item: Item = world.read_model(itemId);
            let mut playerChar: Characters = world.read_model(player);

            let itemPrice = item.price;
            let sellPrice = itemPrice / 2;

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

            // Calculate grid bounds
            let mut xMax = 0;
            let mut yMax = 0;

            if rotation == 0 || rotation == 180 {
                xMax = x + itemWidth - 1;
                yMax = y + itemHeight - 1;
            } else if rotation == 90 || rotation == 270 {
                xMax = x + itemHeight - 1;
                yMax = y + itemWidth - 1;
            } else {
                assert(false, 'invalid rotation');
            }

            // Remove item from grid
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

                    let mut playerBackpackGrids: BackpackGrids = world.read_model((player, i, j));
                    if item.itemType == 4 {
                        assert(!playerBackpackGrids.occupied, 'Already occupied');
                        playerBackpackGrids.enabled = false;
                        world.write_model(@playerBackpackGrids);
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
                        world.write_model(@playerBackpackGrids);

                        // Remove plugin effects when selling
                        if item.isPlugin {
                            if i > 0 && i == x {
                                let grid: BackpackGrids = world.read_model((player, i - 1, j));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
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
                                    world.write_model(@weapon);
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            if j < GRID_Y - 1 && j == yMax {
                                let grid: BackpackGrids = world.read_model((player, i, j + 1));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
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
                                    world.write_model(@weapon);
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            if i < GRID_X - 1 && i == xMax {
                                let grid: BackpackGrids = world.read_model((player, i + 1, j));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
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
                                    world.write_model(@weapon);
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            if j > 0 && j == y {
                                let grid: BackpackGrids = world.read_model((player, i, j - 1));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let mut weapon: CharacterItemInventory = world.read_model((player, grid.inventoryItemId));
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
                                    world.write_model(@weapon);
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

            // Clear inventory item
            inventoryItem.itemId = 0;
            inventoryItem.position.x = 0;
            inventoryItem.position.y = 0;
            inventoryItem.rotation = 0;
            inventoryItem.plugins = array![];

            // Add gold to player
            playerChar.gold += sellPrice;

            world.write_model(@inventoryItem);
            world.write_model(@playerChar);
        }

        fn batch_update_inventory(ref self: ContractState, updates: Array<InventoryUpdate>) {
            let mut world = self.world(@"Warpacks");
            let player = get_caller_address();
            
            // Pre-validate all operations before executing any
            let mut i = 0;
            loop {
                if i >= updates.len() {
                    break;
                }
                
                let update = updates.at(i);
                match update {
                    InventoryUpdate::Move((inventory_item_id, x, y, rotation)) => {
                        // Validate move operation
                        assert(*x < GRID_X, 'x out of range');
                        assert(*y < GRID_Y, 'y out of range');
                        assert(
                            *rotation == 0 || *rotation == 90 || *rotation == 180 || *rotation == 270,
                            'invalid rotation'
                        );
                        
                        let inventoryItem: CharacterItemInventory = world.read_model((player, *inventory_item_id));
                        assert(inventoryItem.itemId != 0, 'item not found');
                        
                        // Check if target position is free (if different from current)
                        if inventoryItem.position.x != *x || inventoryItem.position.y != *y {
                            let target_item: CharacterItemInventory = world.read_model((player, (*x, *y)));
                            assert(target_item.itemId == 0, 'target slot occupied');
                        }
                    },
                    InventoryUpdate::BuyAndPlace((item_id, x, y, rotation)) => {
                        let mut playerChar: Character = world.read_model(player);
                        let item: Item = world.read_model(*item_id);
                        
                        // RE-VALIDATE shop state at execution time (shop might have been rerolled)
                        let shop: Shop = world.read_model(player);
                        assert(shop.item1 == *item_id || shop.item2 == *item_id || shop.item3 == *item_id || shop.item4 == *item_id, 'item no longer in shop');
                        assert(playerChar.gold >= item.price, 'insufficient gold');
                        
                        // Check target slot is still free
                        let target_slot: CharacterItemInventory = world.read_model((player, (*x, *y)));
                        assert(target_slot.itemId == 0, 'slot occupied');
                        
                        // Deduct gold
                        playerChar.gold -= item.price;
                        world.write_model(@playerChar);
                        
                        // Remove item from shop
                        let mut updated_shop = shop;
                        if updated_shop.item1 == *item_id {
                            updated_shop.item1 = 0;
                        } else if updated_shop.item2 == *item_id {
                            updated_shop.item2 = 0;
                        } else if updated_shop.item3 == *item_id {
                            updated_shop.item3 = 0;
                        } else if updated_shop.item4 == *item_id {
                            updated_shop.item4 = 0;
                        }
                        world.write_model(@updated_shop);
                        
                        // Get next inventory counter and create inventory item
                        let mut inventoryCounter: CharacterItemsInventoryCounter = world.read_model(player);
                        inventoryCounter.count += 1;
                        world.write_model(@inventoryCounter);
                        
                        // Create inventory item
                        let new_item = CharacterItemInventory {
                            player,
                            id: inventoryCounter.count,
                            itemId: *item_id,
                            position: Position { x: *x, y: *y },
                            rotation: *rotation,
                            plugins: array![]
                        };
                        world.write_model(@new_item);
                        
                        // Update backpack grids
                        let mut i = 0;
                        loop {
                            if i >= item.width {
                                break;
                            }
                            let mut j = 0;
                            loop {
                                if j >= item.height {
                                    break;
                                }
                                let mut grid: BackpackGrids = world.read_model((player, *x + i, *y + j));
                                grid.occupied = true;
                                grid.inventoryItemId = inventoryCounter.count;
                                grid.itemId = *item_id;
                                grid.isWeapon = item.itemType == 1;
                                grid.isPlugin = item.isPlugin;
                                world.write_model(@grid);
                                j += 1;
                            };
                            i += 1;
                        };
                    },
                    InventoryUpdate::SellFromInventory(inventory_item_id) => {
                        // Validate sell operation
                        let inventoryItem: CharacterItemInventory = world.read_model((player, *inventory_item_id));
                        assert(inventoryItem.itemId != 0, 'item not found');
                    },
                    InventoryUpdate::SellFromStorage(storage_item_id) => {
                        // Validate sell operation
                        let storageItem: CharacterItemStorage = world.read_model((player, *storage_item_id));
                        assert(storageItem.itemId != 0, 'item not found');
                    },
                    InventoryUpdate::PlaceFromStorage((storage_item_id, x, y, rotation)) => {
                        let storageItem: CharacterItemStorage = world.read_model((player, *storage_item_id));
                        let item: Item = world.read_model(storageItem.itemId);
                        
                        // Clear storage slot
                        let mut cleared_storage: CharacterItemStorage = world.read_model((player, *storage_item_id));
                        cleared_storage.itemId = 0;
                        world.write_model(@cleared_storage);
                        
                        // Get next inventory counter
                        let mut inventoryCounter: CharacterItemsInventoryCounter = world.read_model(player);
                        inventoryCounter.count += 1;
                        world.write_model(@inventoryCounter);
                        
                        // Create inventory item
                        let new_inventory_item = CharacterItemInventory {
                            player,
                            id: inventoryCounter.count,
                            itemId: storageItem.itemId,
                            position: Position { x: *x, y: *y },
                            rotation: *rotation,
                            plugins: array![]
                        };
                        world.write_model(@new_inventory_item);
                        
                        // Update backpack grids
                        let mut i = 0;
                        loop {
                            if i >= item.width {
                                break;
                            }
                            let mut j = 0;
                            loop {
                                if j >= item.height {
                                    break;
                                }
                                let mut grid: BackpackGrids = world.read_model((player, *x + i, *y + j));
                                grid.occupied = true;
                                grid.inventoryItemId = inventoryCounter.count;
                                grid.itemId = storageItem.itemId;
                                grid.isWeapon = item.itemType == 1;
                                grid.isPlugin = item.isPlugin;
                                world.write_model(@grid);
                                j += 1;
                            };
                            i += 1;
                        };
                    }
                }
                
                i += 1;
            };
            
            // Execute all operations atomically after validation
            i = 0;
            loop {
                if i >= updates.len() {
                    break;
                }
                
                let update = updates.at(i);
                match update {
                    InventoryUpdate::Move((inventory_item_id, x, y, rotation)) => {
                        let mut inventoryItem: CharacterItemInventory = world.read_model((player, *inventory_item_id));
                        
                        // Clear old position if different
                        if inventoryItem.position.x != *x || inventoryItem.position.y != *y {
                            let mut old_slot: CharacterItemInventory = world.read_model((player, (inventoryItem.position.x, inventoryItem.position.y)));
                            old_slot.itemId = 0;
                            old_slot.position.x = 0;
                            old_slot.position.y = 0;
                            old_slot.rotation = 0;
                            old_slot.plugins = array![];
                            world.write_model(@old_slot);
                        }
                        
                        // Update item position
                        inventoryItem.position.x = *x;
                        inventoryItem.position.y = *y;
                        inventoryItem.rotation = *rotation;
                        world.write_model(@inventoryItem);
                        
                        // Create new slot mapping
                        let new_slot = CharacterItemInventory {
                            player,
                            id: (*x, *y),
                            itemId: inventoryItem.itemId,
                            position: inventoryItem.position,
                            rotation: *rotation,
                            plugins: inventoryItem.plugins
                        };
                        world.write_model(@new_slot);
                    },
                    InventoryUpdate::BuyAndPlace((item_id, x, y, rotation)) => {
                        let mut playerChar: Character = world.read_model(player);
                        let item: Item = world.read_model(*item_id);
                        
                        // Deduct gold
                        playerChar.gold -= item.price;
                        world.write_model(@playerChar);
                        
                        // Create inventory item
                        let new_item = CharacterItemInventory {
                            player,
                            id: (*x, *y),
                            itemId: *item_id,
                            position: Position { x: *x, y: *y },
                            rotation: *rotation,
                            plugins: array![]
                        };
                        world.write_model(@new_item);
                    },
                    InventoryUpdate::SellFromInventory(inventory_item_id) => {
                        let inventoryItem: CharacterItemInventory = world.read_model((player, *inventory_item_id));
                        let item: Item = world.read_model(inventoryItem.itemId);
                        let mut playerChar: Character = world.read_model(player);
                        
                        // Add gold (typically 50% of item price)
                        playerChar.gold += item.price / 2;
                        world.write_model(@playerChar);
                        
                        // Clear inventory slot
                        let mut cleared_slot: CharacterItemInventory = world.read_model((player, (inventoryItem.position.x, inventoryItem.position.y)));
                        cleared_slot.itemId = 0;
                        cleared_slot.position.x = 0;
                        cleared_slot.position.y = 0;
                        cleared_slot.rotation = 0;
                        cleared_slot.plugins = array![];
                        world.write_model(@cleared_slot);
                    },
                    InventoryUpdate::SellFromStorage(storage_item_id) => {
                        let storageItem: CharacterItemStorage = world.read_model((player, *storage_item_id));
                        let item: Item = world.read_model(storageItem.itemId);
                        let mut playerChar: Character = world.read_model(player);
                        
                        // Add gold (typically 50% of item price)
                        playerChar.gold += item.price / 2;
                        world.write_model(@playerChar);
                        
                        // Clear storage slot
                        let mut cleared_slot: CharacterItemStorage = world.read_model((player, *storage_item_id));
                        cleared_slot.itemId = 0;
                        world.write_model(@cleared_slot);
                    },
                    InventoryUpdate::PlaceFromStorage((storage_item_id, x, y, rotation)) => {
                        let storageItem: CharacterItemStorage = world.read_model((player, *storage_item_id));
                        let item: Item = world.read_model(storageItem.itemId);
                        let mut playerChar: Character = world.read_model(player);
                        
                        // Deduct gold
                        playerChar.gold -= item.price;
                        world.write_model(@playerChar);
                        
                        // Create storage item
                        let new_item = CharacterItemStorage {
                            player,
                            id: *storage_item_id,
                            itemId: *storage_item_id,
                        };
                        world.write_model(@new_item);
                    }
                }
                
                i += 1;
            };
            
            // Emit batch event
            world.emit_event(@InventoryBatchUpdated { player, updates_count: updates.len() });
        }

        fn initialize_shop(ref self: ContractState) {
            let mut world = self.world(@"Warpacks");
            let player = get_caller_address();
            
            let char: Character = world.read_model(player);
            
            // Generate initial shop items using shop system logic
            let (item1, item2, item3, item4) = self.generate_shop_items_internal(char.wins);
            
            // Create shop with initial items and 1 free reroll
            let shop = Shop {
                player,
                item1,
                item2,
                item3,
                item4,
                free_rerolls: 1,
                rerolls_since_fight: 0,
            };
            
            world.write_model(@shop);
        }

        fn give_free_shop_reroll(ref self: ContractState) {
            let mut world = self.world(@"Warpacks");
            let player = get_caller_address();
            
            let mut shop: Shop = world.read_model(player);
            shop.free_rerolls += 1;
            world.write_model(@shop);
        }

        fn generate_shop_items_internal(self: @ContractState, wins: u32) -> (u32, u32, u32, u32) {
            let mut world = self.world(@"Warpacks");
            
            // TODO: Will move these arrays after Dojo supports storing array
            let mut common: Array<u32> = ArrayTrait::new();
            let mut rare: Array<u32> = ArrayTrait::new();
            let mut legendary: Array<u32> = ArrayTrait::new();

            let itemsCounter: ItemsCounter = world.read_model(ITEMS_COUNTER_ID);
            let mut count = itemsCounter.count;

            loop {
                if count == 0 {
                    break;
                }

                let item: Item = world.read_model(count);

                match item.rarity {
                    0 => {},
                    1 => {
                        common.append(count);
                    },
                    2 => {
                        rare.append(count);
                    },
                    3 => {
                        legendary.append(count);
                    },
                    _ => {},
                }

                count -= 1;
            };

            assert(common.len() > 0, 'No common items found');

            let (seed1, seed2, seed3, seed4) = pseudo_seed();

            let mut items: Array<u32> = ArrayTrait::new();

            // common: 70%, rare: 20%, legendary: 10%
            for seed in array![seed1, seed2, seed3, seed4] {
                let mut random_index = 0;

                if wins < 3 {
                    random_index = random(seed, 90);
                } else {
                    random_index = random(seed, 100);
                }

                let itemId = if random_index < 70 {
                    random_index = random(seed, common.len());
                    *common.at(random_index)
                } else if random_index < 90 {
                    random_index = random(seed, rare.len());
                    *rare.at(random_index)
                } else {
                    random_index = random(seed, legendary.len());
                    *legendary.at(random_index)
                };

                items.append(itemId);
            };

            (*items.at(0), *items.at(1), *items.at(2), *items.at(3))
        }
    }
}
