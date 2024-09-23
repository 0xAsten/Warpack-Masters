#[dojo::interface]
trait IItem {
    fn add_item(
        ref world: IWorldDispatcher,
        id: u32,
        name: felt252,
        itemType: u8,
        rarity: u8,
        width: usize,
        height: usize,
        price: usize,
        effectType: u8,
        effectStacks: u32,
        effectActivationType: u8,
        chance: usize,
        cooldown: u8,
        energyCost: u8,
        isPlugin: bool,
    );
}

#[dojo::contract]
mod item_system {
    use super::IItem;

    use starknet::{get_caller_address};
    use warpack_masters::models::{Item::{Item, ItemsCounter}};

    use warpack_masters::constants::constants::{GRID_X, GRID_Y, ITEMS_COUNTER_ID};

    use warpack_masters::systems::view::view::ViewImpl;

    #[abi(embed_v0)]
    impl ItemImpl of IItem<ContractState> {
        fn add_item(
            ref world: IWorldDispatcher,
            id: u32,
            name: felt252,
            itemType: u8,
            rarity: u8,
            width: usize,
            height: usize,
            price: usize,
            effectType: u8,
            effectStacks: u32,
            effectActivationType: u8,
            chance: usize,
            cooldown: u8,
            energyCost: u8,
            isPlugin: bool,
        ) {
            let player = get_caller_address();

            assert(ViewImpl::is_world_owner(world, player), 'player not world owner');

            assert(width > 0 && width <= GRID_X, 'width not in range');
            assert(height > 0 && height <= GRID_Y, 'height not in range');

            assert(price > 0, 'price must be greater than 0');

            assert(
                rarity == 1 || rarity == 2 || rarity == 3 || (rarity == 0 && itemType == 4),
                'rarity not valid'
            );

            assert(
                cooldown == 0 || cooldown == 4 || cooldown == 5 || cooldown == 6 || cooldown == 7,
                'cooldown not valid'
            );

            let counter = get!(world, ITEMS_COUNTER_ID, ItemsCounter);
            if id > counter.count {
                set!(world, ItemsCounter { id: ITEMS_COUNTER_ID, count: id });
            }

            let item = Item {
                id,
                name,
                itemType,
                rarity,
                width,
                height,
                price,
                effectType,
                effectStacks,
                effectActivationType,
                chance,
                cooldown,
                energyCost,
                isPlugin,
            };

            set!(world, (item));
        }
    }
}
