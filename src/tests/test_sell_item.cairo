#[cfg(test)]
mod tests {

    use dojo::model::{ModelStorage};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef, WorldStorageTestTrait};

    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        systems::{item::{item_system, IItemDispatcher}},
        systems::{shop::{shop_system, IShopDispatcher, IShopDispatcherTrait}},
        models::backpack::{m_BackpackGrids},
        models::Item::{m_Item, m_ItemsCounter},
        models::Character::{Characters, m_Characters, m_NameRecord, WMClass},
        models::Shop::{Shop, m_Shop},
        models::CharacterItem::{
            CharacterItemStorage, m_CharacterItemStorage, CharacterItemsStorageCounter,
            m_CharacterItemsStorageCounter, m_CharacterItemInventory,
            m_CharacterItemsInventoryCounter
        },
        utils::{test_utils::{add_items}}
    };

    use warpack_masters::items;

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "Warpacks", 
            resources: [
                TestResource::Model(m_BackpackGrids::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Item::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_ItemsCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemStorage::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemsStorageCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemInventory::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterItemsInventoryCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Characters::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_NameRecord::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Shop::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Contract(actions::TEST_CLASS_HASH),
                TestResource::Contract(item_system::TEST_CLASS_HASH),
                TestResource::Contract(shop_system::TEST_CLASS_HASH),
                TestResource::Event(actions::e_BuyItem::TEST_CLASS_HASH),
                TestResource::Event(actions::e_SellItem::TEST_CLASS_HASH),
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
            ContractDefTrait::new(@"Warpacks", @"shop_system")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
        ].span()
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_sell_item() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warrior);
        shop_system.reroll_shop();

        let mut char: Characters = world.read_model(alice);
        char.gold = 100;
        world.write_model(@char);

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 4;
        shop_data.item2 = 6;
        shop_data.item3 = 8;
        shop_data.item4 = 9;
        world.write_model(@shop_data);

        action_system.move_item_from_shop_to_storage(6);
        let storageItemCount: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storageItemCount.count == 2, 'storage count mismatch');

        let prev_char_data: Characters = world.read_model(alice);

        action_system.move_item_from_storage_to_shop(2);
        let storageItemCount: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storageItemCount.count == 2, 'storage count mismatch');

        let char_data: Characters = world.read_model(alice);
        assert(
            char_data.gold == prev_char_data.gold + (items::Shield::price / 2),
            'sell two: gold value mismatch'
        );

        let storageItem: CharacterItemStorage = world.read_model((alice, 1));
        assert(storageItem.itemId == 0, 'item id mismatch');

        let storageItem: CharacterItemStorage = world.read_model((alice, 2));
        assert(storageItem.itemId == 0, 'item id mismatch');

        action_system.move_item_from_shop_to_storage(8);
        action_system.move_item_from_shop_to_storage(9);

        let mut shop_data: Shop = world.read_model(alice);
        assert(shop_data.item1 == 4, 'shop item mismatch');
        assert(shop_data.item2 == 0, 'shop item mismatch');
        assert(shop_data.item3 == 0, 'shop item mismatch');
        assert(shop_data.item4 == 0, 'shop item mismatch');

        shop_data.item1 = 3;
        shop_data.item2 = 5;
        shop_data.item3 = 7;
        shop_data.item4 = 10;
        world.write_model(@shop_data);

        action_system.move_item_from_shop_to_storage(3);

        let storageItemCount: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storageItemCount.count == 3, 'storage count mismatch');

        action_system.move_item_from_storage_to_shop(2);
        let storageItemCount: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storageItemCount.count == 3, 'storage count mismatch');

        let storageItem: CharacterItemStorage = world.read_model((alice, 1));
        assert(storageItem.itemId == 9, 'item id mismatch');
        let storageItem: CharacterItemStorage = world.read_model((alice, 2));
        assert(storageItem.itemId == 0, 'item id mismatch');
        let storageItem: CharacterItemStorage = world.read_model((alice, 3));
        assert(storageItem.itemId == 3, 'item id mismatch');

        action_system.move_item_from_shop_to_storage(5);
        let storageItemCount: CharacterItemsStorageCounter = world.read_model(alice);
        assert(storageItemCount.count == 3, 'storage count mismatch');

        let storageItem: CharacterItemStorage = world.read_model((alice, 1));
        assert(storageItem.itemId == 9, 'item id mismatch');
        let storageItem: CharacterItemStorage = world.read_model((alice, 2));
        assert(storageItem.itemId == 5, 'item id mismatch');
        let storageItem: CharacterItemStorage = world.read_model((alice, 3));
        assert(storageItem.itemId == 3, 'item id mismatch');
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid item_id', 'ENTRYPOINT_FAILED'))]
    fn test_sell_item_with_item_id_0() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warrior);
        shop_system.reroll_shop();

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 4;
        world.write_model(@shop_data);

        action_system.move_item_from_shop_to_storage(4);
        action_system.move_item_from_storage_to_shop(0);
    }

    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid item_id', 'ENTRYPOINT_FAILED'))]
    fn test_sell_item_invalid_item_id() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = starknet::contract_address_const::<0x0>();

        add_items(ref item_system);

        action_system.spawn('Alice', WMClass::Warrior);
        shop_system.reroll_shop();

        // mock shop for testing
        let mut shop_data: Shop = world.read_model(alice);
        shop_data.item1 = 10;
        world.write_model(@shop_data);

        action_system.move_item_from_shop_to_storage(10);
        action_system.move_item_from_storage_to_shop(3);
    }
}

