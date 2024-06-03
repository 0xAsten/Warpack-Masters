#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_contract_address;

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

    #[test]
    #[available_gas(3000000000000000)]
    fn test_rebirth() {
        let alice = starknet::contract_address_const::<0x0>();
        set_contract_address(alice);
        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        actions_system.spawn('alice', WMClass::Warlock);

        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 4;
        shop_data.item2 = 6;
        shop_data.item3 = 8;
        shop_data.item4 = 1;
        set!(world, (shop_data));

        actions_system.buy_item(4);
        actions_system.buy_item(6);
        actions_system.buy_item(8);

        actions_system.place_item(2, 4, 2, 0);
        actions_system.place_item(1, 2, 2, 0);
        actions_system.place_item(3, 5, 2, 0);

        let mut char = get!(world, (alice), Character);
        char.loss = 5;
        set!(world, (char));

        actions_system.rebirth('bob', WMClass::Warrior);

        let char = get!(world, (alice), Character);
        let inventoryItemsCounter = get!(world, (alice), CharacterItemsInventoryCounter);
        let storageItemsCounter = get!(world, (alice), CharacterItemsStorageCounter);
        let playerShopData = get!(world, (alice), Shop);

        assert(!char.dummied, 'Should be false');
        assert(char.wins == 0, 'wins count should be 0');
        assert(char.loss == 0, 'loss count should be 0');
        assert(char.wmClass == WMClass::Warrior, 'class should be Warrior');
        assert(char.name == 'bob', 'name should be bob');
        assert(char.gold == INIT_GOLD + 1, 'gold should be init');
        assert(char.health == INIT_HEALTH, 'health should be init');

        assert(inventoryItemsCounter.count == 2, 'item count should be 0');
        assert(storageItemsCounter.count == 2, 'item count should be 0');

        assert(playerShopData.item1 == 0, 'item 1 should be 0');
        assert(playerShopData.item2 == 0, 'item 2 should be 0');
        assert(playerShopData.item3 == 0, 'item 3 should be 0');
        assert(playerShopData.item4 == 0, 'item 4 should be 0');

        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item 1 should be 0');

        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item 2 should be 0');

        let inventoryItem = get!(world, (alice, 1), CharacterItemInventory);
        assert(inventoryItem.itemId == 1, 'item 1 should be 1');
        assert(inventoryItem.position.x == 4, 'item 1 x should be 4');
        assert(inventoryItem.position.y == 2, 'item 1 y should be 2');

        let inventoryItem = get!(world, (alice, 2), CharacterItemInventory);
        assert(inventoryItem.itemId == 2, 'item 2 should be 2');
        assert(inventoryItem.position.x == 2, 'item 2 x should be 4');
        assert(inventoryItem.position.y == 2, 'item 2 y should be 3');

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
    #[should_panic(expected: ('loss not reached', 'ENTRYPOINT_FAILED'))]
    fn test_loss_not_reached() {
        let alice = starknet::contract_address_const::<0x0>();
        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        actions_system.spawn('alice', WMClass::Warlock);

        let mut char = get!(world, (alice), Character);
        char.loss = 4;
        set!(world, (char));

        actions_system.rebirth('bob', WMClass::Warlock);
    }
}

