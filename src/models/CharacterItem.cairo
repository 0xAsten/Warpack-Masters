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
}

#[derive(Drop, Serde)]
#[dojo::model]
struct CharacterItemsInventoryCounter {
    #[key]
    player: ContractAddress,
    count: usize,
}

#[derive(Drop, Copy)]
struct ItemProperties {
    position: Position,
    rotation: usize,
    width: usize,
    height: usize,
    empower: usize,
    poison: usize,
}

pub fn are_items_nearby(pos1: Position, width1: usize, height1: usize, rotation1: usize, pos2: Position, width2: usize, height2: usize, rotation2: usize) -> bool {
    // Calculate item dimensions considering rotation for the first item
    let (final_width1, final_height1, x1_min, y1_min) = if rotation1 == 90 {
        (height1, width1, pos1.x, pos1.y - (height1 - 1))
    } else if rotation1 == 180 {
        (width1, height1, pos1.x - (width1 - 1), pos1.y)
    } else if rotation1 == 270 {
        (height1, width1, pos1.x, pos1.y + (height1 - 1))
    } else {
        (width1, height1, pos1.x, pos1.y)
    };

    // Calculate item dimensions considering rotation for the second item
    let (final_width2, final_height2, x2_min, y2_min) = if rotation2 == 90 {
        (height2, width2, pos2.x, pos2.y - (height2 - 1))
    } else if rotation2 == 180 {
        (width2, height2, pos2.x - (width2 - 1), pos2.y)
    } else if rotation2 == 270 {
        (height2, width2, pos2.x, pos2.y + (height2 - 1))
    } else {
        (width2, height2, pos2.x, pos2.y)
    };

    // Define the boundaries of the first item
    let x1_max = x1_min + final_width1 - 1;
    let y1_max = y1_min + final_height1 - 1;

    // Define the boundaries of the second item
    let x2_max = x2_min + final_width2 - 1;
    let y2_max = y2_min + final_height2 - 1;

    // Check if the items are adjacent horizontally or vertically
    let horizontally_adjacent = (
        (x1_max + 1 == x2_min || x2_max + 1 == x1_min)
        && (y1_min <= y2_max && y1_max >= y2_min)
    );
    let vertically_adjacent = (
        (y1_max + 1 == y2_min || y2_max + 1 == y1_min)
        && (x1_min <= x2_max && x1_max >= x2_min)
    );

    horizontally_adjacent || vertically_adjacent
}

#[cfg(test)]
mod tests {
    use super::{Position, are_items_nearby};

    #[test]
    fn test_items_horizontally_adjacent_first_left_second_right() {
        let pos1 = Position { x: 2, y: 1 };
        let pos2 = Position { x: 3, y: 1 }; 
        
        assert!(are_items_nearby(pos1, 1, 2, 0, pos2, 1, 3, 0), "Items should be horizontally adjacent when first item is left and second is right");
    }

    #[test]
    fn test_items_horizontally_adjacent_first_right_second_left() {
        let pos1 = Position { x: 3, y: 1 }; 
        let pos2 = Position { x: 1, y: 1 }; 
        
        assert!(are_items_nearby(pos1, 2, 2, 0, pos2, 2, 2, 0), "Items should be horizontally adjacent when first item is right and second is left");
    }

    #[test]
    fn test_items_vertically_adjacent_first_top_second_bottom() {
        let pos1 = Position { x: 1, y: 1 }; 
        let pos2 = Position { x: 1, y: 3 }; 
        
        assert!(are_items_nearby(pos1, 2, 2, 0, pos2, 2, 2, 0), "Items should be vertically adjacent when first item is on top and second is on the bottom");
    }

    #[test]
    fn test_items_vertically_adjacent_first_bottom_second_top() {
        let pos1 = Position { x: 1, y: 3 }; 
        let pos2 = Position { x: 1, y: 1 }; 
        
        assert!(are_items_nearby(pos1, 2, 2, 0, pos2, 2, 2, 0), "Items should be vertically adjacent when first item is on the bottom and second is on top");
    }

    #[test]
    fn test_items_rotated_90_degrees() {
        let pos1 = Position { x: 1, y: 2 };
        let pos2 = Position { x: 3, y: 1 }; 

        assert!(are_items_nearby(pos1, 2, 2, 0, pos2, 2, 1, 90), "Items should be vertically adjacent with rotation");

        // not adjacent without rotation
        assert!(!are_items_nearby(pos1, 2, 2, 0, pos2, 2, 1, 0), "Items should not be adjacent without rotation");
    }

    #[test]
    fn test_items_rotated_180_degrees() {
        let pos1 = Position { x: 1, y: 1 };
        let pos2 = Position { x: 4, y: 1 }; 

        assert!(are_items_nearby(pos1, 2, 2, 0, pos2, 2, 1, 180), "Items should be horizontally adjacent with rotation");
    }

    #[test]
    fn test_items_180_rotation_affects_adjacent_status() {
        let pos1 = Position { x: 1, y: 1 };
        let pos2 = Position { x: 4, y: 1 }; 
        // not adjacent without rotation
        assert!(!are_items_nearby(pos1, 2, 2, 0, pos2, 2, 2, 0), "Items should not be adjacent without rotation");

        // adjacent with 180-degree rotation
        assert!(are_items_nearby(pos1, 2, 2, 0, pos2, 2, 2, 180), "Items should be adjacent with 180-degree rotation");
    }

    #[test]
    fn test_items_270_rotation_affects_adjacent_status() {
        let pos1 = Position { x: 1, y: 2 }; 
        let pos2 = Position { x: 2, y: 0 };
        // not adjacent without rotation
        assert!(!are_items_nearby(pos1, 2, 2, 0, pos2, 2, 1, 0), "Items should not be adjacent without rotation");

         // adjacent with 270-degree rotation
        assert!(are_items_nearby(pos1, 2, 2, 0, pos2, 2, 1, 270), "Items should be adjacent with 270-degree rotation");
    }
}