#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    // import test utils
    use dojo_starter::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::{backpack::{Backpack, backpack}}
    };


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

        assert(backpack.gridSize == 10, 'gridSize should be 10');
    }
}
