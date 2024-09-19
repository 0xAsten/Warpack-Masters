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
    use warpack_masters::items;

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
    fn test_buy_item() {
        let alice = starknet::contract_address_const::<0x1337>();

        let world = spawn_test_world!();
        let (action_system_address, mut action_system, _, mut item_system, _, mut shop_system) =
            get_systems(
            world
        );

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('Alice', WMClass::Warrior);
        shop_system.reroll_shop();

        set_contract_address(action_system_address);

        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 5;
        set!(world, (shop_data));

        set_contract_address(alice);

        shop_system.buy_item(5);

        let char_data = get!(world, alice, (Characters));
        assert(char_data.gold == INIT_GOLD - items::Spike::price, 'gold value mismatch');

        let storageItemCount = get!(world, alice, (CharacterItemsStorageCounter));
        assert(storageItemCount.count == 2, 'total item count mismatch');

        let storageItem = get!(world, (alice, 2), (CharacterItemStorage));
        assert(storageItem.id == 2, 'id mismatch');
        assert(storageItem.itemId == 5, 'item id mismatch');
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('Not enough gold', 'ENTRYPOINT_FAILED'))]
    fn test_buy_item_revert_not_enough_gold() {
        let alice = starknet::contract_address_const::<0x1337>();

        let world = spawn_test_world!();
        let (action_system_address, mut action_system, _, mut item_system, _, mut shop_system) =
            get_systems(
            world
        );

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('Alice', WMClass::Warrior);
        shop_system.reroll_shop();

        set_contract_address(action_system_address);

        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 3;
        set!(world, (shop_data));

        let mut player_data = get!(world, alice, (Characters));
        player_data.gold = 0;
        set!(world, (player_data));

        set_contract_address(alice);

        shop_system.buy_item(3);
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item not on sale', 'ENTRYPOINT_FAILED'))]
    fn test_buy_item_revert_not_on_sale() {
        let alice = starknet::contract_address_const::<0x1337>();

        let world = spawn_test_world!();
        let (_, mut action_system, _, mut item_system, _, mut shop_system) = get_systems(world);

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('Alice', WMClass::Warrior);

        shop_system.buy_item(4);
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('item not on sale', 'ENTRYPOINT_FAILED'))]
    fn test_buy_item_revert_cannot_buy_multiple() {
        let alice = starknet::contract_address_const::<0x1337>();

        let world = spawn_test_world!();
        let (action_system_address, mut action_system, _, mut item_system, _, mut shop_system) =
            get_systems(
            world
        );

        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('Alice', WMClass::Warrior);
        shop_system.reroll_shop();

        set_contract_address(action_system_address);

        let mut player_data = get!(world, alice, (Characters));
        player_data.gold = 100;
        set!(world, (player_data));

        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 4;
        shop_data.item2 = 5;
        shop_data.item3 = 10;
        shop_data.item4 = 11;
        set!(world, (shop_data));

        set_contract_address(alice);

        shop_system.buy_item(11);
        shop_system.buy_item(11);
    }


    #[test]
    #[available_gas(3000000000000000)]
    #[should_panic(expected: ('invalid item_id', 'ENTRYPOINT_FAILED'))]
    fn test_buy_item_revert_invalid_item_id() {
        let alice = starknet::contract_address_const::<0x1337>();

        let world = spawn_test_world!();
        let (action_system_address, mut action_system, _, mut item_system, _, mut shop_system) =
            get_systems(
            world
        );
        add_items(ref item_system);

        set_contract_address(alice);

        action_system.spawn('Alice', WMClass::Warrior);
        shop_system.reroll_shop();

        set_contract_address(action_system_address);

        let mut player_data = get!(world, alice, (Characters));
        player_data.gold = 100;
        set!(world, (player_data));

        let mut shop_data = get!(world, alice, (Shop));
        shop_data.item1 = 3;
        shop_data.item2 = 4;
        shop_data.item3 = 10;
        shop_data.item4 = 12;
        set!(world, (shop_data));

        set_contract_address(alice);

        shop_system.buy_item(3);
        shop_system.buy_item(0);
    }
}

