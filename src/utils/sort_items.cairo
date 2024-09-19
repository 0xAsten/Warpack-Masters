
fn append_item(
    ref items_cooldown4: Array<(u32, felt252)>,
    ref items_cooldown5: Array<(u32, felt252)>,
    ref items_cooldown6: Array<(u32, felt252)>,
    ref items_cooldown7: Array<(u32, felt252)>,
    item_id: u32,
    belongs_to: felt252,
    cooldown: u8,
    items_length: usize,
) -> usize {
    match cooldown {
        0 | 1 | 2 | 3 => {
            assert(false, 'cooldown not valid');
        },
        4 => {
            items_cooldown4.append((item_id, belongs_to));
        },
        5 => {
            items_cooldown5.append((item_id, belongs_to));
        },
        6 => {
            items_cooldown6.append((item_id, belongs_to));
        },
        7 => {
            items_cooldown7.append((item_id, belongs_to));
        },
        _ => {
            assert(false, 'cooldown not valid');
        },
    }

    items_length + 1
}

fn combine_items(
    ref items_cooldown4: Array<(u32, felt252)>,
    ref items_cooldown5: Array<(u32, felt252)>,
    ref items_cooldown6: Array<(u32, felt252)>,
    ref items_cooldown7: Array<(u32, felt252)>,
) -> (Array<u32>, Array<felt252>) {
    let mut item_ids = ArrayTrait::new();
    let mut belongs_tos = ArrayTrait::new();

    for item in items_cooldown4.span() {
        let (item_id, belongs_to) = *item;
        item_ids.append(item_id);
        belongs_tos.append(belongs_to);
    };

    for item in items_cooldown5.span() {
        let (item_id, belongs_to) = *item;
        item_ids.append(item_id);
        belongs_tos.append(belongs_to);
    };

    for item in items_cooldown6.span() {
        let (item_id, belongs_to) = *item;
        item_ids.append(item_id);
        belongs_tos.append(belongs_to);
    };

    for item in items_cooldown7.span() {
        let (item_id, belongs_to) = *item;
        item_ids.append(item_id);
        belongs_tos.append(belongs_to);
    };

    (item_ids, belongs_tos)
}

#[cfg(test)]
mod tests {
    use super::{append_item, combine_items};
    use debug::PrintTrait;

    use warpack_masters::models::Character::{PLAYER, DUMMY};

    #[test]
    #[available_gas(100000)]
    fn test_append_item() {
        let mut items_cooldown4 = ArrayTrait::new();
        let mut items_cooldown5 = ArrayTrait::new();
        let mut items_cooldown6 = ArrayTrait::new();
        let mut items_cooldown7 = ArrayTrait::new();

        let mut items_length = append_item(ref items_cooldown4, ref items_cooldown5, ref items_cooldown6, ref items_cooldown7, 1, PLAYER, 4, 0);
        assert(items_length == 1, 'items_length not 1');
        assert(items_cooldown4.len() == 1, 'items_cooldown4 length not 1');
        assert(items_cooldown5.len() == 0, 'items_cooldown5 length not 0');
        assert(items_cooldown6.len() == 0, 'items_cooldown6 length not 0');

        let (item_id, belongs_to) = *items_cooldown4.at(0);
        assert(item_id == 1, 'item_id not 1');
        assert(belongs_to == PLAYER, 'belongs_to not PLAYER');

        items_length = append_item(ref items_cooldown4, ref items_cooldown5, ref items_cooldown6, ref items_cooldown7, 2, DUMMY, 5, items_length);
        assert(items_length == 2, 'items_length not 2');
        assert(items_cooldown4.len() == 1, 'items_cooldown4 length not 1');
        assert(items_cooldown5.len() == 1, 'items_cooldown5 length not 1');
        assert(items_cooldown6.len() == 0, 'items_cooldown6 length not 0');

        let (item_id, belongs_to) = *items_cooldown5.at(0);
        assert(item_id == 2, 'item_id not 2');
        assert(belongs_to == DUMMY, 'belongs_to not DUMMY');

        items_length = append_item(ref items_cooldown4, ref items_cooldown5, ref items_cooldown6, ref items_cooldown7, 1, DUMMY, 4, items_length);
        assert(items_length == 3, 'items_length not 3');
        assert(items_cooldown4.len() == 2, 'items_cooldown4 length not 2');
        assert(items_cooldown5.len() == 1, 'items_cooldown5 length not 1');
        assert(items_cooldown6.len() == 0, 'items_cooldown6 length not 0');

        let (item_id, belongs_to) = *items_cooldown4.at(0);
        assert(item_id == 1, 'item_id not 1');
        assert(belongs_to == PLAYER, 'belongs_to not PLAYER');

        let (item_id, belongs_to) = *items_cooldown4.at(1);
        assert(item_id == 1, 'item_id not 1');
        assert(belongs_to == DUMMY, 'belongs_to not DUMMY');
    }

    #[test]
    #[available_gas(100000)]
    #[should_panic(expected: 'cooldown not valid')]
    fn test_append_not_valid_cooldown_item() { 
        let mut items_cooldown4 = ArrayTrait::new();
        let mut items_cooldown5 = ArrayTrait::new();
        let mut items_cooldown6 = ArrayTrait::new();
        let mut items_cooldown7 = ArrayTrait::new();

        append_item(ref items_cooldown4, ref items_cooldown5, ref items_cooldown6, ref items_cooldown7, 1, PLAYER, 1, 0);
    }

    #[test]
    #[available_gas(100000)]
    fn test_combine_items() {
        let mut items_cooldown4 = ArrayTrait::new();
        let mut items_cooldown5 = ArrayTrait::new();
        let mut items_cooldown6 = ArrayTrait::new();
        let mut items_cooldown7 = ArrayTrait::new();

        append_item(ref items_cooldown4, ref items_cooldown5, ref items_cooldown6, ref items_cooldown7, 1, PLAYER, 4, 0);
        append_item(ref items_cooldown4, ref items_cooldown5, ref items_cooldown6, ref items_cooldown7, 2, DUMMY, 5, 1);
        append_item(ref items_cooldown4, ref items_cooldown5, ref items_cooldown6, ref items_cooldown7, 1, DUMMY, 4, 2);

        let (item_ids, belongs_tos) = combine_items(ref items_cooldown4, ref items_cooldown5, ref items_cooldown6, ref items_cooldown7);
        assert(item_ids.len() == 3, 'item_ids length not 3');
        assert(belongs_tos.len() == 3, 'belongs_tos length not 3');

        let item_id = *item_ids.at(0);
        let belongs_to = *belongs_tos.at(0);
        assert(item_id == 1, 'item_id not 1');
        assert(belongs_to == PLAYER, 'belongs_to not PLAYER');

        let item_id = *item_ids.at(1);
        let belongs_to = *belongs_tos.at(1);
        assert(item_id == 1, 'item_id not 1');
        assert(belongs_to == DUMMY, 'belongs_to not DUMMY');

        let item_id = *item_ids.at(2);
        let belongs_to = *belongs_tos.at(2);
        assert(item_id == 2, 'item_id not 2');
        assert(belongs_to == DUMMY, 'belongs_to not DUMMY');
    }
}
