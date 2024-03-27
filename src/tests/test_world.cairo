#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    // import test utils
    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::backpack::{Backpack, backpack, Grid, GridTrait},
        models::Item::{Item, item, ItemsCounter},
        models::CharacterItem::{CharacterItem, Position, CharacterItemsCounter}
    };

    use warpack_masters::systems::actions::actions::ITEMS_COUNTER_ID;


    #[test]
    #[available_gas(30000000)]
    fn test_spawn() {
        let caller = starknet::contract_address_const::<0x0>();

        let mut models = array![backpack::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn();

        let backpack = get!(world, caller, Backpack);

        assert(!backpack.grid.is_zero(), 'grid should not be 0');
    }

    #[test]
    #[should_panic]
    #[available_gas(30000000)]
    fn test_spawn_already_exists() {
        let caller = starknet::contract_address_const::<0x0>();

        let mut models = array![backpack::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn();

        actions_system.spawn();
    }

    #[test]
    #[available_gas(30000000)]
    fn test_place_item() {
        let caller = starknet::contract_address_const::<0x0>();

        let mut models = array![backpack::TEST_CLASS_HASH, item::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn();

        actions_system.add_item('Sword', 1, 3, 100, 10, 10, 5, 10, 5);

        let item = get!(world, ITEMS_COUNTER_ID, Item);

        actions_system.place_item(item.id, 0, 0, 0);

        let characterItemsCounter = get!(world, caller, CharacterItemsCounter);
        let characterItem = get!(world, (caller, characterItemsCounter.count), CharacterItem);

        assert(characterItem.itemId == characterItemsCounter.count, 'item id should equal count');
    }
}
