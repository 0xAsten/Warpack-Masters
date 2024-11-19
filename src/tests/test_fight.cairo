#[cfg(test)]
mod tests {
    use core::starknet::contract_address::ContractAddress;
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_contract_address;

    use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef, WorldStorageTestTrait};

    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        systems::{item::{item_system, IItemDispatcher, IItemDispatcherTrait}},
        systems::{fight::{fight_system, IFightDispatcher, IFightDispatcherTrait}},
        systems::{dummy::{dummy_system, IDummyDispatcher, IDummyDispatcherTrait}},
        models::backpack::{BackpackGrids, m_BackpackGrids},
        models::Item::{Item, m_Item, ItemsCounter, m_ItemsCounter},
        models::Character::{Characters, m_Characters, NameRecord, m_NameRecord, WMClass, PLAYER, DUMMY},
        models::DummyCharacter::{DummyCharacter, m_DummyCharacter, DummyCharacterCounter, m_DummyCharacterCounter},
        models::DummyCharacterItem::{
            DummyCharacterItem, m_DummyCharacterItem, DummyCharacterItemsCounter, m_DummyCharacterItemsCounter
        },
        models::CharacterItem::{CharacterItemInventory, CharacterItemsInventoryCounter, m_CharacterItemInventory, m_CharacterItemsInventoryCounter, Position},
        models::Fight::{BattleLog, m_BattleLog, BattleLogCounter, m_BattleLogCounter, BattleLogDetail, e_BattleLogDetail},
        utils::{test_utils::{add_items}},
        constants::constants::{INIT_STAMINA, EFFECT_REFLECT, INIT_GOLD, INIT_HEALTH}
    };

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "Warpacks", 
            resources: [
                TestResource::Model(m_BackpackGrids::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Item::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_ItemsCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Characters::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_NameRecord::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_DummyCharacter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_DummyCharacterCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_DummyCharacterItem::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_DummyCharacterItemsCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_BattleLog::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_BattleLogCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemInventory::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemsInventoryCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Event(e_BattleLogDetail::TEST_CLASS_HASH),
                TestResource::Contract(actions::TEST_CLASS_HASH),
                TestResource::Contract(item_system::TEST_CLASS_HASH),
                TestResource::Contract(fight_system::TEST_CLASS_HASH),
                TestResource::Contract(dummy_system::TEST_CLASS_HASH),
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
            ContractDefTrait::new(@"Warpacks", @"fight_system")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
            ContractDefTrait::new(@"Warpacks", @"dummy_system")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
        ].span()
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_create_dummy() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"dummy_system").unwrap();
        let mut dummy_system = IDummyDispatcher { contract_address };

        add_items(ref item_system);

        let alice = starknet::contract_address_const::<0x0>();
        set_contract_address(alice);
        
        action_system.spawn('alice', WMClass::Warlock);
        dummy_system.create_dummy();

        let char: Characters = world.read_model(alice);
        let dummyChar: DummyCharacter = world.read_model((char.wins, 1));
        
        assert(dummyChar.level == char.wins, 'Should be equal');
        assert(dummyChar.name == 'alice', 'name should be alice');
        assert(dummyChar.wmClass == WMClass::Warlock, 'class should be Warlock');
        assert(dummyChar.health == char.health, 'health should be equal');
        assert(dummyChar.player == alice, 'player should be alice');
        assert(dummyChar.rating == char.rating, 'rating should be equal');
        assert(dummyChar.rating == 0, 'rating should be 0');
        assert(dummyChar.stamina == INIT_STAMINA, 'stamina should be INIT_STAMINA');
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

        action_system.spawn('alice', WMClass::Warlock);
        dummy_system.create_dummy();

        fight_system.fight();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('dummy not created', 'ENTRYPOINT_FAILED'))]
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
    #[should_panic(expected: ('only self dummy created', 'ENTRYPOINT_FAILED'))]
    fn test_only_self_dummy_created() {
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

        action_system.spawn('alice', WMClass::Warlock);
        dummy_system.create_dummy();

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

        action_system.spawn('alice', WMClass::Warlock);
        dummy_system.create_dummy();

        let bob = starknet::contract_address_const::<0x1>();
        set_contract_address(bob);
        action_system.spawn('bob', WMClass::Warlock);
        dummy_system.create_dummy();

        fight_system.match_dummy();
        fight_system.match_dummy();
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_match_dummy() {
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

        let alice = starknet::contract_address_const::<0x0>();
        set_contract_address(alice);

        add_items(ref item_system);
        action_system.spawn('alice', WMClass::Warlock);

        // Add items to inventory for Alice
        let mut inventoryCounter: CharacterItemsInventoryCounter = world.read_model(alice);
        
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

        dummy_system.create_dummy();

        // Add items for Bob
        let bob = starknet::contract_address_const::<0x1>();
        set_contract_address(bob);
        action_system.spawn('bob', WMClass::Warlock);

        let mut inventoryCounter: CharacterItemsInventoryCounter = world.read_model(bob);
        
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
        
        // add Poison id 13, on start +2 poison
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
            plugins: array![(6, 80, 2), (6, 90, 1)],
        };

        world.write_model(@inventoryCounter);
        world.write_model(@item1);
        world.write_model(@item2);
        world.write_model(@item3);
        world.write_model(@item4);
        world.write_model(@item5);

        set_contract_address(bob);
        dummy_system.create_dummy();

        fight_system.match_dummy();

        let battleLog: BattleLog = world.read_model((bob, 1));
        assert(battleLog.dummyLevel == 0, 'dummyLevel should be 0');
        assert(battleLog.dummyCharId == 1, 'dummyCharId should be 1');
        assert(battleLog.sorted_items == array![
            ('player', 6_u32, 1_u8, 1_u8, 90_u32, 3_u32, 4_u8, 20_u8, array![(6, 80, 2), (6, 90, 1)].span()), 
            ('dummy', 6, 1, 1, 90, 3, 4, 20, array![].span()), 
            ('player', 7, 1, 1, 80, 5, 5, 30, array![].span())].span(), 
            'item_ids should be [6, 6, 7]');
        assert(battleLog.items_length == 3, 'items_length should be 3');
        assert(battleLog.player_buffs == array![15, 0, 0, 0, 0, 0].span(), 'player_buffs is incorrect');
        assert(battleLog.dummy_buffs == array![0, 1, 2, 0, 0, 0].span(), 'dummy_buffs is incorrect');
        assert(battleLog.player_on_hit_items == array![(3, 50, 2)].span(), 'incorrect');
        assert(battleLog.dummy_on_hit_items == array![(5, 75, 2)].span(), 'incorrect');
        assert(battleLog.player_on_attack_items == array![].span(), 'incorrect');
        assert(battleLog.dummy_on_attack_items == array![].span(), 'incorrect');
        assert(battleLog.winner == 0, 'winner should be 0');
        assert(battleLog.seconds == 0, 'seconds should be 0');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('dummy already created', 'ENTRYPOINT_FAILED'))]
    fn test_revert_dummy_already_created() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"dummy_system").unwrap();
        let mut dummy_system = IDummyDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();
        set_contract_address(alice);

        add_items(ref item_system);

        action_system.spawn('alice', WMClass::Warlock);
        dummy_system.create_dummy();
        dummy_system.create_dummy();
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

        let alice = starknet::contract_address_const::<0x0>();
        set_contract_address(alice);

        add_items(ref item_system);
        action_system.spawn('alice', WMClass::Warlock);

        // Update character loss count
        let mut char: Characters = world.read_model(alice);
        char.loss = 5;
        world.write_model(@char);

        dummy_system.create_dummy();
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

        let alice = starknet::contract_address_const::<0x0>();
        set_contract_address(alice);

        add_items(ref item_system);
        action_system.spawn('alice', WMClass::Warlock);

        // Add items for Alice
        let mut inventoryCounter: CharacterItemsInventoryCounter = world.read_model(alice);
        
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

        dummy_system.create_dummy();

        // Add items for Bob
        let bob = starknet::contract_address_const::<0x1>();
        set_contract_address(bob);
        action_system.spawn('bob', WMClass::Warlock);

        let mut inventoryCounter: CharacterItemsInventoryCounter = world.read_model(bob);
        
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

        world.write_model(@inventoryCounter);
        world.write_model(@item1);
        world.write_model(@item2);
        world.write_model(@item3);
        world.write_model(@item4);
        world.write_model(@item5);

        dummy_system.create_dummy();
        fight_system.match_dummy();
        fight_system.fight();

        let battleLog: BattleLog = world.read_model((bob, 1));
        assert(battleLog.winner != 0, 'winner should not be 0');
        assert(battleLog.seconds > 0, 'seconds be greater than 0');

        let char: Characters = world.read_model(bob);

        if battleLog.winner == PLAYER {
            assert(char.wins == 1, 'wins should be 1');
            assert(char.totalWins == 1, 'totalWins should be 1');
            assert(char.winStreak == 1, 'winStreak should be 1');
            assert(char.dummied == false, 'dummied should be false');
            assert(char.gold == INIT_GOLD + 6, 'gold should be INIT_GOLD + 6');
            assert(char.health == INIT_HEALTH + 10, 'health be INIT_HEALTH + 10');
            assert(char.rating == 25, 'rating should be 25');
            assert(char.loss == 0, 'loss should be 0');
            assert(char.totalLoss == 0, 'totalLoss should be 0');
        } else {
            assert(char.wins == 0, 'wins should be 0');
            assert(char.totalWins == 0, 'totalWins should be 0');
            assert(char.winStreak == 0, 'winStreak should be 0');
            assert(char.dummied == false, 'dummied should be false');
            assert(char.gold == INIT_GOLD + 6, 'gold be INIT_GOLD + 6');
            assert(char.health == INIT_HEALTH, 'health be INIT_HEALTH');
            assert(char.rating == 0, 'rating should be 25');
            assert(char.loss == 1, 'loss should be 0');
            assert(char.totalLoss == 1, 'totalLoss should be 0');
        }
    }
}

