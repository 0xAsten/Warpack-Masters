use starknet::ContractAddress;

#[derive(Model, Drop, Serde)]
struct Backpack {
    #[key]
    player: ContractAddress,
    gridSize: u8,
}
