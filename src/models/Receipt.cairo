#[derive(Drop, Serde)]
#[dojo::model]
struct Receipt {
    #[key]
    item1_id: u32,
    #[key]
    item2_id: u32,
    result_item_id: u32,
}