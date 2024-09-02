#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_contract_address;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

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
        models::Character::{Character, character, NameRecord, name_record, WMClass},
        models::DummyCharacter::{
            DummyCharacter, dummy_character, DummyCharacterCounter, dummy_character_counter
        },
        models::DummyCharacterItem::{
            DummyCharacterItem, dummy_character_item, DummyCharacterItemsCounter,
            dummy_character_items_counter
        },
        models::Shop::{Shop, shop},
        models::BattleLog::{BattleLog, battle_log, BattleLogCounter, battle_log_counter},
        utils::{test_utils::{add_items}}
    };


    #[test]
    #[available_gas(3000000000000000)]
    fn test_dummy() {
        let mut models = array![
            backpack_grids::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            items_counter::TEST_CLASS_HASH,
            character_item_storage::TEST_CLASS_HASH,
            character_items_storage_counter::TEST_CLASS_HASH,
            character_item_inventory::TEST_CLASS_HASH,
            character_items_inventory_counter::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            name_record::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH,
            dummy_character::TEST_CLASS_HASH,
            dummy_character_counter::TEST_CLASS_HASH,
            dummy_character_item::TEST_CLASS_HASH,
            dummy_character_items_counter::TEST_CLASS_HASH,
            battle_log::TEST_CLASS_HASH,
            battle_log_counter::TEST_CLASS_HASH
        ];

        let world =  spawn_test_world(["Warpacks"].span(), models.span());

        let action_system_address = world
            .deploy_contract(
                'salt1', actions::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut action_system = IActionsDispatcher { contract_address: action_system_address };

        let item_system_address = world
            .deploy_contract(
                'salt2', item_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        let fight_system_address = world
            .deploy_contract(
                'salt3', fight_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut fight_system = IFightDispatcher { contract_address: fight_system_address };

        let dummy_system_address = world
            .deploy_contract(
                'salt4', dummy_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut dummy_system = IDummyDispatcher { contract_address: dummy_system_address };

        add_items(ref item_system);

        let alice = starknet::contract_address_const::<0x0>();
        set_contract_address(alice);
        action_system.spawn('alice', WMClass::Warlock);
        dummy_system.create_dummy();

        let char = get!(world, (alice), Character);
        let dummyChar = get!(world, (char.wins, 1), DummyCharacter);
        assert(dummyChar.level == char.wins, 'Should be equal');
        assert(dummyChar.name == 'alice', 'name should be alice');
        assert(dummyChar.wmClass == WMClass::Warlock, 'class should be Warlock');
        assert(dummyChar.health == char.health, 'health should be equal');
        assert(dummyChar.player == alice, 'player should be alice');
        assert(dummyChar.rating == char.rating, 'rating should be equal');
        assert(dummyChar.rating == 0, 'rating should be 0');

        let bob = starknet::contract_address_const::<0x1>();
        set_contract_address(bob);
        action_system.spawn('bob', WMClass::Warlock);
        dummy_system.create_dummy();

        fight_system.fight();

        let char = get!(world, (bob), Character);
        let dummyChar = get!(world, (0, 1), DummyCharacter);
        if char.wins == 1 {
            assert(dummyChar.rating == 0, 'rating should be 0');
            assert(char.rating == 25, 'rating should be 25')
        } else {
            assert(dummyChar.rating == 25, 'rating should be 25');
            assert(char.rating == 0, 'rating should be 0')
        }
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('only self dummy created', 'ENTRYPOINT_FAILED'))]
    fn test_only_self_dummy_created() {
        let mut models = array![
            backpack_grids::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            items_counter::TEST_CLASS_HASH,
            character_item_storage::TEST_CLASS_HASH,
            character_items_storage_counter::TEST_CLASS_HASH,
            character_item_inventory::TEST_CLASS_HASH,
            character_items_inventory_counter::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            name_record::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH,
            dummy_character::TEST_CLASS_HASH,
            dummy_character_counter::TEST_CLASS_HASH,
            dummy_character_item::TEST_CLASS_HASH,
            dummy_character_items_counter::TEST_CLASS_HASH,
        ];

        let world =  spawn_test_world(["Warpacks"].span(), models.span());

        let action_system_address = world
            .deploy_contract(
                'salt1', actions::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut action_system = IActionsDispatcher { contract_address: action_system_address };

        let item_system_address = world
            .deploy_contract(
                'salt2', item_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        let fight_system_address = world
            .deploy_contract(
                'salt3', fight_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut fight_system = IFightDispatcher { contract_address: fight_system_address };

        let dummy_system_address = world
            .deploy_contract(
                'salt4', dummy_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut dummy_system = IDummyDispatcher { contract_address: dummy_system_address };

        add_items(ref item_system);

        action_system.spawn('alice', WMClass::Warlock);
        dummy_system.create_dummy();

        fight_system.fight();
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_sort_array() {
        let alice = starknet::contract_address_const::<0x0>();

        let mut models = array![
            backpack_grids::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            items_counter::TEST_CLASS_HASH,
            character_item_storage::TEST_CLASS_HASH,
            character_items_storage_counter::TEST_CLASS_HASH,
            character_item_inventory::TEST_CLASS_HASH,
            character_items_inventory_counter::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            name_record::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH,
            dummy_character::TEST_CLASS_HASH,
            dummy_character_counter::TEST_CLASS_HASH,
            dummy_character_item::TEST_CLASS_HASH,
            dummy_character_items_counter::TEST_CLASS_HASH,
            battle_log::TEST_CLASS_HASH,
            battle_log_counter::TEST_CLASS_HASH
        ];

        let world =  spawn_test_world(["Warpacks"].span(), models.span());

        let action_system_address = world
            .deploy_contract(
                'salt1', actions::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut action_system = IActionsDispatcher { contract_address: action_system_address };

        let item_system_address = world
            .deploy_contract(
                'salt2', item_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        let fight_system_address = world
            .deploy_contract(
                'salt3', fight_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut fight_system = IFightDispatcher { contract_address: fight_system_address };

        let dummy_system_address = world
            .deploy_contract(
                'salt4', dummy_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut dummy_system = IDummyDispatcher { contract_address: dummy_system_address };

        let shop_system_address = world
            .deploy_contract(
                'salt', shop_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut shop_system = IShopDispatcher { contract_address: shop_system_address };

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('alice', WMClass::Warlock);

        let mut shop = get!(world, alice, (Shop));
        shop.item1 = 4;
        shop.item2 = 6;
        shop.item3 = 8;
        shop.item4 = 1;
        let mut char = get!(world, alice, (Character));
        char.gold = 100;
        set!(world, (shop, char));

        shop_system.buy_item(4);
        action_system.place_item(2, 2, 4, 0);
        shop_system.buy_item(6);
        action_system.place_item(2, 2, 2, 0);
        shop_system.buy_item(8);
        action_system.place_item(2, 5, 2, 0);
        // actions_system.
        dummy_system.create_dummy();

        let bob = starknet::contract_address_const::<0x1>();
        set_contract_address(bob);
        action_system.spawn('bob', WMClass::Warlock);
        dummy_system.create_dummy();

        fight_system.fight();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('dummy not created', 'ENTRYPOINT_FAILED'))]
    fn test_revert_dummy_not_created() {
        let alice = starknet::contract_address_const::<0x0>();

        let mut models = array![
            backpack_grids::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            items_counter::TEST_CLASS_HASH,
            character_item_storage::TEST_CLASS_HASH,
            character_items_storage_counter::TEST_CLASS_HASH,
            character_item_inventory::TEST_CLASS_HASH,
            character_items_inventory_counter::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            name_record::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH,
            dummy_character::TEST_CLASS_HASH,
            dummy_character_counter::TEST_CLASS_HASH,
            dummy_character_item::TEST_CLASS_HASH,
            dummy_character_items_counter::TEST_CLASS_HASH,
        ];

        let world =  spawn_test_world(["Warpacks"].span(), models.span());

        let action_system_address = world
            .deploy_contract(
                'salt1', actions::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut action_system = IActionsDispatcher { contract_address: action_system_address };

        let item_system_address = world
            .deploy_contract(
                'salt2', item_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        let fight_system_address = world
            .deploy_contract(
                'salt3', fight_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut fight_system = IFightDispatcher { contract_address: fight_system_address };

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('alice', WMClass::Warlock);

        fight_system.fight();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('dummy already created', 'ENTRYPOINT_FAILED'))]
    fn test_revert_dummy_already_created() {
        let alice = starknet::contract_address_const::<0x0>();

        let mut models = array![
            backpack_grids::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            items_counter::TEST_CLASS_HASH,
            character_item_storage::TEST_CLASS_HASH,
            character_items_storage_counter::TEST_CLASS_HASH,
            character_item_inventory::TEST_CLASS_HASH,
            character_items_inventory_counter::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            name_record::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH,
            dummy_character::TEST_CLASS_HASH,
            dummy_character_counter::TEST_CLASS_HASH,
            dummy_character_item::TEST_CLASS_HASH,
            dummy_character_items_counter::TEST_CLASS_HASH,
        ];

        let world =  spawn_test_world(["Warpacks"].span(), models.span());

        let action_system_address = world
            .deploy_contract(
                'salt1', actions::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut action_system = IActionsDispatcher { contract_address: action_system_address };

        let item_system_address = world
            .deploy_contract(
                'salt2', item_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        let dummy_system_address = world
            .deploy_contract(
                'salt4', dummy_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut dummy_system = IDummyDispatcher { contract_address: dummy_system_address };

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('alice', WMClass::Warlock);
        dummy_system.create_dummy();
        dummy_system.create_dummy();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('dummy not created', 'ENTRYPOINT_FAILED'))]
    fn test_dummy_not_created() {
        let alice = starknet::contract_address_const::<0x0>();

        let mut models = array![
            backpack_grids::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            items_counter::TEST_CLASS_HASH,
            character_item_storage::TEST_CLASS_HASH,
            character_items_storage_counter::TEST_CLASS_HASH,
            character_item_inventory::TEST_CLASS_HASH,
            character_items_inventory_counter::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            name_record::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH,
            dummy_character::TEST_CLASS_HASH,
            dummy_character_counter::TEST_CLASS_HASH,
            dummy_character_item::TEST_CLASS_HASH,
            dummy_character_items_counter::TEST_CLASS_HASH,
        ];

        let world =  spawn_test_world(["Warpacks"].span(), models.span());

        let action_system_address = world
            .deploy_contract(
                'salt1', actions::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut action_system = IActionsDispatcher { contract_address: action_system_address };

        let item_system_address = world
            .deploy_contract(
                'salt2', item_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        let fight_system_address = world
            .deploy_contract(
                'salt3', fight_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut fight_system = IFightDispatcher { contract_address: fight_system_address };

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('alice', WMClass::Warlock);

        fight_system.fight();
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('max loss reached', 'ENTRYPOINT_FAILED'))]
    fn test_max_loss_reached() {
        let alice = starknet::contract_address_const::<0x0>();

        let mut models = array![
            backpack_grids::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            items_counter::TEST_CLASS_HASH,
            character_item_storage::TEST_CLASS_HASH,
            character_items_storage_counter::TEST_CLASS_HASH,
            character_item_inventory::TEST_CLASS_HASH,
            character_items_inventory_counter::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            name_record::TEST_CLASS_HASH,
            shop::TEST_CLASS_HASH,
            dummy_character::TEST_CLASS_HASH,
            dummy_character_counter::TEST_CLASS_HASH,
            dummy_character_item::TEST_CLASS_HASH,
            dummy_character_items_counter::TEST_CLASS_HASH,
        ];

        let world =  spawn_test_world(["Warpacks"].span(), models.span());

        let action_system_address = world
            .deploy_contract(
                'salt1', actions::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut action_system = IActionsDispatcher { contract_address: action_system_address };

        let item_system_address = world
            .deploy_contract(
                'salt2', item_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        let fight_system_address = world
            .deploy_contract(
                'salt3', fight_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut fight_system = IFightDispatcher { contract_address: fight_system_address };

        let dummy_system_address = world
            .deploy_contract(
                'salt4', dummy_system::TEST_CLASS_HASH.try_into().unwrap() 
            );
        let mut dummy_system = IDummyDispatcher { contract_address: dummy_system_address };

        add_items(ref item_system);

        action_system.spawn('alice', WMClass::Warlock);

        let mut char = get!(world, (alice), Character);
        char.loss = 5;
        set!(world, (char));

        dummy_system.create_dummy();

        fight_system.fight();
    }
}

