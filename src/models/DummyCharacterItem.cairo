use warpack_masters::models::CharacterItem::Position;

#[derive(Drop, Serde)]
#[dojo::model]
pub struct DummyCharacterItem {
    #[key]
    pub level: u32,
    #[key]
    pub dummyCharId: u32,
    #[key]
    pub counterId: u32,
    pub itemId: u32,
    pub position: Position,
    // 0, 90, 180, 270
    pub rotation: u32,
    // effectType, chance, stacks
    pub plugins: Span<(u8, u32, u32)>,
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct DummyCharacterItemsCounter {
    #[key]
    pub level: u32,
    #[key]
    pub dummyCharId: u32,
    pub count: u32,
}
