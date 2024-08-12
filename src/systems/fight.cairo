#[dojo::interface]
trait IFight {
    fn fight(ref world: IWorldDispatcher);
}

#[dojo::contract]
mod fight_system {
    use super::IFight;

    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use warpack_masters::models::{
        CharacterItem::{
            Position, CharacterItemInventory,
            CharacterItemsInventoryCounter
        },
        Item::Item
    };
    use warpack_masters::models::Character::{Character, WMClass};

    use warpack_masters::utils::random::{pseudo_seed, random};
    use warpack_masters::models::DummyCharacter::{DummyCharacter, DummyCharacterCounter};
    use warpack_masters::models::DummyCharacterItem::{
        DummyCharacterItem, DummyCharacterItemsCounter
    };
    use warpack_masters::models::BattleLog::{BattleLog, BattleLogCounter};

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct BattleLogDetail {
        #[key]
        player: ContractAddress,
        #[key]
        battleLogId: usize,
        #[key]
        id: usize,
        whoTriggered: felt252,
        whichItem: usize,
        damageCaused: usize,
        isDodged: bool,
        cleansePoison: usize,
        buffType: felt252,
        regenHP: usize,
        player_remaining_health: usize,
        dummy_remaining_health: usize,
        player_armor_stacks: usize,
        player_regen_stacks: usize,
        player_reflect_stacks: usize,
        player_empower_stacks: usize,
        player_poison_stacks: usize,
        dummy_armor_stacks: usize,
        dummy_regen_stacks: usize,
        dummy_reflect_stacks: usize,
        dummy_empower_stacks: usize,
        dummy_poison_stacks: usize,
    }
    
    const EFFECT_ARMOR: felt252 = 'armor';
    const EFFECT_REGEN: felt252 = 'regen';
    const EFFECT_REFLECT: felt252 = 'reflect';
    const EFFECT_EMPOWER: felt252 = 'empower';
    const EFFECT_POISON: felt252 = 'poison';
    const EFFECT_CLEANSE_POISON: felt252 = 'cleanse_poison';

    #[abi(embed_v0)]
    impl FightImpl of IFight<ContractState> {
        fn fight(ref world: IWorldDispatcher) {
            let player = get_caller_address();

            let mut char = get!(world, player, (Character));

            assert(char.dummied == true, 'dummy not created');
            assert(char.loss < 5, 'max loss reached');

            let (seed1, seed2, _, _) = pseudo_seed();
            let dummyCharCounter = get!(world, char.wins, (DummyCharacterCounter));
            assert(dummyCharCounter.count > 1, 'only self dummy created');

            let random_index = random(seed1, dummyCharCounter.count) + 1;
            let mut dummy_index = random_index;
            let mut dummyChar = get!(world, (char.wins, dummy_index), DummyCharacter);

            while dummyChar.player == player {
                dummy_index = dummy_index % dummyCharCounter.count + 1;
                assert(dummy_index != random_index, 'no others dummy found');
                dummyChar = get!(world, (char.wins, dummy_index), DummyCharacter);
            };

            // start the battle
            let mut char_health: usize = char.health;
            let char_health_flag: usize = char.health;
            let mut dummy_health: usize = dummyChar.health;
            let dummy_health_flag: usize = dummyChar.health;

            let mut char_items_len: usize = 0;
            let mut dummy_items_len: usize = 0;

            // =========  buffs/debuffs stacks ========= 
            let mut char_armor: usize = 0;
            let mut dummy_armor: usize = 0;

            let mut char_regen: usize = 0;
            let mut dummy_regen: usize = 0;

            let mut char_reflect: usize = 0;
            let mut dummy_reflect: usize = 0;

            let mut char_empower: usize = 0;
            let mut dummy_empower: usize = 0;

            let mut char_poison: usize = 0;
            let mut dummy_poison: usize = 0;

            let mut char_on_hit_items = ArrayTrait::new();
            let mut dummy_on_hit_items = ArrayTrait::new();

            let mut char_on_attack_items = ArrayTrait::new();
            let mut dummy_on_attack_items = ArrayTrait::new();
            // =========  end =========

            // sort items
            let mut items: Felt252Dict<u32> = Default::default();
            let mut item_belongs: Felt252Dict<felt252> = Default::default();
            let mut items_length: usize = 0;

            let inventoryItemsCounter = get!(world, player, (CharacterItemsInventoryCounter));
            let mut inventoryItemCount = inventoryItemsCounter.count;

            loop {
                if inventoryItemCount == 0 {
                    break;
                }
                let charItem = get!(world, (player, inventoryItemCount), (CharacterItemInventory));
                let item = get!(world, charItem.itemId, (Item));
                if item.itemType == 4 {
                    inventoryItemCount -= 1;
                    continue;
                }
                let cooldown = item.cooldown;
                if cooldown > 0 {
                    items.insert(items_length.into(), charItem.itemId);
                    item_belongs.insert(items_length.into(), 'player');

                    items_length += 1;
                    char_items_len += 1;
                } else if cooldown == 0 {
                    // ====== `on start / on hit / on attack` to plus stacks ======
                    // buff
                    if item.armorActivation == 1 {
                        char_armor += item.armor;
                    } else if item.armorActivation == 2 {
                        char_on_hit_items.append((EFFECT_ARMOR, item.chance, item.armor));
                    } else if item.armorActivation == 4 {
                        char_on_attack_items.append((EFFECT_ARMOR, item.chance, item.armor));
                    }

                    if item.regenActivation == 1 {
                        char_regen += item.regen;
                    } else if item.regenActivation == 2 {
                        char_on_hit_items.append((EFFECT_REGEN, item.chance, item.regen));
                    } else if item.regenActivation == 4 {
                        char_on_attack_items.append((EFFECT_REGEN, item.chance, item.regen));
                    }

                    if item.reflectActivation == 1 {
                        char_reflect += item.reflect;
                    } else if item.reflectActivation == 2 {
                        char_on_hit_items.append((EFFECT_REFLECT, item.chance, item.reflect));
                    } else if item.reflectActivation == 4 {
                        char_on_attack_items.append((EFFECT_REFLECT, item.chance, item.reflect));
                    }

                    if item.empowerActivation == 1 {
                        char_empower += item.empower;
                    } else if item.empowerActivation == 2 {
                        char_on_hit_items.append((EFFECT_EMPOWER, item.chance, item.empower));
                    } else if item.empowerActivation == 4 {
                        char_on_attack_items.append((EFFECT_EMPOWER, item.chance, item.empower));
                    }
                    // debuff
                    if item.poisonActivation == 1 {
                        dummy_poison += item.poison;
                    } else if item.poisonActivation == 2 {
                        char_on_hit_items.append((EFFECT_POISON, item.chance, item.poison));
                    } else if item.poisonActivation == 4 {
                        char_on_attack_items.append((EFFECT_POISON, item.chance, item.poison));
                    }
                // ====== end ======
                }

                inventoryItemCount -= 1;
            };
            let char_on_hit_items_span = char_on_hit_items.span();
            let char_on_attack_items_span = char_on_attack_items.span();

            let dummyCharItemsCounter = get!(
                world, (char.wins, dummy_index), (DummyCharacterItemsCounter)
            );
            let mut dummy_item_count = dummyCharItemsCounter.count;
            loop {
                if dummy_item_count == 0 {
                    break;
                }

                let dummy_item = get!(
                    world, (char.wins, dummy_index, dummy_item_count), (DummyCharacterItem)
                );
                let item = get!(world, dummy_item.itemId, (Item));
                if item.itemType == 4 {
                    dummy_item_count -= 1;
                    continue;
                }
                if item.cooldown > 0 {
                    items.insert(items_length.into(), dummy_item.itemId);
                    item_belongs.insert(items_length.into(), 'dummy');

                    items_length += 1;
                    dummy_items_len += 1;
                } else if item.cooldown == 0 {
                    // ====== `on start / on hit / on attack` to plus stacks ======
                    // buff
                    if item.armorActivation == 1 {
                        dummy_armor += item.armor;
                    } else if item.armorActivation == 2 {
                        dummy_on_hit_items.append((EFFECT_ARMOR, item.chance, item.armor));
                    } else if item.armorActivation == 4 {
                        dummy_on_attack_items.append((EFFECT_ARMOR, item.chance, item.armor));
                    }

                    if item.regenActivation == 1 {
                        dummy_regen += item.regen;
                    } else if item.regenActivation == 2 {
                        dummy_on_hit_items.append((EFFECT_REGEN, item.chance, item.regen));
                    } else if item.regenActivation == 4 {
                        dummy_on_attack_items.append((EFFECT_REGEN, item.chance, item.regen));
                    }

                    if item.reflectActivation == 1 {
                        dummy_reflect += item.reflect;
                    } else if item.reflectActivation == 2 {
                        dummy_on_hit_items.append((EFFECT_REFLECT, item.chance, item.reflect));
                    } else if item.reflectActivation == 4 {
                        dummy_on_attack_items.append((EFFECT_REFLECT, item.chance, item.reflect));
                    }

                    if item.empowerActivation == 1 {
                        dummy_empower += item.empower;
                    } else if item.empowerActivation == 2 {
                        dummy_on_hit_items.append((EFFECT_EMPOWER, item.chance, item.empower));
                    } else if item.empowerActivation == 4 {
                        dummy_on_attack_items.append((EFFECT_EMPOWER, item.chance, item.empower));
                    }

                    // debuff
                    if item.poisonActivation == 1 {
                        char_poison += item.poison;
                    } else if item.poisonActivation == 2 {
                        dummy_on_hit_items.append((EFFECT_POISON, item.chance, item.poison));
                    } else if item.poisonActivation == 4 {
                        dummy_on_attack_items.append((EFFECT_POISON, item.chance, item.poison));
                    }
                // ====== end ======
                }

                dummy_item_count -= 1;
            };
            let dummy_on_hit_items_span = dummy_on_hit_items.span();
            let dummy_on_attack_items_span = dummy_on_attack_items.span();

            // sorting items based on cooldown in ascending order
            let mut i: usize = 0;
            let mut j: usize = 0;
            loop {
                if i >= items_length {
                    break;
                }
                loop {
                    if j >= (items_length - i - 1) {
                        break;
                    }

                    // fetch respective itemids
                    let items_at_j = items.get(j.into());
                    let items_at_j_belongs = item_belongs.get(j.into());
                    let items_at_j_plus_one = items.get((j + 1).into());
                    let items_at_j_plus_one_belongs = item_belongs.get((j + 1).into());

                    //fetch itemid data
                    let item_data_at_j = get!(world, items_at_j, Item);
                    let item_data_at_j_plus_one = get!(world, items_at_j_plus_one, Item);

                    if item_data_at_j.cooldown > item_data_at_j_plus_one.cooldown {
                        items.insert(j.into(), items_at_j_plus_one);
                        item_belongs.insert(j.into(), items_at_j_plus_one_belongs);
                        items.insert((j + 1).into(), items_at_j);
                        item_belongs.insert((j + 1).into(), items_at_j_belongs);
                    }

                    j += 1;
                };
                j = 0;
                i += 1;
            };

            // record the battle log
            let mut battleLogCounter = get!(world, player, (BattleLogCounter));
            battleLogCounter.count += 1;
            let battleLogCounterCount = battleLogCounter.count;

            let mut battleLogsCount = 0;

            // battle logic
            let mut seconds = 0;
            let mut winner = '';

            let mut rand = 0;
            let mut v = 0;

            emit!(
                world,
                (BattleLogDetail {
                    player,
                    battleLogId: battleLogCounterCount,
                    id: battleLogsCount,
                    whoTriggered: 0,
                    whichItem: 0,
                    damageCaused: 0,
                    isDodged: false,
                    cleansePoison: 0,
                    buffType: 0,
                    regenHP: 0,
                    player_remaining_health: char_health,
                    dummy_remaining_health: dummy_health,
                    player_armor_stacks: char_armor,
                    player_regen_stacks: char_regen,
                    player_reflect_stacks: char_reflect,
                    player_empower_stacks: char_empower,
                    player_poison_stacks: char_poison,
                    dummy_armor_stacks: dummy_armor,
                    dummy_regen_stacks: dummy_regen,
                    dummy_reflect_stacks: dummy_reflect,
                    dummy_empower_stacks: dummy_empower,
                    dummy_poison_stacks: dummy_poison,
                })
            );

            loop {
                seconds += 1;
                if seconds >= 25_u8 {
                    if char_health <= dummy_health {
                        winner = 'dummy';
                    } else {
                        winner = 'player';
                    }
                    break;
                }

                let mut i: usize = 0;

                loop {
                    if i == items_length {
                        break;
                    }

                    let curr_item_index = items.get(i.into());
                    let curr_item_belongs = item_belongs.get(i.into());

                    let curr_item_data = get!(world, curr_item_index, (Item));

                    let mut damage = curr_item_data.damage;
                    if curr_item_data.itemType == 1 {
                        if curr_item_belongs == 'player' && char_empower > 0 {
                            damage += char_empower;
                        } else if curr_item_belongs == 'dummy' && dummy_empower > 0 {
                            damage += dummy_empower;
                        }
                    }

                    let cleansePoison = curr_item_data.cleansePoison;
                    let chance = curr_item_data.chance;
                    let cooldown = curr_item_data.cooldown;

                    // each second is treated as 1 unit of cooldown 
                    if seconds % cooldown == 0 {
                        v += seconds.into();
                        rand = random(seed2 + v, 100);
                        if rand < chance {
                            if curr_item_belongs == 'player' {
                                // ====== on cooldown to plus stacks, all use the same randomness ======
                                if curr_item_data.armorActivation == 3 {
                                    char_armor += curr_item_data.armor;
                                }
                                if curr_item_data.regenActivation == 3 {
                                    char_regen += curr_item_data.regen;
                                }
                                if curr_item_data.reflectActivation == 3 {
                                    char_reflect += curr_item_data.reflect;
                                }
                                if curr_item_data.empowerActivation == 3 {
                                    char_empower += curr_item_data.empower;
                                }
                                if curr_item_data.poisonActivation == 3 {
                                    dummy_poison += curr_item_data.poison;
                                }
                                // ====== end ======

                                if damage > 0 {
                                    // ====== Armor: used to absorb damage ======
                                    let mut damageCaused = 0;
                                    if damage <= dummy_armor {
                                        dummy_armor -= damage;
                                    } else {
                                        damageCaused = damage - dummy_armor;
                                        dummy_armor = 0;
                                    }
                                    // ====== end ======

                                    if dummy_health <= damageCaused {
                                        dummy_health = 0;
                                    } else {
                                        dummy_health -= damageCaused;
                                    }

                                    battleLogsCount += 1;
                                    emit!(
                                        world,
                                        (BattleLogDetail {
                                            player,
                                            battleLogId: battleLogCounterCount,
                                            id: battleLogsCount,
                                            whoTriggered: curr_item_belongs,
                                            whichItem: curr_item_index,
                                            damageCaused: damageCaused,
                                            isDodged: false,
                                            cleansePoison: 0,
                                            buffType: EFFECT_ARMOR,
                                            regenHP: 0,
                                            player_remaining_health: char_health,
                                            dummy_remaining_health: dummy_health,
                                            player_armor_stacks: char_armor,
                                            player_regen_stacks: char_regen,
                                            player_reflect_stacks: char_reflect,
                                            player_empower_stacks: char_empower,
                                            player_poison_stacks: char_poison,
                                            dummy_armor_stacks: dummy_armor,
                                            dummy_regen_stacks: dummy_regen,
                                            dummy_reflect_stacks: dummy_reflect,
                                            dummy_empower_stacks: dummy_empower,
                                            dummy_poison_stacks: dummy_poison,
                                        })
                                    );

                                    if dummy_health == 0 {
                                        winner = 'player';
                                        break;
                                    }

                                    // ====== dummy get hit, to plus stacks ======
                                    let mut on_hit_items_len = dummy_on_hit_items_span.len();
                                    loop {
                                        if on_hit_items_len == 0 {
                                            break;
                                        }

                                        let (
                                            on_hit_item_type, on_hit_item_chance, on_hit_item_stack
                                        ) =
                                            *dummy_on_hit_items_span
                                            .at(on_hit_items_len - 1);

                                        if rand < on_hit_item_chance {
                                            if on_hit_item_type == EFFECT_ARMOR {
                                                dummy_armor += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_REGEN {
                                                dummy_regen += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_REFLECT {
                                                dummy_reflect += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_EMPOWER {
                                                dummy_empower += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_POISON {
                                                char_poison += on_hit_item_stack;
                                            }
                                        }

                                        on_hit_items_len -= 1;
                                    };
                                    // ====== end ======

                                    // ====== Reflect effect: Deals 1 damage per stack when hit with a Melee weapon (up to 100% of the damage). ======
                                    if curr_item_data.itemType == 1 && dummy_reflect > 0 {
                                        damageCaused = 0;
                                        let mut reflect_damage = dummy_reflect;
                                        if reflect_damage > damage {
                                            reflect_damage = damage;
                                        }

                                        // ====== Armor: used to absorb damage ======
                                        if reflect_damage <= char_armor {
                                            char_armor -= reflect_damage;
                                        } else {
                                            damageCaused = reflect_damage - char_armor;
                                            char_armor = 0;
                                        }
                                        // ====== end ======

                                        if char_health <= damageCaused {
                                            char_health = 0;
                                        } else {
                                            char_health -= damageCaused;
                                        }

                                        battleLogsCount += 1;
                                        emit!(
                                            world,
                                            (BattleLogDetail {
                                                player,
                                                battleLogId: battleLogCounterCount,
                                                id: battleLogsCount,
                                                whoTriggered: 'dummy',
                                                whichItem: 0,
                                                damageCaused: damageCaused,
                                                isDodged: false,
                                                cleansePoison: 0,
                                                buffType: EFFECT_REFLECT,
                                                regenHP: 0,
                                                player_remaining_health: char_health,
                                                dummy_remaining_health: dummy_health,
                                                player_armor_stacks: char_armor,
                                                player_regen_stacks: char_regen,
                                                player_reflect_stacks: char_reflect,
                                                player_empower_stacks: char_empower,
                                                player_poison_stacks: char_poison,
                                                dummy_armor_stacks: dummy_armor,
                                                dummy_regen_stacks: dummy_regen,
                                                dummy_reflect_stacks: dummy_reflect,
                                                dummy_empower_stacks: dummy_empower,
                                                dummy_poison_stacks: dummy_poison,
                                            })
                                        );

                                        if char_health == 0 {
                                            winner = 'dummy';
                                            break;
                                        }
                                    }
                                    // ====== end ======

                                    // ====== char attack, to plus stacks ======
                                    let mut on_attack_items_len = char_on_attack_items_span.len();
                                    loop {
                                        if on_attack_items_len == 0 {
                                            break;
                                        }

                                        let (
                                            on_attack_item_type, on_attack_item_chance, on_attack_item_stack
                                        ) =
                                            *char_on_attack_items_span.at(on_attack_items_len - 1);

                                        if rand < on_attack_item_chance {
                                            if on_attack_item_type == EFFECT_ARMOR {
                                                char_armor += on_attack_item_stack;
                                            } else if on_attack_item_type == EFFECT_REGEN {
                                                char_regen += on_attack_item_stack;
                                            } else if on_attack_item_type == EFFECT_REFLECT {
                                                char_reflect += on_attack_item_stack;
                                            } else if on_attack_item_type == EFFECT_EMPOWER {
                                                char_empower += on_attack_item_stack;
                                            } else if on_attack_item_type == EFFECT_POISON {
                                                dummy_poison += on_attack_item_stack;
                                            }
                                        }

                                        on_attack_items_len -= 1;
                                    };
                                    // ====== end ======

                                } else {
                                    if cleansePoison > 0 {
                                        if char_poison > cleansePoison {
                                            char_poison -= cleansePoison;
                                        } else {
                                            char_poison = 0;
                                        }
                                        battleLogsCount += 1;
                                        emit!(
                                            world,
                                            (BattleLogDetail {
                                                player,
                                                battleLogId: battleLogCounterCount,
                                                id: battleLogsCount,
                                                whoTriggered: curr_item_belongs,
                                                whichItem: curr_item_index,
                                                damageCaused: 0,
                                                cleansePoison: cleansePoison,
                                                isDodged: false,
                                                buffType: EFFECT_CLEANSE_POISON,
                                                regenHP: 0,
                                                player_remaining_health: char_health,
                                                dummy_remaining_health: dummy_health,
                                                player_armor_stacks: char_armor,
                                                player_regen_stacks: char_regen,
                                                player_reflect_stacks: char_reflect,
                                                player_empower_stacks: char_empower,
                                                player_poison_stacks: char_poison,
                                                dummy_armor_stacks: dummy_armor,
                                                dummy_regen_stacks: dummy_regen,
                                                dummy_reflect_stacks: dummy_reflect,
                                                dummy_empower_stacks: dummy_empower,
                                                dummy_poison_stacks: dummy_poison,
                                            })
                                        );
                                    }
                                }
                            } else {
                                // ====== on cooldown to plus stacks, all use the same randomness ======
                                if curr_item_data.armorActivation == 3 {
                                    dummy_armor += curr_item_data.armor;
                                }
                                if curr_item_data.regenActivation == 3 {
                                    dummy_regen += curr_item_data.regen;
                                }
                                if curr_item_data.reflectActivation == 3 {
                                    dummy_reflect += curr_item_data.reflect;
                                }
                                if curr_item_data.empowerActivation == 3 {
                                    dummy_empower += curr_item_data.empower;
                                }
                                if curr_item_data.poisonActivation == 3 {
                                    char_poison += curr_item_data.poison;
                                }
                                // ====== end ======

                                if damage > 0 {
                                    // ====== Armor: used to absorb damage ======
                                    let mut damageCaused = 0;
                                    if damage <= char_armor {
                                        char_armor -= damage;
                                    } else {
                                        damageCaused = damage - char_armor;
                                        char_armor = 0;
                                    }
                                    // ====== end ======

                                    if char_health <= damageCaused {
                                        char_health = 0;
                                    } else {
                                        char_health -= damageCaused;
                                    }

                                    battleLogsCount += 1;
                                    emit!(
                                        world,
                                        (BattleLogDetail {
                                            player,
                                            battleLogId: battleLogCounterCount,
                                            id: battleLogsCount,
                                            whoTriggered: curr_item_belongs,
                                            whichItem: curr_item_index,
                                            damageCaused: damageCaused,
                                            isDodged: false,
                                            cleansePoison: 0,
                                            buffType: EFFECT_ARMOR,
                                            regenHP: 0,
                                            player_remaining_health: char_health,
                                            dummy_remaining_health: dummy_health,
                                            player_armor_stacks: char_armor,
                                            player_regen_stacks: char_regen,
                                            player_reflect_stacks: char_reflect,
                                            player_empower_stacks: char_empower,
                                            player_poison_stacks: char_poison,
                                            dummy_armor_stacks: dummy_armor,
                                            dummy_regen_stacks: dummy_regen,
                                            dummy_reflect_stacks: dummy_reflect,
                                            dummy_empower_stacks: dummy_empower,
                                            dummy_poison_stacks: dummy_poison,
                                        })
                                    );

                                    if char_health == 0 {
                                        winner = 'dummy';
                                        break;
                                    }

                                    // ====== char get hit, to plus stacks ======
                                    let mut on_hit_items_len = char_on_hit_items_span.len();
                                    loop {
                                        if on_hit_items_len == 0 {
                                            break;
                                        }

                                        let (
                                            on_hit_item_type, on_hit_item_chance, on_hit_item_stack
                                        ) =
                                            *char_on_hit_items_span
                                            .at(on_hit_items_len - 1);

                                        if rand < on_hit_item_chance {
                                            if on_hit_item_type == EFFECT_ARMOR {
                                                char_armor += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_REGEN {
                                                char_regen += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_REFLECT {
                                                char_reflect += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_EMPOWER {
                                                char_empower += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_POISON {
                                                dummy_poison += on_hit_item_stack;
                                            }
                                        }

                                        on_hit_items_len -= 1;
                                    };
                                    // ====== end ======

                                    // ====== Reflect effect: Deals 1 damage per stack when hit with a Melee weapon (up to 100% of the damage). ======
                                    if curr_item_data.itemType == 1 && char_reflect > 0 {
                                        damageCaused = 0;
                                        let mut reflect_damage = char_reflect;
                                        if reflect_damage > damage {
                                            reflect_damage = damage;
                                        }

                                        // ====== Armor: used to absorb damage ======
                                        if reflect_damage <= dummy_armor {
                                            dummy_armor -= reflect_damage;
                                        } else {
                                            damageCaused = reflect_damage - dummy_armor;
                                            dummy_armor = 0;
                                        }
                                        // ====== end ======

                                        if dummy_health <= damageCaused {
                                            dummy_health = 0;
                                        } else {
                                            dummy_health -= damageCaused;
                                        }

                                        battleLogsCount += 1;
                                        emit!(
                                            world,
                                            (BattleLogDetail {
                                                player,
                                                battleLogId: battleLogCounterCount,
                                                id: battleLogsCount,
                                                whoTriggered: 'player',
                                                whichItem: 0,
                                                damageCaused: damageCaused,
                                                isDodged: false,
                                                cleansePoison: 0,
                                                buffType: EFFECT_REFLECT,
                                                regenHP: 0,
                                                player_remaining_health: char_health,
                                                dummy_remaining_health: dummy_health,
                                                player_armor_stacks: char_armor,
                                                player_regen_stacks: char_regen,
                                                player_reflect_stacks: char_reflect,
                                                player_empower_stacks: char_empower,
                                                player_poison_stacks: char_poison,
                                                dummy_armor_stacks: dummy_armor,
                                                dummy_regen_stacks: dummy_regen,
                                                dummy_reflect_stacks: dummy_reflect,
                                                dummy_empower_stacks: dummy_empower,
                                                dummy_poison_stacks: dummy_poison,
                                            })
                                        );

                                        if dummy_health == 0 {
                                            winner = 'player';
                                            break;
                                        }
                                    }
                                    // ====== end ======

                                    // ====== char attack, to plus stacks ======
                                    let mut on_attack_items_len = dummy_on_attack_items_span.len();
                                    loop {
                                        if on_attack_items_len == 0 {
                                            break;
                                        }

                                        let (
                                            on_attack_item_type, on_attack_item_chance, on_attack_item_stack
                                        ) =
                                            *dummy_on_attack_items_span.at(on_attack_items_len - 1);

                                        if rand < on_attack_item_chance {
                                            if on_attack_item_type == EFFECT_ARMOR {
                                                dummy_armor += on_attack_item_stack;
                                            } else if on_attack_item_type == EFFECT_REGEN {
                                                dummy_regen += on_attack_item_stack;
                                            } else if on_attack_item_type == EFFECT_REFLECT {
                                                dummy_reflect += on_attack_item_stack;
                                            } else if on_attack_item_type == EFFECT_EMPOWER {
                                                dummy_empower += on_attack_item_stack;
                                            } else if on_attack_item_type == EFFECT_POISON {
                                                char_poison += on_attack_item_stack;
                                            }
                                        }

                                        on_attack_items_len -= 1;
                                    };
                                    // ====== end ======
                                } else {
                                    if cleansePoison > 0 {
                                        if dummy_poison > cleansePoison {
                                            dummy_poison -= cleansePoison;
                                        } else {
                                            dummy_poison = 0;
                                        }
                                        battleLogsCount += 1;
                                        emit!(
                                            world,
                                            (BattleLogDetail {
                                                player,
                                                battleLogId: battleLogCounterCount,
                                                id: battleLogsCount,
                                                whoTriggered: curr_item_belongs,
                                                whichItem: curr_item_index,
                                                damageCaused: 0,
                                                isDodged: false,
                                                cleansePoison: cleansePoison,
                                                buffType: EFFECT_CLEANSE_POISON,
                                                regenHP: 0,
                                                player_remaining_health: char_health,
                                                dummy_remaining_health: dummy_health,
                                                player_armor_stacks: char_armor,
                                                player_regen_stacks: char_regen,
                                                player_reflect_stacks: char_reflect,
                                                player_empower_stacks: char_empower,
                                                player_poison_stacks: char_poison,
                                                dummy_armor_stacks: dummy_armor,
                                                dummy_regen_stacks: dummy_regen,
                                                dummy_reflect_stacks: dummy_reflect,
                                                dummy_empower_stacks: dummy_empower,
                                                dummy_poison_stacks: dummy_poison,
                                            })
                                        );
                                    }
                                }
                            }
                        } else if rand >= chance && damage > 0 {
                            battleLogsCount += 1;
                            emit!(
                                world,
                                (BattleLogDetail {
                                    player,
                                    battleLogId: battleLogCounterCount,
                                    id: battleLogsCount,
                                    whoTriggered: curr_item_belongs,
                                    whichItem: curr_item_index,
                                    damageCaused: 0,
                                    isDodged: true,
                                    cleansePoison: 0,
                                    buffType: 0,
                                    regenHP: 0,
                                    player_remaining_health: char_health,
                                    dummy_remaining_health: dummy_health,
                                    player_armor_stacks: char_armor,
                                    player_regen_stacks: char_regen,
                                    player_reflect_stacks: char_reflect,
                                    player_empower_stacks: char_empower,
                                    player_poison_stacks: char_poison,
                                    dummy_armor_stacks: dummy_armor,
                                    dummy_regen_stacks: dummy_regen,
                                    dummy_reflect_stacks: dummy_reflect,
                                    dummy_empower_stacks: dummy_empower,
                                    dummy_poison_stacks: dummy_poison,
                                })
                            );
                        }
                    }

                    i += 1;
                };

                // ====== Poison effect: Deals 1 damage per stack every 2 seconds. ======
                // ====== Heal effect: Regenerate 1 health per stack every 2 seconds. ======
                if seconds % 2 == 0 {
                    if char_poison > 0 {
                        if char_health <= char_poison {
                            char_health = 0;
                        } else {
                            char_health -= char_poison;
                        }

                        battleLogsCount += 1;
                        emit!(
                            world,
                            (BattleLogDetail {
                                player,
                                battleLogId: battleLogCounterCount,
                                id: battleLogsCount,
                                whoTriggered: 'dummy',
                                whichItem: 0,
                                damageCaused: char_poison,
                                isDodged: false,
                                cleansePoison: 0,
                                buffType: EFFECT_POISON,
                                regenHP: 0,
                                player_remaining_health: char_health,
                                dummy_remaining_health: dummy_health,
                                player_armor_stacks: char_armor,
                                player_regen_stacks: char_regen,
                                player_reflect_stacks: char_reflect,
                                player_empower_stacks: char_empower,
                                player_poison_stacks: char_poison,
                                dummy_armor_stacks: dummy_armor,
                                dummy_regen_stacks: dummy_regen,
                                dummy_reflect_stacks: dummy_reflect,
                                dummy_empower_stacks: dummy_empower,
                                dummy_poison_stacks: dummy_poison,
                            })
                        );

                        if char_health == 0 {
                            winner = 'dummy';
                            break;
                        }
                    }
                    if dummy_poison > 0 {
                        if dummy_health <= dummy_poison {
                            dummy_health = 0;
                        } else {
                            dummy_health -= dummy_poison;
                        }

                        battleLogsCount += 1;
                        emit!(
                            world,
                            (BattleLogDetail {
                                player,
                                battleLogId: battleLogCounterCount,
                                id: battleLogsCount,
                                whoTriggered: 'player',
                                whichItem: 0,
                                damageCaused: dummy_poison,
                                isDodged: false,
                                cleansePoison: 0,
                                buffType: EFFECT_POISON,
                                regenHP: 0,
                                player_remaining_health: char_health,
                                dummy_remaining_health: dummy_health,
                                player_armor_stacks: char_armor,
                                player_regen_stacks: char_regen,
                                player_reflect_stacks: char_reflect,
                                player_empower_stacks: char_empower,
                                player_poison_stacks: char_poison,
                                dummy_armor_stacks: dummy_armor,
                                dummy_regen_stacks: dummy_regen,
                                dummy_reflect_stacks: dummy_reflect,
                                dummy_empower_stacks: dummy_empower,
                                dummy_poison_stacks: dummy_poison,
                            })
                        );

                        if dummy_health == 0 {
                            winner = 'player';
                            break;
                        }
                    }
                    if char_regen > 0 {
                        char_health += char_regen;
                        if char_health > char_health_flag {
                            char_health = char_health_flag;
                        }

                        battleLogsCount += 1;
                        emit!(
                            world,
                            (BattleLogDetail {
                                player,
                                battleLogId: battleLogCounterCount,
                                id: battleLogsCount,
                                whoTriggered: 'player',
                                whichItem: 0,
                                damageCaused: 0,
                                isDodged: false,
                                cleansePoison: 0,
                                buffType: EFFECT_REGEN,
                                regenHP: char_regen,
                                player_remaining_health: char_health,
                                dummy_remaining_health: dummy_health,
                                player_armor_stacks: char_armor,
                                player_regen_stacks: char_regen,
                                player_reflect_stacks: char_reflect,
                                player_empower_stacks: char_empower,
                                player_poison_stacks: char_poison,
                                dummy_armor_stacks: dummy_armor,
                                dummy_regen_stacks: dummy_regen,
                                dummy_reflect_stacks: dummy_reflect,
                                dummy_empower_stacks: dummy_empower,
                                dummy_poison_stacks: dummy_poison,
                            })
                        );
                    }
                    if dummy_regen > 0 {
                        dummy_health += dummy_regen;
                        if dummy_health > dummy_health_flag {
                            dummy_health = dummy_health_flag;
                        }

                        battleLogsCount += 1;
                        emit!(
                            world,
                            (BattleLogDetail {
                                player,
                                battleLogId: battleLogCounterCount,
                                id: battleLogsCount,
                                whoTriggered: 'dummy',
                                whichItem: 0,
                                damageCaused: 0,
                                isDodged: false,
                                cleansePoison: 0,
                                buffType: EFFECT_REGEN,
                                regenHP: dummy_regen,
                                player_remaining_health: char_health,
                                dummy_remaining_health: dummy_health,
                                player_armor_stacks: char_armor,
                                player_regen_stacks: char_regen,
                                player_reflect_stacks: char_reflect,
                                player_empower_stacks: char_empower,
                                player_poison_stacks: char_poison,
                                dummy_armor_stacks: dummy_armor,
                                dummy_regen_stacks: dummy_regen,
                                dummy_reflect_stacks: dummy_reflect,
                                dummy_empower_stacks: dummy_empower,
                                dummy_poison_stacks: dummy_poison,
                            })
                        );
                    }
                }
                // ====== end ======

                if winner != '' {
                    break;
                }
            };

            let battleLog = BattleLog {
                player: player,
                id: battleLogCounter.count,
                dummyCharLevel: char.wins,
                dummyCharId: dummy_index,
                winner: winner,
                seconds: seconds,
            };
            set!(world, (battleLogCounter, battleLog));

            if winner == 'player' {
                char.wins += 1;
                char.totalWins += 1;
                char.winStreak += 1;
                char.dummied = false;
                char.gold += 5;
                if char.wins < 5 {
                    char.health += 10;
                } else if char.wins == 5 {
                    char.health += 15;
                }

                char.rating += 25;

                if (dummyChar.rating < 10) {
                    dummyChar.rating = 0;
                } else {
                    dummyChar.rating -= 10;
                }
            } else {
                char.loss += 1;
                char.totalLoss += 1;
                char.winStreak = 0;
                char.gold += 5;

                dummyChar.rating += 25;

                if (char.rating < 10) {
                    char.rating = 0;
                } else {
                    char.rating -= 10;
                }
            }
            char.updatedAt = get_block_timestamp();
            set!(world, (char, dummyChar));
        }
    }
}
