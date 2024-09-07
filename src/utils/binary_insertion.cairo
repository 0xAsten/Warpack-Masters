fn binary_insertion_sort(
    items: Felt252Dict<u32>,
    item_belongs: Felt252Dict<felt252>,
    items_indexs: Array<u32>,
    item_id: u32,
    belongs_to: felt252,
    world: IWorldDispatcher,
    items_length: usize,
) -> usize {
    let mut low: usize = 0;
    let mut high: usize = items_length;
    let item_data = get!(world, item_id, Item);

    while low < high {
        let mid = (low + high) / 2;
        let mid_item_index = *items_indexs.at(mid);
        let mid_item_id = *items.get(mid_item_index.into());

        let mid_item_data = get!(world, mid_item_id, Item);

        if item_data.cooldown < mid_item_data.cooldown
            || (item_data.cooldown == mid_item_data.cooldown
                && item_data.energyCost < mid_item_data.energyCost)
        {
            high = mid;
        } else {
            low = mid + 1;
        }
    }

    // Insert item into the sorted position
    let mut i = low;
    while i < items_length {
        let next = i + 1;
        let current_item = items.get(i.into());
        let current_belongs = item_belongs.get(i.into());
        items.insert(next.into(), current_item);
        item_belongs.insert(next.into(), current_belongs);
        i = next;
    }

    items.insert(low.into(), item_id);
    item_belongs.insert(low.into(), belongs_to);

    items_length + 1
}