#[cfg(test)]
mod tests {
    use core::starknet::contract_address::ContractAddress;
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::{set_contract_address, set_block_timestamp};

    use dojo::model::{Model, ModelTest, ModelIndex, ModelEntityTest};
    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::utils::test::{spawn_test_world, deploy_contract};

    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        systems::{item::{item_system, IItemDispatcher, IItemDispatcherTrait}},
        systems::{shop::{shop_system, IShopDispatcher, IShopDispatcherTrait}},
        models::backpack::{BackpackGrids, backpack_grids},
        models::Item::{Item, item, ItemsCounter, items_counter},
        models::CharacterItem::{
            Position, CharacterItemStorage, character_item_storage, CharacterItemsStorageCounter,
            character_items_storage_counter, CharacterItemInventory, character_item_inventory,
            CharacterItemsInventoryCounter, character_items_inventory_counter
        },
        models::Character::{Characters, characters, NameRecord, name_record, WMClass},
        models::Shop::{Shop, shop}, utils::{test_utils::{add_items}}
    };

    use warpack_masters::constants::constants::{INIT_HEALTH, INIT_GOLD};

    fn get_systems(
        world: IWorldDispatcher
    ) -> (
        ContractAddress,
        IActionsDispatcher,
        ContractAddress,
        IItemDispatcher,
        ContractAddress,
        IShopDispatcher
    ) {
        let action_system_address = world
            .deploy_contract('salt1', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut action_system = IActionsDispatcher { contract_address: action_system_address };

        world.grant_writer(Model::<CharacterItemStorage>::selector(), action_system_address);
        world
            .grant_writer(Model::<CharacterItemsStorageCounter>::selector(), action_system_address);
        world.grant_writer(Model::<CharacterItemInventory>::selector(), action_system_address);
        world
            .grant_writer(
                Model::<CharacterItemsInventoryCounter>::selector(), action_system_address
            );
        world.grant_writer(Model::<BackpackGrids>::selector(), action_system_address);
        world.grant_writer(Model::<Characters>::selector(), action_system_address);
        world.grant_writer(Model::<NameRecord>::selector(), action_system_address);
        world.grant_writer(Model::<Shop>::selector(), action_system_address);

        let item_system_address = world
            .deploy_contract('salt2', item_system::TEST_CLASS_HASH.try_into().unwrap());
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        world.grant_writer(Model::<Item>::selector(), item_system_address);
        world.grant_writer(Model::<ItemsCounter>::selector(), item_system_address);

        let shop_system_address = world
            .deploy_contract('salt3', shop_system::TEST_CLASS_HASH.try_into().unwrap());
        let mut shop_system = IShopDispatcher { contract_address: shop_system_address };

        world.grant_writer(Model::<CharacterItemStorage>::selector(), shop_system_address);
        world.grant_writer(Model::<CharacterItemsStorageCounter>::selector(), shop_system_address);
        world.grant_writer(Model::<Characters>::selector(), shop_system_address);
        world.grant_writer(Model::<Shop>::selector(), shop_system_address);

        (
            action_system_address,
            action_system,
            item_system_address,
            item_system,
            shop_system_address,
            shop_system
        )
    }


    #[test]
    #[available_gas(3000000000000000)]
    fn test_rebirth() {
        let alice = starknet::contract_address_const::<0x0>();

        let world = spawn_test_world!();
        let (action_system_address, mut action_system, _, mut item_system, _, mut shop_system) =
            get_systems(
            world
        );

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('alice', WMClass::Warlock);

        set_contract_address(action_system_address);

        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 5;
        shop_data.item2 = 6;
        shop_data.item3 = 8;
        shop_data.item4 = 1;
        set!(world, (shop_data));

        set_contract_address(alice);

        shop_system.buy_item(5);
        shop_system.buy_item(6);
        shop_system.buy_item(8);

        action_system.place_item(2, 4, 2, 0);
        action_system.place_item(1, 2, 2, 0);
        action_system.place_item(3, 5, 2, 0);

        set_contract_address(action_system_address);

        let mut char = get!(world, (alice), Characters);
        char.loss = 5;
        char.rating = 300;
        char.totalWins = 10;
        char.totalLoss = 4;
        char.winStreak = 3;
        set!(world, (char));

        // mocking timestamp for testing
        let timestamp = 1717770021;
        set_block_timestamp(timestamp);

        set_contract_address(alice);

        action_system.rebirth('bob', WMClass::Warrior);

        let char = get!(world, (alice), Characters);
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
        assert(char.rating == 300, 'Rating mismatch');
        assert(char.totalWins == 10, 'total wins should be 10');
        assert(char.totalLoss == 4, 'total loss should be 4');
        assert(char.winStreak == 0, 'win streak should be 0');
        assert(char.birthCount == 2, 'birth count should be 2');
        assert(char.updatedAt == timestamp, 'updatedAt mismatch');

        assert(inventoryItemsCounter.count == 2, 'item count should be 0');
        assert(storageItemsCounter.count == 2, 'item count should be 0');

        assert(playerShopData.item1 == 0, 'item 1 should be 0');
        assert(playerShopData.item2 == 0, 'item 2 should be 0');
        assert(playerShopData.item3 == 0, 'item 3 should be 0');
        assert(playerShopData.item4 == 0, 'item 4 should be 0');

        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item 1 should be 0');

        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item 2 should be 0');

        let inventoryItem = get!(world, (alice, 1), CharacterItemInventory);
        assert(inventoryItem.itemId == 1, 'item 1 should be 1');
        assert(inventoryItem.position.x == 4, 'item 1 x should be 4');
        assert(inventoryItem.position.y == 2, 'item 1 y should be 2');

        let inventoryItem = get!(world, (alice, 2), CharacterItemInventory);
        assert(inventoryItem.itemId == 2, 'item 2 should be 2');
        assert(inventoryItem.position.x == 2, 'item 2 x should be 4');
        assert(inventoryItem.position.y == 2, 'item 2 y should be 3');

        let playerGridData = get!(world, (alice, 4, 2), BackpackGrids);
        assert(playerGridData.enabled == true, '(4,2) should be enabled');
        assert(playerGridData.occupied == false, '(4,2) should not be occupied');

        let playerGridData = get!(world, (alice, 4, 3), BackpackGrids);
        assert(playerGridData.enabled == true, '(4,3) should be enabled');
        assert(playerGridData.occupied == false, '(4,3) should not be occupied');

        let playerGridData = get!(world, (alice, 4, 4), BackpackGrids);
        assert(playerGridData.enabled == true, '(4,4) should be enabled');
        assert(playerGridData.occupied == false, '(4,4) should not be occupied');

        let playerGridData = get!(world, (alice, 5, 2), BackpackGrids);
        assert(playerGridData.enabled == true, '(5,2) should be enabled');
        assert(playerGridData.occupied == false, '(5,2) should not be occupied');

        let playerGridData = get!(world, (alice, 5, 3), BackpackGrids);
        assert(playerGridData.enabled == true, '(5,3) should be enabled');
        assert(playerGridData.occupied == false, '(5,3) should not be occupied');

        let playerGridData = get!(world, (alice, 5, 4), BackpackGrids);
        assert(playerGridData.enabled == true, '(5,4) should be enabled');
        assert(playerGridData.occupied == false, '(5,4) should not be occupied');

        let playerGridData = get!(world, (alice, 2, 2), BackpackGrids);
        assert(playerGridData.enabled == true, '(2,2) should be enabled');
        assert(playerGridData.occupied == false, '(2,2) should not be occupied');

        let playerGridData = get!(world, (alice, 2, 3), BackpackGrids);
        assert(playerGridData.enabled == true, '(2,3) should be enabled');
        assert(playerGridData.occupied == false, '(2,3) should not be occupied');

        let playerGridData = get!(world, (alice, 3, 2), BackpackGrids);
        assert(playerGridData.enabled == true, '(3,2) should be enabled');
        assert(playerGridData.occupied == false, '(3,2) should not be occupied');

        let playerGridData = get!(world, (alice, 3, 3), BackpackGrids);
        assert(playerGridData.enabled == true, '(3,3) should be enabled');
        assert(playerGridData.occupied == false, '(3,3) should not be occupied');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('loss not reached', 'ENTRYPOINT_FAILED'))]
    fn test_loss_not_reached() {
        let alice = starknet::contract_address_const::<0x0>();

        let world = spawn_test_world!();
        let (action_system_address, mut action_system, _, mut item_system, _, _) = get_systems(
            world
        );

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('alice', WMClass::Warlock);

        set_contract_address(action_system_address);

        let mut char = get!(world, (alice), Characters);
        char.loss = 4;
        set!(world, (char));

        set_contract_address(alice);

        action_system.rebirth('bob', WMClass::Warlock);
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('name already exists', 'ENTRYPOINT_FAILED'))]
    fn test_name_already_exists() {
        let world = spawn_test_world!();
        let (action_system_address, mut action_system, _, mut item_system, _, _) = get_systems(
            world
        );

        add_items(ref item_system);

        let alice = starknet::contract_address_const::<0x1>();
        set_contract_address(alice);
        action_system.spawn('alice', WMClass::Warlock);

        let bob = starknet::contract_address_const::<0x2>();
        set_contract_address(bob);
        action_system.spawn('bob', WMClass::Warlock);

        set_contract_address(action_system_address);

        let mut char = get!(world, (bob), Characters);
        char.loss = 5;
        set!(world, (char));

        set_contract_address(bob);

        action_system.rebirth('alice', WMClass::Warlock);
    }


    #[test]
    #[available_gas(3000000000000000)]
    fn test_rebirth_with_same_name() {
        let world = spawn_test_world!();
        let (action_system_address, mut action_system, _, mut item_system, _, _) = get_systems(
            world
        );

        add_items(ref item_system);

        let bob = starknet::contract_address_const::<0x2>();
        set_contract_address(bob);
        action_system.spawn('bob', WMClass::Warlock);

        let nameRecord = get!(world, 'bob', NameRecord);
        assert(nameRecord.player == bob, 'player should be bob');

        set_contract_address(action_system_address);

        let mut char = get!(world, (bob), Characters);
        char.loss = 5;
        set!(world, (char));

        set_contract_address(bob);

        action_system.rebirth('bob', WMClass::Warlock);

        let nameRecord = get!(world, 'bob', NameRecord);
        assert(nameRecord.player == bob, 'player should be bob');
    }


    #[test]
    #[available_gas(3000000000000000)]
    fn test_rebirth_with_different_name() {
        let world = spawn_test_world!();
        let (action_system_address, mut action_system, _, mut item_system, _, _) = get_systems(
            world
        );

        add_items(ref item_system);

        let bob = starknet::contract_address_const::<0x2>();
        set_contract_address(bob);
        action_system.spawn('bob', WMClass::Warlock);

        let nameRecord = get!(world, 'bob', NameRecord);
        assert(nameRecord.player == bob, 'player should be bob');

        set_contract_address(action_system_address);

        let mut char = get!(world, (bob), Characters);
        char.loss = 5;
        set!(world, (char));

        set_contract_address(bob);

        action_system.rebirth('Alice', WMClass::Warlock);

        let nameRecord = get!(world, 'Alice', NameRecord);
        assert(nameRecord.player == bob, 'player should be bob');

        let nameRecord = get!(world, 'bob', NameRecord);
        assert(
            nameRecord.player == starknet::contract_address_const::<0x2>(), 'player should be 0x2'
        );
    }
}

