#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_contract_address;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    // import test utils
    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::backpack::{BackpackGrids}, models::Item::{Item, item, ItemsCounter},
        models::CharacterItem::{CharacterItemStorage, CharacterItemsStorageCounter},
        models::Character::{Character, character, WMClass}, models::Shop::{Shop, shop},
        utils::{test_utils::{add_items}}
    };

    use warpack_masters::systems::actions::actions::{ITEMS_COUNTER_ID, INIT_GOLD, STORAGE_FLAG};
    use warpack_masters::items;


    #[test]
    #[available_gas(3000000000000000)]
    fn test_sell_item() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);

        actions_system.spawn('Alice', WMClass::Warrior);
        let mut char = get!(world, alice, (Character));
        char.gold = 100;
        set!(world, (char));
        actions_system.reroll_shop();

        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 1;
        shop_data.item2 = 2;
        shop_data.item3 = 1;
        shop_data.item4 = 2;
        set!(world, (shop_data));

        actions_system.buy_item(1);
        let storageItemCount = get!(world, (alice), (CharacterItemsStorageCounter));
        assert(storageItemCount.count == 1, 'storage count mismatch');

        let prev_char_data = get!(world, alice, (Character));

        actions_system.sell_item(1);
        let storageItemCount = get!(world, (alice), (CharacterItemsStorageCounter));
        assert(storageItemCount.count == 1, 'storage count mismatch');

        let char_data = get!(world, alice, (Character));
        assert(
            char_data.gold == prev_char_data.gold + (items::Backpack1::price / 2),
            'sell one: gold value mismatch'
        );

        let storageItem = get!(world, (alice, 1), (CharacterItemStorage));
        assert(storageItem.itemId == 0, 'sell one: item id mismatch');

        actions_system.buy_item(2);
        let storageItemCount = get!(world, (alice), (CharacterItemsStorageCounter));
        assert(storageItemCount.count == 1, 'storage count mismatch');

        let prev_char_data = get!(world, alice, (Character));

        actions_system.sell_item(1);
        let storageItemCount = get!(world, (alice), (CharacterItemsStorageCounter));
        assert(storageItemCount.count == 1, 'storage count mismatch');

        let char_data = get!(world, alice, (Character));
        assert(
            char_data.gold == prev_char_data.gold + (items::Backpack2::price / 2),
            'sell two: gold value mismatch'
        );

        let storageItem = get!(world, (alice, 1), (CharacterItemStorage));
        assert(storageItem.itemId == 0, 'item id mismatch');

        let storageItem = get!(world, (alice, 2), (CharacterItemStorage));
        assert(storageItem.itemId == 0, 'item id mismatch');

        actions_system.buy_item(1);
        actions_system.buy_item(2);

        let mut shop_data = get!(world, alice, (Shop));
        assert(shop_data.item1 == 0, 'shop item mismatch');
        assert(shop_data.item2 == 0, 'shop item mismatch');
        assert(shop_data.item3 == 0, 'shop item mismatch');
        assert(shop_data.item4 == 0, 'shop item mismatch');
        shop_data.item1 = 1;
        shop_data.item2 = 2;
        shop_data.item3 = 1;
        shop_data.item4 = 2;
        set!(world, (shop_data));

        actions_system.buy_item(2);

        let storageItemCount = get!(world, (alice), (CharacterItemsStorageCounter));
        assert(storageItemCount.count == 3, 'storage count mismatch');

        actions_system.sell_item(2);
        let storageItemCount = get!(world, (alice), (CharacterItemsStorageCounter));
        assert(storageItemCount.count == 3, 'storage count mismatch');

        let storageItem = get!(world, (alice, 1), (CharacterItemStorage));
        assert(storageItem.itemId == 1, 'item id mismatch');
        let storageItem = get!(world, (alice, 2), (CharacterItemStorage));
        assert(storageItem.itemId == 0, 'item id mismatch');
        let storageItem = get!(world, (alice, 3), (CharacterItemStorage));
        assert(storageItem.itemId == 2, 'item id mismatch');

        actions_system.buy_item(1);
        let storageItemCount = get!(world, (alice), (CharacterItemsStorageCounter));
        assert(storageItemCount.count == 3, 'storage count mismatch');

        let storageItem = get!(world, (alice, 1), (CharacterItemStorage));
        assert(storageItem.itemId == 1, 'item id mismatch');
        let storageItem = get!(world, (alice, 2), (CharacterItemStorage));
        assert(storageItem.itemId == 1, 'item id mismatch');
        let storageItem = get!(world, (alice, 3), (CharacterItemStorage));
        assert(storageItem.itemId == 2, 'item id mismatch');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid item_id', 'ENTRYPOINT_FAILED'))]
    fn test_sell_item_with_item_id_0() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);

        actions_system.spawn('Alice', WMClass::Warrior);
        actions_system.reroll_shop();
        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 1;
        set!(world, (shop_data));

        actions_system.buy_item(1);
        actions_system.sell_item(0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid item_id', 'ENTRYPOINT_FAILED'))]
    fn test_sell_item_invalid_item_id() {
        let alice = starknet::contract_address_const::<0x1337>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        set_contract_address(alice);

        actions_system.spawn('Alice', WMClass::Warrior);
        actions_system.reroll_shop();
        // mock shop for testing
        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 1;
        set!(world, (shop_data));

        actions_system.buy_item(1);
        actions_system.sell_item(2);
    }
}

