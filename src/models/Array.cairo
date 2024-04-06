#[derive(Model, Drop, Serde)]
struct ArrayModel {
    #[key]
    array_id: usize,
    #[key]
    array_index: usize,
    array_value: usize,
}
