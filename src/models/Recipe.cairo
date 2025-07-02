#[derive(Drop, Serde)]
#[dojo::model]
pub struct Recipe {
    #[key]
    pub id: u32,
    pub item_ids: Array<u32>,
    pub item_amounts: Array<u32>,
    pub result_item_id: u32,
    pub enabled: bool,
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct RecipesCounter {
    #[key]
    pub id: felt252,
    pub count: u32,
}
