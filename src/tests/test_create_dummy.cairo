#[cfg(test)]
mod tests {
    use core::array::ArrayTrait;
    use core::option::OptionTrait;
    use core::starknet::contract_address::ContractAddress;
    use dojo::model::{Model, ModelEntityTest, ModelIndex, ModelTest};

    // import test utils
    use dojo::utils::test::{deploy_contract, spawn_test_world};
    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use starknet::testing::set_contract_address;
    use warpack_masters::constants::constants::{GAME_CONFIG_ID, INIT_HEALTH, INIT_STAMINA, REBIRTH_FEE};
    use warpack_masters::prdefined_dummies::{
        Dummy0, Dummy1, Dummy10, Dummy11, Dummy12, Dummy13, Dummy14, Dummy15, Dummy16, Dummy17,
        Dummy18, Dummy19, Dummy2, Dummy20, Dummy3, Dummy4, Dummy5, Dummy6, Dummy7, Dummy8, Dummy9,
        PredefinedItem,
    };

    // import test utils
    use warpack_masters::{
        models::Character::{Character, CharacterName, WMClass, character, character_name},
        models::CharacterItem::{
            InventoryCounter, InventoryItem, Position, StorageCounter, StorageItem,
            character_item_inventory, character_item_storage, character_items_inventory_counter,
            character_items_storage_counter,
        },
        models::Game::GameConfig,
        models::DummyCharacter::{
            DummyCharacter, DummyCharacterCounter, dummy_character, dummy_character_counter,
        },
        models::DummyCharacterItem::{
            DummyCharacterItem, DummyCharacterItemsCounter, dummy_character_item,
            dummy_character_items_counter,
        },
        models::Item::{Item, ItemsCounter, item, items_counter}, models::Shop::{Shop, shop},
        models::backpack::{BackpackGrids, backpack_grids},
        systems::{actions::{IActionsDispatcher, IActionsDispatcherTrait, actions}},
        systems::{dummy::{IDummyDispatcher, IDummyDispatcherTrait, dummy_system}},
        systems::{item::{IItemDispatcher, IItemDispatcherTrait, item_system}},
        utils::{test_utils::{add_items}},
    };

    fn get_systems(
        world: IWorldDispatcher,
    ) -> (
        ContractAddress,
        IActionsDispatcher,
        ContractAddress,
        IItemDispatcher,
        ContractAddress,
        IDummyDispatcher,
    ) {
        let action_system_address = world
            .deploy_contract('salt1', actions::TEST_CLASS_HASH.try_into().unwrap());
        let mut action_system = IActionsDispatcher { contract_address: action_system_address };

        world.grant_writer(Model::<StorageItem>::selector(), action_system_address);
        world.grant_writer(Model::<StorageCounter>::selector(), action_system_address);
        world.grant_writer(Model::<InventoryItem>::selector(), action_system_address);
        world.grant_writer(Model::<InventoryCounter>::selector(), action_system_address);
        world.grant_writer(Model::<BackpackGrids>::selector(), action_system_address);
        world.grant_writer(Model::<Character>::selector(), action_system_address);
        world.grant_writer(Model::<CharacterName>::selector(), action_system_address);
        world.grant_writer(Model::<Shop>::selector(), action_system_address);
        world.grant_writer(Model::<GameConfig>::selector(), action_system_address);

        let item_system_address = world
            .deploy_contract('salt2', item_system::TEST_CLASS_HASH.try_into().unwrap());
        let mut item_system = IItemDispatcher { contract_address: item_system_address };

        world.grant_writer(Model::<Item>::selector(), item_system_address);
        world.grant_writer(Model::<ItemsCounter>::selector(), item_system_address);

        let dummy_system_address = world
            .deploy_contract('salt4', dummy_system::TEST_CLASS_HASH.try_into().unwrap());
        let mut dummy_system = IDummyDispatcher { contract_address: dummy_system_address };

        world.grant_writer(Model::<DummyCharacterItem>::selector(), dummy_system_address);
        world.grant_writer(Model::<DummyCharacterItemsCounter>::selector(), dummy_system_address);
        world.grant_writer(Model::<DummyCharacter>::selector(), dummy_system_address);
        world.grant_writer(Model::<DummyCharacterCounter>::selector(), dummy_system_address);
        world.grant_writer(Model::<CharacterName>::selector(), dummy_system_address);
        world.grant_writer(Model::<Character>::selector(), dummy_system_address);

        (
            action_system_address,
            action_system,
            item_system_address,
            item_system,
            dummy_system_address,
            dummy_system,
        )
    }

    #[test]
    #[available_gas(3000000000000000)]
    fn test_create_dummy() {
        let world = spawn_test_world!();
        let (action_system_address, mut action_system, _, mut item_system, _, mut dummy_system) =
            get_systems(
            world,
        );
        add_items(ref item_system);
        world
            .write_model(
                @GameConfig {
                    id: GAME_CONFIG_ID,
                    strk_address: warpack_masters::utils::address::zero_address(),
                    rebirth_fee: REBIRTH_FEE,
                },
            );

        let dummy0 = warpack_masters::utils::address::address_from(0x001);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy0,
            Dummy0::level,
            Dummy0::name,
            Dummy0::wmClass,
            Dummy0::health,
            Dummy0::get_items(),
        );

        let dummy1 = warpack_masters::utils::address::address_from(0x002);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy1,
            Dummy1::level,
            Dummy1::name,
            Dummy1::wmClass,
            Dummy1::health,
            Dummy1::get_items(),
        );

        let dummy2 = warpack_masters::utils::address::address_from(0x003);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy2,
            Dummy2::level,
            Dummy2::name,
            Dummy2::wmClass,
            Dummy2::health,
            Dummy2::get_items(),
        );

        let dummy3 = warpack_masters::utils::address::address_from(0x004);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy3,
            Dummy3::level,
            Dummy3::name,
            Dummy3::wmClass,
            Dummy3::health,
            Dummy3::get_items(),
        );

        let dummy4 = warpack_masters::utils::address::address_from(0x005);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy4,
            Dummy4::level,
            Dummy4::name,
            Dummy4::wmClass,
            Dummy4::health,
            Dummy4::get_items(),
        );

        let dummy5 = warpack_masters::utils::address::address_from(0x006);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy5,
            Dummy5::level,
            Dummy5::name,
            Dummy5::wmClass,
            Dummy5::health,
            Dummy5::get_items(),
        );

        let dummy6 = warpack_masters::utils::address::address_from(0x007);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy6,
            Dummy6::level,
            Dummy6::name,
            Dummy6::wmClass,
            Dummy6::health,
            Dummy6::get_items(),
        );

        let dummy7 = warpack_masters::utils::address::address_from(0x008);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy7,
            Dummy7::level,
            Dummy7::name,
            Dummy7::wmClass,
            Dummy7::health,
            Dummy7::get_items(),
        );

        let dummy8 = warpack_masters::utils::address::address_from(0x009);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy8,
            Dummy8::level,
            Dummy8::name,
            Dummy8::wmClass,
            Dummy8::health,
            Dummy8::get_items(),
        );

        let dummy9 = warpack_masters::utils::address::address_from(0x00a);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy9,
            Dummy9::level,
            Dummy9::name,
            Dummy9::wmClass,
            Dummy9::health,
            Dummy9::get_items(),
        );

        let dummy10 = warpack_masters::utils::address::address_from(0x00b);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy10,
            Dummy10::level,
            Dummy10::name,
            Dummy10::wmClass,
            Dummy10::health,
            Dummy10::get_items(),
        );

        let dummy11 = warpack_masters::utils::address::address_from(0x00c);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy11,
            Dummy11::level,
            Dummy11::name,
            Dummy11::wmClass,
            Dummy11::health,
            Dummy11::get_items(),
        );

        let dummy12 = warpack_masters::utils::address::address_from(0x00d);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy12,
            Dummy12::level,
            Dummy12::name,
            Dummy12::wmClass,
            Dummy12::health,
            Dummy12::get_items(),
        );

        let dummy13 = warpack_masters::utils::address::address_from(0x00e);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy13,
            Dummy13::level,
            Dummy13::name,
            Dummy13::wmClass,
            Dummy13::health,
            Dummy13::get_items(),
        );

        let dummy14 = warpack_masters::utils::address::address_from(0x00f);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy14,
            Dummy14::level,
            Dummy14::name,
            Dummy14::wmClass,
            Dummy14::health,
            Dummy14::get_items(),
        );

        let dummy15 = warpack_masters::utils::address::address_from(0x010);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy15,
            Dummy15::level,
            Dummy15::name,
            Dummy15::wmClass,
            Dummy15::health,
            Dummy15::get_items(),
        );

        let dummy16 = warpack_masters::utils::address::address_from(0x011);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy16,
            Dummy16::level,
            Dummy16::name,
            Dummy16::wmClass,
            Dummy16::health,
            Dummy16::get_items(),
        );

        let dummy17 = warpack_masters::utils::address::address_from(0x012);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy17,
            Dummy17::level,
            Dummy17::name,
            Dummy17::wmClass,
            Dummy17::health,
            Dummy17::get_items(),
        );

        let dummy18 = warpack_masters::utils::address::address_from(0x013);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy18,
            Dummy18::level,
            Dummy18::name,
            Dummy18::wmClass,
            Dummy18::health,
            Dummy18::get_items(),
        );

        let dummy19 = warpack_masters::utils::address::address_from(0x014);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy19,
            Dummy19::level,
            Dummy19::name,
            Dummy19::wmClass,
            Dummy19::health,
            Dummy19::get_items(),
        );

        let dummy20 = warpack_masters::utils::address::address_from(0x015);
        create_dummy(
            world,
            action_system_address,
            action_system,
            item_system,
            dummy_system,
            dummy20,
            Dummy20::level,
            Dummy20::name,
            Dummy20::wmClass,
            Dummy20::health,
            Dummy20::get_items(),
        );
    }

    fn create_dummy(
        world: IWorldDispatcher,
        action_system_address: ContractAddress,
        action_system: IActionsDispatcher,
        item_system: IItemDispatcher,
        dummy_system: IDummyDispatcher,
        dummy0: ContractAddress,
        level: u32,
        name: felt252,
        wmClass: WMClass,
        health: u32,
        items: Array<PredefinedItem>,
    ) {
        set_contract_address(dummy0);
        action_system.spawn(name, wmClass);
        action_system.move_item_from_inventory_to_storage(1);
        action_system.move_item_from_inventory_to_storage(2);

        set_contract_address(action_system_address);
        let mut character = get!(world, dummy0, (Character));
        character.health = health;
        character.wins = level;
        set!(world, (character));

        let mut i = 0;
        loop {
            if i == items.len() {
                break;
            }
            let item = *items.at(i);

            let storageItem = CharacterItemStorage { player: dummy0, id: 3, itemId: item.itemId };
            set_contract_address(action_system_address);
            set!(world, (storageItem));

            set_contract_address(dummy0);
            action_system
                .move_item_from_storage_to_inventory(
                    3, item.position.x, item.position.y, item.rotation,
                );
            i += 1;
        }

        dummy_system.create_dummy();
        let dummyCharacterCounter = get!(world, level, (DummyCharacterCounter));
        assert(dummyCharacterCounter.count == 1, 'count should be 1');
        let dummyCharacter = get!(world, (level, 1), (DummyCharacter));
        assert(dummyCharacter.name == name, 'name should be Dummy0::name');
        assert(dummyCharacter.wmClass == wmClass, 'wmClass should be Warlock');
        assert(dummyCharacter.health == health, 'health should be Dummy0::health');
        assert(dummyCharacter.player == dummy0, 'player should be dummy0');
        assert(dummyCharacter.rating == 0, 'rating should be 0');
        assert(dummyCharacter.stamina == INIT_STAMINA, 'stamina should be INIT_STAMINA');

        let dummyCharacterItemsCounter = get!(world, (level, 1), (DummyCharacterItemsCounter));
        assert(dummyCharacterItemsCounter.count == items.len(), 'count should be items.len()');

        let wmClassIndex = match dummyCharacter.wmClass {
            WMClass::Warrior => 0,
            WMClass::Warlock => 1,
            WMClass::Archer => 2,
        };
        let mut str: ByteArray = format!(
            "{},{},{}", dummyCharacter.level, dummyCharacter.name, wmClassIndex,
        );
        str += format!(",{}", items.len());

        let mut i = 0;
        loop {
            if i == items.len() {
                break;
            }
            let mut item = *items.at(i);
            let j = if i == 0 {
                2
            } else if i == 1 {
                1
            } else {
                i + 1
            };
            let dummyCharacterItem = get!(world, (level, 1, j), (DummyCharacterItem));
            assert(dummyCharacterItem.itemId == item.itemId, 'itemId should be item.itemId');
            assert(dummyCharacterItem.position.x == item.position.x, 'should be item.position');
            assert(dummyCharacterItem.position.y == item.position.y, 'should be item.position');
            assert(dummyCharacterItem.rotation == item.rotation, 'should be item.rotation');
            item.plugins = dummyCharacterItem.plugins;
            i += 1;

            str += format!(",{}", item);
        }

        println!("{}", str);
    }
}
