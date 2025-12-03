use starknet::ContractAddress;
use warpack_masters::models::Character::WMClass;

#[starknet::interface]
pub trait IActions<T> {
    fn spawn(ref self: T, name: felt252, wmClass: WMClass);
    fn rebirth(ref self: T);
    fn move_item_from_storage_to_inventory(
        ref self: T, storage_item_id: u32, x: u32, y: u32, rotation: u32,
    );
    fn move_item_from_inventory_to_storage(ref self: T, inventory_item_id: u32);
    fn get_balance(self: @T) -> u256;
    fn withdraw_strk(ref self: T, amount: u256, recipient: ContractAddress);
    fn move_item_within_inventory(
        ref self: T, inventory_item_id: u32, x: u32, y: u32, rotation: u32,
    );
    fn move_item_from_shop_to_storage(ref self: T, item_id: u32);
    fn move_item_from_storage_to_shop(ref self: T, storage_item_id: u32);
    fn move_item_from_shop_to_inventory(ref self: T, item_id: u32, x: u32, y: u32, rotation: u32);
    fn move_item_from_inventory_to_shop(ref self: T, inventory_item_id: u32);
    fn craft_item(ref self: T, recipe_id: u32, storage_ids: Array<u32>);
}

// TODO: rename the count filed in counter model

#[dojo::contract]
mod actions {
    use core::array::{Array, ArrayTrait, SpanTrait};
    use core::bytes_31::bytes31;
    use core::dict::Felt252Dict;
    use core::traits::TryInto;
    use dojo::event::EventStorage;
    use dojo::model::ModelStorage;
    use dojo::world::{IWorldDispatcherTrait, WorldStorage};
    use openzeppelin_interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};
    use warpack_masters::constants::constants::{
        GAME_CONFIG_ID, GOLD_ITEM_ID, GRID_X, GRID_Y, INIT_GOLD, INIT_HEALTH, INIT_STAMINA,
        MAX_LOSSES_BEFORE_REBIRTH, REBIRTH_FEE,
    };
    use warpack_masters::externals::interface::{
        IERC20MINTABLEDispatcher, IERC20MINTABLEDispatcherTrait,
    };
    use warpack_masters::items::{Backpack, Pack};
    use warpack_masters::models::Character::{Character, CharacterName, Characters};
    use warpack_masters::models::CharacterItem::{
        InventoryCounter, InventoryItem, Position, StorageCounter, StorageItem,
    };
    use warpack_masters::models::Fight::{BattleLog, BattleLogCounter};
    use warpack_masters::models::Game::GameConfig;
    use warpack_masters::models::Item::Item;
    use warpack_masters::models::Recipe::RecipeV2;
    use warpack_masters::models::TokenRegistry::TokenRegistry;
    use warpack_masters::models::backpack::BackpackGrids;
    use warpack_masters::utils::storage_pointers as ptrs;
    use super::{IActions, WMClass};

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
        fn spawn(ref self: ContractState, name: felt252, wmClass: WMClass) {
            self._spawn_with_fee(name, wmClass, true);
        }

        fn rebirth(ref self: ContractState) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            let char_ptr = ptrs::character(player);
            let mut char: Character = world.read_model(player);

            assert(char.loss >= MAX_LOSSES_BEFORE_REBIRTH.into(), 'loss not reached');

            let gameConfig: GameConfig = self._load_game_config(ref world);
            let STRK_ADDRESS: ContractAddress = gameConfig.strk_address;
            self._collect_rebirth_fee(player, gameConfig.rebirth_fee, STRK_ADDRESS);

            let prev_name = char.name;
            // required to calling spawn doesn't fail
            world
                .write_member(
                    char_ptr,
                    selector!("name"),
                    '',
                );

            let inventory_counter_ptr = ptrs::inventory_counter(player);
            let mut count = world.read_member(inventory_counter_ptr, selector!("count"));

            loop {
                if count == 0 {
                    break;
                }

                let item_ptr = ptrs::inventory_item(player, count);
                world.write_member(item_ptr, selector!("itemId"), 0);
                world.write_member(item_ptr, selector!("position"), Position { x: 0, y: 0 });
                world.write_member(item_ptr, selector!("rotation"), 0);
                world.write_member(item_ptr, selector!("plugins"), ArrayTrait::<(u8, u32, u32)>::new());

                count -= 1;
            }

            let storage_counter_ptr = ptrs::storage_counter(player);
            let mut count = world.read_member(storage_counter_ptr, selector!("count"));

            loop {
                if count == 0 {
                    break;
                }

                let storage_item_ptr = ptrs::storage_item(player, count);
                world.write_member(storage_item_ptr, selector!("itemId"), 0);

                count -= 1;
            }

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

                    let grid_ptr = ptrs::backpack_grid(player, i, j);
                    let grid_enabled: bool = world.read_member(grid_ptr, selector!("enabled"));
                    let grid_occupied: bool = world.read_member(grid_ptr, selector!("occupied"));

                    if grid_enabled || grid_occupied {
                        world.write_member(grid_ptr, selector!("enabled"), false);
                        world.write_member(grid_ptr, selector!("occupied"), false);
                        world.write_member(grid_ptr, selector!("itemId"), 0);
                        world.write_member(grid_ptr, selector!("inventoryItemId"), 0);
                        world.write_member(grid_ptr, selector!("isWeapon"), false);
                        world.write_member(grid_ptr, selector!("isPlugin"), false);
                    }
                    j += 1;
                }
                j = 0;
                i += 1;
            }

            // clear shop
            let shop_ptr = ptrs::shop(player);
            world.write_member(shop_ptr, selector!("item1"), 0);
            world.write_member(shop_ptr, selector!("item2"), 0);
            world.write_member(shop_ptr, selector!("item3"), 0);
            world.write_member(shop_ptr, selector!("item4"), 0);

            world.write_member(inventory_counter_ptr, selector!("count"), 0);
            world.write_member(storage_counter_ptr, selector!("count"), 0);

            world.write_member(char_ptr, selector!("loss"), char.loss);
            world.write_member(char_ptr, selector!("rating"), char.rating);
            world.write_member(char_ptr, selector!("totalWins"), char.totalWins);
            world.write_member(char_ptr, selector!("totalLoss"), char.totalLoss);
            world.write_member(char_ptr, selector!("winStreak"), char.winStreak);
            world.write_member(char_ptr, selector!("birthCount"), char.birthCount);
            world.write_member(char_ptr, selector!("stamina"), char.stamina);
            world.write_member(char_ptr, selector!("updatedAt"), char.updatedAt);

            self._spawn_with_fee(prev_name, char.wmClass, false);
        }

        fn withdraw_strk(ref self: ContractState, amount: u256, recipient: ContractAddress) {
            let mut world = self.world(@"Warpacks");

            let caller = get_caller_address();
            assert(world.dispatcher.is_owner(0, caller), 'caller not world owner');

            let gameConfig: GameConfig = self._load_game_config(ref world);
            let STRK_ADDRESS: ContractAddress = gameConfig.strk_address;
            IERC20Dispatcher { contract_address: STRK_ADDRESS }.transfer(recipient, amount);
        }

        fn get_balance(self: @ContractState) -> u256 {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            let zero_address: ContractAddress = 0.try_into().unwrap();
            let gameConfig: GameConfig = world.read_model(GAME_CONFIG_ID);
            if gameConfig.id == 0 || gameConfig.strk_address == zero_address {
                return 0;
            }

            IERC20Dispatcher { contract_address: gameConfig.strk_address }.balance_of(player)
        }

        fn move_item_from_storage_to_inventory(
            ref self: ContractState, storage_item_id: u32, x: u32, y: u32, rotation: u32,
        ) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            // check if the player has joined the matching battle
            self._check_if_player_has_joined_a_matched_battle(player);

            assert(x < GRID_X, 'x out of range');
            assert(y < GRID_Y, 'y out of range');
            assert(
                rotation == 0 || rotation == 90 || rotation == 180 || rotation == 270,
                'invalid rotation',
            );

            let storage_item_ptr = ptrs::storage_item(player, storage_item_id);
            let itemId: u32 = world.read_member(storage_item_ptr, selector!("itemId"));

            assert(itemId != 0, 'item not found');

            self._add_item_to_inventory(player, itemId, x, y, rotation);

            world.write_member(storage_item_ptr, selector!("itemId"), 0);
        }

        fn move_item_from_inventory_to_storage(ref self: ContractState, inventory_item_id: u32) {
            let player = get_caller_address();

            // check if the player has joined the matching battle
            self._check_if_player_has_joined_a_matched_battle(player);

            let item_id = self._remove_item_from_inventory(player, inventory_item_id);

            self._add_item_to_storage(player, item_id);
        }

        fn move_item_within_inventory(
            ref self: ContractState, inventory_item_id: u32, x: u32, y: u32, rotation: u32,
        ) {
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

            let storage_item_ptr = ptrs::storage_item(player, storage_item_id);
            let item_id: u32 = world.read_member(storage_item_ptr, selector!("itemId"));
            assert(item_id != 0, 'invalid item_id');

            self._sell_item(player, item_id);

            world.write_member(storage_item_ptr, selector!("itemId"), 0);
        }

        fn move_item_from_shop_to_inventory(
            ref self: ContractState, item_id: u32, x: u32, y: u32, rotation: u32,
        ) {
            let player = get_caller_address();

            self._buy_item(player, item_id);

            self._add_item_to_inventory(player, item_id, x, y, rotation);
        }

        fn move_item_from_inventory_to_shop(ref self: ContractState, inventory_item_id: u32) {
            let player = get_caller_address();

            let item_id = self._remove_item_from_inventory(player, inventory_item_id);
            self._sell_item(player, item_id);
        }

        fn craft_item(ref self: ContractState, recipe_id: u32, storage_ids: Array<u32>) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            let recipe: RecipeV2 = world.read_model(recipe_id);
            assert(recipe.enabled, 'recipe is not enabled');

            let item_ids_len = recipe.item_ids.len();
            assert(item_ids_len > 0, 'must have at least one item');
            assert(item_ids_len == recipe.item_amounts.len(), 'must the same length');

            let mut required_items: Felt252Dict<u32> = Default::default();
            for i in 0..item_ids_len {
                let item_id = *recipe.item_ids[i];
                let item_amount = *recipe.item_amounts[i];
                required_items.insert(item_id.into(), item_amount);
            }

            let storage_ids_len = storage_ids.len();
            assert(storage_ids_len > 0, 'must have at least one item');

            for i in 0..storage_ids_len {
                let storage_id = *storage_ids[i];
                let storage_item_ptr = ptrs::storage_item(player, storage_id);
                let storage_item_id: u32 = world.read_member(storage_item_ptr, selector!("itemId"));
                assert(storage_item_id != 0, 'item not owned');

                let required_item_amount = required_items.get(storage_item_id.into());
                if (required_item_amount > 0) {
                    required_items.insert(storage_item_id.into(), required_item_amount - 1);
                    world.write_member(storage_item_ptr, selector!("itemId"), 0);
                }
            }

            for i in 0..item_ids_len {
                let item_id = *recipe.item_ids[i];

                assert(required_items.get(item_id.into()) == 0, 'item not enough');
            }

            self._add_item_to_storage(player, recipe.result_item_id);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _check_if_player_has_joined_a_matched_battle(
            ref self: ContractState, player: ContractAddress,
        ) {
            let mut world = self.world(@"Warpacks");

            let mut battleLogCounter: BattleLogCounter = world.read_model(player);
            let latestBattleLog: BattleLog = world.read_model((player, battleLogCounter.count));
            assert(
                battleLogCounter.count == 0 || latestBattleLog.winner != 0,
                'matched battle not joined',
            );
        }

        fn _remove_item_from_inventory(
            ref self: ContractState, player: ContractAddress, inventory_item_id: u32,
        ) -> u32 {
            let mut world = self.world(@"Warpacks");

            let inventory_item_ptr = ptrs::inventory_item(player, inventory_item_id);
            let itemId: u32 = world.read_member(inventory_item_ptr, selector!("itemId"));
            assert(itemId != 0, 'item not found');
            let item: Item = world.read_model(itemId);

            let position: Position = world.read_member(inventory_item_ptr, selector!("position"));
            let rotation: u32 = world.read_member(inventory_item_ptr, selector!("rotation"));
            let (x, y) = (position.x, position.y);

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

                    let grid_ptr = ptrs::backpack_grid(player, i, j);
                    let mut playerBackpackGrids: BackpackGrids = world.read_model((player, i, j));
                    if item.itemType == 4 {
                        assert(!playerBackpackGrids.occupied, 'Already occupied');
                        world.write_member(grid_ptr, selector!("enabled"), false);
                    } else {
                        assert(playerBackpackGrids.enabled, 'Grid not enabled');
                        assert(playerBackpackGrids.occupied, 'Grid not occupied');
                        assert(
                            playerBackpackGrids.inventoryItemId == inventory_item_id,
                            'Invalid inventory item id',
                        );
                        assert(playerBackpackGrids.itemId == itemId, 'Invalid item id');
                        assert(playerBackpackGrids.isWeapon == isWeapon, 'Invalid item type');
                        assert(
                            playerBackpackGrids.isPlugin == item.isPlugin,
                            'Is not aligned with plugin',
                        );

                        world.write_member(grid_ptr, selector!("occupied"), false);
                        world.write_member(grid_ptr, selector!("itemId"), 0);
                        world.write_member(grid_ptr, selector!("inventoryItemId"), 0);
                        world.write_member(grid_ptr, selector!("isWeapon"), false);
                        world.write_member(grid_ptr, selector!("isPlugin"), false);

                        // to check around if it is a plugin
                        if item.isPlugin {
                            // left
                            if i > 0 && i == x {
                                let grid: BackpackGrids = world.read_model((player, i - 1, j));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let weapon_ptr = ptrs::inventory_item(player, grid.inventoryItemId);
                                    let plugins: Array<(u8, u32, u32)> = world
                                        .read_member(weapon_ptr, selector!("plugins"));
                                    let mut filtered: Array<(u8, u32, u32)> = ArrayTrait::new();
                                    let mut idx = 0;
                                    loop {
                                        if idx >= plugins.len() {
                                            break;
                                        }
                                        let current = plugins.span().at(idx);
                                        if *current != (item.effectType, item.chance, item.effectStacks) {
                                            filtered.append(*current);
                                        }
                                        idx += 1;
                                    }
                                    world.write_member(weapon_ptr, selector!("plugins"), filtered);
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            // top
                            if j < GRID_Y - 1 && j == yMax {
                                let grid: BackpackGrids = world.read_model((player, i, j + 1));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let weapon_ptr = ptrs::inventory_item(player, grid.inventoryItemId);
                                    let plugins: Array<(u8, u32, u32)> = world
                                        .read_member(weapon_ptr, selector!("plugins"));
                                    let mut filtered: Array<(u8, u32, u32)> = ArrayTrait::new();
                                    let mut idx = 0;
                                    loop {
                                        if idx >= plugins.len() {
                                            break;
                                        }
                                        let current = plugins.span().at(idx);
                                        if *current != (item.effectType, item.chance, item.effectStacks) {
                                            filtered.append(*current);
                                        }
                                        idx += 1;
                                    }
                                    world.write_member(weapon_ptr, selector!("plugins"), filtered);
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            // right
                            if i < GRID_X - 1 && i == xMax {
                                let grid: BackpackGrids = world.read_model((player, i + 1, j));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let weapon_ptr = ptrs::inventory_item(player, grid.inventoryItemId);
                                    let plugins: Array<(u8, u32, u32)> = world
                                        .read_member(weapon_ptr, selector!("plugins"));
                                    let mut filtered: Array<(u8, u32, u32)> = ArrayTrait::new();
                                    let mut idx = 0;
                                    loop {
                                        if idx >= plugins.len() {
                                            break;
                                        }
                                        let current = plugins.span().at(idx);
                                        if *current != (item.effectType, item.chance, item.effectStacks) {
                                            filtered.append(*current);
                                        }
                                        idx += 1;
                                    }
                                    world.write_member(weapon_ptr, selector!("plugins"), filtered);
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                            // bottom
                            if j > 0 && j == y {
                                let grid: BackpackGrids = world.read_model((player, i, j - 1));
                                if !isHandled.get(grid.inventoryItemId.into()) && grid.isWeapon {
                                    let weapon_ptr = ptrs::inventory_item(player, grid.inventoryItemId);
                                    let plugins: Array<(u8, u32, u32)> = world
                                        .read_member(weapon_ptr, selector!("plugins"));
                                    let mut filtered: Array<(u8, u32, u32)> = ArrayTrait::new();
                                    let mut idx = 0;
                                    loop {
                                        if idx >= plugins.len() {
                                            break;
                                        }
                                        let current = plugins.span().at(idx);
                                        if *current != (item.effectType, item.chance, item.effectStacks) {
                                            filtered.append(*current);
                                        }
                                        idx += 1;
                                    }
                                    world.write_member(weapon_ptr, selector!("plugins"), filtered);
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                        }
                    }

                    j += 1;
                }
                j = y;
                i += 1;
            }
            world.write_member(inventory_item_ptr, selector!("itemId"), 0);
            world.write_member(inventory_item_ptr, selector!("position"), Position { x: 0, y: 0 });
            world.write_member(inventory_item_ptr, selector!("rotation"), 0);
            world.write_member(inventory_item_ptr, selector!("plugins"), ArrayTrait::<(u8, u32, u32)>::new());

            itemId
        }

        fn _add_item_to_inventory(
            ref self: ContractState,
            player: ContractAddress,
            itemId: u32,
            x: u32,
            y: u32,
            rotation: u32,
        ) {
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

            let inventory_counter_ptr = ptrs::inventory_counter(player);
            let current_count: u32 = world.read_member(inventory_counter_ptr, selector!("count"));

            let mut slot: u32 = 0;
            let mut probe = current_count;
            loop {
                if probe == 0 {
                    break;
                }

                let item_ptr = ptrs::inventory_item(player, probe);
                let existing_item_id: u32 = world.read_member(item_ptr, selector!("itemId"));
                if existing_item_id == 0 {
                    slot = probe;
                    break;
                }

                probe -= 1;
            }

            if slot == 0 {
                let new_count = current_count + 1;
                world.write_member(inventory_counter_ptr, selector!("count"), new_count);
                slot = new_count;

                let empty_item = InventoryItem {
                    player,
                    id: slot,
                    itemId: 0,
                    position: Position { x: 0, y: 0 },
                    rotation: 0,
                    plugins: ArrayTrait::new(),
                };
                world.write_model(@empty_item);
            }

            let inventory_item_ptr = ptrs::inventory_item(player, slot);
            let inventory_item_id = slot;
            let mut item_plugins: Array<(u8, u32, u32)> = ArrayTrait::new();

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
                    let grid_ptr = ptrs::backpack_grid(player, i, j);
                    if item.itemType == 4 {
                        assert(!playerBackpackGrids.enabled, 'Already enabled');
                        world.write_member(grid_ptr, selector!("enabled"), true);
                        world.write_member(grid_ptr, selector!("occupied"), false);
                        world.write_member(grid_ptr, selector!("itemId"), 0);
                        world.write_member(grid_ptr, selector!("inventoryItemId"), 0);
                        world.write_member(grid_ptr, selector!("isWeapon"), false);
                        world.write_member(grid_ptr, selector!("isPlugin"), false);
                    } else {
                        assert(playerBackpackGrids.enabled, 'Grid not enabled');
                        assert(!playerBackpackGrids.occupied, 'Already occupied');
                        world.write_member(grid_ptr, selector!("enabled"), true);
                        world.write_member(grid_ptr, selector!("occupied"), true);
                        world.write_member(grid_ptr, selector!("itemId"), itemId);
                        world.write_member(grid_ptr, selector!("inventoryItemId"), inventory_item_id);
                        world.write_member(grid_ptr, selector!("isWeapon"), isWeapon);
                        world.write_member(grid_ptr, selector!("isPlugin"), item.isPlugin);

                        // to check around if it is a weapon or plugin
                        if isWeapon || item.isPlugin {
                            // left
                            if i > 0 && i == x {
                                let grid: BackpackGrids = world.read_model((player, i - 1, j));
                                if !isHandled.get(grid.inventoryItemId.into()) {
                                    if isWeapon && grid.isPlugin {
                                        let plugin: Item = world.read_model(grid.itemId);
                                        item_plugins
                                            .append(
                                                (
                                                    plugin.effectType,
                                                    plugin.chance,
                                                    plugin.effectStacks,
                                                ),
                                            );
                                    } else if item.isPlugin && grid.isWeapon {
                                        let weapon_ptr = ptrs::inventory_item(player, grid.inventoryItemId);
                                        let mut weapon_plugins: Array<(u8, u32, u32)> = world
                                            .read_member(weapon_ptr, selector!("plugins"));
                                        weapon_plugins
                                            .append(
                                                (item.effectType, item.chance, item.effectStacks),
                                            );
                                        world.write_member(
                                            weapon_ptr,
                                            selector!("plugins"),
                                            weapon_plugins,
                                        );
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
                                        item_plugins
                                            .append(
                                                (
                                                    plugin.effectType,
                                                    plugin.chance,
                                                    plugin.effectStacks,
                                                ),
                                            );
                                    } else if item.isPlugin && grid.isWeapon {
                                        let weapon_ptr = ptrs::inventory_item(player, grid.inventoryItemId);
                                        let mut weapon_plugins: Array<(u8, u32, u32)> = world
                                            .read_member(weapon_ptr, selector!("plugins"));
                                        weapon_plugins
                                            .append(
                                                (item.effectType, item.chance, item.effectStacks),
                                            );
                                        world.write_member(
                                            weapon_ptr,
                                            selector!("plugins"),
                                            weapon_plugins,
                                        );
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
                                        item_plugins
                                            .append(
                                                (
                                                    plugin.effectType,
                                                    plugin.chance,
                                                    plugin.effectStacks,
                                                ),
                                            );
                                    } else if item.isPlugin && grid.isWeapon {
                                        let weapon_ptr = ptrs::inventory_item(player, grid.inventoryItemId);
                                        let mut weapon_plugins: Array<(u8, u32, u32)> = world
                                            .read_member(weapon_ptr, selector!("plugins"));
                                        weapon_plugins
                                            .append(
                                                (item.effectType, item.chance, item.effectStacks),
                                            );
                                        world.write_member(
                                            weapon_ptr,
                                            selector!("plugins"),
                                            weapon_plugins,
                                        );
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
                                        item_plugins
                                            .append(
                                                (
                                                    plugin.effectType,
                                                    plugin.chance,
                                                    plugin.effectStacks,
                                                ),
                                            );
                                    } else if item.isPlugin && grid.isWeapon {
                                        let weapon_ptr = ptrs::inventory_item(player, grid.inventoryItemId);
                                        let mut weapon_plugins: Array<(u8, u32, u32)> = world
                                            .read_member(weapon_ptr, selector!("plugins"));
                                        weapon_plugins
                                            .append(
                                                (item.effectType, item.chance, item.effectStacks),
                                            );
                                        world.write_member(
                                            weapon_ptr,
                                            selector!("plugins"),
                                            weapon_plugins,
                                        );
                                    }
                                    isHandled.insert(grid.inventoryItemId.into(), true);
                                }
                            }
                        }
                    }

                    j += 1;
                }
                j = y;
                i += 1;
            }
            world.write_member(inventory_item_ptr, selector!("itemId"), itemId);
            world.write_member(inventory_item_ptr, selector!("position"), Position { x, y });
            world.write_member(inventory_item_ptr, selector!("rotation"), rotation);
            world.write_member(inventory_item_ptr, selector!("plugins"), item_plugins);
        }

        fn _buy_item(ref self: ContractState, player: ContractAddress, item_id: u32) {
            assert(item_id != 0, 'invalid item_id');

            let mut world = self.world(@"Warpacks");

            let shop_ptr = ptrs::shop(player);
            let shop_item1: u32 = world.read_member(shop_ptr, selector!("item1"));
            let shop_item2: u32 = world.read_member(shop_ptr, selector!("item2"));
            let shop_item3: u32 = world.read_member(shop_ptr, selector!("item3"));
            let shop_item4: u32 = world.read_member(shop_ptr, selector!("item4"));
            assert(
                shop_item1 == item_id
                    || shop_item2 == item_id
                    || shop_item3 == item_id
                    || shop_item4 == item_id,
                'item not on sale',
            );

            let item: Item = world.read_model(item_id);
            let player_char: Characters = world.read_model(player);

            // assert(player_char.gold >= item.price, 'Not enough gold');
            // player_char.gold -= item.price;

            let price_amount: u256 = item.price.into();
            self._collect_gold_fee(player, price_amount);
            self._burn_gold(price_amount);

            //delete respective item bought from the shop
            if shop_item1 == item_id {
                world.write_member(shop_ptr, selector!("item1"), 0);
            } else {
                if shop_item2 == item_id {
                    world.write_member(shop_ptr, selector!("item2"), 0);
                } else {
                    if shop_item3 == item_id {
                        world.write_member(shop_ptr, selector!("item3"), 0);
                    } else {
                        world.write_member(shop_ptr, selector!("item4"), 0);
                    }
                }
            }

            world
                .emit_event(
                    @BuyItem {
                        player,
                        itemId: item_id,
                        cost: item.price,
                        itemRarity: item.rarity,
                        birthCount: player_char.birthCount,
                    },
                );

            // world.write_model(@player_char);
        }

        fn _sell_item(ref self: ContractState, player: ContractAddress, item_id: u32) {
            let mut world = self.world(@"Warpacks");

            let item: Item = world.read_model(item_id);
            let playerChar: Characters = world.read_model(player);

            let item_price = item.price;
            let sell_price = item_price / 2;

            // playerChar.gold += sell_price;
            self._mint_gold(player, sell_price.into());

            world
                .emit_event(
                    @SellItem {
                        player,
                        itemId: item_id,
                        price: sell_price,
                        itemRarity: item.rarity,
                        birthCount: playerChar.birthCount,
                    },
                );
            // world.write_model(@playerChar);
        }

        fn _add_item_to_storage(ref self: ContractState, player: ContractAddress, item_id: u32) {
            let mut world = self.world(@"Warpacks");

            let storage_counter_ptr = ptrs::storage_counter(player);
            let storage_count: u32 = world.read_member(storage_counter_ptr, selector!("count"));
            let mut slot = storage_count;
            loop {
                if slot == 0 {
                    break;
                }

                let ptr = ptrs::storage_item(player, slot);
                let current_item_id: u32 = world.read_member(ptr, selector!("itemId"));
                if current_item_id == 0 {
                    world.write_model(@StorageItem { player, id: slot, itemId: item_id });
                    return;
                }

                slot -= 1;
            }

            if slot == 0 {
                let new_count = storage_count + 1;
                world.write_member(storage_counter_ptr, selector!("count"), new_count);
                world.write_model(@StorageItem { player, id: new_count, itemId: item_id });
            }
        }

        fn _mint_gold(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            let mut world = self.world(@"Warpacks");

            let registry: TokenRegistry = world.read_model(GOLD_ITEM_ID);
            assert(
                registry.token_address != warpack_masters::utils::address::zero_address(),
                'Token not registered',
            );
            assert(registry.is_active, 'Token not active');

            // Mint tokens to the player
            let token_amount = amount * 1_000_000_000_000_000_000;
            let token_contract = IERC20MINTABLEDispatcher {
                contract_address: registry.token_address,
            };
            token_contract.mint(recipient, token_amount);
        }

        fn _burn_gold(ref self: ContractState, value: u256) {
            let mut world = self.world(@"Warpacks");

            let registry: TokenRegistry = world.read_model(GOLD_ITEM_ID);
            assert(
                registry.token_address != warpack_masters::utils::address::zero_address(),
                'Token not registered',
            );
            assert(registry.is_active, 'Token not active');

            // Mint tokens to the player
            let token_amount = value * 1_000_000_000_000_000_000;
            let token_contract = IERC20MINTABLEDispatcher {
                contract_address: registry.token_address,
            };
            token_contract.burn(token_amount);
        }

        fn _collect_gold_fee(ref self: ContractState, player: ContractAddress, amount: u256) {
            let mut world = self.world(@"Warpacks");

            let registry: TokenRegistry = world.read_model(GOLD_ITEM_ID);
            assert(
                registry.token_address != warpack_masters::utils::address::zero_address(),
                'Token not registered',
            );
            assert(registry.is_active, 'Token not active');

            let token_amount = amount * 1_000_000_000_000_000_000;

            IERC20Dispatcher { contract_address: registry.token_address }
                .transfer_from(player, starknet::get_contract_address(), token_amount);
        }

        fn _collect_rebirth_fee(
            ref self: ContractState,
            player: ContractAddress,
            fee: u256,
            strk_address: ContractAddress,
        ) {
            if fee == 0 {
                return;
            }

            let zero_address: ContractAddress = 0.try_into().unwrap();
            if strk_address == zero_address {
                return;
            }

            IERC20Dispatcher { contract_address: strk_address }
                .transfer_from(player, starknet::get_contract_address(), fee);
        }

        fn _load_game_config(ref self: ContractState, ref world: WorldStorage) -> GameConfig {
            let zero_address: ContractAddress = 0.try_into().unwrap();
            let mut gameConfig: GameConfig = world.read_model(GAME_CONFIG_ID);

            if gameConfig.id == 0 {
                gameConfig = GameConfig {
                    id: GAME_CONFIG_ID,
                    strk_address: zero_address,
                    rebirth_fee: REBIRTH_FEE,
                };
            }

            gameConfig
        }

        fn _spawn_with_fee(
            ref self: ContractState, name: felt252, wmClass: WMClass, charge_fee: bool,
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
            }
            assert(len <= 12 && len >= 3, 'name size is invalid');

            let nameRecord: CharacterName = world.read_model((name,));
            let zero_address: ContractAddress = 0.try_into().unwrap();
            assert(
                nameRecord.player == zero_address || nameRecord.player == player,
                'name already exists',
            );

            let player_exists: Character = world.read_model(player);
            assert(player_exists.name == '', 'player already exists');

            if charge_fee {
                let gameConfig: GameConfig = self._load_game_config(ref world);
                let fee = if gameConfig.rebirth_fee == 0 {
                    REBIRTH_FEE
                } else {
                    gameConfig.rebirth_fee
                };
                self._collect_rebirth_fee(player, fee, gameConfig.strk_address);
            }

            world.write_model(@CharacterName { name, player });

            // Default the player has 2 Backpacks
            // Must add two backpack items when setup the game
            let item: Item = world.read_model(Backpack::id);
            assert(item.itemType == 4, 'Invalid item type');
            let item: Item = world.read_model(Pack::id);
            assert(item.itemType == 4, 'Invalid item type');

            world.write_model(@StorageItem { player, id: 1, itemId: Backpack::id });
            world.write_model(@StorageItem { player, id: 2, itemId: Pack::id });
            world.write_model(@StorageCounter { player, count: 2 });
            world.write_model(@InventoryCounter { player, count: 0 });

            self.move_item_from_storage_to_inventory(1, 4, 2, 0);
            self.move_item_from_storage_to_inventory(2, 2, 2, 0);

            // keep the previous rating, totalWins and totalLoss during rebirth
            let prev_rating = player_exists.rating;
            let prev_total_wins = player_exists.totalWins;
            let prev_total_loss = player_exists.totalLoss;
            let prev_birth_count = player_exists.birthCount;
            let updatedAt = get_block_timestamp();

            self._mint_gold(player, INIT_GOLD.into() + 1);

            // add one gold for reroll shop
            let character = Character {
                player,
                name,
                wmClass,
                gold: 0,
                health: INIT_HEALTH,
                wins: 0,
                loss: 0,
                rating: prev_rating,
                totalWins: prev_total_wins,
                totalLoss: prev_total_loss,
                winStreak: 0,
                stamina: INIT_STAMINA,
                birthCount: prev_birth_count + 1,
                updatedAt,
            };
            world.write_model(@character);
        }

    }
}
