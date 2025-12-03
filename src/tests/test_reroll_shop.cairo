#[cfg(test)]
mod tests {
    use dojo::model::ModelStorage;
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{
        ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
        spawn_test_world,
    };
    use starknet::testing::set_contract_address;
    use warpack_masters::constants::constants::INIT_GOLD;
    use warpack_masters::models::Character::{Character, WMClass, m_Character, m_CharacterName};
    use warpack_masters::models::CharacterItem::{
        m_InventoryCounter, m_InventoryItem, m_StorageCounter, m_StorageItem,
    };
    use warpack_masters::models::Game::m_GameConfig;
    use warpack_masters::models::Item::{m_Item, m_ItemsCounter};
    use warpack_masters::models::Shop::{Shop, m_Shop};
    use warpack_masters::models::backpack::m_BackpackGrids;
    use warpack_masters::systems::actions::{IActionsDispatcher, IActionsDispatcherTrait, actions};
    use warpack_masters::systems::item::{IItemDispatcher, item_system};
    use warpack_masters::systems::shop::{IShopDispatcher, IShopDispatcherTrait, shop_system};
    use warpack_masters::utils::test_utils::add_items;

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "Warpacks",
            resources: [
                TestResource::Model(m_BackpackGrids::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Item::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_ItemsCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_StorageItem::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_StorageCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_InventoryItem::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_InventoryCounter::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Character::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_CharacterName::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Shop::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_GameConfig::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Contract(actions::TEST_CLASS_HASH),
                TestResource::Contract(item_system::TEST_CLASS_HASH),
                TestResource::Contract(shop_system::TEST_CLASS_HASH),
                TestResource::Event(actions::e_BuyItem::TEST_CLASS_HASH),
                TestResource::Event(actions::e_SellItem::TEST_CLASS_HASH),
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
            ContractDefTrait::new(@"Warpacks", @"shop_system")
                .with_writer_of([dojo::utils::bytearray_hash(@"Warpacks")].span()),
        ]
            .span()
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_reroll_shop() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = warpack_masters::utils::address::zero_address();

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('Alice', WMClass::Warrior);

        let shop: Shop = world.read_model(alice);
        assert(shop.item1 == 0, 'item1 should be 0');

        shop_system.reroll_shop();

        let shop: Shop = world.read_model(alice);
        assert(shop.item1 != 0, 'item1 should not be 0');
    }

    #[test]
    #[should_panic(expected: ('Not enough gold', 'ENTRYPOINT_FAILED'))]
    #[available_gas(3000000000000000)]
    fn test_reroll_shop_not_enough_gold() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let action_system = IActionsDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"item_system").unwrap();
        let mut item_system = IItemDispatcher { contract_address };

        let (contract_address, _) = world.dns(@"shop_system").unwrap();
        let mut shop_system = IShopDispatcher { contract_address };

        let alice = warpack_masters::utils::address::zero_address();

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('Alice', WMClass::Warrior);

        let mut char: Character = world.read_model(alice);
        char.gold -= INIT_GOLD + 1;
        world.write_model(@char);

        let shop: Shop = world.read_model(alice);
        assert(shop.item1 == 0, 'item1 should be 0');

        shop_system.reroll_shop();
    }
}
