#[cfg(test)]
mod tests {
    use core::starknet::contract_address::ContractAddress;
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_contract_address;

    use dojo::model::{Model, ModelTest, ModelIndex, ModelEntityTest};
    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::utils::test::{spawn_test_world, deploy_contract};

    // import test utils
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

    use debug::PrintTrait;

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
    fn test_undo_place_item() {
        let alice = starknet::contract_address_const::<0x1337>();

        let world = spawn_test_world!();
        let (action_system_address, mut action_system, _, mut item_system, _, mut shop_system) =
            get_systems(
            world
        );

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('Alice', WMClass::Warlock);

        set_contract_address(action_system_address);

        // mock player gold for testing
        let mut player_data = get!(world, alice, (Characters));
        player_data.gold = 100;
        set!(world, (player_data));
        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 5;
        shop_data.item2 = 6;
        shop_data.item3 = 8;
        shop_data.item4 = 1;
        set!(world, (shop_data));

        set_contract_address(alice);

        shop_system.buy_item(5);
        // place a sword on (4,2)
        action_system.place_item(2, 4, 2, 0);

        action_system.undo_place_item(3);

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 5, 'item id should equal 5');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 3, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 3), CharacterItemInventory);
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');

        let mut backpack_grid_data = get!(world, (alice, 4, 2), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(4,2) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(4,2) should be enabled');
        assert(backpack_grid_data.inventoryItemId == 0, 'id should equal 0');
        assert(backpack_grid_data.itemId == 0, 'item id should equal 0');
        assert(backpack_grid_data.isWeapon == false, 'isWeapon should be false');
        assert(backpack_grid_data.isPlugin == false, 'isPlugin should be false');

        let mut backpack_grid_data = get!(world, (alice, 4, 3), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(4,3) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(4,3) should be enabled');
        assert(backpack_grid_data.inventoryItemId == 0, 'id should equal 0');
        assert(backpack_grid_data.itemId == 0, 'item id should equal 0');
        assert(backpack_grid_data.isWeapon == false, 'isWeapon should be false');
        assert(backpack_grid_data.isPlugin == false, 'isPlugin should be false');

        let mut backpack_grid_data = get!(world, (alice, 4, 4), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(4,4) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(4,4) should be enabled');
        assert(backpack_grid_data.inventoryItemId == 0, 'id should equal 0');
        assert(backpack_grid_data.itemId == 0, 'item id should equal 0');
        assert(backpack_grid_data.isWeapon == false, 'isWeapon should be false');
        assert(backpack_grid_data.isPlugin == false, 'isPlugin should be false');

        shop_system.buy_item(6);
        // place a shield on (2,2)
        action_system.place_item(1, 2, 2, 0);

        action_system.undo_place_item(3);

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 5, 'item id should equal 5');
        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 6, 'item id should equal 6');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 3, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 3), CharacterItemInventory);
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');

        let mut backpack_grid_data = get!(world, (alice, 2, 2), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(2,2) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(2,2) should be occupied');
        assert(backpack_grid_data.inventoryItemId == 0, 'id should equal 0');
        assert(backpack_grid_data.itemId == 0, 'item id should equal 0');
        assert(backpack_grid_data.isWeapon == false, 'isWeapon should be false');
        assert(backpack_grid_data.isPlugin == false, 'isPlugin should be false');

        let mut backpack_grid_data = get!(world, (alice, 3, 2), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(3,2) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(3,2) should be enabled');
        assert(backpack_grid_data.inventoryItemId == 0, 'id should equal 0');
        assert(backpack_grid_data.itemId == 0, 'item id should equal 0');
        assert(backpack_grid_data.isWeapon == false, 'isWeapon should be false');
        assert(backpack_grid_data.isPlugin == false, 'isPlugin should be false');

        let mut backpack_grid_data = get!(world, (alice, 2, 3), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(2,3) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(2,3) should be enabled');
        assert(backpack_grid_data.inventoryItemId == 0, 'id should equal 0');
        assert(backpack_grid_data.itemId == 0, 'item id should equal 0');
        assert(backpack_grid_data.isWeapon == false, 'isWeapon should be false');
        assert(backpack_grid_data.isPlugin == false, 'isPlugin should be false');

        let mut backpack_grid_data = get!(world, (alice, 3, 3), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(3,3) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(3,3) should be enabled');
        assert(backpack_grid_data.inventoryItemId == 0, 'id should equal 0');
        assert(backpack_grid_data.itemId == 0, 'item id should equal 0');
        assert(backpack_grid_data.isWeapon == false, 'isWeapon should be false');
        assert(backpack_grid_data.isPlugin == false, 'isPlugin should be false');

        shop_system.buy_item(8);
        // place a potion on (5,2)
        action_system.place_item(3, 5, 2, 0);

        action_system.undo_place_item(3);

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 3, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 3), CharacterItemStorage);
        assert(storageItem.itemId == 8, 'item id should equal 2');
        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 5, 'item id should equal 4');
        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 6, 'item id should equal 6');
        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 3, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 3), CharacterItemInventory);
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');

        let mut backpack_grid_data = get!(world, (alice, 5, 2), BackpackGrids);
        assert(backpack_grid_data.occupied == false, '(5,2) should not be occupied');
        assert(backpack_grid_data.enabled == true, '(5,2) should be enabled');
        assert(backpack_grid_data.inventoryItemId == 0, 'id should equal 0');
        assert(backpack_grid_data.itemId == 0, 'item id should equal 0');
        assert(backpack_grid_data.isWeapon == false, 'isWeapon should be false');
        assert(backpack_grid_data.isPlugin == false, 'isPlugin should be false');

        action_system.place_item(2, 4, 2, 0);
        action_system.place_item(1, 2, 2, 0);
        action_system.place_item(3, 5, 2, 0);

        action_system.undo_place_item(4);

        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 3, 'storage item count mismatch');

        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item id should equal 0');
        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item id should equal 0');
        let storageItem = get!(world, (alice, 3), CharacterItemStorage);
        assert(storageItem.itemId == 6, 'item id should equal 6');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 5, 'inventory item count mismatch');

        let invetoryItem = get!(world, (alice, 3), CharacterItemInventory);
        assert(invetoryItem.itemId == 5, 'item id should equal 5');
        assert(invetoryItem.position.x == 4, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');

        let invetoryItem = get!(world, (alice, 4), CharacterItemInventory);
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');

        let invetoryItem = get!(world, (alice, 5), CharacterItemInventory);
        assert(invetoryItem.itemId == 8, 'item id should equal 6');
        assert(invetoryItem.position.x == 5, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid inventory item id', 'ENTRYPOINT_FAILED'))]
    fn test_undo_place_item_revert_not_in_inventory() {
        let alice = starknet::contract_address_const::<0x1337>();

        let world = spawn_test_world!();
        let (_, mut action_system, _, mut item_system, _, _) = get_systems(world);

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('Alice', WMClass::Warlock);

        action_system.undo_place_item(3);
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_undo_place_item_with_plugins_check() {
        let alice = starknet::contract_address_const::<0x1337>();

        let world = spawn_test_world!();
        let (action_system_address, mut action_system, _, mut item_system, _, mut shop_system) = get_systems(world);

        add_items(ref item_system);

        set_contract_address(alice);
        action_system.spawn('Alice', WMClass::Warlock);
        shop_system.reroll_shop();

        // mock player gold for testing
        let mut player_data = get!(world, alice, (Characters));
        player_data.gold = 100;

        set_contract_address(action_system_address);
        set!(world, (player_data));
        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 7; // sword weapon
        shop_data.item2 = 13; // poison plugin
        shop_data.item3 = 17; // PlagueFlower plugin
        shop_data.item4 = 1;
        set!(world, (shop_data));

        set_contract_address(alice);

        shop_system.buy_item(13);
        action_system.place_item(2, 5, 2, 0);

        shop_system.buy_item(7);
        // place a sword on (4,2)
        action_system.place_item(2, 4, 2, 0);
        
        shop_system.buy_item(17);
        action_system.place_item(2, 2, 2, 0);

        action_system.undo_place_item(3);
        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');
        let storageItem = get!(world, (alice, 2), CharacterItemStorage);
        assert(storageItem.itemId == 13, 'item id should equal 7');
        
        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 5, 'inventory item count mismatch');
        let invetoryItem = get!(world, (alice, 3), CharacterItemInventory);
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');
        let invetoryItem = get!(world, (alice, 4), CharacterItemInventory);
        assert(invetoryItem.itemId == 7, 'item id should equal 7');
        assert(invetoryItem.position.x == 4, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 1, 'plugins length mismatch');
        assert(*invetoryItem.plugins.at(0) == (6, 80, 3), 'plugin length mismatch');

        action_system.undo_place_item(4);
        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');
        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 7, 'item id should equal 7');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 5, 'inventory item count mismatch');
        let invetoryItem = get!(world, (alice, 4), CharacterItemInventory);
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');

        action_system.place_item(1, 4, 2, 0);
        let storageItemCounter = get!(world, alice, CharacterItemsStorageCounter);
        assert(storageItemCounter.count == 2, 'storage item count mismatch');
        let storageItem = get!(world, (alice, 1), CharacterItemStorage);
        assert(storageItem.itemId == 0, 'item id should equal 0');

        let inventoryItemCounter = get!(world, alice, CharacterItemsInventoryCounter);
        assert(inventoryItemCounter.count == 5, 'inventory item count mismatch');
        let invetoryItem = get!(world, (alice, 4), CharacterItemInventory);
        assert(invetoryItem.itemId == 7, 'item id should equal 7');
        assert(invetoryItem.position.x == 4, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 1, 'plugins length mismatch');
        assert(*invetoryItem.plugins.at(0) == (6, 80, 3), 'plugin length mismatch');
        let invetoryItem = get!(world, (alice, 5), CharacterItemInventory);
        assert(invetoryItem.itemId == 17, 'item id should equal 17');
        assert(invetoryItem.position.x == 2, 'x position mismatch');
        assert(invetoryItem.position.y == 2, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');
        let invetoryItem = get!(world, (alice, 3), CharacterItemInventory);
        assert(invetoryItem.itemId == 0, 'item id should equal 0');
        assert(invetoryItem.position.x == 0, 'x position mismatch');
        assert(invetoryItem.position.y == 0, 'y position mismatch');
        assert(invetoryItem.rotation == 0, 'rotation mismatch');
        assert(invetoryItem.plugins.len() == 0, 'plugins length mismatch');
    }
}

