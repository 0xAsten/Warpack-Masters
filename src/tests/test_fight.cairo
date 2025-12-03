#[cfg(test)]
mod tests {
    use dojo::model::ModelStorage;
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{
        ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
        spawn_test_world,
    };
    use starknet::testing::set_contract_address;
    use warpack_masters::constants::constants::{
        INIT_GOLD, INIT_HEALTH, MAX_LOSSES_BEFORE_REBIRTH,
    };
    use warpack_masters::models::Character::{
        Character, CharacterName, PLAYER, WMClass, m_Character, m_CharacterName,
    };
    use warpack_masters::models::CharacterItem::{
        InventoryCounter, InventoryItem, Position, m_InventoryCounter, m_InventoryItem,
        m_StorageCounter, m_StorageItem,
    };
    use warpack_masters::models::DummyCharacter::{m_DummyCharacter, m_DummyCharacterCounter};
    use warpack_masters::models::DummyCharacterItem::{
        m_DummyCharacterItem, m_DummyCharacterItemsCounter,
    };
    use warpack_masters::models::Fight::{
        BattleLog, e_BattleLogDetail, m_BattleLog, m_BattleLogCounter,
    };
    use warpack_masters::models::Game::m_GameConfig;
    use warpack_masters::models::Item::{m_Item, m_ItemsCounter};
    use warpack_masters::models::backpack::m_BackpackGrids;
    use warpack_masters::systems::actions::{IActionsDispatcher, IActionsDispatcherTrait, actions};
    use warpack_masters::systems::dummy::{IDummyDispatcher, dummy_system};
    use warpack_masters::systems::fight::{IFightDispatcher, IFightDispatcherTrait, fight_system};
    use warpack_masters::systems::item::{IItemDispatcher, item_system};
    use warpack_masters::utils::test_utils::{add_dummy, add_items};

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "Warpacks",
            resources: [
                TestResource::Model(m_BackpackGrids::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Item::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_ItemsCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Character::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterName::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_DummyCharacter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_DummyCharacterCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_DummyCharacterItem::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(
                    m_DummyCharacterItemsCounter::TEST_CLASS_HASH.try_into().unwrap(),
                ),
                TestResource::Model(m_BattleLog::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_BattleLogCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_InventoryItem::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_InventoryCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_StorageItem::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_StorageCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_GameConfig::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Event(e_BattleLogDetail::TEST_CLASS_HASH),
                TestResource::Contract(actions::TEST_CLASS_HASH),
                TestResource::Contract(item_system::TEST_CLASS_HASH),
                TestResource::Contract(fight_system::TEST_CLASS_HASH),
                TestResource::Contract(dummy_system::TEST_CLASS_HASH),
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
            ContractDefTrait::new(@"Warpacks", @"dummy_system")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
        ]
            .span()
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('no new match found', 'ENTRYPOINT_FAILED'))]
    fn test_no_new_matching_battle() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"fight_system").unwrap();
        let mut fight_system = IFightDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"dummy_system").unwrap();
        let mut dummy_system = IDummyDispatcher { contract_address };

        add_items(ref item_system);
        add_dummy(ref dummy_system);

        action_system.spawn('alice', WMClass::Warlock);

        fight_system.fight();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('no dummy created', 'ENTRYPOINT_FAILED'))]
    fn test_dummy_not_created() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"fight_system").unwrap();
        let mut fight_system = IFightDispatcher { contract_address };

        add_items(ref item_system);

        action_system.spawn('alice', WMClass::Warlock);

        fight_system.match_dummy();
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('battle not fought', 'ENTRYPOINT_FAILED'))]
    fn test_battle_not_fought() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"fight_system").unwrap();
        let mut fight_system = IFightDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"dummy_system").unwrap();
        let mut dummy_system = IDummyDispatcher { contract_address };

        add_items(ref item_system);
        add_dummy(ref dummy_system);

        action_system.spawn('alice', WMClass::Warlock);

        let bob = warpack_masters::utils::address::address_from(0x1);
        set_contract_address(bob);
        action_system.spawn('bob', WMClass::Warlock);

        fight_system.match_dummy();
        fight_system.match_dummy();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('max loss reached', 'ENTRYPOINT_FAILED'))]
    fn test_max_loss_reached() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"fight_system").unwrap();
        let mut fight_system = IFightDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"dummy_system").unwrap();
        let mut dummy_system = IDummyDispatcher { contract_address };

        add_items(ref item_system);
        add_dummy(ref dummy_system);

        let alice = warpack_masters::utils::address::zero_address();

        action_system.spawn('alice', WMClass::Warlock);

        // Update character loss count
        let mut char: Character = world.read_model(alice);
        char.loss = MAX_LOSSES_BEFORE_REBIRTH.into();
        world.write_model(@char);

        fight_system.match_dummy();
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_fight() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"fight_system").unwrap();
        let mut fight_system = IFightDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"dummy_system").unwrap();
        let mut dummy_system = IDummyDispatcher { contract_address };

        let alice = warpack_masters::utils::address::zero_address();

        add_items(ref item_system);
        add_dummy(ref dummy_system);

        action_system.spawn('alice', WMClass::Warlock);

        // Add items for Alice
        let mut inventoryCounter: InventoryCounter = world.read_model(alice);

        // add Herb id 5, on start +1 regen
        inventoryCounter.count += 1;
        let item1 = CharacterItemInventory {
            player: alice,
            id: inventoryCounter.count,
            itemId: 5,
            position: Position { x: 0, y: 0 },
            rotation: 0,
            plugins: array![],
        };

        // add Dagger id 6, damage 3, cooldown 4
        inventoryCounter.count += 1;
        let item2 = CharacterItemInventory {
            player: alice,
            id: inventoryCounter.count,
            itemId: 6,
            position: Position { x: 0, y: 0 },
            rotation: 0,
            plugins: array![],
        };

        // add Spike id 8, on start +1 reflect
        inventoryCounter.count += 1;
        let item3 = CharacterItemInventory {
            player: alice,
            id: inventoryCounter.count,
            itemId: 8,
            position: Position { x: 0, y: 0 },
            rotation: 0,
            plugins: array![],
        };

        // add SpikeShield id 16, chance 75, on hit +2 reflect
        inventoryCounter.count += 1;
        let item4 = CharacterItemInventory {
            player: alice,
            id: inventoryCounter.count,
            itemId: 16,
            position: Position { x: 0, y: 0 },
            rotation: 0,
            plugins: array![],
        };

        world.write_model(@inventoryCounter);
        world.write_model(@item1);
        world.write_model(@item2);
        world.write_model(@item3);
        world.write_model(@item4);

        // Add items for Bob
        let bob = warpack_masters::utils::address::address_from(0x1);
        set_contract_address(bob);
        action_system.spawn('bob', WMClass::Warlock);

        let mut inventoryCounter: InventoryCounter = world.read_model(bob);

        // add Sword id 7, damage 5, cooldown 5
        inventoryCounter.count += 1;
        let item1 = CharacterItemInventory {
            player: bob,
            id: inventoryCounter.count,
            itemId: 7,
            position: Position { x: 0, y: 0 },
            rotation: 0,
            plugins: array![],
        };

        // add Shield id 9, on start +15 armor
        inventoryCounter.count += 1;
        let item2 = CharacterItemInventory {
            player: bob,
            id: inventoryCounter.count,
            itemId: 9,
            position: Position { x: 0, y: 0 },
            rotation: 0,
            plugins: array![],
        };

        // add Helmet id 10, chance 50, on hit +3 armor
        inventoryCounter.count += 1;
        let item3 = CharacterItemInventory {
            player: bob,
            id: inventoryCounter.count,
            itemId: 10,
            position: Position { x: 0, y: 0 },
            rotation: 0,
            plugins: array![],
        };

        // add Poison id 13, on start +2 posion
        inventoryCounter.count += 1;
        let item4 = CharacterItemInventory {
            player: bob,
            id: inventoryCounter.count,
            itemId: 13,
            position: Position { x: 0, y: 0 },
            rotation: 0,
            plugins: array![],
        };

        // add Dagger id 6, damage 3, cooldown 4
        inventoryCounter.count += 1;
        let item5 = CharacterItemInventory {
            player: bob,
            id: inventoryCounter.count,
            itemId: 6,
            position: Position { x: 0, y: 0 },
            rotation: 0,
            plugins: array![],
        };

        set_contract_address(alice);
        world.write_model(@inventoryCounter);
        world.write_model(@item1);
        world.write_model(@item2);
        world.write_model(@item3);
        world.write_model(@item4);
        world.write_model(@item5);

        set_contract_address(bob);
        fight_system.match_dummy();
        fight_system.fight();

        let battleLog: BattleLog = world.read_model((bob, 1));
        assert(battleLog.winner != 0, 'winner should not be 0');
        assert(battleLog.seconds > 0, 'seconds be greater than 0');

        let char: Character = world.read_model(bob);

        if battleLog.winner == PLAYER {
            assert(char.wins == 1, 'wins should be 1');
            assert(char.totalWins == 1, 'totalWins should be 1');
            assert(char.winStreak == 1, 'winStreak should be 1');
            assert(char.gold == INIT_GOLD + 6, 'gold should be INIT_GOLD + 6');
            assert(char.health == INIT_HEALTH + 10, 'health be INIT_HEALTH + 10');
            assert(char.rating == 25, 'rating should be 25');
            assert(char.loss == 0, 'loss should be 0');
            assert(char.totalLoss == 0, 'totalLoss should be 0');
        } else {
            assert(char.wins == 0, 'wins should be 0');
            assert(char.totalWins == 0, 'totalWins should be 0');
            assert(char.winStreak == 0, 'winStreak should be 0');
            assert(char.gold == INIT_GOLD + 6, 'gold be INIT_GOLD + 6');
            assert(char.health == INIT_HEALTH, 'health be INIT_HEALTH');
            assert(char.rating == 0, 'rating should be 25');
            assert(char.loss == 1, 'loss should be 0');
            assert(char.totalLoss == 1, 'totalLoss should be 0');
        }
    }
}
