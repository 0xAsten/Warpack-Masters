#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::{set_contract_address, set_block_timestamp};

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::utils::test::{spawn_test_world, deploy_contract};

    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        systems::{item::{item_system, IItemDispatcher, IItemDispatcherTrait}},
        models::backpack::{BackpackGrids, backpack_grids},
        models::Item::{Item, item, ItemsCounter, items_counter},
        models::CharacterItem::{
            Position, CharacterItemStorage, character_item_storage, CharacterItemsStorageCounter,
            character_items_storage_counter, CharacterItemInventory, character_item_inventory,
            CharacterItemsInventoryCounter, character_items_inventory_counter
        },
        models::Character::{Character, character, NameRecord, name_record, WMClass},
        models::Shop::{Shop, shop}, utils::{test_utils::{add_items}}
    };

    use warpack_masters::constants::constants::{INIT_HEALTH, INIT_GOLD};


    #[test]
    #[available_gas(3000000000000000)]
    fn test_spawn() {
        let alice = starknet::contract_address_const::<0x0>();

        let mut models = array![
            backpack_grids::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            items_counter::TEST_CLASS_HASH,
            character_item_storage::TEST_CLASS_HASH,
            character_items_storage_counter::TEST_CLASS_HASH,
            character_item_inventory::TEST_CLASS_HASH,
            character_items_inventory_counter::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            name_record::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH
        ];

        let world = spawn_test_world("Warpacks", models);

        let action_system_address = world
            .deploy_contract(
                'salt1', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut action_system = IActionsDispatcher { contract_address: action_system_address };

        let item_system_address = world
            .deploy_contract(
                'salt2', item_system::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        add_items(ref item_system);

        set_contract_address(alice);

        // mocking timestamp for testing
        let timestamp = 1716770021;
        set_block_timestamp(timestamp);
        action_system.spawn('alice', WMClass::Warlock);

        let char = get!(world, (alice), Character);
        assert(!char.dummied, 'Should be false');
        assert(char.wins == 0, 'wins count should be 0');
        assert(char.loss == 0, 'loss count should be 0');
        assert(char.wmClass == WMClass::Warlock, 'class should be Warlock');
        assert(char.name == 'alice', 'name should be bob');
        assert(char.gold == INIT_GOLD + 1, 'gold should be init');
        assert(char.health == INIT_HEALTH, 'health should be init');
        assert(char.rating == 0, 'Rating mismatch');
        assert(char.totalWins == 0, 'total wins should be 0');
        assert(char.totalLoss == 0, 'total loss should be 0');
        assert(char.winStreak == 0, 'win streak should be 0');
        assert(char.birthCount == 1, 'birth count should be 1');
        assert(char.updatedAt == timestamp, 'updatedAt mismatch');

        let storageItemsCounter = get!(world, (alice), CharacterItemsStorageCounter);
        assert(storageItemsCounter.count == 2, 'Storage item count should be 2');

        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item 1 should be 0');

        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item 2 should be 0');

        let inventoryItemsCounter = get!(world, (alice), CharacterItemsInventoryCounter);
        assert(inventoryItemsCounter.count == 2, 'item count should be 2');

        let inventoryItem = get!(world, (alice, 1), CharacterItemInventory);
        assert(inventoryItem.itemId == 1, 'item 1 should be 1');
        assert(inventoryItem.position.x == 4, 'item 1 x should be 4');
        assert(inventoryItem.position.y == 2, 'item 1 y should be 2');

        let inventoryItem = get!(world, (alice, 2), CharacterItemInventory);
        assert(inventoryItem.itemId == 2, 'item 2 should be 2');
        assert(inventoryItem.position.x == 2, 'item 2 x should be 4');
        assert(inventoryItem.position.y == 2, 'item 2 y should be 3');

        let playerShopData = get!(world, (alice), Shop);
        assert(playerShopData.item1 == 0, 'item 1 should be 0');
        assert(playerShopData.item2 == 0, 'item 2 should be 0');
        assert(playerShopData.item3 == 0, 'item 3 should be 0');
        assert(playerShopData.item4 == 0, 'item 4 should be 0');

        // During spawn backpacks are added at (4,2) and (2,2) with h and w of 2 and 3 & 2 and 2
        // respectively The following grids will be enabled but not occupied
        // (4,2), (4,3), (4,4), (5,2), (5,3), (5,4), (2,2), (2,3), (3,2), (3,3)
        let playerGridData = get!(world, (alice, 4, 2), BackpackGrids);
        assert(playerGridData.enabled == true, '(4,2) should be enabled');
        assert(playerGridData.occupied == false, '(4,2) should not be occupied');

        let playerGridData = get!(world, (alice, 4, 3), BackpackGrids);
        assert(playerGridData.enabled == true, '(4,3) should be enabled');
        assert(playerGridData.occupied == false, '(4,3) should not be occupied');

        let playerGridData = get!(world, (alice, 4, 4), BackpackGrids);
        assert(playerGridData.enabled == true, '(4,4) should be enabled');
        assert(playerGridData.occupied == false, '(4,4) should not be occupied');

        let playerGridData = get!(world, (alice, 5, 2), BackpackGrids);
        assert(playerGridData.enabled == true, '(5,2) should be enabled');
        assert(playerGridData.occupied == false, '(5,2) should not be occupied');

        let playerGridData = get!(world, (alice, 5, 3), BackpackGrids);
        assert(playerGridData.enabled == true, '(5,3) should be enabled');
        assert(playerGridData.occupied == false, '(5,3) should not be occupied');

        let playerGridData = get!(world, (alice, 5, 4), BackpackGrids);
        assert(playerGridData.enabled == true, '(5,4) should be enabled');
        assert(playerGridData.occupied == false, '(5,4) should not be occupied');

        let playerGridData = get!(world, (alice, 2, 2), BackpackGrids);
        assert(playerGridData.enabled == true, '(2,2) should be enabled');
        assert(playerGridData.occupied == false, '(2,2) should not be occupied');

        let playerGridData = get!(world, (alice, 2, 3), BackpackGrids);
        assert(playerGridData.enabled == true, '(2,3) should be enabled');
        assert(playerGridData.occupied == false, '(2,3) should not be occupied');

        let playerGridData = get!(world, (alice, 3, 2), BackpackGrids);
        assert(playerGridData.enabled == true, '(3,2) should be enabled');
        assert(playerGridData.occupied == false, '(3,2) should not be occupied');

        let playerGridData = get!(world, (alice, 3, 3), BackpackGrids);
        assert(playerGridData.enabled == true, '(3,3) should be enabled');
        assert(playerGridData.occupied == false, '(3,3) should not be occupied');
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('name cannot be empty', 'ENTRYPOINT_FAILED'))]
    fn test_name_is_empty() {
        let alice = starknet::contract_address_const::<0x0>();

        let mut models = array![
            backpack_grids::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            items_counter::TEST_CLASS_HASH,
            character_item_storage::TEST_CLASS_HASH,
            character_items_storage_counter::TEST_CLASS_HASH,
            character_item_inventory::TEST_CLASS_HASH,
            character_items_inventory_counter::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            name_record::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH
        ];

        let world = spawn_test_world("Warpacks", models);

        let action_system_address = world
            .deploy_contract(
                'salt1', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut action_system = IActionsDispatcher { contract_address: action_system_address };

        set_contract_address(alice);

        action_system.spawn('', WMClass::Warlock);
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('player already exists', 'ENTRYPOINT_FAILED'))]
    fn test_player_already_exists() {
        let alice = starknet::contract_address_const::<0x0>();

        let mut models = array![
            backpack_grids::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            items_counter::TEST_CLASS_HASH,
            character_item_storage::TEST_CLASS_HASH,
            character_items_storage_counter::TEST_CLASS_HASH,
            character_item_inventory::TEST_CLASS_HASH,
            character_items_inventory_counter::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            name_record::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH
        ];

        let world = spawn_test_world("Warpacks", models);

        let action_system_address = world
            .deploy_contract(
                'salt1', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut action_system = IActionsDispatcher { contract_address: action_system_address };

        let item_system_address = world
            .deploy_contract(
                'salt2', item_system::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('alice', WMClass::Warlock);
        action_system.spawn('bob', WMClass::Warlock);
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('name already exists', 'ENTRYPOINT_FAILED'))]
    fn test_name_already_exists() {
        let mut models = array![
            backpack_grids::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            items_counter::TEST_CLASS_HASH,
            character_item_storage::TEST_CLASS_HASH,
            character_items_storage_counter::TEST_CLASS_HASH,
            character_item_inventory::TEST_CLASS_HASH,
            character_items_inventory_counter::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            name_record::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH
        ];

        let world = spawn_test_world("Warpacks", models);

        let action_system_address = world
            .deploy_contract(
                'salt1', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut action_system = IActionsDispatcher { contract_address: action_system_address };

        let item_system_address = world
            .deploy_contract(
                'salt2', item_system::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        add_items(ref item_system);

        let alice = starknet::contract_address_const::<0x1>();
        set_contract_address(alice);
        action_system.spawn('alice', WMClass::Warlock);

        let bob = starknet::contract_address_const::<0x2>();
        set_contract_address(bob);
        action_system.spawn('alice', WMClass::Warlock);
    }


    #[test]
    #[available_gas(3000000000000000)]
    fn test_spawn_a_Archer() {
        let mut models = array![
            backpack_grids::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            items_counter::TEST_CLASS_HASH,
            character_item_storage::TEST_CLASS_HASH,
            character_items_storage_counter::TEST_CLASS_HASH,
            character_item_inventory::TEST_CLASS_HASH,
            character_items_inventory_counter::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            name_record::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH
        ];

        let world = spawn_test_world("Warpacks", models);

        let action_system_address = world
            .deploy_contract(
                'salt1', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut action_system = IActionsDispatcher { contract_address: action_system_address };

        let item_system_address = world
            .deploy_contract(
                'salt2', item_system::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        add_items(ref item_system);

        let alice = starknet::contract_address_const::<0x1>();
        set_contract_address(alice);

        // mocking timestamp for testing
        let timestamp = 1716770021;
        set_block_timestamp(timestamp);

        action_system.spawn('alice', WMClass::Archer);

        let char = get!(world, (alice), Character);
        assert(!char.dummied, 'Should be false');
        assert(char.wins == 0, 'wins count should be 0');
        assert(char.loss == 0, 'loss count should be 0');
        assert(char.wmClass == WMClass::Archer, 'class should be Warlock');
        assert(char.name == 'alice', 'name should be bob');
        assert(char.gold == INIT_GOLD + 1, 'gold should be init');
        assert(char.health == INIT_HEALTH, 'health should be init');
        assert(char.rating == 0, 'Rating mismatch');
        assert(char.totalWins == 0, 'total wins should be 0');
        assert(char.totalLoss == 0, 'total loss should be 0');
        assert(char.winStreak == 0, 'win streak should be 0');
        assert(char.birthCount == 1, 'birth count should be 1');
        assert(char.updatedAt == timestamp, 'updatedAt mismatch');
    }
}

