#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_contract_address;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    // import test utils
    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::backpack::{BackpackGrids}, models::Item::{Item, item, ItemsCounter},
        models::CharacterItem::{
            Position, CharacterItemStorage, CharacterItemsStorageCounter, CharacterItemInventory,
            CharacterItemsInventoryCounter
        },
        models::Character::{Character, character, WMClass}, models::Shop::{Shop, shop},
        utils::{test_utils::{add_items}}
    };

    use warpack_masters::systems::actions::actions::{ITEMS_COUNTER_ID, STORAGE_FLAG};


    #[test]
    #[available_gas(3000000000000000)]
    fn test_undo_place_item() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        // mock player gold for testing
        let mut player_data = get!(world, alice, (Character));
        player_data.gold = 100;
        set!(world, (player_data));
        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 4;
        shop_data.item2 = 6;
        shop_data.item3 = 8;
        shop_data.item4 = 1;
        set!(world, (shop_data));

        actions_system.buy_item(4);
        // place a sword on (4,2)
        actions_system.place_item(2, 4, 2, 0);

        actions_system.undo_place_item(3);

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 4, 'item id should equal 2');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 3, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 3), CharacterItemInventory);
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');

        let mut backpack_grid_data = get!(world, (alice, 4, 2), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(4,2) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(4,2) should be enabled');

        let mut backpack_grid_data = get!(world, (alice, 4, 3), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(4,3) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(4,3) should be enabled');

        let mut backpack_grid_data = get!(world, (alice, 4, 4), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(4,4) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(4,4) should be enabled');

        actions_system.buy_item(6);
        // place a shield on (2,2)
        actions_system.place_item(1, 2, 2, 0);

        actions_system.undo_place_item(3);

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 4, 'item id should equal 4');
        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 6, 'item id should equal 6');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 3, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 3), CharacterItemInventory);
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');

        let mut backpack_grid_data = get!(world, (alice, 2, 2), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(2,2) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(2,2) should be occupied');

        let mut backpack_grid_data = get!(world, (alice, 3, 2), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(3,2) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(3,2) should be enabled');

        let mut backpack_grid_data = get!(world, (alice, 2, 3), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(2,3) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(2,3) should be enabled');

        let mut backpack_grid_data = get!(world, (alice, 3, 3), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(3,3) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(3,3) should be enabled');

        actions_system.buy_item(8);
        // place a potion on (5,2)
        actions_system.place_item(3, 5, 2, 0);

        actions_system.undo_place_item(3);

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 3, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 3), CharacterItemStorage);
        assert(storageItem.itemId == 8, 'item id should equal 2');
        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 4, 'item id should equal 4');
        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 6, 'item id should equal 6');
        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 3, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 3), CharacterItemInventory);
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');

        let mut backpack_grid_data = get!(world, (alice, 5, 2), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(5,2) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(5,2) should be enabled');

        actions_system.place_item(2, 4, 2, 0);
        actions_system.place_item(1, 2, 2, 0);
        actions_system.place_item(3, 5, 2, 0);

        actions_system.undo_place_item(4);

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 3, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item id should equal 0');
        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item id should equal 0');
        let storageItem = get!(world, (alice, 3), CharacterItemStorage);
        assert(storageItem.itemId == 6, 'item id should equal 6');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 5, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 3), CharacterItemInventory);
        assert(invetoryItem.itemId == 4, 'item id should equal 2');
        assert(invetoryItem.position.x == 4, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        let invetoryItem = get!(world, (alice, 4), CharacterItemInventory);
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        let invetoryItem = get!(world, (alice, 5), CharacterItemInventory);
        assert(invetoryItem.itemId == 8, 'item id should equal 6');
        assert(invetoryItem.position.x == 5, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid inventory item id', 'ENTRYPOINT_FAILED'))]
    fn test_undo_place_item_revert_not_in_inventory() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);

        actions_system.undo_place_item(3);
    }
}

