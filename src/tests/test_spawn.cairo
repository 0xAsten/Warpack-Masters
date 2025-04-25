#[cfg(test)]
mod tests {
    use starknet::testing::{set_contract_address, set_block_timestamp};

    use dojo::model::{ModelStorage};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef, WorldStorageTestTrait};

    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        systems::{item::{item_system, IItemDispatcher}},
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

    use warpack_masters::constants::constants::{INIT_HEALTH, INIT_GOLD, INIT_STAMINA};

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
        ].span()
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_spawn() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();

        add_items(ref item_system);

        // mocking timestamp for testing
        let timestamp = 1716770021;
        set_block_timestamp(timestamp);

        action_system.spawn('alice', WMClass::Warlock);

        let char: Characters = world.read_model(alice);
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
        assert(char.stamina == INIT_STAMINA, 'stamina mismatch');

        let storageItemsCounter: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storageItemsCounter.count == 2, 'Storage item count should be 2');

        let storageItem: CharacterItemStorage = world.read_model((alice, 1));
        assert(storageItem.itemId == 0, 'item 1 should be 0');

        let storageItem: CharacterItemStorage = world.read_model((alice, 2));
        assert(storageItem.itemId == 0, 'item 2 should be 0');

        let inventoryItemsCounter: CharacterItemsInventoryCounter = world.read_model(alice);
        assert(inventoryItemsCounter.count == 2, 'item count should be 2');

        let inventoryItem: CharacterItemInventory = world.read_model((alice, 1));
        assert(inventoryItem.itemId == 1, 'item 1 should be 1');
        assert(inventoryItem.position.x == 4, 'item 1 x should be 4');
        assert(inventoryItem.position.y == 2, 'item 1 y should be 2');
        assert(inventoryItem.rotation == 0, 'item 1 rotation should be 0');
        assert(inventoryItem.plugins.len() == 0, 'item 1 plugins should be empty');

        let inventoryItem: CharacterItemInventory = world.read_model((alice, 2));
        assert(inventoryItem.itemId == 2, 'item 2 should be 2');
        assert(inventoryItem.position.x == 2, 'item 2 x should be 4');
        assert(inventoryItem.position.y == 2, 'item 2 y should be 3');
        assert(inventoryItem.rotation == 0, 'item 1 rotation should be 0');
        assert(inventoryItem.plugins.len() == 0, 'item 1 plugins should be empty');

        let playerShopData: Shop = world.read_model(alice);
        assert(playerShopData.item1 == 0, 'item 1 should be 0');
        assert(playerShopData.item2 == 0, 'item 2 should be 0');
        assert(playerShopData.item3 == 0, 'item 3 should be 0');
        assert(playerShopData.item4 == 0, 'item 4 should be 0');

        // During spawn backpacks are added at (4,2) and (2,2) with h and w of 2 and 3 & 2 and 2
        // respectively The following grids will be enabled but not occupied
        // (4,2), (4,3), (4,4), (5,2), (5,3), (5,4), (2,2), (2,3), (3,2), (3,3)
        let playerGridData:BackpackGrids = world.read_model((alice, 4, 2));
        assert(playerGridData.enabled == true, '(4,2) should be enabled');
        assert(playerGridData.occupied == false, '(4,2) should not be occupied');
        assert(playerGridData.inventoryItemId == 0, 'should have inventory item 0');
        assert(playerGridData.itemId == 0, 'should have item 0');
        assert(playerGridData.isWeapon == false, 'should not be weapon');
        assert(playerGridData.isPlugin == false, 'should not be plugin');

        let playerGridData: BackpackGrids = world.read_model((alice, 4, 3));
        assert(playerGridData.enabled == true, '(4,3) should be enabled');
        assert(playerGridData.occupied == false, '(4,3) should not be occupied');
        assert(playerGridData.inventoryItemId == 0, 'should have inventory item 0');
        assert(playerGridData.itemId == 0, 'should have item 0');
        assert(playerGridData.isWeapon == false, 'should not be weapon');
        assert(playerGridData.isPlugin == false, 'should not be plugin');

        let playerGridData: BackpackGrids = world.read_model((alice, 4, 4));
        assert(playerGridData.enabled == true, '(4,4) should be enabled');
        assert(playerGridData.occupied == false, '(4,4) should not be occupied');
        assert(playerGridData.inventoryItemId == 0, 'should have inventory item 0');
        assert(playerGridData.itemId == 0, 'should have item 0');
        assert(playerGridData.isWeapon == false, 'should not be weapon');
        assert(playerGridData.isPlugin == false, 'should not be plugin');

        let playerGridData: BackpackGrids = world.read_model((alice, 5, 2));
        assert(playerGridData.enabled == true, '(5,2) should be enabled');
        assert(playerGridData.occupied == false, '(5,2) should not be occupied');
        assert(playerGridData.inventoryItemId == 0, 'should have inventory item 0');
        assert(playerGridData.itemId == 0, 'should have item 0');
        assert(playerGridData.isWeapon == false, 'should not be weapon');
        assert(playerGridData.isPlugin == false, 'should not be plugin');

        let playerGridData: BackpackGrids = world.read_model((alice, 5, 3));
        assert(playerGridData.enabled == true, '(5,3) should be enabled');
        assert(playerGridData.occupied == false, '(5,3) should not be occupied');
        assert(playerGridData.inventoryItemId == 0, 'should have inventory item 0');
        assert(playerGridData.itemId == 0, 'should have item 0');
        assert(playerGridData.isWeapon == false, 'should not be weapon');
        assert(playerGridData.isPlugin == false, 'should not be plugin');

        let playerGridData: BackpackGrids = world.read_model((alice, 5, 4));
        assert(playerGridData.enabled == true, '(5,4) should be enabled');
        assert(playerGridData.occupied == false, '(5,4) should not be occupied');
        assert(playerGridData.inventoryItemId == 0, 'should have inventory item 0');
        assert(playerGridData.itemId == 0, 'should have item 0');
        assert(playerGridData.isWeapon == false, 'should not be weapon');
        assert(playerGridData.isPlugin == false, 'should not be plugin');

        let playerGridData: BackpackGrids = world.read_model((alice, 2, 2));
        assert(playerGridData.enabled == true, '(2,2) should be enabled');
        assert(playerGridData.occupied == false, '(2,2) should not be occupied');
        assert(playerGridData.inventoryItemId == 0, 'should have inventory item 0');
        assert(playerGridData.itemId == 0, 'should have item 0');
        assert(playerGridData.isWeapon == false, 'should not be weapon');
        assert(playerGridData.isPlugin == false, 'should not be plugin');

        let playerGridData: BackpackGrids = world.read_model((alice, 2, 3));
        assert(playerGridData.enabled == true, '(2,3) should be enabled');
        assert(playerGridData.occupied == false, '(2,3) should not be occupied');
        assert(playerGridData.inventoryItemId == 0, 'should have inventory item 0');
        assert(playerGridData.itemId == 0, 'should have item 0');
        assert(playerGridData.isWeapon == false, 'should not be weapon');
        assert(playerGridData.isPlugin == false, 'should not be plugin');

        let playerGridData: BackpackGrids = world.read_model((alice, 3, 2));
        assert(playerGridData.enabled == true, '(3,2) should be enabled');
        assert(playerGridData.occupied == false, '(3,2) should not be occupied');
        assert(playerGridData.inventoryItemId == 0, 'should have inventory item 0');
        assert(playerGridData.itemId == 0, 'should have item 0');
        assert(playerGridData.isWeapon == false, 'should not be weapon');
        assert(playerGridData.isPlugin == false, 'should not be plugin');

        let playerGridData: BackpackGrids = world.read_model((alice, 3, 3));
        assert(playerGridData.enabled == true, '(3,3) should be enabled');
        assert(playerGridData.occupied == false, '(3,3) should not be occupied');
        assert(playerGridData.inventoryItemId == 0, 'should have inventory item 0');
        assert(playerGridData.itemId == 0, 'should have item 0');
        assert(playerGridData.isWeapon == false, 'should not be weapon');
        assert(playerGridData.isPlugin == false, 'should not be plugin');
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('name cannot be empty', 'ENTRYPOINT_FAILED'))]
    fn test_name_is_empty() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        action_system.spawn('', WMClass::Warlock);
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('player already exists', 'ENTRYPOINT_FAILED'))]
    fn test_player_already_exists() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        add_items(ref item_system);

        action_system.spawn('alice', WMClass::Warlock);
        action_system.spawn('bob', WMClass::Warlock);
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('name already exists', 'ENTRYPOINT_FAILED'))]
    fn test_name_already_exists() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

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
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        add_items(ref item_system);

        let alice = starknet::contract_address_const::<0x1>();

        // mocking timestamp for testing
        let timestamp = 1716770021;
        set_block_timestamp(timestamp);

        set_contract_address(alice);

        action_system.spawn('alice', WMClass::Archer);

        let char: Characters = world.read_model(alice);
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
        assert(char.stamina == INIT_STAMINA, 'stamina mismatch');
    }
}

