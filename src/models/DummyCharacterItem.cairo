use starknet::ContractAddress;
use warpack_masters::models::CharacterItem::Position;

#[derive(Drop, Serde)]
#[dojo::model]
struct DummyCharacterItem {
    #[key]
    level: u32,
    #[key]
    dummyCharId: u32,
    #[key]
    counterId: u32,
    itemId: u32,
    position: Position,
    // 0, 90, 180, 270
    rotation: u32,
    // effectType, chance, stacks
    plugins: Span<(u8, u32, u32)>,
}

#[derive(Drop, Serde)]
#[dojo::model]
struct DummyCharacterItemsCounter {
    #[key]
    level: u32,
    #[key]
    dummyCharId: u32,
    count: u32,
}
