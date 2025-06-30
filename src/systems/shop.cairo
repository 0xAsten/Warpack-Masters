#[starknet::interface]
pub trait IShop<T> {
    fn reroll_shop(ref self: T,);
}

#[dojo::contract]
mod shop_system {
    use super::{IShop};

    use starknet::{get_caller_address};
    use warpack_masters::models::{
        Item::{Item, ItemsCounter}
    };
    use warpack_masters::models::Character::{Characters};
    use warpack_masters::models::Shop::Shop;
    use warpack_masters::utils::random::{pseudo_seed, random};
    use warpack_masters::constants::constants::{ITEMS_COUNTER_ID};

    use dojo::model::{ModelStorage};

    #[abi(embed_v0)]
    impl ShopImpl of IShop<ContractState> {
        fn reroll_shop(ref self: ContractState) {
            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            let mut char: Characters = world.read_model(player);
            assert(char.gold >= 1, 'Not enough gold');

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

            let mut shop: Shop = world.read_model(player);

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

            world.write_model(@shop);
            world.write_model(@char);
        }
    }
}
