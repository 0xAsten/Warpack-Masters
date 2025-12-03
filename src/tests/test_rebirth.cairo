#[cfg(test)]
mod tests {
    use dojo::model::ModelStorage;
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{
        ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
        deploy_contract, spawn_test_world,
    };
    use openzeppelin_interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::testing::{set_block_timestamp, set_contract_address};
    use warpack_masters::constants::constants::{
        GAME_CONFIG_ID, INIT_GOLD, INIT_HEALTH, MAX_LOSSES_BEFORE_REBIRTH, REBIRTH_FEE,
    };
    use warpack_masters::externals::erc20::ERC20Token;
    use warpack_masters::models::Character::{
        Character, CharacterName, WMClass, m_Character, m_CharacterName,
    };
    use warpack_masters::models::CharacterItem::{
        InventoryCounter, InventoryItem, StorageCounter, StorageItem, m_InventoryCounter,
        m_InventoryItem, m_StorageCounter, m_StorageItem,
    };
    use warpack_masters::models::Game::{GameConfig, m_GameConfig};
    use warpack_masters::models::Item::{m_Item, m_ItemsCounter};
    use warpack_masters::models::Shop::{Shop, m_Shop};
    use warpack_masters::models::backpack::{BackpackGrids, m_BackpackGrids};
    use warpack_masters::systems::actions::{IActionsDispatcher, IActionsDispatcherTrait, actions};
    use warpack_masters::systems::item::{IItemDispatcher, item_system};
    use warpack_masters::utils::test_utils::add_items;

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "Warpacks",
            resources: [
                TestResource::Model(m_BackpackGrids::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Item::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_ItemsCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_StorageItem::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_StorageCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_InventoryItem::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_InventoryCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Character::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterName::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Shop::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_GameConfig::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Contract(actions::TEST_CLASS_HASH),
                TestResource::Contract(item_system::TEST_CLASS_HASH),
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
        ]
            .span()
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_rebirth() {
        let alice = warpack_masters::utils::address::address_from('alice');
        let default_address = warpack_masters::utils::address::zero_address();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (actions_contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address: actions_contract_address };

        let (item_contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address: item_contract_address };

        let mock_erc20_calldata: Array<felt252> = array![
            0, 'stark', 1, 0, 'strk', 1, 10000000000000000000, 0, alice.into(), alice.into(),
        ];
        let erc20_address = deploy_contract(
            ERC20Token::TEST_CLASS_HASH, mock_erc20_calldata.span(),
        );
        world.write_model(
            @GameConfig {
                id: GAME_CONFIG_ID,
                strk_address: erc20_address,
                rebirth_fee: REBIRTH_FEE,
            },
        );

        add_items(ref item_system);

        set_contract_address(alice);
        let erc20_dispatcher = IERC20Dispatcher { contract_address: erc20_address };
        erc20_dispatcher.approve(actions_contract_address, 10000000000000000000);

        action_system.spawn('alice', WMClass::Warlock);

        set_contract_address(default_address);
        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 5;
        shop_data.item2 = 6;
        shop_data.item3 = 8;
        shop_data.item4 = 1;
        world.write_model(@shop_data);

        set_contract_address(alice);
        action_system.move_item_from_shop_to_storage(5);
        action_system.move_item_from_shop_to_storage(6);
        action_system.move_item_from_shop_to_storage(8);

        action_system.move_item_from_storage_to_inventory(2, 4, 2, 0);
        action_system.move_item_from_storage_to_inventory(1, 2, 2, 0);
        action_system.move_item_from_storage_to_inventory(3, 5, 2, 0);

        set_contract_address(default_address);
        let mut char: Character = world.read_model(alice);
        char.loss = MAX_LOSSES_BEFORE_REBIRTH.into();
        char.rating = 300;
        char.totalWins = 10;
        char.totalLoss = 4;
        char.winStreak = 3;
        world.write_model(@char);

        // mocking timestamp for testing
        let timestamp = 1717770021;
        set_block_timestamp(timestamp);

        set_contract_address(alice);
        action_system.rebirth();

        set_contract_address(default_address);
        let char: Character = world.read_model(alice);
        let inventoryItemsCounter: InventoryCounter = world.read_model(alice);
        let storageItemsCounter: StorageCounter = world.read_model(alice);
        let playerShopData: Shop = world.read_model(alice);

        assert(char.wins == 0, 'wins count should be 0');
        assert(char.loss == 0, 'loss count should be 0');
        assert(char.wmClass == WMClass::Warlock, 'class should be Warlock');
        assert(char.name == 'alice', 'name should be alice');
        assert(char.gold == INIT_GOLD + 1, 'gold should be init');
        assert(char.health == INIT_HEALTH, 'health should be init');
        assert(char.rating == 300, 'Rating mismatch');
        assert(char.totalWins == 10, 'total wins should be 10');
        assert(char.totalLoss == 4, 'total loss should be 4');
        assert(char.winStreak == 0, 'win streak should be 0');
        assert(char.birthCount == 2, 'birth count should be 2');
        assert(char.updatedAt == timestamp, 'updatedAt mismatch');
        assert(char.stamina == 100, 'stamina should be INIT');

        assert(inventoryItemsCounter.count == 2, 'item count should be 0');
        assert(storageItemsCounter.count == 2, 'item count should be 0');

        assert(playerShopData.item1 == 0, 'item 1 should be 0');
        assert(playerShopData.item2 == 0, 'item 2 should be 0');
        assert(playerShopData.item3 == 0, 'item 3 should be 0');
        assert(playerShopData.item4 == 0, 'item 4 should be 0');

        let storageItem: StorageItem = world.read_model((alice, 1));
        assert(storageItem.itemId == 0, 'item 1 should be 0');

        let storageItem: StorageItem = world.read_model((alice, 2));
        assert(storageItem.itemId == 0, 'item 2 should be 0');

        let inventoryItem: InventoryItem = world.read_model((alice, 1));
        assert(inventoryItem.itemId == 1, 'item 1 should be 1');
        assert(inventoryItem.position.x == 4, 'item 1 x should be 4');
        assert(inventoryItem.position.y == 2, 'item 1 y should be 2');
        assert(inventoryItem.rotation == 0, 'item 1 rotation should be 0');
        assert(inventoryItem.plugins.len() == 0, 'item 1 plugins should be empty');

        let inventoryItem: InventoryItem = world.read_model((alice, 2));
        assert(inventoryItem.itemId == 2, 'item 2 should be 2');
        assert(inventoryItem.position.x == 2, 'item 2 x should be 4');
        assert(inventoryItem.position.y == 2, 'item 2 y should be 3');
        assert(inventoryItem.rotation == 0, 'item 2 rotation should be 0');
        assert(inventoryItem.plugins.len() == 0, 'item 2 plugins should be empty');

        let playerGridData: BackpackGrids = world.read_model((alice, 4, 2));
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
    #[should_panic(expected: ('loss not reached', 'ENTRYPOINT_FAILED'))]
    fn test_loss_not_reached() {
        let alice = warpack_masters::utils::address::zero_address();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        add_items(ref item_system);

        action_system.spawn('alice', WMClass::Warlock);

        let mut char: Character = world.read_model(alice);
        char.loss = (MAX_LOSSES_BEFORE_REBIRTH - 1).into();
        world.write_model(@char);

        action_system.rebirth();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('name already exists', 'ENTRYPOINT_FAILED'))]
    fn test_name_already_exists() {
        let default_address = warpack_masters::utils::address::zero_address();
        let alice = warpack_masters::utils::address::address_from('alice');
        let bob = warpack_masters::utils::address::address_from('bob');

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        add_items(ref item_system);

        set_contract_address(alice);
        action_system.spawn('alice', WMClass::Warlock);

        set_contract_address(default_address);
        let mut char: Character = world.read_model(alice);
        char.loss = MAX_LOSSES_BEFORE_REBIRTH.into();
        world.write_model(@char);

        set_contract_address(bob);
        action_system.spawn('alice', WMClass::Warlock);
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_rebirth_with_same_name() {
        let default_address = warpack_masters::utils::address::zero_address();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (actions_contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address: actions_contract_address };

        let (item_contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address: item_contract_address };

        let alice = warpack_masters::utils::address::address_from('alice');

        let mock_erc20_calldata: Array<felt252> = array![
            0, 'stark', 1, 0, 'strk', 1, 10000000000000000000, 0, alice.into(), alice.into(),
        ];

        let erc20_address = deploy_contract(
            ERC20Token::TEST_CLASS_HASH, mock_erc20_calldata.span(),
        );

        world.write_model(
            @GameConfig {
                id: GAME_CONFIG_ID,
                strk_address: erc20_address,
                rebirth_fee: REBIRTH_FEE,
            },
        );

        add_items(ref item_system);

        set_contract_address(alice);
        let erc20_dispatcher = IERC20Dispatcher { contract_address: erc20_address };
        erc20_dispatcher.approve(actions_contract_address, 10000000000000000000);

        action_system.spawn('alice', WMClass::Warlock);

        let nameRecord: NameRecord = world.read_model('alice');
        assert(nameRecord.player == alice, 'player should be alice - 1');

        set_contract_address(default_address);

        let mut char: Character = world.read_model(alice);
        char.loss = MAX_LOSSES_BEFORE_REBIRTH.into();
        world.write_model(@char);

        set_contract_address(alice);
        action_system.rebirth();

        let nameRecord: NameRecord = world.read_model('alice');
        assert(nameRecord.player == alice, 'player should be alice - 2');
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_rebirth_with_different_name() {
        let alice = warpack_masters::utils::address::address_from('alice');
        let default_address = warpack_masters::utils::address::zero_address();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (actions_contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address: actions_contract_address };

        let (item_contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address: item_contract_address };
        add_items(ref item_system);

        let mock_erc20_calldata: Array<felt252> = array![
            0, 'stark', 1, 0, 'strk', 1, 10000000000000000000, 0, alice.into(), alice.into(),
        ];
        let erc20_address = deploy_contract(
            ERC20Token::TEST_CLASS_HASH, mock_erc20_calldata.span(),
        );
        world.write_model(
            @GameConfig {
                id: GAME_CONFIG_ID,
                strk_address: erc20_address,
                rebirth_fee: REBIRTH_FEE,
            },
        );

        set_contract_address(alice);
        let erc20_dispatcher = IERC20Dispatcher { contract_address: erc20_address };
        erc20_dispatcher.approve(actions_contract_address, 10000000000000000000);

        action_system.spawn('alice', WMClass::Warlock);

        set_contract_address(default_address);

        let nameRecord: NameRecord = world.read_model('alice');
        assert(nameRecord.player == alice, 'player should be alice');

        let mut char: Character = world.read_model(alice);
        char.loss = MAX_LOSSES_BEFORE_REBIRTH.into();
        world.write_model(@char);

        set_contract_address(alice);
        action_system.rebirth();

        set_contract_address(default_address);
        let nameRecord: NameRecord = world.read_model('alice');
        assert(nameRecord.player == alice, 'player should be alice');

        let nameRecord: NameRecord = world.read_model('alice');
        assert(nameRecord.player == alice, 'player should be alice');
    }
}
