#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_contract_address;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait, WMClass}},
        models::backpack::{Backpack, backpack, BackpackGrids, Grid, GridTrait},
        models::Item::{Item, item, ItemsCounter}, models::Character::{Character, character},
        models::CharacterItem::{
            Position, CharacterItemStorage, CharacterItemsStorageCounter, CharacterItemInventory,
            CharacterItemsInventoryCounter
        },
        models::DummyCharacter::{DummyCharacter, DummyCharacterCounter},
        models::DummyCharacterItem::{DummyCharacterItem, DummyCharacterItemsCounter},
        models::Shop::Shop, utils::{test_utils::{add_items}}
    };

    use warpack_masters::systems::actions::actions::{ITEMS_COUNTER_ID, INIT_HEALTH, INIT_GOLD};

    #[test]
    #[available_gas(3000000000000000)]
    fn test_rebirth() {
        let alice = starknet::contract_address_const::<0x0>();
        set_contract_address(alice);
        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn('alice', WMClass::Warlock);

        add_items(ref actions_system);

        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 1;
        shop_data.item2 = 2;
        shop_data.item3 = 1;
        shop_data.item4 = 3;
        set!(world, (shop_data));

        actions_system.buy_item(1);
        actions_system.buy_item(2);
        actions_system.buy_item(3);

        actions_system.place_item(1, 0, 0, 0);
        actions_system.place_item(2, 1, 0, 0);
        actions_system.place_item(3, 3, 0, 0);

        let mut char = get!(world, (alice), Character);
        char.loss = 5;
        set!(world, (char));
        actions_system.rebirth('bob', WMClass::Warrior);

        let char = get!(world, (alice), Character);
        let inventoryItemsCounter = get!(world, (alice), CharacterItemsInventoryCounter);
        let storageItemsCounter = get!(world, (alice), CharacterItemsStorageCounter);
        let playerShopData = get!(world, (alice), Shop);
        assert(!char.dummied, 'Should be false');
        assert(char.wins == 0, 'wins count should be 0');
        assert(char.loss == 0, 'loss count should be 0');
        assert(char.wmClass == WMClass::Warrior, 'class should be Warrior');
        assert(char.name == 'bob', 'name should be bob');
        assert(char.gold == INIT_GOLD + 1, 'gold should be init');
        assert(char.health == INIT_HEALTH, 'health should be init');
        assert(inventoryItemsCounter.count == 0, 'item count should be 0');
        assert(storageItemsCounter.count == 0, 'item count should be 0');
        assert(playerShopData.item1 == 0, 'item 1 should be 0');
        assert(playerShopData.item2 == 0, 'item 2 should be 0');
        assert(playerShopData.item3 == 0, 'item 3 should be 0');
        assert(playerShopData.item4 == 0, 'item 4 should be 0');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('loss not reached', 'ENTRYPOINT_FAILED'))]
    fn test_loss_not_reached() {
        let alice = starknet::contract_address_const::<0x0>();
        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn('alice', WMClass::Warlock);

        let mut char = get!(world, (alice), Character);
        char.loss = 4;
        set!(world, (char));

        actions_system.rebirth('bob', WMClass::Warlock);
    }
}

