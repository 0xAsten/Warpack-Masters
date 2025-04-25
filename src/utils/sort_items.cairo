use warpack_masters::models::Item::Item;

pub fn append_item(
    ref items_cooldown: Array<(felt252, u32, u8, u8, u32, u32, u8, u8, Span<(u8, u32, u32)>)>,
    plugins: Span<(u8, u32, u32)>,
    item : @Item,
    belongs_to: felt252,
) {
    items_cooldown.append(
        (belongs_to, *item.id, *item.itemType, *item.effectType, *item.chance, *item.effectStacks, *item.cooldown, *item.energyCost, plugins)
    );
}

pub fn order_items(
    ref items_cooldown4: Array<(felt252, u32, u8, u8, u32, u32, u8, u8, Span<(u8, u32, u32)>)>,
    ref items_cooldown5: Array<(felt252, u32, u8, u8, u32, u32, u8, u8, Span<(u8, u32, u32)>)>,
    ref items_cooldown6: Array<(felt252, u32, u8, u8, u32, u32, u8, u8, Span<(u8, u32, u32)>)>,
    ref items_cooldown7: Array<(felt252, u32, u8, u8, u32, u32, u8, u8, Span<(u8, u32, u32)>)>,
) -> Array<(felt252, u32, u8, u8, u32, u32, u8, u8, Span<(u8, u32, u32)>)> {
    let mut sorted_items = ArrayTrait::new();

    for item in items_cooldown4.span() {
        sorted_items.append(*item);
    };

    for item in items_cooldown5.span() {
        sorted_items.append(*item);
    };

    for item in items_cooldown6.span() {
        sorted_items.append(*item);
    };

    for item in items_cooldown7.span() {
        sorted_items.append(*item);
    };

    sorted_items
}

// #[cfg(test)]
// mod tests {
//     use super::{append_item, combine_items};
//     use debug::PrintTrait;

//     use warpack_masters::models::Character::{PLAYER, DUMMY};

//     #[test]
//     #[available_gas(100000)]
//     fn test_append_item() {
//         let mut items_cooldown4 = ArrayTrait::new();
//         let mut items_cooldown5 = ArrayTrait::new();
//         let mut items_cooldown6 = ArrayTrait::new();
//         let mut items_cooldown7 = ArrayTrait::new();

//         let mut items_length = append_item(ref items_cooldown4, ref items_cooldown5, ref items_cooldown6, ref items_cooldown7, 1, PLAYER, 4, 0);
//         assert(items_length == 1, 'items_length not 1');
//         assert(items_cooldown4.len() == 1, 'items_cooldown4 length not 1');
//         assert(items_cooldown5.len() == 0, 'items_cooldown5 length not 0');
//         assert(items_cooldown6.len() == 0, 'items_cooldown6 length not 0');

//         let (item_id, belongs_to) = *items_cooldown4.at(0);
//         assert(item_id == 1, 'item_id not 1');
//         assert(belongs_to == PLAYER, 'belongs_to not PLAYER');

//         items_length = append_item(ref items_cooldown4, ref items_cooldown5, ref items_cooldown6, ref items_cooldown7, 2, DUMMY, 5, items_length);
//         assert(items_length == 2, 'items_length not 2');
//         assert(items_cooldown4.len() == 1, 'items_cooldown4 length not 1');
//         assert(items_cooldown5.len() == 1, 'items_cooldown5 length not 1');
//         assert(items_cooldown6.len() == 0, 'items_cooldown6 length not 0');

//         let (item_id, belongs_to) = *items_cooldown5.at(0);
//         assert(item_id == 2, 'item_id not 2');
//         assert(belongs_to == DUMMY, 'belongs_to not DUMMY');

//         items_length = append_item(ref items_cooldown4, ref items_cooldown5, ref items_cooldown6, ref items_cooldown7, 1, DUMMY, 4, items_length);
//         assert(items_length == 3, 'items_length not 3');
//         assert(items_cooldown4.len() == 2, 'items_cooldown4 length not 2');
//         assert(items_cooldown5.len() == 1, 'items_cooldown5 length not 1');
//         assert(items_cooldown6.len() == 0, 'items_cooldown6 length not 0');

//         let (item_id, belongs_to) = *items_cooldown4.at(0);
//         assert(item_id == 1, 'item_id not 1');
//         assert(belongs_to == PLAYER, 'belongs_to not PLAYER');

//         let (item_id, belongs_to) = *items_cooldown4.at(1);
//         assert(item_id == 1, 'item_id not 1');
//         assert(belongs_to == DUMMY, 'belongs_to not DUMMY');
//     }

//     #[test]
//     #[available_gas(100000)]
//     #[should_panic(expected: 'cooldown not valid')]
//     fn test_append_not_valid_cooldown_item() { 
//         let mut items_cooldown4 = ArrayTrait::new();
//         let mut items_cooldown5 = ArrayTrait::new();
//         let mut items_cooldown6 = ArrayTrait::new();
//         let mut items_cooldown7 = ArrayTrait::new();

//         append_item(ref items_cooldown4, ref items_cooldown5, ref items_cooldown6, ref items_cooldown7, 1, PLAYER, 1, 0);
//     }

//     #[test]
//     #[available_gas(100000)]
//     fn test_combine_items() {
//         let mut items_cooldown4 = ArrayTrait::new();
//         let mut items_cooldown5 = ArrayTrait::new();
//         let mut items_cooldown6 = ArrayTrait::new();
//         let mut items_cooldown7 = ArrayTrait::new();

//         append_item(ref items_cooldown4, ref items_cooldown5, ref items_cooldown6, ref items_cooldown7, 1, PLAYER, 4, 0);
//         append_item(ref items_cooldown4, ref items_cooldown5, ref items_cooldown6, ref items_cooldown7, 2, DUMMY, 5, 1);
//         append_item(ref items_cooldown4, ref items_cooldown5, ref items_cooldown6, ref items_cooldown7, 1, DUMMY, 4, 2);

//         let (item_ids, belongs_tos) = combine_items(ref items_cooldown4, ref items_cooldown5, ref items_cooldown6, ref items_cooldown7);
//         assert(item_ids.len() == 3, 'item_ids length not 3');
//         assert(belongs_tos.len() == 3, 'belongs_tos length not 3');

//         let item_id = *item_ids.at(0);
//         let belongs_to = *belongs_tos.at(0);
//         assert(item_id == 1, 'item_id not 1');
//         assert(belongs_to == PLAYER, 'belongs_to not PLAYER');

//         let item_id = *item_ids.at(1);
//         let belongs_to = *belongs_tos.at(1);
//         assert(item_id == 1, 'item_id not 1');
//         assert(belongs_to == DUMMY, 'belongs_to not DUMMY');

//         let item_id = *item_ids.at(2);
//         let belongs_to = *belongs_tos.at(2);
//         assert(item_id == 2, 'item_id not 2');
//         assert(belongs_to == DUMMY, 'belongs_to not DUMMY');
//     }
// }
