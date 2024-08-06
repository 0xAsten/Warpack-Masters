use warpack_masters::models::Character::WMClass;

use starknet::ContractAddress;

#[dojo::interface]
trait IActions {
    fn spawn(name: felt252, wmClass: WMClass);
    fn place_item(storage_item_id: u32, x: usize, y: usize, rotation: usize);
    fn undo_place_item(inventory_item_id: u32);
    fn add_item(
        id: u32,
        name: felt252,
        itemType: u8,
        width: usize,
        height: usize,
        price: usize,
        damage: usize,
        cleansePoison: usize,
        chance: usize,
        cooldown: u8,
        rarity: u8,
        armor: u32,
        armorActivation: u8,
        regen: u32,
        regenActivation: u8,
        reflect: u32,
        reflectActivation: u8,
        poison: u32,
        poisonActivation: u8,
        empower: u32,
        empowerActivation: u8,
    );
    fn edit_item(item_id: u32, item_key: felt252, item_value: felt252);
    fn buy_item(item_id: u32);
    fn sell_item(storage_item_id: u32);
    fn is_world_owner(player: ContractAddress) -> bool;
    fn is_item_owned(player: ContractAddress, id: usize) -> bool;
    fn reroll_shop();
    fn create_dummy();
    fn rebirth(name: felt252, wmClass: WMClass);
    fn prefine_dummy(level: usize);
    fn update_prefine_dummy(level: usize, dummyCharId: usize);
}

// TODO: rename the count filed in counter model
// TODO: consider restruct inventory items in case too much items owned by player increasing the loop time

#[dojo::contract]
mod actions {
    use super::IActions;

    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use warpack_masters::models::{backpack::{BackpackGrids}};
    use warpack_masters::models::{
        CharacterItem::{
            Position, CharacterItemsStorageCounter, CharacterItemStorage, CharacterItemInventory,
            CharacterItemsInventoryCounter
        },
        Item::{Item, ItemsCounter}
    };
    use warpack_masters::models::Character::{Character, WMClass, NameRecord};
    use warpack_masters::models::Shop::Shop;
    use warpack_masters::utils::random::{pseudo_seed, random};
    use warpack_masters::models::DummyCharacter::{DummyCharacter, DummyCharacterCounter};
    use warpack_masters::models::DummyCharacterItem::{
        DummyCharacterItem, DummyCharacterItemsCounter
    };
    use warpack_masters::models::BattleLog::{BattleLog, BattleLogCounter};
    use warpack_masters::items::{Backpack, Pack};
    use warpack_masters::prdefined_dummies::{PredefinedItem, Dummy0, Dummy1, Dummy2, Dummy3, Dummy4, Dummy5, Dummy6, Dummy7, Dummy8, Dummy9, Dummy10, Dummy11, Dummy12, Dummy13, Dummy14, Dummy15, Dummy16, Dummy17, Dummy18, Dummy19, Dummy20};

    #[derive(Model, Copy, Drop, Serde)]
    #[dojo::event]
    struct BuyItem {
        #[key]
        player: ContractAddress,
        itemId: usize,
        cost: usize,
        itemRarity: u8,
        birthCount: u32,
    }

    #[derive(Model, Copy, Drop, Serde)]
    #[dojo::event]
    struct SellItem {
        #[key]
        player: ContractAddress,
        itemId: usize,
        price: usize,
        itemRarity: u8,
        birthCount: u32,
    }

    const GRID_X: usize = 9;
    const GRID_Y: usize = 7;
    const INIT_GOLD: usize = 8;
    const INIT_HEALTH: usize = 25;

    const ITEMS_COUNTER_ID: felt252 = 'ITEMS_COUNTER_ID';

    const STORAGE_FLAG: usize = 999;

    const EFFECT_ARMOR: felt252 = 'armor';
    const EFFECT_REGEN: felt252 = 'regen';
    const EFFECT_REFLECT: felt252 = 'reflect';
    const EFFECT_EMPOWER: felt252 = 'empower';
    const EFFECT_POISON: felt252 = 'poison';
    const EFFECT_CLEANSE_POISON: felt252 = 'cleanse_poison';

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn spawn(world: IWorldDispatcher, name: felt252, wmClass: WMClass) {
            let player = get_caller_address();

            assert(name != '', 'name cannot be empty');

            let nameRecord = get!(world, name, NameRecord);
            assert(
                nameRecord.player == starknet::contract_address_const::<0>()
                    || nameRecord.player == player,
                'name already exists'
            );

            let player_exists = get!(world, player, (Character));
            assert(player_exists.name == '', 'player already exists');

            // Default the player has 2 Backpacks
            // Must add two backpack items when setup the game
            let item = get!(world, Backpack::id, (Item));
            assert(item.itemType == 4, 'Invalid item type');
            let item = get!(world, Pack::id, (Item));
            assert(item.itemType == 4, 'Invalid item type');

            set!(
                world,
                (
                    CharacterItemStorage { player, id: 1, itemId: Backpack::id },
                    CharacterItemStorage { player, id: 2, itemId: Pack::id },
                    CharacterItemsStorageCounter { player, count: 2 },
                )
            );

            self.place_item(1, 4, 2, 0);
            self.place_item(2, 2, 2, 0);

            // keep the previous rating, totalWins and totalLoss during rebirth
            let prev_rating = player_exists.rating;
            let prev_total_wins = player_exists.totalWins;
            let prev_total_loss = player_exists.totalLoss;
            let prev_birth_count = player_exists.birthCount;
            let updatedAt = get_block_timestamp();

            // add one gold for reroll shop
            set!(
                world,
                (
                    Character {
                        player,
                        name,
                        wmClass,
                        gold: INIT_GOLD + 1,
                        health: INIT_HEALTH,
                        wins: 0,
                        loss: 0,
                        dummied: false,
                        rating: prev_rating,
                        totalWins: prev_total_wins,
                        totalLoss: prev_total_loss,
                        winStreak: 0,
                        birthCount: prev_birth_count + 1,
                        updatedAt,
                    },
                    NameRecord { name, player }
                )
            );
        }

        fn add_item(
            world: IWorldDispatcher,
            id: u32,
            name: felt252,
            itemType: u8,
            width: usize,
            height: usize,
            price: usize,
            damage: usize,
            cleansePoison: usize,
            chance: usize,
            cooldown: u8,
            rarity: u8,
            armor: u32,
            armorActivation: u8,
            regen: u32,
            regenActivation: u8,
            reflect: u32,
            reflectActivation: u8,
            poison: u32,
            poisonActivation: u8,
            empower: u32,
            empowerActivation: u8,
        ) {
            let player = get_caller_address();

            assert(self.is_world_owner(player), 'player not world owner');

            assert(width > 0 && width <= GRID_X, 'width not in range');
            assert(height > 0 && height <= GRID_Y, 'height not in range');

            assert(price > 0, 'price must be greater than 0');

            assert(
                rarity == 1 || rarity == 2 || rarity == 3 || (rarity == 0 && itemType == 4),
                'rarity not valid'
            );

            let counter = get!(world, ITEMS_COUNTER_ID, ItemsCounter);
            if id > counter.count {
                set!(world, ItemsCounter { id: ITEMS_COUNTER_ID, count: id });
            }

            let item = Item {
                id,
                name,
                itemType,
                width,
                height,
                price,
                damage,
                cleansePoison,
                chance,
                cooldown,
                rarity,
                armor,
                armorActivation,
                regen,
                regenActivation,
                reflect,
                reflectActivation,
                poison,
                poisonActivation,
                empower,
                empowerActivation,
            };

            set!(world, (item));
        }

        fn edit_item(
            world: IWorldDispatcher, item_id: u32, item_key: felt252, item_value: felt252
        ) {
            let player = get_caller_address();

            assert(self.is_world_owner(player), 'player not world owner');

            let mut item_data = get!(world, item_id, (Item));

            match item_key {
                // name
                0 => {
                    item_data.name = item_value;
                    set!(world, (item_data,));
                },
                // itemType
                1 => {
                    let new_itemType: u8 = item_value.try_into().unwrap();

                    item_data.itemType = new_itemType;
                    set!(world, (item_data,));
                },
                // width
                2 => {
                    let new_width: usize = item_value.try_into().unwrap();
                    assert(new_width > 0 && new_width <= GRID_X, 'new_width not in range');

                    item_data.width = new_width;
                    set!(world, (item_data,));
                },
                // height
                3 => {
                    let new_height: usize = item_value.try_into().unwrap();
                    assert(new_height > 0 && new_height <= GRID_Y, 'new_height not in range');

                    item_data.height = new_height;
                    set!(world, (item_data,));
                },
                // price
                4 => {
                    let new_price: usize = item_value.try_into().unwrap();
                    assert(new_price > 0, 'new_price must be > 0');

                    item_data.price = new_price;
                    set!(world, (item_data,));
                },
                // damage
                5 => {
                    let new_damage: usize = item_value.try_into().unwrap();

                    item_data.damage = new_damage;
                    set!(world, (item_data,));
                },
                // cleansePoison
                6 => {
                    let new_cleansePoison: usize = item_value.try_into().unwrap();

                    item_data.cleansePoison = new_cleansePoison;
                    set!(world, (item_data,));
                },
                // chance
                7 => {
                    let new_chance: usize = item_value.try_into().unwrap();

                    item_data.chance = new_chance;
                    set!(world, (item_data,));
                },
                // cooldown
                8 => {
                    let new_cooldown: u8 = item_value.try_into().unwrap();

                    item_data.cooldown = new_cooldown;
                    set!(world, (item_data,));
                },
                // rarity
                9 => {
                    let new_rarity: u8 = item_value.try_into().unwrap();
                    assert(
                        new_rarity == 1 || new_rarity == 2 || new_rarity == 3,
                        'new_rarity not valid'
                    );

                    item_data.rarity = new_rarity;
                    set!(world, (item_data,));
                },
                // armor
                10 => {
                    let new_armor: usize = item_value.try_into().unwrap();

                    item_data.armor = new_armor;
                    set!(world, (item_data,));
                },
                // armorActivation
                11 => {
                    let new_armorActivation: u8 = item_value.try_into().unwrap();

                    item_data.armorActivation = new_armorActivation;
                    set!(world, (item_data,));
                },
                // regen
                12 => {
                    let new_regen: usize = item_value.try_into().unwrap();

                    item_data.regen = new_regen;
                    set!(world, (item_data,));
                },
                // regenActivation
                13 => {
                    let new_regenActivation: u8 = item_value.try_into().unwrap();

                    item_data.regenActivation = new_regenActivation;
                    set!(world, (item_data,));
                },
                // reflect
                14 => {
                    let new_reflect: usize = item_value.try_into().unwrap();

                    item_data.reflect = new_reflect;
                    set!(world, (item_data,));
                },
                // reflectActivation
                15 => {
                    let new_reflectActivation: u8 = item_value.try_into().unwrap();

                    item_data.reflectActivation = new_reflectActivation;
                    set!(world, (item_data,));
                },
                // poison
                16 => {
                    let new_poison: usize = item_value.try_into().unwrap();

                    item_data.poison = new_poison;
                    set!(world, (item_data,));
                },
                // poisonActivation
                17 => {
                    let new_poisonActivation: u8 = item_value.try_into().unwrap();

                    item_data.poisonActivation = new_poisonActivation;
                    set!(world, (item_data,));
                },
                // empower
                18 => {
                    let new_empower: usize = item_value.try_into().unwrap();

                    item_data.empower = new_empower;
                    set!(world, (item_data,));
                },
                // empowerActivation
                19 => {
                    let new_empowerActivation: u8 = item_value.try_into().unwrap();

                    item_data.empowerActivation = new_empowerActivation;
                    set!(world, (item_data,));
                },
                _ => { panic!("Invalid item_key: {}", item_key); }
            }
        }


        fn place_item(
            world: IWorldDispatcher, storage_item_id: u32, x: usize, y: usize, rotation: usize
        ) {
            let player = get_caller_address();

            assert(x < GRID_X, 'x out of range');
            assert(y < GRID_Y, 'y out of range');
            assert(
                rotation == 0 || rotation == 90 || rotation == 180 || rotation == 270,
                'invalid rotation'
            );

            let mut storageItem = get!(world, (player, storage_item_id), (CharacterItemStorage));

            assert(storageItem.itemId != 0, 'item not owned');

            let itemId = storageItem.itemId;
            let item = get!(world, itemId, (Item));

            let itemHeight = item.height;
            let itemWidth = item.width;

            let playerBackpackGrids = get!(world, (player, x, y), (BackpackGrids));

            // if the item is 1x1, occupy the empty grid
            if itemHeight == 1 && itemWidth == 1 {
                if item.itemType == 4 {
                    assert(!playerBackpackGrids.enabled, 'Already enabled');
                    set!(
                        world,
                        (BackpackGrids {
                            player: player, x: x, y: y, enabled: true, occupied: false
                        })
                    );
                } else {
                    assert(playerBackpackGrids.enabled, 'Grid not enabled');
                    assert(!playerBackpackGrids.occupied, 'Already occupied');
                    set!(
                        world,
                        (BackpackGrids {
                            player: player, x: x, y: y, enabled: true, occupied: true
                        })
                    );
                }
            } else {
                let mut xMax = 0;
                let mut yMax = 0;

                // only check grids which are above the starting (x,y)
                if rotation == 0 || rotation == 180 {
                    xMax = x + itemWidth - 1;
                    yMax = y + itemHeight - 1;
                }

                // only check grids which are to the right of the starting (x,y)
                if rotation == 90 || rotation == 270 {
                    //item_h becomes item_w and vice versa
                    xMax = x + itemHeight - 1;
                    yMax = y + itemWidth - 1;
                }

                assert(xMax < GRID_X, 'item out of bound for x');
                assert(yMax < GRID_Y, 'item out of bound for y');

                let mut i = x;
                let mut j = y;
                loop {
                    if i > xMax {
                        break;
                    }
                    loop {
                        if j > yMax {
                            break;
                        }

                        let playerBackpackGrids = get!(world, (player, i, j), (BackpackGrids));
                        if item.itemType == 4 {
                            assert(!playerBackpackGrids.enabled, 'Already enabled');
                            set!(
                                world,
                                (BackpackGrids {
                                    player: player, x: i, y: j, enabled: true, occupied: false
                                })
                            );
                        } else {
                            assert(playerBackpackGrids.enabled, 'Grid not enabled');
                            assert(!playerBackpackGrids.occupied, 'Already occupied');
                            set!(
                                world,
                                (BackpackGrids {
                                    player: player, x: i, y: j, enabled: true, occupied: true
                                })
                            );
                        }

                        j += 1;
                    };
                    j = y;
                    i += 1;
                }
            }

            let mut inventoryCounter = get!(world, player, (CharacterItemsInventoryCounter));
            let mut count = inventoryCounter.count;
            let mut isUpdated = false;
            loop {
                if count == 0 {
                    break;
                }

                let mut inventoryItem = get!(world, (player, count), (CharacterItemInventory));
                if inventoryItem.itemId == 0 {
                    inventoryItem.itemId = itemId;
                    inventoryItem.position = Position { x, y };
                    inventoryItem.rotation = rotation;
                    isUpdated = true;
                    set!(world, (inventoryItem));
                    break;
                }

                count -= 1;
            };

            if isUpdated == false {
                inventoryCounter.count += 1;
                set!(
                    world,
                    (
                        CharacterItemInventory {
                            player,
                            id: inventoryCounter.count,
                            itemId: itemId,
                            position: Position { x, y },
                            rotation,
                        },
                        CharacterItemsInventoryCounter { player, count: inventoryCounter.count },
                    )
                );
            }

            storageItem.itemId = 0;
            set!(world, (storageItem));
        }

        fn undo_place_item(world: IWorldDispatcher, inventory_item_id: u32) {
            let player = get_caller_address();

            let mut inventoryItem = get!(
                world, (player, inventory_item_id), (CharacterItemInventory)
            );
            let itemId = inventoryItem.itemId;
            assert(itemId != 0, 'invalid inventory item id');
            let item = get!(world, itemId, (Item));

            let x = inventoryItem.position.x;
            let y = inventoryItem.position.y;
            let rotation = inventoryItem.rotation;
            let itemHeight = item.height;
            let itemWidth = item.width;

            let playerBackpackGrids = get!(world, (player, x, y), (BackpackGrids));
            if itemHeight == 1 && itemWidth == 1 {
                if item.itemType == 4 {
                    assert(!playerBackpackGrids.occupied, 'Already occupied');
                    set!(
                        world,
                        (BackpackGrids {
                            player: player, x: x, y: y, enabled: false, occupied: false
                        })
                    );
                } else {
                    set!(
                        world,
                        (BackpackGrids {
                            player: player, x: x, y: y, enabled: true, occupied: false
                        })
                    );
                }
            } else {
                let mut xMax = 0;
                let mut yMax = 0;

                // only check grids which are above the starting (x,y)
                if rotation == 0 || rotation == 180 {
                    xMax = x + itemWidth - 1;
                    yMax = y + itemHeight - 1;
                }

                // only check grids which are to the right of the starting (x,y)
                if rotation == 90 || rotation == 270 {
                    //item_h becomes item_w and vice versa
                    xMax = x + itemHeight - 1;
                    yMax = y + itemWidth - 1;
                }

                let mut i = x;
                let mut j = y;
                loop {
                    if i > xMax {
                        break;
                    }
                    loop {
                        if j > yMax {
                            break;
                        }

                        let playerBackpackGrids = get!(world, (player, i, j), (BackpackGrids));
                        if item.itemType == 4 {
                            assert(!playerBackpackGrids.occupied, 'Already occupied');
                            set!(
                                world,
                                (BackpackGrids {
                                    player: player, x: i, y: j, enabled: false, occupied: false
                                })
                            );
                        } else {
                            set!(
                                world,
                                (BackpackGrids {
                                    player: player, x: i, y: j, enabled: true, occupied: false
                                })
                            );
                        }

                        j += 1;
                    };
                    j = y;
                    i += 1;
                }
            }

            let mut storageCounter = get!(world, player, (CharacterItemsStorageCounter));
            let mut count = storageCounter.count;
            let mut isUpdated = false;
            loop {
                if count == 0 {
                    break;
                }

                let mut storageItem = get!(world, (player, count), (CharacterItemStorage));
                if storageItem.itemId == 0 {
                    storageItem.itemId = itemId;
                    isUpdated = true;
                    set!(world, (storageItem));
                    break;
                }

                count -= 1;
            };

            if isUpdated == false {
                storageCounter.count += 1;
                set!(
                    world,
                    (
                        CharacterItemStorage { player, id: storageCounter.count, itemId: itemId, },
                        CharacterItemsStorageCounter { player, count: storageCounter.count },
                    )
                );
            }

            inventoryItem.itemId = 0;
            inventoryItem.position.x = 0;
            inventoryItem.position.y = 0;
            inventoryItem.rotation = 0;
            set!(world, (inventoryItem));
        }

        fn buy_item(world: IWorldDispatcher, item_id: u32) {
            let player = get_caller_address();

            assert(item_id != 0, 'invalid item_id');

            let mut shop_data = get!(world, player, (Shop));
            assert(
                shop_data.item1 == item_id
                    || shop_data.item2 == item_id
                    || shop_data.item3 == item_id
                    || shop_data.item4 == item_id,
                'item not on sale'
            );

            let item = get!(world, item_id, (Item));
            let mut player_char = get!(world, player, (Character));

            assert(player_char.gold >= item.price, 'Not enough gold');
            player_char.gold -= item.price;

            //delete respective item bought from the shop
            if (shop_data.item1 == item_id) {
                shop_data.item1 = 0
            } else if (shop_data.item2 == item_id) {
                shop_data.item2 = 0
            } else if (shop_data.item3 == item_id) {
                shop_data.item3 = 0
            } else if (shop_data.item4 == item_id) {
                shop_data.item4 = 0
            }

            let mut storageCounter = get!(world, player, (CharacterItemsStorageCounter));
            let mut count = storageCounter.count;
            let mut isUpdated = false;
            loop {
                if count == 0 {
                    break;
                }

                let mut storageItem = get!(world, (player, count), (CharacterItemStorage));
                if storageItem.itemId == 0 {
                    storageItem.itemId = item_id;
                    isUpdated = true;
                    set!(world, (storageItem));
                    break;
                }

                count -= 1;
            };

            if isUpdated == false {
                storageCounter.count += 1;
                set!(
                    world,
                    (
                        CharacterItemStorage { player, id: storageCounter.count, itemId: item_id, },
                        CharacterItemsStorageCounter { player, count: storageCounter.count },
                    )
                );
            }

            emit!(
                world,
                (BuyItem {
                    player,
                    itemId: item_id,
                    cost: item.price,
                    itemRarity: item.rarity,
                    birthCount: player_char.birthCount
                })
            );

            set!(world, (player_char, shop_data));
        }


        fn sell_item(world: IWorldDispatcher, storage_item_id: u32) {
            let player = get_caller_address();

            let mut storageItem = get!(world, (player, storage_item_id), (CharacterItemStorage));
            let itemId = storageItem.itemId;
            assert(itemId != 0, 'invalid item_id');

            let mut item = get!(world, itemId, (Item));
            let mut playerChar = get!(world, player, (Character));

            let itemPrice = item.price;
            let sellPrice = itemPrice / 2;

            storageItem.itemId = 0;

            playerChar.gold += sellPrice;

            emit!(
                world,
                (SellItem {
                    player,
                    itemId: itemId,
                    price: sellPrice,
                    itemRarity: item.rarity,
                    birthCount: playerChar.birthCount
                })
            );

            set!(world, (storageItem, playerChar));
        }

        fn reroll_shop(world: IWorldDispatcher) {
            let player = get_caller_address();

            let mut char = get!(world, player, (Character));
            assert(char.gold >= 1, 'Not enough gold');

            let mut shop = get!(world, player, (Shop));

            // TODO: Will move these arrays after Dojo supports storing array
            let mut common: Array<usize> = ArrayTrait::new();
            let mut commonSize: usize = 0;
            let mut uncommon: Array<usize> = ArrayTrait::new();
            let mut uncommonSize: usize = 0;
            let mut rare: Array<usize> = ArrayTrait::new();
            let mut rareSize: usize = 0;

            let itemsCounter = get!(world, ITEMS_COUNTER_ID, ItemsCounter);
            let mut count = itemsCounter.count;

            loop {
                if count == 0 {
                    break;
                }

                let item = get!(world, count, (Item));

                if item.id == 14 || item.id == 18 || item.id == 19 || item.id == 22 {
                    count -= 1;
                    continue;
                }

                let rarity: felt252 = item.rarity.into();
                match rarity {
                    0 => {},
                    1 => {
                        common.append(count);
                        commonSize += 1;
                    },
                    2 => {
                        uncommon.append(count);
                        uncommonSize += 1;
                    },
                    3 => {
                        rare.append(count);
                        rareSize += 1;
                    },
                    _ => {}
                }

                count -= 1;
            };

            assert(commonSize > 0, 'No common items found');

            let (seed1, seed2, seed3, seed4) = pseudo_seed();

            let mut rareFlag = false;
            // common: 70%, uncommon: 30%, rare: 10%
            let mut random_index = 0;
            if char.wins < 3 {
                random_index = random(seed1, 90);
            } else {
                random_index = random(seed1, 100);
            }
            if uncommonSize == 0 {
                random_index = random(seed1, 70);
            } else if rareSize == 0 && uncommonSize > 0 {
                random_index = random(seed1, 90);
            }

            if random_index < 70 {
                // commonSize is always greater than 0
                random_index = random(seed1, commonSize);
                shop.item1 = *common.at(random_index);
            } else if random_index < 90 {
                // uncommonSize is always greater than 0
                random_index = random(seed1, uncommonSize);
                shop.item1 = *uncommon.at(random_index);

                rareFlag = true;
            } else {
                // rareSize is always greater than 0
                random_index = random(seed1, rareSize);
                shop.item1 = *rare.at(random_index);

                rareFlag = true;
            }

            if char.wins < 3 {
                random_index = random(seed2, 90);
            } else {
                random_index = random(seed2, 100);
            }
            if uncommonSize == 0 {
                random_index = random(seed2, 70);
            } else if rareSize == 0 && uncommonSize > 0 {
                random_index = random(seed2, 90);
            }

            if random_index < 70 || rareFlag {
                random_index = random(seed2, commonSize);
                shop.item2 = *common.at(random_index);
            } else if random_index < 90 {
                random_index = random(seed2, uncommonSize);
                shop.item2 = *uncommon.at(random_index);

                rareFlag = true;
            } else {
                random_index = random(seed2, rareSize);
                shop.item2 = *rare.at(random_index);

                rareFlag = true;
            }

            if char.wins < 3 {
                random_index = random(seed3, 90);
            } else {
                random_index = random(seed3, 100);
            }
            if uncommonSize == 0 {
                random_index = random(seed3, 70);
            } else if rareSize == 0 && uncommonSize > 0 {
                random_index = random(seed3, 90);
            }

            if random_index < 70 || rareFlag {
                random_index = random(seed3, commonSize);
                shop.item3 = *common.at(random_index);
            } else if random_index < 90 {
                random_index = random(seed3, uncommonSize);
                shop.item3 = *uncommon.at(random_index);

                rareFlag = true;
            } else {
                random_index = random(seed3, rareSize);
                shop.item3 = *rare.at(random_index);

                rareFlag = true;
            }

            if char.wins < 3 {
                random_index = random(seed4, 90);
            } else {
                random_index = random(seed4, 100);
            }
            if uncommonSize == 0 {
                random_index = random(seed4, 70);
            } else if rareSize == 0 && uncommonSize > 0 {
                random_index = random(seed4, 90);
            }

            if random_index < 70 || rareFlag {
                random_index = random(seed4, commonSize);
                shop.item4 = *common.at(random_index);
            } else if random_index < 90 {
                random_index = random(seed4, uncommonSize);
                shop.item4 = *uncommon.at(random_index);
            } else {
                random_index = random(seed4, rareSize);
                shop.item4 = *rare.at(random_index);
            }

            char.gold -= 1;

            set!(world, (shop, char));
        }


        fn is_world_owner(world: IWorldDispatcher, player: ContractAddress) -> bool {
            // resource id of world is 0
            let is_owner = world.is_owner(player, 0);

            is_owner
        }

        fn is_item_owned(world: IWorldDispatcher, player: ContractAddress, id: usize) -> bool {
            let storageItem = get!(world, (player, id), (CharacterItemStorage));

            if storageItem.itemId == 0 {
                return false;
            }

            true
        }

        fn create_dummy(world: IWorldDispatcher) {
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

        fn rebirth(world: IWorldDispatcher, name: felt252, wmClass: WMClass) {
            let player = get_caller_address();

            let mut char = get!(world, player, (Character));

            assert(char.loss >= 5, 'loss not reached');

            // To allow others to use the player's privous name
            // if char.name != name {
            //     let mut nameRecord = get!(world, char.name, NameRecord);
            //     nameRecord.player = starknet::contract_address_const::<0>();
            //     set!(world, (nameRecord));
            // }

            // required to calling spawn doesn't fail
            char.name = '';

            let mut inventoryItemsCounter = get!(world, player, (CharacterItemsInventoryCounter));
            let mut count = inventoryItemsCounter.count;

            loop {
                if count == 0 {
                    break;
                }

                let mut inventoryItem = get!(world, (player, count), (CharacterItemInventory));

                inventoryItem.itemId = 0;
                inventoryItem.position.x = 0;
                inventoryItem.position.y = 0;
                inventoryItem.rotation = 0;

                set!(world, (inventoryItem));

                count -= 1;
            };

            let mut storageItemsCounter = get!(world, player, (CharacterItemsStorageCounter));
            let mut count = storageItemsCounter.count;

            loop {
                if count == 0 {
                    break;
                }

                let mut storageItem = get!(world, (player, count), (CharacterItemStorage));

                storageItem.itemId = 0;

                set!(world, (storageItem));

                count -= 1;
            };

            // clear BackpackGrids
            let mut i = 0;
            let mut j = 0;
            loop {
                if i >= GRID_X {
                    break;
                }
                loop {
                    if j >= GRID_Y {
                        break;
                    }

                    let player_backpack_grid_data = get!(world, (player, i, j), (BackpackGrids));

                    if player_backpack_grid_data.occupied || player_backpack_grid_data.enabled {
                        set!(
                            world,
                            (BackpackGrids {
                                player: player, x: i, y: j, enabled: false, occupied: false
                            })
                        );
                    }
                    j += 1;
                };
                j = 0;
                i += 1;
            };

            // clear shop
            let mut shop = get!(world, player, (Shop));
            shop.item1 = 0;
            shop.item2 = 0;
            shop.item3 = 0;
            shop.item4 = 0;

            inventoryItemsCounter.count = 0;
            storageItemsCounter.count = 0;
            set!(world, (char, shop, inventoryItemsCounter, storageItemsCounter));

            self.spawn(name, wmClass);
        }

        fn prefine_dummy(world: IWorldDispatcher, level: usize) {
            let player = get_caller_address();
            assert(self.is_world_owner(player), 'player not world owner');

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
                11 => {
                    name = Dummy11::name;
                    wmClassNo = Dummy11::wmClass;
                    health = Dummy11::health;
                    items = Dummy11::get_items();
                },
                12 => {
                    name = Dummy12::name;
                    wmClassNo = Dummy12::wmClass;
                    health = Dummy12::health;
                    items = Dummy12::get_items();
                },
                13 => {
                    name = Dummy13::name;
                    wmClassNo = Dummy13::wmClass;
                    health = Dummy13::health;
                    items = Dummy13::get_items();
                },
                14 => {
                    name = Dummy14::name;
                    wmClassNo = Dummy14::wmClass;
                    health = Dummy14::health;
                    items = Dummy14::get_items();
                },
                15 => {
                    name = Dummy15::name;
                    wmClassNo = Dummy15::wmClass;
                    health = Dummy15::health;
                    items = Dummy15::get_items();
                },
                16 => {
                    name = Dummy16::name;
                    wmClassNo = Dummy16::wmClass;
                    health = Dummy16::health;
                    items = Dummy16::get_items();
                },
                17 => {
                    name = Dummy17::name;
                    wmClassNo = Dummy17::wmClass;
                    health = Dummy17::health;
                    items = Dummy17::get_items();
                },
                18 => {
                    name = Dummy18::name;
                    wmClassNo = Dummy18::wmClass;
                    health = Dummy18::health;
                    items = Dummy18::get_items();
                },
                19 => {
                    name = Dummy19::name;
                    wmClassNo = Dummy19::wmClass;
                    health = Dummy19::health;
                    items = Dummy19::get_items();
                },
                20 => {
                    name = Dummy20::name;
                    wmClassNo = Dummy20::wmClass;
                    health = Dummy20::health;
                    items = Dummy20::get_items();
                },
                _ => {
                    assert(false, 'invalid level');
                },
            }

            match wmClassNo {
                0 => {
                    wmClass = WMClass::Warrior;
                },
                1 => {
                    wmClass = WMClass::Warlock;
                },
                2 => {
                    wmClass = WMClass::Archer;
                },
                _ => {
                    assert(false, 'invalid wmClass');
                }
            }

            let nameRecord = get!(world, name, NameRecord);
            assert(
                nameRecord.player == starknet::contract_address_const::<0>(),
                'name already exists'
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

            set!(world, (dummyCharCounter, dummyChar, dummyCharItemsCounter, NameRecord { name, player }));
        }

        fn update_prefine_dummy(world: IWorldDispatcher, level: usize, dummyCharId: usize) {
            let player = get_caller_address();
            assert(self.is_world_owner(player), 'player not world owner');
    
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
                _ => {
                    assert(false, 'invalid level');
                }
            }
    
            match wmClassNo {
                0 => {
                    wmClass = WMClass::Warrior;
                },
                1 => {
                    wmClass = WMClass::Warlock;
                },
                2 => {
                    wmClass = WMClass::Archer;
                },
                _ => {
                    assert(false, 'invalid wmClass');
                }
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
