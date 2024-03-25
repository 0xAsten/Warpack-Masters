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
    position: (usize, usize),
    // 0, 90, 180, 270
    rotation: usize,
}


#[derive(Model, Drop, Serde)]
struct CharacterItemsCounter {
    #[key]
    player: ContractAddress,
    count: usize,
}
