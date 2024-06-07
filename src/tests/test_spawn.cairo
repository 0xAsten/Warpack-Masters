#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::{set_contract_address, set_block_timestamp};

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait, WMClass}},
        models::backpack::{BackpackGrids}, models::Item::{Item, item, ItemsCounter},
        models::Character::{Character, character},
        models::CharacterItem::{
            Position, CharacterItemStorage, CharacterItemsStorageCounter, CharacterItemInventory,
            CharacterItemsInventoryCounter
        },
        models::DummyCharacter::{DummyCharacter, DummyCharacterCounter},
        models::DummyCharacterItem::{DummyCharacterItem, DummyCharacterItemsCounter},
        models::Shop::Shop, utils::{test_utils::{add_items}}
    };

    use warpack_masters::systems::actions::actions::{ITEMS_COUNTER_ID, INIT_HEALTH, INIT_GOLD};
    use debug::PrintTrait;


    #[test]
    #[available_gas(3000000000000000)]
    fn test_spawn() {
        let alice = starknet::contract_address_const::<0x0>();
        set_contract_address(alice);

        let mut models = array![];
        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        // mocking timestamp for testing
        let timestamp = 1716770021;
        set_block_timestamp(timestamp);
        actions_system.spawn('alice', WMClass::Warlock);

        let char = get!(world, (alice), Character);
        assert(!char.dummied, 'Should be false');
        assert(char.wins == 0, 'wins count should be 0');
        assert(char.loss == 0, 'loss count should be 0');
        assert(char.wmClass == WMClass::Warlock, 'class should be Warlock');
        assert(char.name == 'alice', 'name should be bob');
        assert(char.gold == INIT_GOLD + 1, 'gold should be init');
        assert(char.health == INIT_HEALTH, 'health should be init');
        assert(char.rating == 0, 'Rating mismatch');
        assert(char.total_wins == 0, 'total_wins should be 0');
        assert(char.total_loss == 0, 'total_loss should be 0');
        assert(char.win_streak == 0, 'win_streak should be 0');
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

        // During spawn backpacks are added at (4,2) and (2,2) with h and w of 
        // 2 and 3 & 2 and 2 respectively
        // The following grids will be enabled but not occupied
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
        let mut models = array![];
        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn('', WMClass::Warlock);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('player already exists', 'ENTRYPOINT_FAILED'))]
    fn test_player_already_exists() {
        let mut models = array![];
        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };
        add_items(ref actions_system);

        actions_system.spawn('alice', WMClass::Warlock);
        actions_system.spawn('bob', WMClass::Warlock);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('name already exists', 'ENTRYPOINT_FAILED'))]
    fn test_name_already_exists() {
        let mut models = array![];
        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };
        add_items(ref actions_system);

        let alice = starknet::contract_address_const::<0x1>();
        set_contract_address(alice);
        actions_system.spawn('alice', WMClass::Warlock);

        let bob = starknet::contract_address_const::<0x2>();
        set_contract_address(bob);
        actions_system.spawn('alice', WMClass::Warlock);
    }
}

