#[cfg(test)]
mod tests {
    use dojo::model::ModelStorage;
    use dojo::world::{WorldStorageTrait, world};
    use dojo_cairo_test::{
        ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
        spawn_test_world,
    };
    use starknet::ContractAddress;
    use starknet::testing::{set_block_timestamp, set_contract_address};
    use warpack_masters::constants::constants::{
        GAME_CONFIG_ID, INIT_GOLD, INIT_HEALTH, REBIRTH_FEE,
    };
    use warpack_masters::externals::erc20_mintable::MintableERC20Token;
    use warpack_masters::externals::interface::{
        IERC20MINTABLEDispatcher, IERC20MINTABLEDispatcherTrait,
    };
    use warpack_masters::models::Character::{Character, WMClass, m_Character, m_CharacterName};
    use warpack_masters::models::CharacterItem::{
        InventoryCounter, InventoryItem, StorageCounter, StorageItem, m_InventoryCounter,
        m_InventoryItem, m_StorageCounter, m_StorageItem, m_CharacterItemInventory,
    };
    use warpack_masters::models::Game::{GameConfig, m_GameConfig};
    use warpack_masters::models::Item::{m_Item, m_ItemsCounter};
    use warpack_masters::models::Shop::m_Shop;
    use warpack_masters::models::backpack::m_BackpackGrids;
    use warpack_masters::systems::actions::{IActionsDispatcher, IActionsDispatcherTrait, actions};
    use warpack_masters::systems::item::{IItemDispatcher, item_system};
    use warpack_masters::systems::fight::{IFightDispatcher, IFightDispatcherTrait, fight};
    use warpack_masters::utils::test_utils::{add_items, deploy_contract};

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "Warpacks",
            resources: [
                TestResource::Model(m_BackpackGrids::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Item::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_ItemsCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_StorageItem::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_StorageCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemInventory::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_InventoryCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Character::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterName::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Shop::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_GameConfig::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Contract(actions::TEST_CLASS_HASH),
                TestResource::Contract(item_system::TEST_CLASS_HASH),
                TestResource::Contract(fight::TEST_CLASS_HASH),
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
            ContractDefTrait::new(@"Warpacks", @"fight_system")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
        ]
            .span()
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_deployment_flow() {
        // 1. Setup World
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (actions_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address: actions_address };

        let (fight_address, _) = world.dns(@"fight_system").unwrap();
        
        let (item_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address: item_address };

        // 2. Deploy ERC20 Token (Simulating "Declare and Deploy external contracts")
        let alice = warpack_masters::utils::address::address_from('alice');
        let mock_erc20_calldata: Array<felt252> = array![
            0, 'Gold', 4, 0, 'GLD', 4, 1000000000000000000000, 0, alice.into(), alice.into(),
        ];
        let erc20_address = deploy_contract(
            MintableERC20Token::TEST_CLASS_HASH.try_into().unwrap(), mock_erc20_calldata.span(),
        );

        // 3. Grant Minter Role (Simulating "Grant mint permisson")
        // MINTER_ROLE = 0x032df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6 (keccak256("MINTER_ROLE"))
        // But in OpenZeppelin v0.8.1 (which MintableERC20Token likely uses or mimics), we might need to check the exact role hash.
        // Assuming standard AccessControl.
        // The SETUP.md mentions 0x032df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6.
        let minter_role = 0x032df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
        
        let erc20_dispatcher = IERC20MINTABLEDispatcher { contract_address: erc20_address };
        
        // Alice deployed it, so she is admin (default admin role usually 0x00).
        // She grants minter role to systems.
        set_contract_address(alice);
        erc20_dispatcher.grant_role(minter_role, actions_address);
        erc20_dispatcher.grant_role(minter_role, fight_address);

        // 4. Configure Game (Setting the token address in GameConfig)
        // This step is implicit in SETUP.md but required for the game to work.
        set_contract_address(warpack_masters::utils::address::zero_address()); // Back to world admin? Or whoever has permission to write GameConfig.
        // In tests, we often write directly to world for config.
        world.write_model(
            @GameConfig {
                id: GAME_CONFIG_ID,
                strk_address: erc20_address,
                rebirth_fee: REBIRTH_FEE,
            },
        );

        // 5. Add Items (Prerequisite for spawning)
        add_items(ref item_system);

        // 6. Spawn Character (Simulating user interaction)
        set_contract_address(alice);
        // Approve actions system to spend tokens (if there's an entry fee, though spawn usually mints or is free?)
        // Checking spawn logic: it mints initial gold.
        
        action_system.spawn('alice', WMClass::Warlock);

        // 7. Verify Spawn
        let char: Character = world.read_model(alice);
        assert(char.name == 'alice', 'Character name mismatch');
        assert(char.wmClass == WMClass::Warlock, 'Character class mismatch');
        assert(char.gold == INIT_GOLD, 'Initial gold mismatch'); // Spawn gives INIT_GOLD
        
        // Verify token balance (Spawn mints INIT_GOLD tokens to the player)
        let balance = erc20_dispatcher.balance_of(alice);
        assert(balance == INIT_GOLD.into(), 'Token balance mismatch');
    }
}
