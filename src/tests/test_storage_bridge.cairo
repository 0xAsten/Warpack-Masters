#[cfg(test)]
mod tests {
    use starknet::testing::{set_contract_address};
    use starknet::{contract_address_const, ContractAddress};

    use dojo::model::{ModelStorage};
    use dojo::world::storage::WorldStorage;
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef, WorldStorageTestTrait};

    use warpack_masters::{
        systems::{storage_bridge::{storage_bridge, IStorageBridgeDispatcher, IStorageBridgeDispatcherTrait}},
        systems::{token_factory::{token_factory, ITokenFactoryDispatcher, ITokenFactoryDispatcherTrait}},
        systems::{item::{item_system, IItemDispatcher}},
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::backpack::{m_BackpackGrids},
        models::Item::{m_Item, m_ItemsCounter},
        models::TokenRegistry::{m_TokenRegistry},
        models::CharacterItem::{
            CharacterItemStorage, m_CharacterItemStorage, CharacterItemsStorageCounter,
            m_CharacterItemsStorageCounter, m_CharacterItemInventory,
            m_CharacterItemsInventoryCounter
        },
        models::Character::{m_Characters, m_NameRecord, WMClass},
        models::Shop::{m_Shop},
        utils::{test_utils::{add_items}},
        externals::erc20::{ERC20Token},
        constants::constants::{TOKEN_SUPPLY_BASE}
    };

    use warpack_masters::{items};

    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "Warpacks", 
            resources: [
                TestResource::Model(m_BackpackGrids::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Item::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_ItemsCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_TokenRegistry::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemStorage::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemsStorageCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemInventory::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemsInventoryCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Characters::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_NameRecord::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Shop::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Contract(storage_bridge::TEST_CLASS_HASH),
                TestResource::Contract(token_factory::TEST_CLASS_HASH),
                TestResource::Contract(item_system::TEST_CLASS_HASH),
                TestResource::Contract(actions::TEST_CLASS_HASH),
                TestResource::Event(storage_bridge::e_DepositItem::TEST_CLASS_HASH),
                TestResource::Event(storage_bridge::e_WithdrawItem::TEST_CLASS_HASH),
            ].span()
        };
 
        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"Warpacks", @"storage_bridge")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
            ContractDefTrait::new(@"Warpacks", @"token_factory")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
            ContractDefTrait::new(@"Warpacks", @"item_system")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
            ContractDefTrait::new(@"Warpacks", @"actions")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
        ].span()
    }

    fn setup_test_environment() -> (ContractAddress, ContractAddress, IStorageBridgeDispatcher, ITokenFactoryDispatcher, IActionsDispatcher, WorldStorage) {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (storage_bridge_address, _) = world.dns(@"storage_bridge").unwrap();
        let storage_bridge = IStorageBridgeDispatcher { contract_address: storage_bridge_address };

        let (token_factory_address, _) = world.dns(@"token_factory").unwrap();
        let token_factory = ITokenFactoryDispatcher { contract_address: token_factory_address };

        let (item_contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address: item_contract_address };

        let (actions_address, _) = world.dns(@"actions").unwrap();
        let actions = IActionsDispatcher { contract_address: actions_address };

        // Add items to the world
        add_items(ref item_system);

        let alice = contract_address_const::<'alice'>();
        let default_address = contract_address_const::<0x0>();
        (alice, default_address, storage_bridge, token_factory, actions, world)
    }

    fn create_token_and_setup_storage(alice: ContractAddress, default_address: ContractAddress, item_id: u32, token_factory: ITokenFactoryDispatcher, actions: IActionsDispatcher, mut world: WorldStorage) -> ContractAddress {
        // Create token for item
        let token_address = token_factory.create_token_for_item(
            item_id,
            items::Dagger::name(),
            "DAG",
            alice,
            ERC20Token::TEST_CLASS_HASH.try_into().unwrap()
        );

        // Spawn character and add item to storage
        set_contract_address(alice);
        actions.spawn('Alice', WMClass::Warrior);

        // Manually add item to storage
        set_contract_address(default_address);
        let storage_counter = CharacterItemsStorageCounter { player: alice, count: 1 };
        let storage_item = CharacterItemStorage { player: alice, id: 1, itemId: item_id };
        world.write_model(@storage_counter);
        world.write_model(@storage_item);

        token_address
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_deposit_item_success() {
        let (alice, default_address, storage_bridge, token_factory, actions, mut world) = setup_test_environment();
        let item_id = 6; // Dagger
        
        let token_address = create_token_and_setup_storage(alice, default_address, item_id, token_factory, actions, world);

        // Give the storage bridge contract some tokens to transfer
        set_contract_address(alice);
        let token_contract = IERC20Dispatcher { contract_address: token_address };
        let token_amount = 1 * 1_000_000_000_000_000_000;
        token_contract.transfer(storage_bridge.contract_address, token_amount * 10); // Give it some tokens

        let player_balance = token_contract.balance_of(alice);
        assert(player_balance == TOKEN_SUPPLY_BASE - token_amount * 10, 'Player should have tokens');

        // Call deposit_item
        storage_bridge.deposit_item(1);

        // Verify the storage item was removed
        set_contract_address(default_address);
        let storage_item: CharacterItemStorage = world.read_model((alice, 1));
        assert(storage_item.itemId == 0, 'Storage item should be removed');

        // Verify tokens were transferred to player
        let player_balance = token_contract.balance_of(alice);
        assert(player_balance == TOKEN_SUPPLY_BASE - token_amount * 9, 'Player should receive tokens');
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_withdraw_item_success() {
        let (alice, default_address, storage_bridge, token_factory, actions, mut world) = setup_test_environment();
        let item_id = 6; // Dagger
        
        let token_address = create_token_and_setup_storage(alice, default_address, item_id, token_factory, actions, world);

        // Give player some tokens and approve storage bridge
        set_contract_address(alice);
        let token_contract = IERC20Dispatcher { contract_address: token_address };
        let token_amount = 1 * 1_000_000_000_000_000_000;
        token_contract.approve(storage_bridge.contract_address, token_amount);

        // Call withdraw_item
        storage_bridge.withdraw_item(item_id);

        // Verify item was added to storage
        set_contract_address(default_address);
        let storage_counter: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storage_counter.count == 2, 'Storage count should increase');

        let storage_item: CharacterItemStorage = world.read_model((alice, 2));
        assert(storage_item.itemId == item_id, 'Item should be in storage');

        // Verify tokens were transferred from player
        let player_balance = token_contract.balance_of(alice);
        assert(player_balance == TOKEN_SUPPLY_BASE - token_amount, 'Player tokens should be spent');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('Storage item does not exist', 'ENTRYPOINT_FAILED'))]
    fn test_deposit_item_nonexistent_storage_item() {
        let (alice, default_address, storage_bridge, token_factory, actions, mut world) = setup_test_environment();
        let item_id = 6; // Dagger
        
        create_token_and_setup_storage(alice, default_address, item_id, token_factory, actions, world);

        set_contract_address(alice);
        // Try to deposit non-existent storage item
        storage_bridge.deposit_item(999);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('Storage item does not exist', 'ENTRYPOINT_FAILED'))]
    fn test_deposit_item_empty_storage_slot() {
        let (alice, default_address, storage_bridge, token_factory, actions, mut world) = setup_test_environment();
        let item_id = 6; // Dagger
        
        create_token_and_setup_storage(alice, default_address, item_id, token_factory, actions, world);

        // Create empty storage slot
        let empty_storage_item = CharacterItemStorage { player: alice, id: 2, itemId: 0 };
        world.write_model(@empty_storage_item);

        set_contract_address(alice);
        // Try to deposit from empty storage slot
        storage_bridge.deposit_item(2);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('Token not registered', 'ENTRYPOINT_FAILED'))]
    fn test_deposit_item_token_not_registered() {
        let (alice, default_address, storage_bridge, _, actions, mut world) = setup_test_environment();
        let item_id = 9; // Shield - no token created for this
        
        // Setup storage without creating token
        set_contract_address(alice);
        actions.spawn('Alice', WMClass::Warrior);

        set_contract_address(default_address);
        let storage_counter = CharacterItemsStorageCounter { player: alice, count: 1 };
        let storage_item = CharacterItemStorage { player: alice, id: 1, itemId: item_id };
        world.write_model(@storage_counter);
        world.write_model(@storage_item);

        // Try to deposit item without token
        set_contract_address(alice);
        storage_bridge.deposit_item(1);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('Item does not exist', 'ENTRYPOINT_FAILED'))]
    fn test_withdraw_item_nonexistent_item() {
        let (alice, _, storage_bridge, _, actions, _) = setup_test_environment();
        
        set_contract_address(alice);
        actions.spawn('Alice', WMClass::Warrior);

        // Try to withdraw non-existent item
        storage_bridge.withdraw_item(999);
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_withdraw_item_creates_new_storage_slot() {
        let (alice, default_address, storage_bridge, token_factory, actions, mut world) = setup_test_environment();
        let item_id = 6; // Dagger
        
        let token_address = create_token_and_setup_storage(alice, default_address, item_id, token_factory, actions, world);

        // Fill the existing storage slot
        let mut existing_storage: CharacterItemStorage = world.read_model((alice, 1));
        existing_storage.itemId = 9; // Different item
        world.write_model(@existing_storage);

        // Give tokens and approve
        set_contract_address(alice);
        let token_contract = IERC20Dispatcher { contract_address: token_address };
        let token_amount = 1 * 1_000_000_000_000_000_000;
        token_contract.transfer(storage_bridge.contract_address, token_amount);
        token_contract.approve(storage_bridge.contract_address, token_amount);

        // Withdraw item - should create new storage slot
        storage_bridge.withdraw_item(item_id);

        // Verify new slot was created
        set_contract_address(default_address);
        let storage_counter: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storage_counter.count == 2, 'Storage count should be 2');

        let new_storage_item: CharacterItemStorage = world.read_model((alice, 2));
        assert(new_storage_item.itemId == item_id, 'Item should be in new slot');
    }
}
