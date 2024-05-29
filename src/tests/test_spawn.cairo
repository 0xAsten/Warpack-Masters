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
        models::backpack::{BackpackGrids}, models::Item::{Item, item, ItemsCounter},
        models::Character::{Character, character},
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
    fn test_spawn() {
        let alice = starknet::contract_address_const::<0x0>();
        set_contract_address(alice);

        let mut models = array![];
        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        actions_system.spawn('alice', WMClass::Warlock);

        let char = get!(world, (alice), Character);
        assert(!char.dummied, 'Should be false');
        assert(char.wins == 0, 'wins count should be 0');
        assert(char.loss == 0, 'loss count should be 0');
        assert(char.wmClass == WMClass::Warlock, 'class should be Warlock');
        assert(char.name == 'alice', 'name should be bob');
        assert(char.gold == INIT_GOLD + 1, 'gold should be init');
        assert(char.health == INIT_HEALTH, 'health should be init');

        let storageItemsCounter = get!(world, (alice), CharacterItemsStorageCounter);
        assert(storageItemsCounter.count == 2, 'Storage item count should be 2');

        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item 1 should be 0');

        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item 2 should be 0');

        let inventoryItemsCounter = get!(world, (alice), CharacterItemsInventoryCounter);
        assert(inventoryItemsCounter.count == 2, 'item count should be 2');

        let inventoryItem = get!(world, (alice, 1), CharacterItemInventory);
        assert(inventoryItem.itemId == 1, 'item 1 should be 1');
        assert(inventoryItem.position.x == 4, 'item 1 x should be 4');
        assert(inventoryItem.position.y == 2, 'item 1 y should be 2');

        let inventoryItem = get!(world, (alice, 2), CharacterItemInventory);
        assert(inventoryItem.itemId == 2, 'item 2 should be 2');
        assert(inventoryItem.position.x == 2, 'item 2 x should be 4');
        assert(inventoryItem.position.y == 2, 'item 2 y should be 3');

        let playerShopData = get!(world, (alice), Shop);
        assert(playerShopData.item1 == 0, 'item 1 should be 0');
        assert(playerShopData.item2 == 0, 'item 2 should be 0');
        assert(playerShopData.item3 == 0, 'item 3 should be 0');
        assert(playerShopData.item4 == 0, 'item 4 should be 0');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('name cannot be empty', 'ENTRYPOINT_FAILED'))]
    fn test_name_is_empty() {
        let mut models = array![];
        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn('', WMClass::Warlock);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('player already exists', 'ENTRYPOINT_FAILED'))]
    fn test_player_already_exists() {
        let mut models = array![];
        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };
        add_items(ref actions_system);

        actions_system.spawn('alice', WMClass::Warlock);
        actions_system.spawn('bob', WMClass::Warlock);
    }
}

