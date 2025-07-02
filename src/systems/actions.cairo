use warpack_masters::models::Character::WMClass;
use starknet::ContractAddress;

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
    fn move_item_from_storage_to_inventory(
        ref self: T, storage_item_id: u32, x: u32, y: u32, rotation: u32
    );
    fn move_item_from_inventory_to_storage(ref self: T, inventory_item_id: u32);
    fn get_balance(self: @T) -> u256;
    fn withdraw_strk(ref self: T, amount: u256, recipient: ContractAddress);
    fn move_item_within_inventory(ref self: T, inventory_item_id: u32, x: u32, y: u32, rotation: u32);
    fn move_item_from_shop_to_storage(ref self: T, item_id: u32);
    fn move_item_from_storage_to_shop(ref self: T, storage_item_id: u32);
    fn move_item_from_shop_to_inventory(ref self: T, item_id: u32, x: u32, y: u32, rotation: u32);
    fn move_item_from_inventory_to_shop(ref self: T, inventory_item_id: u32);
    fn craft_item(ref self: T, recipe_id: u32, storage_ids: Array<u32>);
}

// TODO: rename the count filed in counter model

#[dojo::contract]
mod actions {
    use super::{IActions, WMClass};
    use starknet::ContractAddress;
    use core::dict::Felt252Dict;
    use core::array::Array;
    use core::bytes_31::bytes31;

    use starknet::{get_caller_address, get_block_timestamp};
    use warpack_masters::models::{backpack::{BackpackGrids}};
    use warpack_masters::models::{
        CharacterItem::{
            Position, CharacterItemsStorageCounter, CharacterItemStorage, CharacterItemInventory,
            CharacterItemsInventoryCounter
        },
        Item::{Item},
        Character::{Characters, NameRecord},
        Shop::Shop,
        Fight::{BattleLog, BattleLogCounter},
        Game::GameConfig,
        Recipe::Recipe
    };

    use warpack_masters::items::{Backpack, Pack};
    use warpack_masters::constants::constants::{GRID_X, GRID_Y, INIT_GOLD, INIT_HEALTH, INIT_STAMINA, REBIRTH_FEE, GAME_CONFIG_ID};

    use dojo::model::{ModelStorage};

    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    use dojo::world::{IWorldDispatcherTrait};

    use dojo::event::EventStorage;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event(historical: true)]
    struct BuyItem {
        #[key]
        player: ContractAddress,
        itemId: u32,
        cost: u32,
        itemRarity: u8,
        birthCount: u32,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event(historical: true)]
    struct SellItem {
        #[key]
        player: ContractAddress,
        itemId: u32,
        price: u32,
        itemRarity: u8,
        birthCount: u32,
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
            assert(len <= 12 && len >= 3, 'name size is invalid');

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

            self.move_item_from_storage_to_inventory(1, 4, 2, 0);
            self.move_item_from_storage_to_inventory(2, 2, 2, 0);

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

            inventoryItemsCounter.count = 0;
            storageItemsCounter.count = 0;

            world.write_model(@char);
            world.write_model(@shop);
            world.write_model(@inventoryItemsCounter);
            world.write_model(@storageItemsCounter);

            self.spawn(prev_name, char.wmClass);
        }

        fn withdraw_strk(ref self: ContractState, amount: u256, recipient: ContractAddress) {
            let mut world = self.world(@"Warpacks");

            let caller = get_caller_address();
            assert(world.dispatcher.is_owner(0, caller), 'caller not world owner');

            let gameConfig: GameConfig = world.read_model(GAME_CONFIG_ID);
            let STRK_ADDRESS: ContractAddress = gameConfig.strk_address;
            IERC20Dispatcher { contract_address: STRK_ADDRESS }
                .transfer(recipient, amount);
        }

        fn get_balance(self: @ContractState) -> u256 {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            let gameConfig: GameConfig = world.read_model(GAME_CONFIG_ID);
            let STRK_ADDRESS: ContractAddress = gameConfig.strk_address;
            return IERC20Dispatcher { contract_address: STRK_ADDRESS }
                .balance_of(player);
        }
        
        fn move_item_from_storage_to_inventory(
            ref self: ContractState, storage_item_id: u32, x: u32, y: u32, rotation: u32
        ) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            // check if the player has joined the matching battle
            self._check_if_player_has_joined_a_matched_battle(player);

            assert(x < GRID_X, 'x out of range');
            assert(y < GRID_Y, 'y out of range');
            assert(
                rotation == 0 || rotation == 90 || rotation == 180 || rotation == 270,
                'invalid rotation'
            );

            let mut storageItem: CharacterItemStorage = world.read_model((player, storage_item_id));

            assert(storageItem.itemId != 0, 'item not found');

            let itemId = storageItem.itemId;
            
            self._add_item_to_inventory(player, itemId, x, y, rotation);

            storageItem.itemId = 0;
            world.write_model(@storageItem);
        }

        fn move_item_from_inventory_to_storage(ref self: ContractState, inventory_item_id: u32) {
            let player = get_caller_address();

            // check if the player has joined the matching battle
            self._check_if_player_has_joined_a_matched_battle(player);

            let item_id = self._remove_item_from_inventory(player, inventory_item_id);
        
            self._add_item_to_storage(player, item_id);
        }

        fn move_item_within_inventory(ref self: ContractState, inventory_item_id: u32, x: u32, y: u32, rotation: u32) {
            let player = get_caller_address();

            // check if the player has joined the matching battle
            self._check_if_player_has_joined_a_matched_battle(player);

            let itemId = self._remove_item_from_inventory(player, inventory_item_id);
            self._add_item_to_inventory(player, itemId, x, y, rotation);
        }

        fn move_item_from_shop_to_storage(ref self: ContractState, item_id: u32) {
            let player = get_caller_address();

            self._buy_item(player, item_id);

            self._add_item_to_storage(player, item_id);
        }

        fn move_item_from_storage_to_shop(ref self: ContractState, storage_item_id: u32) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            let mut storageItem: CharacterItemStorage = world.read_model((player, storage_item_id));
            let item_id = storageItem.itemId;
            assert(item_id != 0, 'invalid item_id');

            self._sell_item(player, item_id);

            storageItem.itemId = 0;
            world.write_model(@storageItem);
        }

        fn move_item_from_shop_to_inventory(ref self: ContractState, item_id: u32, x: u32, y: u32, rotation: u32) {
            let player = get_caller_address();

            self._buy_item(player, item_id);

            self._add_item_to_inventory(player, item_id, x, y, rotation);
        }

        fn move_item_from_inventory_to_shop(ref self: ContractState, inventory_item_id: u32) {
            let player = get_caller_address();

            let item_id = self._remove_item_from_inventory(player, inventory_item_id);
            self._sell_item(player, item_id);
        }

        fn craft_item(
            ref self: ContractState, recipe_id: u32, storage_ids: Array<u32>
        ) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            let recipe: Recipe = world.read_model(recipe_id);
            assert(recipe.enabled, 'recipe is not enabled');

            let item_ids_len = recipe.item_ids.len();
            assert(item_ids_len > 0, 'must have at least one item');
            assert(item_ids_len == recipe.item_amounts.len(), 'must the same length');

            let mut required_items: Felt252Dict<u32> = Default::default();
            for i in 0..item_ids_len {
                let item_id = *recipe.item_ids[i];
                let item_amount = *recipe.item_amounts[i];
                required_items.insert(item_id.into(), item_amount);
            };

            let storage_ids_len = storage_ids.len();
            assert(storage_ids_len > 0, 'must have at least one item');

            for i in 0..storage_ids_len {
                let storage_id = *storage_ids[i];
                let mut storage_item: CharacterItemStorage = world.read_model((player, storage_id));
                assert(storage_item.itemId != 0, 'item not owned');

                let required_item_amount = required_items.get(storage_item.itemId.into());
                if (required_item_amount > 0) {
                    required_items.insert(storage_item.itemId.into(), required_item_amount - 1);
                    storage_item.itemId = 0;
                    world.write_model(@storage_item);
                }
            };

            for i in 0..item_ids_len {
                let item_id = *recipe.item_ids[i];

                assert(required_items.get(item_id.into()) == 0, 'item not enough');
            };

            self._add_item_to_storage(player, recipe.result_item_id);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _check_if_player_has_joined_a_matched_battle(ref self: ContractState, player: ContractAddress) {
            let mut world = self.world(@"Warpacks");

            let mut battleLogCounter: BattleLogCounter = world.read_model(player);
            let latestBattleLog: BattleLog = world.read_model((player, battleLogCounter.count));
            assert(battleLogCounter.count == 0 || latestBattleLog.winner != 0, 'matched battle not joined');
        }

        fn _remove_item_from_inventory(ref self: ContractState, player: ContractAddress, inventory_item_id: u32) -> u32 {
            let mut world = self.world(@"Warpacks");

            let mut inventoryItem: CharacterItemInventory = world.read_model((player, inventory_item_id));
            let itemId = inventoryItem.itemId;
            assert(itemId != 0, 'item not found');
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

            inventoryItem.itemId = 0;
            inventoryItem.position.x = 0;
            inventoryItem.position.y = 0;
            inventoryItem.rotation = 0;
            inventoryItem.plugins = array![];
            world.write_model(@inventoryItem);

            itemId
        }

        fn _add_item_to_inventory(ref self: ContractState, player: ContractAddress, itemId: u32, x: u32, y: u32, rotation: u32) {
            let mut world = self.world(@"Warpacks");

            let item: Item = world.read_model(itemId);

            assert(item.width > 0 && item.height > 0, 'invalid item dimensions');

            let itemHeight = item.height;
            let itemWidth = item.width;
            let isWeapon = if item.itemType == 1 || item.itemType == 2 {
                true
            } else {
                false
            };

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

            world.write_model(@inventoryItem);
            world.write_model(@inventoryCounter);
            
        }

        fn _buy_item(ref self: ContractState, player: ContractAddress, item_id: u32) {
            assert(item_id != 0, 'invalid item_id');

            let mut world = self.world(@"Warpacks");

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

            assert(player_char.gold >= item.price, 'Not enough gold');
            player_char.gold -= item.price;

            //delete respective item bought from the shop
            if (shop_data.item1 == item_id) {
                shop_data.item1 = 0
            } else if (shop_data.item2 == item_id) {
                shop_data.item2 = 0
            } else if (shop_data.item3 == item_id) {
                shop_data.item3 = 0
            } else if (shop_data.item4 == item_id) {
                shop_data.item4 = 0
            }

            world.emit_event(@BuyItem {
                player,
                itemId: item_id,
                cost: item.price,
                itemRarity: item.rarity,
                birthCount: player_char.birthCount
            });

            world.write_model(@player_char);
            world.write_model(@shop_data);
        }

        fn _sell_item(ref self: ContractState, player: ContractAddress, item_id: u32) {
            let mut world = self.world(@"Warpacks");

            let item: Item = world.read_model(item_id);
            let mut playerChar: Characters = world.read_model(player);

            let item_price = item.price;
            let sell_price = item_price / 2;

            playerChar.gold += sell_price;

            world.emit_event(@SellItem {
                player,
                itemId: item_id,
                price: sell_price,
                itemRarity: item.rarity,
                birthCount: playerChar.birthCount
            });

            world.write_model(@playerChar);
        }

        fn _add_item_to_storage(ref self: ContractState, player: ContractAddress, item_id: u32) {
            let mut world = self.world(@"Warpacks");

            let mut storageCounter: CharacterItemsStorageCounter = world.read_model(player);
            let mut count = storageCounter.count;
            loop {
                if count == 0 {
                    break;
                }

                let mut storageItem: CharacterItemStorage = world.read_model((player, count));
                if storageItem.itemId == 0 {
                    storageItem.itemId = item_id;
                    world.write_model(@storageItem);
                    break;
                }

                count -= 1;
            };

            if count == 0 {
                storageCounter.count += 1;
                world.write_model(@CharacterItemStorage { player, id: storageCounter.count, itemId: item_id });
                world.write_model(@storageCounter);
            }
        }
    }
}
