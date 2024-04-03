#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_contract_address;

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    use dojo::test_utils::{spawn_test_world, deploy_contract};

    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::backpack::{Backpack, backpack, BackpackGrids, Grid, GridTrait},
        models::Item::{Item, item, ItemsCounter},
        models::CharacterItem::{
            CharacterItemsCounter, character_items_counter, CharacterItem, character_item
        },
        models::Character::{Character, character, Class}, models::Shop::{Shop, shop},
    };

    use warpack_masters::systems::actions::actions::{ITEMS_COUNTER_ID, INIT_GOLD, STORAGE_FLAG};

    use debug::PrintTrait;


    #[test]
    #[should_panic(expected: ('No items found', 'ENTRYPOINT_FAILED'))]
    #[available_gas(3000000000000000)]
    fn test_reroll_shop_no_items() {
        let owner = starknet::contract_address_const::<0x0>();

        let mut models = array![
            backpack::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            character_items_counter::TEST_CLASS_HASH,
            character_item::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.reroll_shop();
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_reroll_shop() {
        let owner = starknet::contract_address_const::<0x0>();

        let mut models = array![
            backpack::TEST_CLASS_HASH,
            character::TEST_CLASS_HASH,
            item::TEST_CLASS_HASH,
            character_items_counter::TEST_CLASS_HASH,
            character_item::TEST_CLASS_HASH
        ];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        let item_one_name = 'Sword';
        let item_one_width = 1;
        let item_one_height = 3;
        let item_one_price = INIT_GOLD + 10;
        let item_one_damage = 10;
        let item_one_armor = 10;
        let item_one_chance = 5;
        let item_one_cooldown = 10;
        let item_one_heal = 5;
        let item_one_rarity = 1;

        actions_system
            .add_item(
                item_one_name,
                item_one_width,
                item_one_height,
                item_one_price,
                item_one_damage,
                item_one_armor,
                item_one_chance,
                item_one_cooldown,
                item_one_heal,
                item_one_rarity,
            );

        let shop = get!(world, owner, (Shop));
        assert(shop.item1 == 0, 'item1 should be 0');

        actions_system.reroll_shop();

        let shop = get!(world, owner, (Shop));
        assert(shop.item1 == 1, 'item1 should not be 0');
    }
}

