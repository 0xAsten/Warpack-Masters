#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_contract_address;

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    use dojo::test_utils::{spawn_test_world, deploy_contract};

    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::backpack::{BackpackGrids}, models::Item::{Item, item, ItemsCounter},
        models::Character::{Character, character, WMClass}, models::Shop::{Shop, shop},
        utils::{test_utils::{add_items}}
    };

    use warpack_masters::systems::actions::actions::{ITEMS_COUNTER_ID, INIT_GOLD, STORAGE_FLAG};


    #[test]
    #[should_panic(expected: ('No items found', 'ENTRYPOINT_FAILED'))]
    #[available_gas(3000000000000000)]
    fn test_reroll_shop_no_items() {
        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn('Alice', WMClass::Warrior);

        actions_system.reroll_shop();
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_reroll_shop() {
        let owner = starknet::contract_address_const::<0x0>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        actions_system.spawn('Alice', WMClass::Warrior);

        let shop = get!(world, owner, (Shop));
        assert(shop.item1 == 0, 'item1 should be 0');

        actions_system.reroll_shop();

        let shop = get!(world, owner, (Shop));
        assert(shop.item1 != 0, 'item1 should not be 0');
    }

    #[test]
    #[should_panic(expected: ('Not enough gold', 'ENTRYPOINT_FAILED'))]
    #[available_gas(3000000000000000)]
    fn test_reroll_shop_not_enouth_gold() {
        let owner = starknet::contract_address_const::<0x0>();

        let mut models = array![];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut actions_system = IActionsDispatcher { contract_address };

        add_items(ref actions_system);

        actions_system.spawn('Alice', WMClass::Warrior);

        let mut char = get!(world, owner, (Character));
        char.gold -= INIT_GOLD + 1;
        set!(world, (char));

        let shop = get!(world, owner, (Shop));
        assert(shop.item1 == 0, 'item1 should be 0');

        actions_system.reroll_shop();

        let shop = get!(world, owner, (Shop));
        assert(shop.item1 != 0, 'item1 should not be 0');
    }
}

