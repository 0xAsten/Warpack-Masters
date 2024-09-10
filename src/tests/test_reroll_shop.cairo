#[cfg(test)]
mod tests {
    use core::starknet::contract_address::ContractAddress;
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_contract_address;

    use dojo::model::{Model, ModelTest, ModelIndex, ModelEntityTest};
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    use dojo::utils::test::{spawn_test_world, deploy_contract};

    // import test utils
    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        systems::{item::{item_system, IItemDispatcher, IItemDispatcherTrait}},
        systems::{shop::{shop_system, IShopDispatcher, IShopDispatcherTrait}},
        models::backpack::{BackpackGrids, backpack_grids},
        models::Item::{Item, item, ItemsCounter, items_counter},
        models::Character::{Characters, characters, NameRecord, name_record, WMClass},
        models::Shop::{Shop, shop},
        models::CharacterItem::{
            Position, CharacterItemStorage, character_item_storage, CharacterItemsStorageCounter,
            character_items_storage_counter, CharacterItemInventory, character_item_inventory,
            CharacterItemsInventoryCounter, character_items_inventory_counter
        },
        utils::{test_utils::{add_items}}
    };

    use warpack_masters::constants::constants::{INIT_GOLD};

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
    fn test_reroll_shop() {
        let alice = starknet::contract_address_const::<0x0>();

        let world = spawn_test_world!();
        let (_, mut action_system, _, mut item_system, _, mut shop_system) =
            get_systems(
            world
        );

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('Alice', WMClass::Warrior);

        let shop = get!(world, alice, (Shop));
        assert(shop.item1 == 0, 'item1 should be 0');

        shop_system.reroll_shop();

        let shop = get!(world, alice, (Shop));
        assert(shop.item1 != 0, 'item1 should not be 0');
    }


    #[test]
    #[should_panic(expected: ('Not enough gold', 'ENTRYPOINT_FAILED'))]
    #[available_gas(3000000000000000)]
    fn test_reroll_shop_not_enough_gold() {
        let alice = starknet::contract_address_const::<0x0>();

        let world = spawn_test_world!();
        let (action_system_address, mut action_system, _, mut item_system, _, mut shop_system) =
            get_systems(
            world
        );

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('Alice', WMClass::Warrior);

        set_contract_address(action_system_address);

        let mut char = get!(world, alice, (Characters));
        char.gold -= INIT_GOLD + 1;
        set!(world, (char));

        set_contract_address(alice);

        let shop = get!(world, alice, (Shop));
        assert(shop.item1 == 0, 'item1 should be 0');

        shop_system.reroll_shop();
    }
}

