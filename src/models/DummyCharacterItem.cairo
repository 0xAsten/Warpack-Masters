use starknet::ContractAddress;
use warpack_masters::models::CharacterItem::Position;

#[derive(Model, Drop, Serde)]
#[dojo::model]
struct DummyCharacterItem {
    #[key]
    level: usize,
    #[key]
    dummyCharId: u32,
    #[key]
    counterId: usize,
    itemId: usize,
    position: Position,
    // 0, 90, 180, 270
    rotation: usize,
}

#[derive(Model, Drop, Serde)]
#[dojo::model]
struct DummyCharacterItemsCounter {
    #[key]
    level: usize,
    #[key]
    dummyCharId: u32,
    count: usize,
}
