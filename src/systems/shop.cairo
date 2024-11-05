use starknet::ContractAddress;

#[starknet::interface]
trait IShop<T> {
    fn buy_item(ref self: T, item_id: u32);
    fn sell_item(ref self: T, storage_item_id: u32);
    fn reroll_shop(ref self: T,);
}

#[dojo::contract]
mod shop_system {
    use super::{IShop, ContractAddress};

    use starknet::{get_caller_address};
    use warpack_masters::models::{
        CharacterItem::{CharacterItemsStorageCounter, CharacterItemStorage,},
        Item::{Item, ItemsCounter}
    };
    use warpack_masters::models::Character::{Characters};
    use warpack_masters::models::Shop::Shop;
    use warpack_masters::utils::random::{pseudo_seed, random};
    use warpack_masters::constants::constants::{ITEMS_COUNTER_ID};


    #[derive(Copy, Drop, Serde)]
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

    #[derive(Copy, Drop, Serde)]
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
        fn buy_item(ref self: ContractState, item_id: u32) {
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
            let mut player_char = get!(world, player, (Characters));

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


        fn sell_item(ref self: ContractState, storage_item_id: u32) {
            let player = get_caller_address();

            let mut storageItem = get!(world, (player, storage_item_id), (CharacterItemStorage));
            let itemId = storageItem.itemId;
            assert(itemId != 0, 'invalid item_id');

            let mut item = get!(world, itemId, (Item));
            let mut playerChar = get!(world, player, (Characters));

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

        fn reroll_shop(ref self: ContractState) {
            let player = get_caller_address();

            let mut char = get!(world, player, (Characters));
            assert(char.gold >= 1, 'Not enough gold');

            // TODO: Will move these arrays after Dojo supports storing array
            let mut common: Array<usize> = ArrayTrait::new();
            let mut rare: Array<usize> = ArrayTrait::new();
            let mut legendary: Array<usize> = ArrayTrait::new();

            let itemsCounter = get!(world, ITEMS_COUNTER_ID, ItemsCounter);
            let mut count = itemsCounter.count;

            loop {
                if count == 0 {
                    break;
                }

                let item = get!(world, count, (Item));

                // skip some without images
                // if item.id == 14 || item.id == 18 || item.id == 19 || item.id == 22 {
                //     count -= 1;
                //     continue;
                // }

                match item.rarity {
                    0 => {},
                    1 => {
                        common.append(count);
                    },
                    2 => {
                        rare.append(count);
                    },
                    3 => {
                        legendary.append(count);
                    },
                    _ => {},
                }

                count -= 1;
            };

            assert(common.len() > 0, 'No common items found');

            let mut shop = get!(world, player, (Shop));

            let (seed1, seed2, seed3, seed4) = pseudo_seed();

            // common: 70%, rare: 20%, legendary: 10%
            let mut i = 0;
            for seed in array![seed1, seed2, seed3, seed4] {
                let mut random_index = 0;

                if char.wins < 3 {
                    random_index = random(seed, 90);
                } else {
                    random_index = random(seed, 100);
                }
    
                let itemId = if random_index < 70 {
                    random_index = random(seed, common.len());
                    *common.at(random_index)
                } else if random_index < 90 {
                    random_index = random(seed, rare.len());
                    *rare.at(random_index)
                } else {
                    random_index = random(seed, legendary.len());
                    *legendary.at(random_index)
                };

                match i {
                    0 => shop.item1 = itemId,
                    1 => shop.item2 = itemId,
                    2 => shop.item3 = itemId,
                    3 => shop.item4 = itemId,
                    _ => {},
                }

                i += 1;
            };

            char.gold -= 1;

            set!(world, (shop, char));
        }
    }
}
