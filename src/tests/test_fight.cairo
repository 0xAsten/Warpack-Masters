#[cfg(test)]
mod tests {
    use core::starknet::contract_address::ContractAddress;
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_contract_address;
    use debug::PrintTrait;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use dojo::model::{Model, ModelTest, ModelIndex, ModelEntityTest};

    // import test utils
    use dojo::utils::test::{spawn_test_world, deploy_contract};

    // import test utils
    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        systems::{item::{item_system, IItemDispatcher, IItemDispatcherTrait}},
        systems::{fight::{fight_system, IFightDispatcher, IFightDispatcherTrait}},
        systems::{dummy::{dummy_system, IDummyDispatcher, IDummyDispatcherTrait}},
        systems::{shop::{shop_system, IShopDispatcher, IShopDispatcherTrait}},
        models::backpack::{BackpackGrids, backpack_grids},
        models::Item::{Item, item, ItemsCounter, items_counter},

        models::CharacterItem::{
            Position, CharacterItemStorage, character_item_storage, CharacterItemsStorageCounter,
            character_items_storage_counter, CharacterItemInventory, character_item_inventory,
            CharacterItemsInventoryCounter, character_items_inventory_counter
        },
        models::Character::{Characters, characters, NameRecord, name_record, WMClass, PLAYER, DUMMY},
        models::DummyCharacter::{
            DummyCharacter, dummy_character, DummyCharacterCounter, dummy_character_counter
        },
        models::DummyCharacterItem::{
            DummyCharacterItem, dummy_character_item, DummyCharacterItemsCounter,
            dummy_character_items_counter
        },
        models::Shop::{Shop, shop},
        models::BattleLog::{BattleLog, battle_log, BattleLogCounter, battle_log_counter},
        utils::{test_utils::{add_items}},
        constants::constants::{INIT_STAMINA, EFFECT_ARMOR, EFFECT_REFLECT, INIT_GOLD, INIT_HEALTH}
    };

    fn get_systems(
        world: IWorldDispatcher
    ) -> (ContractAddress, IActionsDispatcher, ContractAddress, IItemDispatcher, ContractAddress, IFightDispatcher, ContractAddress, IDummyDispatcher) {
        let action_system_address = world.deploy_contract('salt1', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut action_system = IActionsDispatcher { contract_address: action_system_address };

        world.grant_writer(Model::<CharacterItemStorage>::selector(), action_system_address);
        world.grant_writer(Model::<CharacterItemsStorageCounter>::selector(), action_system_address);
        world.grant_writer(Model::<CharacterItemInventory>::selector(), action_system_address);
        world.grant_writer(Model::<CharacterItemsInventoryCounter>::selector(), action_system_address);
        world.grant_writer(Model::<BackpackGrids>::selector(), action_system_address);
        world.grant_writer(Model::<Characters>::selector(), action_system_address);
        world.grant_writer(Model::<NameRecord>::selector(), action_system_address);
        world.grant_writer(Model::<Shop>::selector(), action_system_address);

        let item_system_address = world.deploy_contract('salt2', item_system::TEST_CLASS_HASH.try_into().unwrap());
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        world.grant_writer(Model::<Item>::selector(), item_system_address);
        world.grant_writer(Model::<ItemsCounter>::selector(), item_system_address);

        let fight_system_address = world.deploy_contract('salt3', fight_system::TEST_CLASS_HASH.try_into().unwrap());
        let mut fight_system = IFightDispatcher { contract_address: fight_system_address };

        world.grant_writer(Model::<BattleLog>::selector(), fight_system_address);
        world.grant_writer(Model::<BattleLogCounter>::selector(), fight_system_address);
        world.grant_writer(Model::<Characters>::selector(), fight_system_address);
        world.grant_writer(Model::<DummyCharacter>::selector(), fight_system_address);

        let dummy_system_address = world.deploy_contract('salt4', dummy_system::TEST_CLASS_HASH.try_into().unwrap());
        let mut dummy_system = IDummyDispatcher { contract_address: dummy_system_address };

        world.grant_writer(Model::<DummyCharacterItem>::selector(), dummy_system_address);
        world.grant_writer(Model::<DummyCharacterItemsCounter>::selector(), dummy_system_address);
        world.grant_writer(Model::<DummyCharacter>::selector(), dummy_system_address);
        world.grant_writer(Model::<DummyCharacterCounter>::selector(), dummy_system_address);
        world.grant_writer(Model::<NameRecord>::selector(), dummy_system_address);
        world.grant_writer(Model::<Characters>::selector(), dummy_system_address);

        (action_system_address, action_system, item_system_address, item_system, fight_system_address, fight_system, dummy_system_address, dummy_system)
    }


    #[test]
    #[available_gas(3000000000000000)]
    fn test_create_dummy() {
        let world =  spawn_test_world!();
        let (_, mut action_system, _, mut item_system, _, _, _, mut dummy_system) = get_systems(world);

        add_items(ref item_system);

        let alice = starknet::contract_address_const::<0x0>();
        set_contract_address(alice);
        action_system.spawn('alice', WMClass::Warlock);
        dummy_system.create_dummy();

        let char = get!(world, (alice), Characters);
        let dummyChar = get!(world, (char.wins, 1), DummyCharacter);
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
        let world =  spawn_test_world!();
        let (_, mut action_system, _, mut item_system, _, mut fight_system, _, mut dummy_system) = get_systems(world);

        add_items(ref item_system);

        action_system.spawn('alice', WMClass::Warlock);
        dummy_system.create_dummy();

        fight_system.fight();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('dummy not created', 'ENTRYPOINT_FAILED'))]
    fn test_dummy_not_created() {
        let world =  spawn_test_world!();
        let (_, mut action_system, _, mut item_system, _, mut fight_system, _, _) = get_systems(world);

        add_items(ref item_system);

        action_system.spawn('alice', WMClass::Warlock);

        fight_system.match_dummy();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('only self dummy created', 'ENTRYPOINT_FAILED'))]
    fn test_only_self_dummy_created() {
        let world =  spawn_test_world!();
        let (_, mut action_system, _, mut item_system, _, mut fight_system, _, mut dummy_system) = get_systems(world);

        add_items(ref item_system);

        action_system.spawn('alice', WMClass::Warlock);
        dummy_system.create_dummy();

        fight_system.match_dummy();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('battle not fought', 'ENTRYPOINT_FAILED'))]
    fn test_battle_not_fought() {
        let world =  spawn_test_world!();
        let (_, mut action_system, _, mut item_system, _, mut fight_system, _, mut dummy_system) = get_systems(world);

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
        let alice = starknet::contract_address_const::<0x0>();

        let world =  spawn_test_world!();
        let (action_system_address, mut action_system, _, mut item_system, _, mut fight_system, _, mut dummy_system) = get_systems(world);

        add_items(ref item_system);

        set_contract_address(alice);
        action_system.spawn('alice', WMClass::Warlock);

        set_contract_address(action_system_address);
        let mut inventoryCounter = get!(world, alice, (CharacterItemsInventoryCounter));
        // add Herb id 5, on start +1 regen
        inventoryCounter.count += 1;
        let item1 = CharacterItemInventory {
            player: alice,
            id: inventoryCounter.count,
            itemId: 5,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };
        // add Dagger id 6, damage 3, cooldown 4
        inventoryCounter.count += 1;
        let item2 = CharacterItemInventory {
            player: alice,
            id: inventoryCounter.count,
            itemId: 6,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };
        // add Spike id 8, on start +1 reflect
        inventoryCounter.count += 1;
        let item3 = CharacterItemInventory {
            player: alice,
            id: inventoryCounter.count,
            itemId: 8,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };
        // add SpikeShield id 16, chance 75, on hit +2 reflect
        inventoryCounter.count += 1;
        let item4 = CharacterItemInventory {
            player: alice,
            id: inventoryCounter.count,
            itemId: 16,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };

        set!(world, (inventoryCounter, item1, item2, item3, item4));

        set_contract_address(alice);
        dummy_system.create_dummy();

        let bob = starknet::contract_address_const::<0x1>();
        set_contract_address(bob);
        action_system.spawn('bob', WMClass::Warlock);

        set_contract_address(action_system_address);
        let mut inventoryCounter = get!(world, bob, (CharacterItemsInventoryCounter));
        // add Sward id 7, damage 5, cooldown 5
        inventoryCounter.count += 1;
        let item1 = CharacterItemInventory {
            player: bob,
            id: inventoryCounter.count,
            itemId: 7,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };
        // add Shield id 9, on start +15 armor
        inventoryCounter.count += 1;
        let item2 = CharacterItemInventory {
            player: bob,
            id: inventoryCounter.count,
            itemId: 9,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };
        // add Helmet id 10, chance 50, on hit +3 armor
        inventoryCounter.count += 1;
        let item3 = CharacterItemInventory {
            player: bob,
            id: inventoryCounter.count,
            itemId: 10,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };
        // add Poison id 13, on start +2 posion
        inventoryCounter.count += 1;
        let item4 = CharacterItemInventory {
            player: bob,
            id: inventoryCounter.count,
            itemId: 13,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };
        // add Dagger id 6, damage 3, cooldown 4
        inventoryCounter.count += 1;
        let item5 = CharacterItemInventory {
            player: bob,
            id: inventoryCounter.count,
            itemId: 6,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };

        set!(world, (inventoryCounter, item1, item2, item3, item4, item5));

        set_contract_address(bob);
        dummy_system.create_dummy();

        fight_system.match_dummy();

        let battleLog = get!(world, (bob, 1), (BattleLog));
        assert(battleLog.dummyLevel == 0, 'dummyLevel should be 0');
        assert(battleLog.dummyCharId == 1, 'dummyCharId should be 1');
        assert(battleLog.item_ids == array![6, 6, 7].span(), 'item_ids should be [6, 6, 7]');
        assert(battleLog.belongs_tos == array![PLAYER, DUMMY, PLAYER].span(), 'belongs_tos is incorrect');
        assert(battleLog.items_length == 3, 'items_length should be 3');
        // armor, regen, reflect, empower, poison, vampirism
        assert(battleLog.char_buffs == array![15, 0, 0, 0, 0, 0].span(), 'char_buffs is incorrect');
        assert(battleLog.dummy_buffs == array![0, 1, 1, 0, 2, 0].span(), 'dummy_buffs is incorrect');
        // on hit, on attack
        assert(battleLog.char_on_hit_items == array![(EFFECT_ARMOR, 50, 3)].span(), 'char_on_hit_items is incorrect');
        assert(battleLog.dummy_on_hit_items == array![(EFFECT_REFLECT, 75, 2)].span(), 'dummy_on_hit_items is incorrect');
        assert(battleLog.char_on_attack_items == array![].span(), 'on_attack_items is incorrect');
        assert(battleLog.dummy_on_attack_items == array![].span(), 'on_attack_items is incorrect');
        assert(battleLog.winner == 0, 'winner should be 0');
        assert(battleLog.seconds == 0, 'seconds should be 0');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('dummy already created', 'ENTRYPOINT_FAILED'))]
    fn test_revert_dummy_already_created() {
        let alice = starknet::contract_address_const::<0x0>();
        
        let world =  spawn_test_world!();
        let (_, mut action_system, _, mut item_system, _, _, _, mut dummy_system) = get_systems(world);

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('alice', WMClass::Warlock);
        dummy_system.create_dummy();
        dummy_system.create_dummy();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('max loss reached', 'ENTRYPOINT_FAILED'))]
    fn test_max_loss_reached() {
        let alice = starknet::contract_address_const::<0x0>();

        let world =  spawn_test_world!();
        let (action_system_address, mut action_system, _, mut item_system, _, mut fight_system, _, mut dummy_system) = get_systems(world);

        add_items(ref item_system);

        set_contract_address(alice);
        action_system.spawn('alice', WMClass::Warlock);

        set_contract_address(action_system_address);
        let mut char = get!(world, (alice), Characters);
        char.loss = 5;
        set!(world, (char));

        set_contract_address(alice);
        dummy_system.create_dummy();

        fight_system.match_dummy();
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_fight() {
        let alice = starknet::contract_address_const::<0x0>();

        let world =  spawn_test_world!();
        let (action_system_address, mut action_system, _, mut item_system, _, mut fight_system, _, mut dummy_system) = get_systems(world);

        add_items(ref item_system);

        set_contract_address(alice);
        action_system.spawn('alice', WMClass::Warlock);

        set_contract_address(action_system_address);
        let mut inventoryCounter = get!(world, alice, (CharacterItemsInventoryCounter));
        // add Herb id 5, on start +1 regen
        inventoryCounter.count += 1;
        let item1 = CharacterItemInventory {
            player: alice,
            id: inventoryCounter.count,
            itemId: 5,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };
        // add Dagger id 6, damage 3, cooldown 4
        inventoryCounter.count += 1;
        let item2 = CharacterItemInventory {
            player: alice,
            id: inventoryCounter.count,
            itemId: 6,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };
        // add Spike id 8, on start +1 reflect
        inventoryCounter.count += 1;
        let item3 = CharacterItemInventory {
            player: alice,
            id: inventoryCounter.count,
            itemId: 8,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };
        // add SpikeShield id 16, chance 75, on hit +2 reflect
        inventoryCounter.count += 1;
        let item4 = CharacterItemInventory {
            player: alice,
            id: inventoryCounter.count,
            itemId: 16,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };

        set!(world, (inventoryCounter, item1, item2, item3, item4));

        set_contract_address(alice);
        dummy_system.create_dummy();

        let bob = starknet::contract_address_const::<0x1>();
        set_contract_address(bob);
        action_system.spawn('bob', WMClass::Warlock);

        set_contract_address(action_system_address);
        let mut inventoryCounter = get!(world, bob, (CharacterItemsInventoryCounter));
        // add Sward id 7, damage 5, cooldown 5
        inventoryCounter.count += 1;
        let item1 = CharacterItemInventory {
            player: bob,
            id: inventoryCounter.count,
            itemId: 7,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };
        // add Shield id 9, on start +15 armor
        inventoryCounter.count += 1;
        let item2 = CharacterItemInventory {
            player: bob,
            id: inventoryCounter.count,
            itemId: 9,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };
        // add Helmet id 10, chance 50, on hit +3 armor
        inventoryCounter.count += 1;
        let item3 = CharacterItemInventory {
            player: bob,
            id: inventoryCounter.count,
            itemId: 10,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };
        // add Poison id 13, on start +2 posion
        inventoryCounter.count += 1;
        let item4 = CharacterItemInventory {
            player: bob,
            id: inventoryCounter.count,
            itemId: 13,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };
        // add Dagger id 6, damage 3, cooldown 4
        inventoryCounter.count += 1;
        let item5 = CharacterItemInventory {
            player: bob,
            id: inventoryCounter.count,
            itemId: 6,
            position: Position { x: 0, y: 0 },
            rotation: 0,
        };

        set!(world, (inventoryCounter, item1, item2, item3, item4, item5));

        set_contract_address(bob);
        dummy_system.create_dummy();

        fight_system.match_dummy();

        fight_system.fight();

        let battleLog = get!(world, (bob, 1), (BattleLog));
        assert(battleLog.winner != 0, 'winner should not be 0');
        assert(battleLog.seconds > 0, 'seconds be greater than 0');

        let char = get!(world, (bob), Characters);

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

