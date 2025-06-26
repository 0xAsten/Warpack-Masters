use starknet::ContractAddress;

#[starknet::interface]
pub trait IShop<T> {
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

    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;


    #[derive(Copy, Drop, Serde)]
    #[dojo::event(historical: true)]
    struct BuyItem {
        #[key]
        player: ContractAddress,
        itemId: u32,
        cost: u32,
        itemRarity: u8,
        birthCount: u32,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event(historical: true)]
    struct SellItem {
        #[key]
        player: ContractAddress,
        itemId: u32,
        price: u32,
        itemRarity: u8,
        birthCount: u32,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event(historical: true)]
    struct ShopRerolled {
        #[key]
        player: ContractAddress,
        cost_paid: u32,
        reroll_count: u32,
        used_free_reroll: bool,
    }

    #[abi(embed_v0)]
    impl ShopImpl of IShop<ContractState> {
        fn buy_item(ref self: ContractState, item_id: u32) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            assert(item_id != 0, 'invalid item_id');

            let mut shop_data: Shop = world.read_model(player);
            assert(
                shop_data.item1 == item_id
                    || shop_data.item2 == item_id
                    || shop_data.item3 == item_id
                    || shop_data.item4 == item_id,
                'item not on sale'
            );

            let item: Item = world.read_model(item_id);
            let mut player_char: Characters = world.read_model(player);

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

            let mut storageCounter: CharacterItemsStorageCounter = world.read_model(player);
            let mut count = storageCounter.count;
            let mut isUpdated = false;
            loop {
                if count == 0 {
                    break;
                }

                let mut storageItem: CharacterItemStorage = world.read_model((player, count));
                if storageItem.itemId == 0 {
                    storageItem.itemId = item_id;
                    isUpdated = true;
                    world.write_model(@storageItem);
                    break;
                }

                count -= 1;
            };

            if isUpdated == false {
                storageCounter.count += 1;
                world.write_model(@CharacterItemStorage { player, id: storageCounter.count, itemId: item_id, });
                world.write_model(@CharacterItemsStorageCounter { player, count: storageCounter.count });
            }

            world.emit_event(@BuyItem {
                player,
                itemId: item_id,
                cost: item.price,
                itemRarity: item.rarity,
                birthCount: player_char.birthCount
            });

            world.write_model(@player_char);
            world.write_model(@shop_data);
        }


        fn sell_item(ref self: ContractState, storage_item_id: u32) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            let mut storageItem: CharacterItemStorage = world.read_model((player, storage_item_id));
            let itemId = storageItem.itemId;
            assert(itemId != 0, 'invalid item_id');

            let mut item: Item = world.read_model(itemId);
            let mut playerChar: Characters = world.read_model(player);

            let itemPrice = item.price;
            let sellPrice = itemPrice / 2;

            storageItem.itemId = 0;

            playerChar.gold += sellPrice;

            world.emit_event(@SellItem {
                player,
                itemId: itemId,
                price: sellPrice,
                itemRarity: item.rarity,
                birthCount: playerChar.birthCount
            });

            world.write_model(@storageItem);
            world.write_model(@playerChar);
        }

        fn reroll_shop(ref self: ContractState) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            let mut char: Characters = world.read_model(player);
            let mut shop: Shop = world.read_model(player);
            
            // Determine reroll cost based on rerolls since last fight
            let reroll_cost = if shop.rerolls_since_fight < 2 {
                1  // First 2 rerolls cost 1 gold
            } else {
                2  // 3rd+ rerolls cost 2 gold
            };
            
            // Check if player has free rerolls or enough gold
            let used_free_reroll = if shop.free_rerolls > 0 {
                shop.free_rerolls -= 1;
                true
            } else {
                assert(char.gold >= reroll_cost, 'Not enough gold');
                char.gold -= reroll_cost;
                false
            };
            
            // Increment reroll counter
            shop.rerolls_since_fight += 1;

            let (item1, item2, item3, item4) = generate_shop_items(ref world, player, char.wins);

            shop.item1 = item1;
            shop.item2 = item2;
            shop.item3 = item3;
            shop.item4 = item4;

            // Emit reroll event
            world.emit_event(@ShopRerolled {
                player,
                cost_paid: if used_free_reroll { 0 } else { reroll_cost },
                reroll_count: shop.rerolls_since_fight,
                used_free_reroll,
            });

            world.write_model(@shop);
            world.write_model(@char);
        }
    }

    fn generate_shop_items(ref world: WorldStorage, player: ContractAddress, wins: u32) -> (u32, u32, u32, u32) {
        // TODO: Will move these arrays after Dojo supports storing array
        let mut common: Array<u32> = ArrayTrait::new();
        let mut rare: Array<u32> = ArrayTrait::new();
        let mut legendary: Array<u32> = ArrayTrait::new();

        let itemsCounter: ItemsCounter = world.read_model(ITEMS_COUNTER_ID);
        let mut count = itemsCounter.count;

        loop {
            if count == 0 {
                break;
            }

            let item: Item = world.read_model(count);

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

        let (seed1, seed2, seed3, seed4) = pseudo_seed();

        let mut items: Array<u32> = ArrayTrait::new();

        // common: 70%, rare: 20%, legendary: 10%
        for seed in array![seed1, seed2, seed3, seed4] {
            let mut random_index = 0;

            if wins < 3 {
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

            items.append(itemId);
        };

        (*items.at(0), *items.at(1), *items.at(2), *items.at(3))
    }
}
