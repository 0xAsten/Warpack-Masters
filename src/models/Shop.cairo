use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
struct Shop {
    #[key]
    player: ContractAddress,
    item1: u32,
    item2: u32,
    item3: u32,
    item4: u32,
}
