mod systems {
    mod actions;
}

mod models {
    mod backpack;
    mod CharacterItem;
    mod Item;
    mod Character;
    mod Shop;
    mod DummyCharacter;
    mod DummyCharacterItem;
    mod BattleLog;
}

mod tests {
    mod test_player_spawn;
    mod test_place_item;
    mod test_add_item;
    mod test_edit_item;
    mod test_buy_item;
    mod test_undo_place_item;
    mod test_sell_item;
    mod test_reroll_shop;
    mod test_fight;
}

mod utils {
    mod random;
}
