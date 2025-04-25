#[derive(Drop, Serde)]
#[dojo::model]
pub struct Recipe {
    #[key]
    pub item1_id: u32,
    #[key]
    pub item2_id: u32,
    pub result_item_id: u32,
}