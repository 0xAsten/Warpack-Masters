#[cfg(test)]
mod tests {
    use core::array::{ArrayTrait, SpanTrait};
    use dojo::model::ModelStorage;
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{
        ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
        spawn_test_world,
    };
    use warpack_masters::models::Character::{Character, WMClass, m_Character, m_CharacterName};
    use warpack_masters::models::CharacterItem::{
        InventoryCounter, InventoryItem, StorageCounter, StorageItem, m_InventoryCounter,
        m_InventoryItem, m_StorageCounter, m_StorageItem,
    };
    use warpack_masters::models::Game::m_GameConfig;
    use warpack_masters::models::Item::{m_Item, m_ItemsCounter};
    use warpack_masters::models::Shop::{Shop, m_Shop};
    use warpack_masters::models::backpack::{BackpackGrids, m_BackpackGrids};
    use warpack_masters::systems::actions::{IActionsDispatcher, IActionsDispatcherTrait, actions};
    use warpack_masters::systems::item::{IItemDispatcher, item_system};
    use warpack_masters::systems::shop::{IShopDispatcher, IShopDispatcherTrait, shop_system};
    use warpack_masters::utils::test_utils::{add_items, setup_rebirth_fee_context};

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "Warpacks",
            resources: [
                TestResource::Model(m_BackpackGrids::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Item::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_ItemsCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemStorage::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_StorageCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_InventoryItem::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_InventoryCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Character::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterName::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Shop::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_GameConfig::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Contract(actions::TEST_CLASS_HASH),
                TestResource::Contract(item_system::TEST_CLASS_HASH),
                TestResource::Contract(shop_system::TEST_CLASS_HASH),
                TestResource::Event(actions::e_BuyItem::TEST_CLASS_HASH),
                TestResource::Event(actions::e_SellItem::TEST_CLASS_HASH),
            ]
                .span(),
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
        ]
            .span()
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_move_item_from_inventory_to_storage() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let alice = warpack_masters::utils::address::zero_address();

        add_items(ref item_system);
        let players = array![alice];
        setup_rebirth_fee_context(world, action_system.contract_address, players.span());

        action_system.spawn('Alice', WMClass::Warlock);

        let mut player_data: Character = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 5;
        shop_data.item2 = 6;
        shop_data.item3 = 8;
        shop_data.item4 = 1;
        world.write_model(@shop_data);

        action_system.move_item_from_shop_to_storage(5);
        // place a sword on (4,2)
        action_system.move_item_from_storage_to_inventory(2, 4, 2, 0);

        action_system.move_item_from_inventory_to_storage(3);

        let storageItemCounter: StorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');

        let storageItem: CharacterItemStorage = world.read_model((alice, 2));
        assert(storageItem.itemId == 5, 'item id should equal 5');

        let inventoryItemCounter: InventoryCounter = world.read_model(alice);
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

        action_system.move_item_from_shop_to_storage(6);
        // place a shield on (2,2)
        action_system.move_item_from_storage_to_inventory(1, 2, 2, 0);

        action_system.move_item_from_inventory_to_storage(3);

        let storageItemCounter: StorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');

        let storageItem: CharacterItemStorage = world.read_model((alice, 2));
        assert(storageItem.itemId == 5, 'item id should equal 5');
        let storageItem: CharacterItemStorage = world.read_model((alice, 1));
        assert(storageItem.itemId == 6, 'item id should equal 6');

        let inventoryItemCounter: InventoryCounter = world.read_model(alice);
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

        action_system.move_item_from_shop_to_storage(8);
        // place a potion on (5,2)
        action_system.move_item_from_storage_to_inventory(3, 5, 2, 0);

        action_system.move_item_from_inventory_to_storage(3);

        let storageItemCounter: StorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 3, 'storage item count mismatch');

        let storageItem: CharacterItemStorage = world.read_model((alice, 3));
        assert(storageItem.itemId == 8, 'item id should equal 2');
        let storageItem: CharacterItemStorage = world.read_model((alice, 2));
        assert(storageItem.itemId == 5, 'item id should equal 4');
        let storageItem: CharacterItemStorage = world.read_model((alice, 1));
        assert(storageItem.itemId == 6, 'item id should equal 6');
        let inventoryItemCounter: InventoryCounter = world.read_model(alice);
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

        action_system.move_item_from_storage_to_inventory(2, 4, 2, 0);
        action_system.move_item_from_storage_to_inventory(1, 2, 2, 0);
        action_system.move_item_from_storage_to_inventory(3, 5, 2, 0);

        action_system.move_item_from_inventory_to_storage(4);

        let storageItemCounter: StorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 3, 'storage item count mismatch');

        let storageItem: CharacterItemStorage = world.read_model((alice, 1));
        assert(storageItem.itemId == 0, 'item id should equal 0');
        let storageItem: CharacterItemStorage = world.read_model((alice, 2));
        assert(storageItem.itemId == 0, 'item id should equal 0');
        let storageItem: CharacterItemStorage = world.read_model((alice, 3));
        assert(storageItem.itemId == 6, 'item id should equal 6');

        let inventoryItemCounter: InventoryCounter = world.read_model(alice);
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
    #[should_panic(expected: ('item not found', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_inventory_to_storage_revert_not_in_inventory() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);

        action_system.move_item_from_inventory_to_storage(3);
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_move_item_from_inventory_to_storage_with_plugins_check() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = warpack_masters::utils::address::zero_address();

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        let mut player_data: Character = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword weapon
        shop_data.item2 = 13; // poison plugin
        shop_data.item3 = 17; // PlagueFlower plugin
        shop_data.item4 = 1;
        world.write_model(@shop_data);

        action_system.move_item_from_shop_to_storage(13);
        action_system.move_item_from_storage_to_inventory(2, 5, 2, 0);

        action_system.move_item_from_shop_to_storage(7);
        // place a sword on (4,2)
        action_system.move_item_from_storage_to_inventory(2, 4, 2, 0);

        action_system.move_item_from_shop_to_storage(17);
        action_system.move_item_from_storage_to_inventory(2, 2, 2, 0);

        action_system.move_item_from_inventory_to_storage(3);
        let storageItemCounter: StorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');
        let storageItem: CharacterItemStorage = world.read_model((alice, 2));
        assert(storageItem.itemId == 13, 'item id should equal 7');

        let inventoryItemCounter: InventoryCounter = world.read_model(alice);
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

        action_system.move_item_from_inventory_to_storage(4);
        let storageItemCounter: StorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');
        let storageItem: CharacterItemStorage = world.read_model((alice, 1));
        assert(storageItem.itemId == 7, 'item id should equal 7');

        let inventoryItemCounter: InventoryCounter = world.read_model(alice);
        assert(inventoryItemCounter.count == 5, 'inventory item count mismatch');
        let invetoryItem: CharacterItemInventory = world.read_model((alice, 4));
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');

        action_system.move_item_from_storage_to_inventory(1, 4, 2, 0);
        let storageItemCounter: StorageCounter = world.read_model(alice);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');
        let storageItem: CharacterItemStorage = world.read_model((alice, 1));
        assert(storageItem.itemId == 0, 'item id should equal 0');

        let inventoryItemCounter: InventoryCounter = world.read_model(alice);
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
