use warpack_masters::models::CharacterItem::Position;

#[derive(Copy, Drop, Serde)]
struct PredefinedItem {
    itemId: usize,
    position: Position,
    // rotation: 0, 90, 180, 270
    rotation: usize,
}

mod Dummy0 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack1, Backpack2};

    const name: felt252 = 'Dummy0';
    const wmClass: u8 = 0;
    const health: usize = 100;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack1::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Backpack2::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items
    }
}

mod Dummy1 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack1, Backpack2};

    const name: felt252 = 'Dummy1';
    const wmClass: u8 = 1;
    const health: usize = 100;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack1::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Backpack2::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items
    }
}
