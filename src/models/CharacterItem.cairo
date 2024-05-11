use starknet::ContractAddress;

#[derive(Model, Drop, Serde)]
struct CharacterItem {
    #[key]
    player: ContractAddress,
    #[key]
    id: usize,
    itemId: usize,
    // is it in inventory or in storage
    where: felt252,
    position: Position,
    // 0, 90, 180, 270
    rotation: usize,
}

#[derive(Copy, Drop, Serde, Introspect)]
struct Position {
    x: usize,
    y: usize
}


#[derive(Model, Drop, Serde)]
struct CharacterItemsCounter {
    #[key]
    player: ContractAddress,
    count: usize,
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
