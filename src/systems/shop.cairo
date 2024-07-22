use starknet::ContractAddress;

#[dojo::interface]
trait IShop {
    fn buy_item(ref world: IWorldDispatcher, item_id: u32);
    fn sell_item(ref world: IWorldDispatcher, storage_item_id: u32);
    fn reroll_shop(ref world: IWorldDispatcher,);
}

#[dojo::contract]
mod shop {
    use super::{IShop, ContractAddress};

    use starknet::{get_caller_address};
    use warpack_masters::models::{
        CharacterItem::{CharacterItemsStorageCounter, CharacterItemStorage,},
        Item::{Item, ItemsCounter}
    };
    use warpack_masters::models::Character::{Character};
    use warpack_masters::models::Shop::Shop;
    use warpack_masters::utils::random::{pseudo_seed, random};
    use warpack_masters::constants::constants::{ITEMS_COUNTER_ID};


    #[derive(Model, Copy, Drop, Serde)]
    #[dojo::event]
    #[dojo::model]
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
    #[dojo::model]
    struct SellItem {
        #[key]
        player: ContractAddress,
        itemId: usize,
        price: usize,
        itemRarity: u8,
        birthCount: u32,
    }

    #[abi(embed_v0)]
    impl ShopImpl of IShop<ContractState> {
        fn buy_item(ref world: IWorldDispatcher, item_id: u32) {
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


        fn sell_item(ref world: IWorldDispatcher, storage_item_id: u32) {
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

        fn reroll_shop(ref world: IWorldDispatcher) {
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
    }
}
