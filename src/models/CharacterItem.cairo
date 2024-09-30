use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Introspect)]
struct Position {
    x: usize,
    y: usize
}

#[derive(Drop, Serde)]
#[dojo::model]
struct CharacterItemStorage {
    #[key]
    player: ContractAddress,
    #[key]
    id: usize,
    itemId: usize,
}

#[derive(Drop, Serde)]
#[dojo::model]
struct CharacterItemsStorageCounter {
    #[key]
    player: ContractAddress,
    count: usize,
}

#[derive(Drop, Serde)]
#[dojo::model]
struct CharacterItemInventory {
    #[key]
    player: ContractAddress,
    #[key]
    id: usize,
    itemId: usize,
    position: Position,
    // 0, 90, 180, 270
    rotation: usize,
    // effectType, chance, stacks
    plugins: Array<(u8, usize, usize)>,
}

#[derive(Drop, Serde)]
#[dojo::model]
struct CharacterItemsInventoryCounter {
    #[key]
    player: ContractAddress,
    count: usize,
}

pub fn are_items_nearby(pos1: Position, width1: usize, height1: usize, rotation1: usize, pos2: Position, width2: usize, height2: usize, rotation2: usize) -> bool {
    // Calculate item dimensions considering rotation
    let (final_width1, final_height1) = if rotation1 == 90 || rotation1 == 270 {
        (height1, width1)
    } else {
        (width1, height1)
    };

    let (final_width2, final_height2) = if rotation2 == 90 || rotation2 == 270 {
        (height2, width2)
    } else {
        (width2, height2)
    };

    // Define the boundaries of the first item
    let x1_min = pos1.x;
    let x1_max = pos1.x + final_width1 - 1;
    let y1_min = pos1.y;
    let y1_max = pos1.y + final_height1 - 1;

    // Define the boundaries of the second item
    let x2_min = pos2.x;
    let x2_max = pos2.x + final_width2 - 1;
    let y2_min = pos2.y;
    let y2_max = pos2.y + final_height2 - 1;

    // Check if the items are adjacent horizontally or vertically
    let horizontally_adjacent = (x1_max + 1 == x2_min || x2_max + 1 == x1_min) && (y1_min <= y2_max && y1_max >= y2_min);
    let vertically_adjacent = (y1_max + 1 == y2_min || y2_max + 1 == y1_min) && (x1_min <= x2_max && x1_max >= x2_min);

    horizontally_adjacent || vertically_adjacent
}

// #[cfg(test)]
// mod tests {
//     use super::*;

//     #[test]
//     fn test_items_adjacent_horizontally() {
//         let pos1 = Position { x: 0, y: 0 };
//         let pos2 = Position { x: 2, y: 0 };
//         assert!(are_items_nearby(pos1, 2, 2, 0, pos2, 2, 2, 0));
//     }
// }