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
        models::backpack::{Backpack, backpack, BackpackGrids, Grid, GridTrait},
        models::Item::{Item, item, ItemsCounter},
        models::CharacterItem::{
            Position, CharacterItemStorage, CharacterItemsStorageCounter, CharacterItemInventory,
            CharacterItemsInventoryCounter
        },
        models::Character::{Character, character, WMClass}, models::Shop::{Shop, shop}
    };

    use warpack_masters::systems::actions::actions::{ITEMS_COUNTER_ID, STORAGE_FLAG};


    #[test]
    #[available_gas(3000000000000000)]
    fn test_undo_place_item() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 1, 3, 2, 10, 10, 5, 10, 5, 1);
        actions_system.add_item('Shield', 2, 2, 2, 0, 5, 5, 10, 5, 1);
        actions_system.add_item('Potion', 1, 1, 2, 0, 0, 5, 10, 15, 2);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);
        // mock player gold for testing
        let mut player_data = get!(world, alice, (Character));
        player_data.gold = 100;
        set!(world, (player_data));
        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 1;
        shop_data.item2 = 2;
        shop_data.item3 = 1;
        shop_data.item4 = 3;
        set!(world, (shop_data));

        actions_system.buy_item(1);
        // place a sword on (0,4)
        actions_system.place_item(1, 0, 0, 0);

        actions_system.undo_place_item(1);

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 1, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 1, 'item id should equal 0');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 1, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 1), CharacterItemInventory);
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');

        let mut backpack_grid_data = get!(world, (alice, 0, 4), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(0,4) should not be occupied');
        let mut backpack_grid_data = get!(world, (alice, 0, 5), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(0,5) should not be occupied');
        let mut backpack_grid_data = get!(world, (alice, 0, 6), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(0,6) should not be occupied');

        actions_system.buy_item(2);
        // place a shield on (1,5)
        actions_system.place_item(2, 0, 0, 0);

        actions_system.undo_place_item(1);

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 1, 'item id should equal 0');
        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 2, 'item id should equal 0');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 1, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 1), CharacterItemInventory);
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');

        actions_system.buy_item(3);
        // place a potion on (1,4)
        actions_system.place_item(3, 0, 0, 0);

        actions_system.undo_place_item(1);

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 3, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 1, 'item id should equal 0');
        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 2, 'item id should equal 0');
        let storageItem = get!(world, (alice, 3), CharacterItemStorage);
        assert(storageItem.itemId == 3, 'item id should equal 0');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 1, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 1), CharacterItemInventory);
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');

        let mut backpack_grid_data = get!(world, (alice, 1, 4), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(1,4) should be occupied');

        actions_system.place_item(1, 0, 0, 0);
        actions_system.place_item(2, 1, 0, 0);
        actions_system.place_item(3, 3, 0, 0);
        actions_system.undo_place_item(2);

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 3, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item id should equal 0');
        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item id should equal 0');
        let storageItem = get!(world, (alice, 3), CharacterItemStorage);
        assert(storageItem.itemId == 2, 'item id should equal 2');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 3, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 1), CharacterItemInventory);
        assert(invetoryItem.itemId == 1, 'item id should equal 1');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        let invetoryItem = get!(world, (alice, 2), CharacterItemInventory);
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        let invetoryItem = get!(world, (alice, 3), CharacterItemInventory);
        assert(invetoryItem.itemId == 3, 'item id should equal 3');
        assert(invetoryItem.position.x == 3, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid inventory item id', 'ENTRYPOINT_FAILED'))]
    fn test_place_item_revert_not_in_inventory() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![
            backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH, character::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.add_item('Sword', 1, 3, 100, 10, 10, 5, 10, 5, 1);

        set_contract_address(alice);
        actions_system.spawn('Alice', WMClass::Warlock);

        actions_system.undo_place_item(1);
    }
}

