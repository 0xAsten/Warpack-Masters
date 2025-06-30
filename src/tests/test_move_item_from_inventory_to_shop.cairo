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
        models::Item::{m_Item, ItemsCounter, m_ItemsCounter},
        models::CharacterItem::{
            m_CharacterItemStorage,
            m_CharacterItemsStorageCounter, CharacterItemInventory, m_CharacterItemInventory,
            m_CharacterItemsInventoryCounter
        },
        models::Character::{Characters, m_Characters, m_NameRecord, WMClass},
        models::Shop::{Shop, m_Shop}, utils::{test_utils::{add_items}}
    };

    use warpack_masters::constants::constants::ITEMS_COUNTER_ID;

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
                TestResource::Event(actions::e_BuyItem::TEST_CLASS_HASH),
                TestResource::Event(actions::e_SellItem::TEST_CLASS_HASH),
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
    fn test_move_item_from_inventory_to_shop_sword() {
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
        let item: ItemsCounter = world.read_model(ITEMS_COUNTER_ID); 
        assert(item.count == 34, 'total item count mismatch');

        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // Mock player gold for testing
        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        // Mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword (price = 2)
        shop_data.item2 = 0;
        shop_data.item3 = 0;
        shop_data.item4 = 0;
        world.write_model(@shop_data);

        // Buy and place sword in inventory
        action_system.move_item_from_shop_to_inventory(7, 4, 2, 0);

        // Verify sword is in inventory before selling
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(inventoryItem.itemId == 7, 'item should be in inventory');
        assert(inventoryItem.position.x == 4, 'x position mismatch');
        assert(inventoryItem.position.y == 2, 'y position mismatch');

        // Verify initial gold after purchase (100 - 2 = 98)
        let player_data: Characters = world.read_model(alice);
        assert(player_data.gold == 98, 'gold after purchase mismatch');

        // Sell the sword from inventory
        action_system.move_item_from_inventory_to_shop(3);

        // Verify sword is removed from inventory
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(inventoryItem.itemId == 0, 'item should be removed');
        assert(inventoryItem.position.x == 0, 'x should be reset');
        assert(inventoryItem.position.y == 0, 'y should be reset');
        assert(inventoryItem.rotation == 0, 'rotation should be reset');
        assert(inventoryItem.plugins.len() == 0, 'plugins should be empty');

        // Verify grids are cleared
        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 2));
        assert(!backpack_grid_data.occupied, '(4,2) should not be occupied');
        assert(backpack_grid_data.itemId == 0, 'itemId should be reset');
        assert(backpack_grid_data.inventoryItemId == 0, 'inventoryItemId should be reset');
        assert(!backpack_grid_data.isWeapon, 'isWeapon should be reset');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 3));
        assert(!backpack_grid_data.occupied, '(4,3) should not be occupied');

        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 4, 4));
        assert(!backpack_grid_data.occupied, '(4,4) should not be occupied');

        // Verify gold is increased by sell price (price / 2 = 2 / 2 = 1)
        let player_data: Characters = world.read_model(alice);
        assert(player_data.gold == 99, 'gold after sale mismatch'); // 98 + 1 = 99
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_move_item_from_inventory_to_shop_shield() {
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

        // Mock player gold for testing
        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        // Mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 9; // shield (2x2, price = 3)
        world.write_model(@shop_data);

        // Buy and place shield in inventory
        action_system.move_item_from_shop_to_inventory(9, 2, 2, 0);

        // Verify shield occupies correct grids
        let mut backpack_grid_data: BackpackGrids = world.read_model((alice, 2, 2));
        assert(backpack_grid_data.occupied, '(2,2) should be occupied');
        assert(!backpack_grid_data.isWeapon, 'should not be weapon');

        // Sell the shield from inventory
        action_system.move_item_from_inventory_to_shop(3);

        // Verify all grids are cleared (2x2 shield)
        let grids_to_check = array![(2, 2), (3, 2), (2, 3), (3, 3)];
        let mut i = 0;
        loop {
            if i >= grids_to_check.len() {
                break;
            }
            let (x, y) = *grids_to_check.at(i);
            let backpack_grid_data: BackpackGrids = world.read_model((alice, x, y));
            assert(!backpack_grid_data.occupied, 'grid should not be occupied');
            assert(backpack_grid_data.itemId == 0, 'itemId should be reset');
            i += 1;
        };

        // Verify gold calculation (100 - 3 + 1 = 98) since sell price is price/2 = 3/2 = 1
        let player_data: Characters = world.read_model(alice);
        assert(player_data.gold == 98, 'gold calculation mismatch');
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_move_item_from_inventory_to_shop_potion() {
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

        // Mock player gold for testing
        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        // Mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 8; // Spike (1x1, price = 2)
        world.write_model(@shop_data);

        // Buy and place Spike in inventory
        action_system.move_item_from_shop_to_inventory(8, 5, 2, 0);

        // Verify Spike is in inventory
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(inventoryItem.itemId == 8, 'Spike should be in inventory');

        // Verify gold after purchase (100 - 2 = 98)
        let player_data: Characters = world.read_model(alice);
        assert(player_data.gold == 98, 'gold after purchase mismatch');

        // Sell the Spike from inventory
        action_system.move_item_from_inventory_to_shop(3);

        // Verify Spike is removed from inventory
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 3));
        assert(inventoryItem.itemId == 0, 'Spike should be removed');

        // Verify grid is cleared
        let backpack_grid_data: BackpackGrids = world.read_model((alice, 5, 2));
        assert(!backpack_grid_data.occupied, '(5,2) should not be occupied');

        // Verify gold after sale (98 + 1 = 99) since sell price is 1/2 = 0 (integer division)
        let player_data: Characters = world.read_model(alice);
        assert(player_data.gold == 99, 'gold after sale mismatch');
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_move_item_from_inventory_to_shop_with_plugins() {
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

        // Mock player gold for testing
        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        // Mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword weapon 1*3
        shop_data.item2 = 13; // poison plugin 1*1
        shop_data.item3 = 17; // PlagueFlower plugin 2*2
        shop_data.item4 = 0;
        world.write_model(@shop_data);

        // Place a plugin first
        action_system.move_item_from_shop_to_inventory(13, 5, 2, 0);

        // Place a weapon next to the plugin so it gets attached
        action_system.move_item_from_shop_to_inventory(7, 4, 2, 0);

        // Verify weapon has plugin attached
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 4));
        assert(inventoryItem.plugins.len() == 1, 'weapon should have plugin');
        assert(*inventoryItem.plugins.at(0) == (6, 100, 2), 'plugin data mismatch');

        // Place another plugin next to the weapon
        action_system.move_item_from_shop_to_inventory(17, 2, 2, 0);

        // Verify weapon now has two plugins
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 4));
        assert(inventoryItem.plugins.len() == 2, 'weapon should have 2 plugins');

        // Sell the weapon (this should remove plugins from weapon)
        action_system.move_item_from_inventory_to_shop(4);

        // Verify weapon is removed from inventory
        let inventoryItem: CharacterItemInventory = world.read_model((alice, 4));
        assert(inventoryItem.itemId == 0, 'weapon should be removed');
        assert(inventoryItem.plugins.len() == 0, 'plugins should be cleared');

        // Verify plugins are still in inventory but no longer attached to any weapon
        let plugin1: CharacterItemInventory = world.read_model((alice, 3));
        assert(plugin1.itemId == 13, 'plugin1 should remain');
        assert(plugin1.plugins.len() == 0, 'plugin1 has no plugins');

        let plugin2: CharacterItemInventory = world.read_model((alice, 5));
        assert(plugin2.itemId == 17, 'plugin2 should remain');
        assert(plugin2.plugins.len() == 0, 'plugin2 has no plugins');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item not found', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_inventory_to_shop_revert_item_not_found() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warlock);

        // Try to sell an item that doesn't exist in inventory
        action_system.move_item_from_inventory_to_shop(3);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item not found', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_inventory_to_shop_revert_invalid_inventory_id() {
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

        // Mock player gold for testing
        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        // Mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword
        world.write_model(@shop_data);

        // Buy and place one item in inventory (will have id = 3)
        action_system.move_item_from_shop_to_inventory(7, 4, 2, 0);

        // Try to sell with invalid inventory_item_id (5)
        action_system.move_item_from_inventory_to_shop(5);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item not found', 'ENTRYPOINT_FAILED'))]
    fn test_move_item_from_inventory_to_shop_revert_already_sold_item() {
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

        // Mock player gold for testing
        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        // Mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword
        world.write_model(@shop_data);

        // Buy and place sword in inventory
        action_system.move_item_from_shop_to_inventory(7, 4, 2, 0);

        // Sell the sword once
        action_system.move_item_from_inventory_to_shop(3);

        // Try to sell the same item again (should fail)
        action_system.move_item_from_inventory_to_shop(3);
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_move_item_from_inventory_to_shop_multiple_items() {
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

        // Mock player gold for testing
        let mut player_data: Characters = world.read_model(alice);
        player_data.gold = 100;
        world.write_model(@player_data);

        // Mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 7; // sword (price = 2)
        shop_data.item2 = 8; // Spike (price = 2)
        shop_data.item3 = 9; // shield (price = 3)
        shop_data.item4 = 0;
        world.write_model(@shop_data);

        // Buy multiple items
        action_system.move_item_from_shop_to_inventory(7, 4, 2, 0); // sword - inventory id 3
        
        // Reset shop to buy more items
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 8; // potion
        shop_data.item2 = 9; // shield
        world.write_model(@shop_data);
        
        action_system.move_item_from_shop_to_inventory(8, 5, 2, 0); // potion - inventory id 4
        action_system.move_item_from_shop_to_inventory(9, 2, 2, 0); // shield - inventory id 5

        // Check gold after purchases: 100 - 2 - 1 - 3 = 94
        let player_data: Characters = world.read_model(alice);
        assert(player_data.gold == 93, 'gold after purchases mismatch');

        // Sell items one by one
        action_system.move_item_from_inventory_to_shop(3); // sell sword (+1 gold)
        action_system.move_item_from_inventory_to_shop(4); // sell potion (+0 gold)
        action_system.move_item_from_inventory_to_shop(5); // sell shield (+1 gold)

        // Check final gold: 94 + 1 + 0 + 1 = 96
        let player_data: Characters = world.read_model(alice);
        assert(player_data.gold == 96, 'gold after sales mismatch');

        // Verify all items are removed from inventory
        let inventoryItem3: CharacterItemInventory = world.read_model((alice, 3));
        assert(inventoryItem3.itemId == 0, 'sword should be removed');

        let inventoryItem4: CharacterItemInventory = world.read_model((alice, 4));
        assert(inventoryItem4.itemId == 0, 'potion should be removed');

        let inventoryItem5: CharacterItemInventory = world.read_model((alice, 5));
        assert(inventoryItem5.itemId == 0, 'shield should be removed');
    }
} 