#[cfg(test)]
mod tests {
    use dojo::model::{ModelStorage};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef, WorldStorageTestTrait};

    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        systems::{item::{item_system, IItemDispatcher}},
        systems::{shop::{shop_system, IShopDispatcher, IShopDispatcherTrait}},
        models::backpack::{BackpackGrids, m_BackpackGrids},
        models::Item::{m_Item, m_ItemsCounter},
        models::CharacterItem::{
            CharacterItemStorage, m_CharacterItemStorage, CharacterItemsStorageCounter,
            m_CharacterItemsStorageCounter, CharacterItemInventory, m_CharacterItemInventory,
            CharacterItemsInventoryCounter, m_CharacterItemsInventoryCounter
        },
        models::Character::{Characters, m_Characters, m_NameRecord, WMClass},
        models::Shop::{Shop, m_Shop}, utils::{test_utils::{add_items}}
    };

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "Warpacks", 
            resources: [
                TestResource::Model(m_BackpackGrids::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Item::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_ItemsCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemStorage::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemsStorageCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemInventory::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemsInventoryCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Characters::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_NameRecord::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Shop::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Contract(actions::TEST_CLASS_HASH),
                TestResource::Contract(item_system::TEST_CLASS_HASH),
                TestResource::Contract(shop_system::TEST_CLASS_HASH),
                TestResource::Event(shop_system::e_BuyItem::TEST_CLASS_HASH),
                TestResource::Event(shop_system::e_SellItem::TEST_CLASS_HASH),
            ].span()
        };
 
        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"Warpacks", @"actions")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
            ContractDefTrait::new(@"Warpacks", @"item_system")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
            ContractDefTrait::new(@"Warpacks", @"shop_system")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
        ].span()
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_undo_place_item() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);

        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);
        
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 5;
        shop_data.item2 = 6;
        shop_data.item3 = 8;
        shop_data.item4 = 1;
        world.write_model(@shop_data);

        shop_system.buy_item(5);
        // place a sword on (4,2)
        action_system.place_item(2, 4, 2, 0);

        action_system.undo_place_item(3);

        let storageItemCounter: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');

        let storageItem: CharacterItemStorage = world.read_model((alice, 2));
        assert(storageItem.itemId == 5, 'item id should equal 5');

        let inventoryItemCounter: CharacterItemsInventoryCounter = world.read_model(alice);
        assert(inventoryItemCounter.count == 3, 'inventory item count mismatch');

        let invetoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 2));
        assert(backpack_grid_data.occupied == false, '(4,2) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(4,2) should be enabled');
        assert(backpack_grid_data.inventoryItemId == 0, 'id should equal 0');
        assert(backpack_grid_data.itemId == 0, 'item id should equal 0');
        assert(backpack_grid_data.isWeapon == false, 'isWeapon should be false');
        assert(backpack_grid_data.isPlugin == false, 'isPlugin should be false');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 3));
        assert(backpack_grid_data.occupied == false, '(4,3) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(4,3) should be enabled');
        assert(backpack_grid_data.inventoryItemId == 0, 'id should equal 0');
        assert(backpack_grid_data.itemId == 0, 'item id should equal 0');
        assert(backpack_grid_data.isWeapon == false, 'isWeapon should be false');
        assert(backpack_grid_data.isPlugin == false, 'isPlugin should be false');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 4));
        assert(backpack_grid_data.occupied == false, '(4,4) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(4,4) should be enabled');
        assert(backpack_grid_data.inventoryItemId == 0, 'id should equal 0');
        assert(backpack_grid_data.itemId == 0, 'item id should equal 0');
        assert(backpack_grid_data.isWeapon == false, 'isWeapon should be false');
        assert(backpack_grid_data.isPlugin == false, 'isPlugin should be false');

        shop_system.buy_item(6);
        // place a shield on (2,2)
        action_system.place_item(1, 2, 2, 0);

        action_system.undo_place_item(3);

        let storageItemCounter: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');

        let storageItem: CharacterItemStorage = world.read_model((alice, 2));
        assert(storageItem.itemId == 5, 'item id should equal 5');
        let storageItem: CharacterItemStorage = world.read_model((alice, 1));
        assert(storageItem.itemId == 6, 'item id should equal 6');

        let inventoryItemCounter: CharacterItemsInventoryCounter = world.read_model(alice);
        assert(inventoryItemCounter.count == 3, 'inventory item count mismatch');

        let invetoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 2, 2));
        assert(backpack_grid_data.occupied == false, '(2,2) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(2,2) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 0, 'id should equal 0');
        assert(backpack_grid_data.itemId == 0, 'item id should equal 0');
        assert(backpack_grid_data.isWeapon == false, 'isWeapon should be false');
        assert(backpack_grid_data.isPlugin == false, 'isPlugin should be false');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 3, 2));
        assert(backpack_grid_data.occupied == false, '(3,2) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(3,2) should be enabled');
        assert(backpack_grid_data.inventoryItemId == 0, 'id should equal 0');
        assert(backpack_grid_data.itemId == 0, 'item id should equal 0');
        assert(backpack_grid_data.isWeapon == false, 'isWeapon should be false');
        assert(backpack_grid_data.isPlugin == false, 'isPlugin should be false');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 2, 3));
        assert(backpack_grid_data.occupied == false, '(2,3) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(2,3) should be enabled');
        assert(backpack_grid_data.inventoryItemId == 0, 'id should equal 0');
        assert(backpack_grid_data.itemId == 0, 'item id should equal 0');
        assert(backpack_grid_data.isWeapon == false, 'isWeapon should be false');
        assert(backpack_grid_data.isPlugin == false, 'isPlugin should be false');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 3, 3));
        assert(backpack_grid_data.occupied == false, '(3,3) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(3,3) should be enabled');
        assert(backpack_grid_data.inventoryItemId == 0, 'id should equal 0');
        assert(backpack_grid_data.itemId == 0, 'item id should equal 0');
        assert(backpack_grid_data.isWeapon == false, 'isWeapon should be false');
        assert(backpack_grid_data.isPlugin == false, 'isPlugin should be false');

        shop_system.buy_item(8);
        // place a potion on (5,2)
        action_system.place_item(3, 5, 2, 0);

        action_system.undo_place_item(3);

        let storageItemCounter: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 3, 'storage item count mismatch');

        let storageItem: CharacterItemStorage = world.read_model((alice, 3));
        assert(storageItem.itemId == 8, 'item id should equal 2');
        let storageItem: CharacterItemStorage = world.read_model((alice, 2));
        assert(storageItem.itemId == 5, 'item id should equal 4');
        let storageItem: CharacterItemStorage = world.read_model((alice, 1));
        assert(storageItem.itemId == 6, 'item id should equal 6');
        let inventoryItemCounter: CharacterItemsInventoryCounter = world.read_model(alice);
        assert(inventoryItemCounter.count == 3, 'inventory item count mismatch');

        let invetoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 5, 2));
        assert(backpack_grid_data.occupied == false, '(5,2) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(5,2) should be enabled');
        assert(backpack_grid_data.inventoryItemId == 0, 'id should equal 0');
        assert(backpack_grid_data.itemId == 0, 'item id should equal 0');
        assert(backpack_grid_data.isWeapon == false, 'isWeapon should be false');
        assert(backpack_grid_data.isPlugin == false, 'isPlugin should be false');

        action_system.place_item(2, 4, 2, 0);
        action_system.place_item(1, 2, 2, 0);
        action_system.place_item(3, 5, 2, 0);

        action_system.undo_place_item(4);

        let storageItemCounter: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 3, 'storage item count mismatch');

        let storageItem: CharacterItemStorage = world.read_model((alice, 1));
        assert(storageItem.itemId == 0, 'item id should equal 0');
        let storageItem: CharacterItemStorage = world.read_model((alice, 2));
        assert(storageItem.itemId == 0, 'item id should equal 0');
        let storageItem: CharacterItemStorage = world.read_model((alice, 3));
        assert(storageItem.itemId == 6, 'item id should equal 6');

        let inventoryItemCounter: CharacterItemsInventoryCounter = world.read_model(alice);
        assert(inventoryItemCounter.count == 5, 'inventory item count mismatch');

        let invetoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(invetoryItem.itemId == 5, 'item id should equal 5');
        assert(invetoryItem.position.x == 4, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');

        let invetoryItem: CharacterItemInventory = world.read_model((alice, 4));
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');

        let invetoryItem: CharacterItemInventory = world.read_model((alice, 5));
        assert(invetoryItem.itemId == 8, 'item id should equal 6');
        assert(invetoryItem.position.x == 5, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid inventory item id', 'ENTRYPOINT_FAILED'))]
    fn test_undo_place_item_revert_not_in_inventory() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);

        action_system.undo_place_item(3);
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_undo_place_item_with_plugins_check() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword weapon
        shop_data.item2 = 13; // poison plugin
        shop_data.item3 = 17; // PlagueFlower plugin
        shop_data.item4 = 1;
        world.write_model(@shop_data);

        shop_system.buy_item(13);
        action_system.place_item(2, 5, 2, 0);

        shop_system.buy_item(7);
        // place a sword on (4,2)
        action_system.place_item(2, 4, 2, 0);
        
        shop_system.buy_item(17);
        action_system.place_item(2, 2, 2, 0);

        action_system.undo_place_item(3);
        let storageItemCounter: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');
        let storageItem: CharacterItemStorage = world.read_model((alice, 2));
        assert(storageItem.itemId == 13, 'item id should equal 7');
        
        let inventoryItemCounter: CharacterItemsInventoryCounter = world.read_model(alice);
        assert(inventoryItemCounter.count == 5, 'inventory item count mismatch');
        let invetoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');
        let invetoryItem: CharacterItemInventory = world.read_model((alice, 4));
        assert(invetoryItem.itemId == 7, 'item id should equal 7');
        assert(invetoryItem.position.x == 4, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 1, 'plugins length mismatch');
        assert(*invetoryItem.plugins.at(0) == (6, 80, 3), 'plugin length mismatch');

        action_system.undo_place_item(4);
        let storageItemCounter: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');
        let storageItem: CharacterItemStorage = world.read_model((alice, 1));
        assert(storageItem.itemId == 7, 'item id should equal 7');

        let inventoryItemCounter: CharacterItemsInventoryCounter = world.read_model(alice);
        assert(inventoryItemCounter.count == 5, 'inventory item count mismatch');
        let invetoryItem: CharacterItemInventory = world.read_model((alice, 4));
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');

        action_system.place_item(1, 4, 2, 0);
        let storageItemCounter: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');
        let storageItem: CharacterItemStorage = world.read_model((alice, 1));
        assert(storageItem.itemId == 0, 'item id should equal 0');

        let inventoryItemCounter: CharacterItemsInventoryCounter = world.read_model(alice);
        assert(inventoryItemCounter.count == 5, 'inventory item count mismatch');
        let invetoryItem: CharacterItemInventory = world.read_model((alice, 4));
        assert(invetoryItem.itemId == 7, 'item id should equal 7');
        assert(invetoryItem.position.x == 4, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 1, 'plugins length mismatch');
        assert(*invetoryItem.plugins.at(0) == (6, 80, 3), 'plugin length mismatch');
        let invetoryItem: CharacterItemInventory = world.read_model((alice, 5));
        assert(invetoryItem.itemId == 17, 'item id should equal 17');
        assert(invetoryItem.position.x == 2, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');
        let invetoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');
    }
}

