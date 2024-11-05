use warpack_masters::prdefined_dummies::PredefinedItem;
use warpack_masters::models::Character::WMClass;


#[starknet::interface]
trait IDummy<T> {
    fn create_dummy(ref self: T,);
    fn prefine_dummy(ref self: T, level: usize, name: felt252, wmClass: WMClass, items: Array<PredefinedItem>);
    fn update_prefine_dummy(ref self: T, dummyCharId: usize, level: usize, name: felt252, wmClass: WMClass, items: Array<PredefinedItem>);
}

#[dojo::contract]
mod dummy_system {
    use super::IDummy;

    use starknet::{get_caller_address};
    use warpack_masters::models::Character::{Characters, WMClass, NameRecord};
    use warpack_masters::models::CharacterItem::{
        CharacterItemsInventoryCounter, CharacterItemInventory
    };
    use warpack_masters::models::DummyCharacter::{DummyCharacter, DummyCharacterCounter};
    use warpack_masters::models::DummyCharacterItem::{
        DummyCharacterItem, DummyCharacterItemsCounter
    };
    use warpack_masters::prdefined_dummies::PredefinedItem;

    use warpack_masters::systems::view::view::ViewImpl;

    use warpack_masters::constants::constants::{INIT_HEALTH, INIT_STAMINA};

    #[abi(embed_v0)]
    impl DummyImpl of IDummy<ContractState> {
        fn create_dummy(ref self: ContractState) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            let mut char: Characters = world.read_model(player);

            assert(char.dummied == false, 'dummy already created');
            assert(char.loss < 5, 'max loss reached');

            let mut dummyCharCounter: DummyCharacterCounter = world.read_model(char.wins);
            dummyCharCounter.count += 1;

            let dummyChar = DummyCharacter {
                level: char.wins,
                id: dummyCharCounter.count,
                name: char.name,
                wmClass: char.wmClass,
                health: char.health,
                player: player,
                rating: char.rating,
                stamina: INIT_STAMINA,
            };
            char.dummied = true;

            let inventoryItemCounter: CharacterItemsInventoryCounter = world.read_model(player);

            let mut count = 0;
            loop {
                if count == inventoryItemCounter.count {
                    break;
                }

                let inventoryItem: CharacterItemInventory = world.read_model((player, count+1));

                let mut dummyCharItemsCounter: DummyCharacterItemsCounter = world.read_model((char.wins, dummyCharCounter.count));

                dummyCharItemsCounter.count += 1;

                let dummyCharItem = DummyCharacterItem {
                    level: char.wins,
                    dummyCharId: dummyCharCounter.count,
                    counterId: dummyCharItemsCounter.count,
                    itemId: inventoryItem.itemId,
                    position: inventoryItem.position,
                    rotation: inventoryItem.rotation,
                    plugins: inventoryItem.plugins.span(),
                };

                world.set_model(@dummyCharItemsCounter);
                world.set_model(@dummyCharItem);

                count += 1;
            };

            world.set_model(@char);
            world.set_model(@dummyCharCounter);
            world.set_model(@dummyChar);
        }

        fn prefine_dummy(ref self: ContractState, level: usize, name: felt252, wmClass: WMClass, items: Array<PredefinedItem>) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();
            assert(ViewImpl::is_world_owner(world, player), 'player not world owner');

            let mut health: usize = INIT_HEALTH;

            match level {
                0 => {
                    health = INIT_HEALTH;
                },
                1 => {
                    health = INIT_HEALTH + 10;
                },
                2 => {
                    health = INIT_HEALTH + 20;
                },
                3 => {
                    health = INIT_HEALTH + 30;
                },
                4 => {
                    health = INIT_HEALTH + 40;
                },
                _ => {
                    health = INIT_HEALTH + 55;
                }
            }

            let nameRecord: NameRecord = world.read_model(name);
            assert(
                nameRecord.player == starknet::contract_address_const::<0>(),
                'name already exists'
            );

            let mut dummyCharCounter: DummyCharacterCounter = world.read_model(level);
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
                stamina: INIT_STAMINA,
            };

            let mut dummyCharItemsCounter: DummyCharacterItemsCounter = world.read_model((level, dummyCharCounter.count));

            let mut i = 0;
            loop {
                if items.len() == i {
                    break;
                }

                dummyCharItemsCounter.count += 1;

                let item = *items.at(i);

                let dummyCharItem = DummyCharacterItem {
                    level: level,
                    dummyCharId: dummyCharCounter.count,
                    counterId: dummyCharItemsCounter.count,
                    itemId: item.itemId,
                    position: item.position,
                    rotation: item.rotation,
                    plugins: item.plugins,
                };

                world.set_model(@dummyCharItem);
                
                i += 1;
            };

            world.set_model(@dummyCharCounter);
            world.set_model(@dummyChar);
            world.set_model(@dummyCharItemsCounter);
            world.set_model(@NameRecord{ name, player });
        }

        fn update_prefine_dummy(ref self: ContractState, dummyCharId: usize, level: usize, name: felt252, wmClass: WMClass, items: Array<PredefinedItem>) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();
            assert(ViewImpl::is_world_owner(world, player), 'player not world owner');
    
            let mut health: usize = INIT_HEALTH;
        
            match level {
                0 => {
                    health = INIT_HEALTH;
                },
                1 => {
                    health = INIT_HEALTH + 10;
                },
                2 => {
                    health = INIT_HEALTH + 20;
                },
                3 => {
                    health = INIT_HEALTH + 30;
                },
                4 => {
                    health = INIT_HEALTH + 40;
                },
                _ => {
                    health = INIT_HEALTH + 55;
                }
            }
            
            let mut dummyChar: DummyCharacter = world.read_model((level, dummyCharId));
            if dummyChar.name != name {
                let nameRecord: NameRecord = world.read_model(name);
                assert(
                    nameRecord.player == starknet::contract_address_const::<0>(),
                    'name already exists'
                );

                dummyChar.name = name;
            }
            
            dummyChar.wmClass = wmClass;
            dummyChar.health = health;
            world.set_model(@dummyChar);
            
            let mut dummyCharItemsCounter: DummyCharacterItemsCounter = world.read_model((level, dummyCharId));
            assert(dummyCharItemsCounter.count <= items.len(), 'invalid items length');
    
            let mut i = 0;
            loop {
                if items.len() == i {
                    break;
                }
    
                let item = *items.at(i);
    
                i += 1;
                let dummyCharItem = DummyCharacterItem {
                    level: level,
                    dummyCharId: dummyCharId,
                    counterId: i,
                    itemId: item.itemId,
                    position: item.position,
                    rotation: item.rotation,
                    plugins: item.plugins,
                };
                
                world.set_model(@dummyCharItem);
            };

            dummyCharItemsCounter.count = i;
            world.set_model(@dummyCharItemsCounter);
        }
    }
}
