use starknet::ContractAddress;

#[derive(Model, Drop, Serde)]
struct Shop {
    #[key]
    player: ContractAddress,
    item1: usize,
    item2: usize,
    item3: usize,
    item4: usize,
}
