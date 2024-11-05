#[starknet::interface]
trait IItem<T> {
    fn add_item(
        ref self: T,
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
            ref self: ContractState,
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
            // TODO: effectStacks can't be 0
            // TODO: Cooldown can't be 0 when effectActivationType is cooldown
            // TODO: The possible value of effectActivationType is 0, 1, 2, 3, 4
            // TODO: The possible value of effectType is 1, 2, 3, 4, 5, 6, 7, 8, 9
            // TODO: The possible value of itemType is 1, 2, 3, 4

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
