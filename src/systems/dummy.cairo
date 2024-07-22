#[dojo::interface]
trait IDummy {
    fn create_dummy(ref world: IWorldDispatcher);
    fn prefine_dummy(ref world: IWorldDispatcher, level: usize);
    fn update_prefine_dummy(ref world: IWorldDispatcher, level: usize, dummyCharId: usize);
}

#[dojo::contract]
mod dummy_system {
    use super::IDummy;

    use starknet::{get_caller_address};
    use warpack_masters::models::Character::{Character, WMClass, NameRecord};
    use warpack_masters::models::DummyCharacter::{DummyCharacter, DummyCharacterCounter};
    use warpack_masters::models::DummyCharacterItem::{
        DummyCharacterItem, DummyCharacterItemsCounter
    };
    use warpack_masters::prdefined_dummies::{
        PredefinedItem, Dummy0, Dummy1, Dummy2, Dummy3, Dummy4, Dummy5, Dummy6, Dummy7, Dummy8,
        Dummy9, Dummy10
    };

    #[abi(embed_v0)]
    impl DummyImpl of IDummy<ContractState> {
        fn create_dummy(ref world: IWorldDispatcher) {
            let player = get_caller_address();

            let mut char = get!(world, player, (Character));

            assert(char.dummied == false, 'dummy already created');
            assert(char.loss < 5, 'max loss reached');

            let mut dummyCharCounter = get!(world, char.wins, (DummyCharacterCounter));
            dummyCharCounter.count += 1;

            let dummyChar = DummyCharacter {
                level: char.wins,
                id: dummyCharCounter.count,
                name: char.name,
                wmClass: char.wmClass,
                health: char.health,
                player: player,
                rating: char.rating,
            };
            char.dummied = true;

            let inventoryItemCounter = get!(world, player, (CharacterItemsInventoryCounter));
            let mut count = inventoryItemCounter.count;

            loop {
                if count == 0 {
                    break;
                }

                let inventoryItem = get!(world, (player, count), (CharacterItemInventory));

                let mut dummyCharItemsCounter = get!(
                    world, (char.wins, dummyCharCounter.count), (DummyCharacterItemsCounter)
                );
                dummyCharItemsCounter.count += 1;

                let dummyCharItem = DummyCharacterItem {
                    level: char.wins,
                    dummyCharId: dummyCharCounter.count,
                    counterId: dummyCharItemsCounter.count,
                    itemId: inventoryItem.itemId,
                    position: inventoryItem.position,
                    rotation: inventoryItem.rotation,
                };

                set!(world, (dummyCharItemsCounter, dummyCharItem));

                count -= 1;
            };

            set!(world, (char, dummyCharCounter, dummyChar));
        }

        fn prefine_dummy(ref world: IWorldDispatcher, level: usize) {
            let player = get_caller_address();
            // @todo ref view_system
            // assert(self.is_world_owner(world, player), 'player not world owner');

            let mut name: felt252 = '';
            let mut wmClassNo: u8 = 0;
            let mut wmClass: WMClass = WMClass::Warrior;
            let mut health: usize = 0;

            let mut items: Array<PredefinedItem> = array![];

            match level {
                0 => {
                    name = Dummy0::name;
                    wmClassNo = Dummy0::wmClass;
                    health = Dummy0::health;
                    items = Dummy0::get_items();
                },
                1 => {
                    name = Dummy1::name;
                    wmClassNo = Dummy1::wmClass;
                    health = Dummy1::health;
                    items = Dummy1::get_items();
                },
                2 => {
                    name = Dummy2::name;
                    wmClassNo = Dummy2::wmClass;
                    health = Dummy2::health;
                    items = Dummy2::get_items();
                },
                3 => {
                    name = Dummy3::name;
                    wmClassNo = Dummy3::wmClass;
                    health = Dummy3::health;
                    items = Dummy3::get_items();
                },
                4 => {
                    name = Dummy4::name;
                    wmClassNo = Dummy4::wmClass;
                    health = Dummy4::health;
                    items = Dummy4::get_items();
                },
                5 => {
                    name = Dummy5::name;
                    wmClassNo = Dummy5::wmClass;
                    health = Dummy5::health;
                    items = Dummy5::get_items();
                },
                6 => {
                    name = Dummy6::name;
                    wmClassNo = Dummy6::wmClass;
                    health = Dummy6::health;
                    items = Dummy6::get_items();
                },
                7 => {
                    name = Dummy7::name;
                    wmClassNo = Dummy7::wmClass;
                    health = Dummy7::health;
                    items = Dummy7::get_items();
                },
                8 => {
                    name = Dummy8::name;
                    wmClassNo = Dummy8::wmClass;
                    health = Dummy8::health;
                    items = Dummy8::get_items();
                },
                9 => {
                    name = Dummy9::name;
                    wmClassNo = Dummy9::wmClass;
                    health = Dummy9::health;
                    items = Dummy9::get_items();
                },
                10 => {
                    name = Dummy10::name;
                    wmClassNo = Dummy10::wmClass;
                    health = Dummy10::health;
                    items = Dummy10::get_items();
                },
                _ => { assert(false, 'invalid level'); }
            }

            match wmClassNo {
                0 => { wmClass = WMClass::Warrior; },
                1 => { wmClass = WMClass::Warlock; },
                2 => { wmClass = WMClass::Archer; },
                _ => { assert(false, 'invalid wmClass'); }
            }

            let nameRecord = get!(world, name, NameRecord);
            assert(
                nameRecord.player == starknet::contract_address_const::<0>(), 'name already exists'
            );

            let mut dummyCharCounter = get!(world, level, (DummyCharacterCounter));
            dummyCharCounter.count += 1;

            let player = starknet::contract_address_const::<0x1>();
            let dummyChar = DummyCharacter {
                level: level,
                id: dummyCharCounter.count,
                name: name,
                wmClass: wmClass,
                health: health,
                player: player,
                rating: 0,
            };

            let mut dummyCharItemsCounter = get!(
                world, (level, dummyCharCounter.count), (DummyCharacterItemsCounter)
            );

            loop {
                if items.len() == 0 {
                    break;
                }

                let item = items.pop_front().unwrap();

                dummyCharItemsCounter.count += 1;

                let dummyCharItem = DummyCharacterItem {
                    level: level,
                    dummyCharId: dummyCharCounter.count,
                    counterId: dummyCharItemsCounter.count,
                    itemId: item.itemId,
                    position: item.position,
                    rotation: item.rotation,
                };

                set!(world, (dummyCharItem));
            };

            set!(
                world,
                (dummyCharCounter, dummyChar, dummyCharItemsCounter, NameRecord { name, player })
            );
        }

        fn update_prefine_dummy(ref world: IWorldDispatcher, level: usize, dummyCharId: usize) {
            let player = get_caller_address();
            // @todo ref view_system
            // assert(self.is_world_owner(world, player), 'player not world owner');

            let mut name: felt252 = '';
            let mut wmClassNo: u8 = 0;
            let mut wmClass: WMClass = WMClass::Warrior;
            let mut health: usize = 0;

            let mut items: Array<PredefinedItem> = array![];

            match level {
                0 => {
                    name = Dummy0::name;
                    wmClassNo = Dummy0::wmClass;
                    health = Dummy0::health;
                    items = Dummy0::get_items();
                },
                1 => {
                    name = Dummy1::name;
                    wmClassNo = Dummy1::wmClass;
                    health = Dummy1::health;
                    items = Dummy1::get_items();
                },
                2 => {
                    name = Dummy2::name;
                    wmClassNo = Dummy2::wmClass;
                    health = Dummy2::health;
                    items = Dummy2::get_items();
                },
                3 => {
                    name = Dummy3::name;
                    wmClassNo = Dummy3::wmClass;
                    health = Dummy3::health;
                    items = Dummy3::get_items();
                },
                4 => {
                    name = Dummy4::name;
                    wmClassNo = Dummy4::wmClass;
                    health = Dummy4::health;
                    items = Dummy4::get_items();
                },
                5 => {
                    name = Dummy5::name;
                    wmClassNo = Dummy5::wmClass;
                    health = Dummy5::health;
                    items = Dummy5::get_items();
                },
                6 => {
                    name = Dummy6::name;
                    wmClassNo = Dummy6::wmClass;
                    health = Dummy6::health;
                    items = Dummy6::get_items();
                },
                7 => {
                    name = Dummy7::name;
                    wmClassNo = Dummy7::wmClass;
                    health = Dummy7::health;
                    items = Dummy7::get_items();
                },
                8 => {
                    name = Dummy8::name;
                    wmClassNo = Dummy8::wmClass;
                    health = Dummy8::health;
                    items = Dummy8::get_items();
                },
                9 => {
                    name = Dummy9::name;
                    wmClassNo = Dummy9::wmClass;
                    health = Dummy9::health;
                    items = Dummy9::get_items();
                },
                10 => {
                    name = Dummy10::name;
                    wmClassNo = Dummy10::wmClass;
                    health = Dummy10::health;
                    items = Dummy10::get_items();
                },
                _ => { assert(false, 'invalid level'); }
            }

            match wmClassNo {
                0 => { wmClass = WMClass::Warrior; },
                1 => { wmClass = WMClass::Warlock; },
                2 => { wmClass = WMClass::Archer; },
                _ => { assert(false, 'invalid wmClass'); }
            }

            let player = starknet::contract_address_const::<0x1>();
            let dummyChar = DummyCharacter {
                level: level,
                id: dummyCharId,
                name: name,
                wmClass: wmClass,
                health: health,
                player: player,
                rating: 0,
            };

            let mut dummyCharItemsCounter = get!(
                world, (level, dummyCharId), (DummyCharacterItemsCounter)
            );
            assert(dummyCharItemsCounter.count == items.len(), 'invalid items length');

            let mut i = 0;
            loop {
                if items.len() == 0 {
                    break;
                }

                let item = items.pop_front().unwrap();

                i += 1;
                let dummyCharItem = DummyCharacterItem {
                    level: level,
                    dummyCharId: dummyCharId,
                    counterId: i,
                    itemId: item.itemId,
                    position: item.position,
                    rotation: item.rotation,
                };

                set!(world, (dummyCharItem));
            };

            set!(world, (dummyChar));
        }
    }
}
