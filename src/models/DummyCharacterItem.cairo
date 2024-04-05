use starknet::ContractAddress;
use warpack_masters::model::CharacterItem::Position;

#[derive(Model, Drop, Serde)]
struct DummyCharacterItem {
    #[key]
    level: usize,
    #[key]
    id: u32,
    #[key]
    counterId: usize,
    itemId: usize,
    position: Position,
    // 0, 90, 180, 270
    rotation: usize,
}

#[derive(Model, Drop, Serde)]
struct DummyCharacterItemsCounter {
    #[key]
    level: usize,
    #[key]
    id: u32,
    count: usize,
}
