use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Introspect)]
struct Position {
    x: usize,
    y: usize
}

#[derive(Model, Drop, Serde)]
struct CharacterItemStorage {
    #[key]
    player: ContractAddress,
    #[key]
    id: usize,
    itemId: usize,
}

#[derive(Model, Drop, Serde)]
struct CharacterItemsStorageCounter {
    #[key]
    player: ContractAddress,
    count: usize,
}

#[derive(Model, Drop, Serde)]
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

#[derive(Model, Drop, Serde)]
struct CharacterItemsInventoryCounter {
    #[key]
    player: ContractAddress,
    count: usize,
}
