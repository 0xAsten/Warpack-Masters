#[dojo::interface]
trait IFight {
    fn match_dummy(ref world: IWorldDispatcher);
    // fn fight(ref world: IWorldDispatcher);
}

#[dojo::contract]
mod fight_system {
    use super::IFight;

    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use warpack_masters::models::{
        CharacterItem::{Position, CharacterItemInventory, CharacterItemsInventoryCounter},
        Item::Item
    };
    use warpack_masters::models::Character::{Characters, WMClass, PLAYER, DUMMY};

    use warpack_masters::utils::random::{pseudo_seed, random};
    use warpack_masters::utils::sort_items::{append_item, order_items};
    use warpack_masters::models::DummyCharacter::{DummyCharacter, DummyCharacterCounter};
    use warpack_masters::models::DummyCharacterItem::{
        DummyCharacterItem, DummyCharacterItemsCounter
    };
    use warpack_masters::models::BattleLog::{BattleLog, BattleLogCounter};
    use warpack_masters::constants::constants::{EFFECT_ARMOR, EFFECT_REGEN, EFFECT_REFLECT, EFFECT_EMPOWER, EFFECT_POISON, EFFECT_CLEANSE_POISON, EFFECT_VAMPIRISM};

    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
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
        player_stamina: u8,
        dummy_stamina: u8,
        player_armor_stacks: usize,
        player_regen_stacks: usize,
        player_reflect_stacks: usize,
        player_empower_stacks: usize,
        player_vampirism_stacks: usize,
        player_poison_stacks: usize,
        dummy_armor_stacks: usize,
        dummy_regen_stacks: usize,
        dummy_reflect_stacks: usize,
        dummy_empower_stacks: usize,
        dummy_vampirism_stacks: usize,
        dummy_poison_stacks: usize,
    }

    #[abi(embed_v0)]
    impl FightImpl of IFight<ContractState> {
        fn match_dummy(ref world: IWorldDispatcher) {
            let player = get_caller_address();

            let mut char = get!(world, player, (Characters));

            assert(char.dummied == true, 'dummy not created');
            assert(char.loss < 5, 'max loss reached');

            let (seed1, _, _, _) = pseudo_seed();
            let dummyCharCounter = get!(world, char.wins, (DummyCharacterCounter));
            assert(dummyCharCounter.count > 1, 'only self dummy created');

            let mut battleLogCounter = get!(world, player, (BattleLogCounter));
            let latestBattleLog = get!(world, (player, battleLogCounter.count), BattleLog);
            assert(battleLogCounter.count == 0 || latestBattleLog.winner != 0, 'battle not fought');

            let random_index = random(seed1, dummyCharCounter.count) + 1;
            let mut dummy_index = random_index;
            let mut dummyChar = get!(world, (char.wins, dummy_index), DummyCharacter);

            while dummyChar.player == player {
                dummy_index = dummy_index % dummyCharCounter.count + 1;
                assert(dummy_index != random_index, 'no others dummy found');
                dummyChar = get!(world, (char.wins, dummy_index), DummyCharacter);
            };

            let mut items_cooldown4 = ArrayTrait::new();
            let mut items_cooldown5 = ArrayTrait::new();
            let mut items_cooldown6 = ArrayTrait::new();
            let mut items_cooldown7 = ArrayTrait::new();

            // =========  buffs/debuffs stacks ========= 
            let mut char_armor: usize = 0;
            let mut dummy_armor: usize = 0;

            let mut char_regen: usize = 0;
            let mut dummy_regen: usize = 0;

            let mut char_reflect: usize = 0;
            let mut dummy_reflect: usize = 0;

            let mut char_empower: usize = 0;
            let mut dummy_empower: usize = 0;

            let mut char_vampirism: usize = 0;
            let mut dummy_vampirism: usize = 0;

            let mut char_poison: usize = 0;
            let mut dummy_poison: usize = 0;
            // =========  end =========

            let mut char_on_hit_items = ArrayTrait::new();
            let mut dummy_on_hit_items = ArrayTrait::new();

            let mut char_on_attack_items = ArrayTrait::new();
            let mut dummy_on_attack_items = ArrayTrait::new();

            let inventoryItemsCounter = get!(world, player, (CharacterItemsInventoryCounter));
            let mut inventoryItemCount = inventoryItemsCounter.count;

            let mut items_length: usize = 0;
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

                if item.cooldown > 0 {
                    match item.cooldown {
                        0 | 1 | 2 | 3 => {
                            assert(false, 'cooldown not valid');
                        },
                        4 => {
                            append_item(ref items_cooldown4, charItem.plugins.span(), @item, PLAYER);
                        },
                        5 => {
                            append_item(ref items_cooldown5, charItem.plugins.span(), @item, PLAYER);
                        },
                        6 => {
                            append_item(ref items_cooldown6, charItem.plugins.span(), @item, PLAYER);
                        },
                        7 => {
                            append_item(ref items_cooldown7, charItem.plugins.span(), @item, PLAYER);
                        },
                        _ => {
                            assert(false, 'cooldown not valid');
                        },
                    }

                    items_length += 1;
                } else {
                    // ====== `on start -- 1 / on hit -- 2 / on attack -- 4` to plus stacks ======
                    if item.effectActivationType == 1 {
                        if item.effectType == 3 {
                            char_armor += item.effectStacks;
                        } else if item.effectType == 4 {
                            char_regen += item.effectStacks;
                        } else if item.effectType == 5 {
                            char_reflect += item.effectStacks;
                        } else if item.effectType == 7 {
                            char_empower += item.effectStacks;
                        } else if item.effectType == 8 {
                            char_vampirism += item.effectStacks;
                        } else if item.effectType == 6 {
                            dummy_poison += item.effectStacks;
                        }
                    }

                    if item.effectActivationType == 2 {
                        char_on_hit_items.append((item.effectType, item.chance, item.effectStacks));
                    }

                    if item.effectActivationType == 4 {
                        char_on_attack_items.append((item.effectType, item.chance, item.effectStacks));
                    }
                    // ====== plus stacks end ======
                }

                inventoryItemCount -= 1;
            };

            let dummyCharItemsCounter = get!(
                world, (char.wins, dummy_index), DummyCharacterItemsCounter
            );
            let mut dummy_item_count = dummyCharItemsCounter.count;
            loop {
                if dummy_item_count == 0 {
                    break;
                }

                let dummy_item = get!(
                    world, (char.wins, dummy_index, dummy_item_count), DummyCharacterItem
                );

                let item = get!(world, dummy_item.itemId, (Item));
                if item.itemType == 4 {
                    dummy_item_count -= 1;
                    continue;
                }

                if item.cooldown > 0 {
                    match item.cooldown {
                        0 | 1 | 2 | 3 => {
                            assert(false, 'cooldown not valid');
                        },
                        4 => {
                            append_item(ref items_cooldown4, dummy_item.plugins, @item, DUMMY);
                        },
                        5 => {
                            append_item(ref items_cooldown5, dummy_item.plugins, @item, DUMMY);
                        },
                        6 => {
                            append_item(ref items_cooldown6, dummy_item.plugins, @item, DUMMY);
                        },
                        7 => {
                            append_item(ref items_cooldown7, dummy_item.plugins, @item, DUMMY);
                        },
                        _ => {
                            assert(false, 'cooldown not valid');
                        },
                    }

                    items_length += 1;
                } else {
                    // ====== `on start / on hit / on attack` to plus stacks ======
                    if item.effectActivationType == 1 {
                        if item.effectType == 3 {
                            dummy_armor += item.effectStacks;
                        } else if item.effectType == 4 {
                            dummy_regen += item.effectStacks;
                        } else if item.effectType == 5 {
                            dummy_reflect += item.effectStacks;
                        } else if item.effectType == 7 {
                            dummy_empower += item.effectStacks;
                        } else if item.effectType == 8 {
                            dummy_vampirism += item.effectStacks;
                        } else if item.effectType == 6 {
                            char_poison += item.effectStacks;
                        }
                    }

                    if item.effectActivationType == 2 {
                        dummy_on_hit_items.append((item.effectType, item.chance, item.effectStacks));
                    }

                    if item.effectActivationType == 4 {
                        dummy_on_attack_items.append((item.effectType, item.chance, item.effectStacks));
                    }
                    // ====== plus stacks end ======
                }

                dummy_item_count -= 1;
            };

            // combine items
            let sorted_items = order_items(
                ref items_cooldown4,
                ref items_cooldown5,
                ref items_cooldown6,
                ref items_cooldown7,
            );

            // record the battle log
            battleLogCounter.count += 1;

            let battleLog = BattleLog {
                player: player,
                id: battleLogCounter.count,
                dummyLevel: char.wins,
                dummyCharId: dummy_index,
                sorted_items: sorted_items.span(),
                items_length: items_length,
                char_buffs: array![char_armor, char_regen, char_reflect, char_empower, char_poison, char_vampirism].span(),
                dummy_buffs: array![dummy_armor, dummy_regen, dummy_reflect, dummy_empower, dummy_poison, dummy_vampirism].span(),
                char_on_hit_items: char_on_hit_items.span(),
                dummy_on_hit_items: dummy_on_hit_items.span(),
                char_on_attack_items: char_on_attack_items.span(),
                dummy_on_attack_items: dummy_on_attack_items.span(),
                winner: 0,
                seconds: 0,
            };
            set!(world, (battleLogCounter, battleLog));
        }

        fn fight(ref world: IWorldDispatcher) {
            let player = get_caller_address();

            let mut char = get!(world, player, (Characters));

            let battleLogCounter = get!(world, player, (BattleLogCounter));
            let mut battleLog = get!(world, (player, battleLogCounter.count), BattleLog);

            let battleLogCounterCount = battleLogCounter.count;

            assert(battleLogCounterCount != 0 && battleLog.winner == 0, 'no new match found');

            let dummy_index = battleLog.dummyCharId;
            let mut dummyChar = get!(world, (char.wins, dummy_index), DummyCharacter);

            // start the battle
            let mut char_health: usize = char.health;
            let char_health_flag: usize = char.health;
            let mut dummy_health: usize = dummyChar.health;
            let dummy_health_flag: usize = dummyChar.health;

            // stamina
            let mut char_stamina = char.stamina;
            let mut dummy_stamina = dummyChar.stamina;

            let item_ids = battleLog.item_ids;
            let belongs_tos = battleLog.belongs_tos;
            let items_length = battleLog.items_length;

            let char_on_hit_items_span = battleLog.char_on_hit_items;
            let char_on_attack_items_span = battleLog.char_on_attack_items;

            let dummy_on_hit_items_span = battleLog.dummy_on_hit_items;
            let dummy_on_attack_items_span = battleLog.dummy_on_attack_items;

            let char_buffs = battleLog.char_buffs;
            let mut char_armor = *char_buffs.at(0);
            let mut char_regen = *char_buffs.at(1);
            let mut char_reflect = *char_buffs.at(2);
            let mut char_empower = *char_buffs.at(3);
            let mut char_poison = *char_buffs.at(4);
            let mut char_vampirism = *char_buffs.at(5);

            let dummy_buffs = battleLog.dummy_buffs;
            let mut dummy_armor = *dummy_buffs.at(0);
            let mut dummy_regen = *dummy_buffs.at(1);
            let mut dummy_reflect = *dummy_buffs.at(2);
            let mut dummy_empower = *dummy_buffs.at(3);
            let mut dummy_poison = *dummy_buffs.at(4);
            let mut dummy_vampirism = *dummy_buffs.at(5);

            // record the battle log
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
                    player_stamina: char_stamina,
                    dummy_stamina: dummy_stamina,
                    player_armor_stacks: char_armor,
                    player_regen_stacks: char_regen,
                    player_reflect_stacks: char_reflect,
                    player_empower_stacks: char_empower,
                    player_vampirism_stacks: char_vampirism,
                    player_poison_stacks: char_poison,
                    dummy_armor_stacks: dummy_armor,
                    dummy_regen_stacks: dummy_regen,
                    dummy_reflect_stacks: dummy_reflect,
                    dummy_empower_stacks: dummy_empower,
                    dummy_vampirism_stacks: dummy_vampirism,
                    dummy_poison_stacks: dummy_poison,
                })
            );

            loop {
                seconds += 1;
                if seconds >= 25_u8 {
                    if char_health <= dummy_health {
                        winner = DUMMY;
                    } else {
                        winner = PLAYER;
                    }
                    break;
                }

                let mut i: usize = 0;

                // Skip stamina regeneration on the first second
                if seconds > 1 {
                    // Regenerate stamina for both player and dummy at the beginning of each cycle
                    if char_stamina < 100 {
                        char_stamina += 10;
                        if char_stamina > 100 {
                            char_stamina = 100;
                        }
                    }

                    if dummy_stamina < 100 {
                        dummy_stamina += 10;
                        if dummy_stamina > 100 {
                            dummy_stamina = 100;
                        }
                    }
                }

                loop {
                    if i == items_length {
                        break;
                    }

                    let curr_item_index = *item_ids.at(i);
                    let curr_item_belongs = *belongs_tos.at(i.into());

                    let curr_item_data = get!(world, curr_item_index, (Item));

                    let cleansePoison = curr_item_data.cleansePoison;
                    let chance = curr_item_data.chance;
                    let cooldown = curr_item_data.cooldown;

                    let mut damage = curr_item_data.damage;

                    // each second is treated as 1 unit of cooldown 
                    let (_, seed2, _, _) = pseudo_seed();
                    if seconds % cooldown == 0 {
                        v += seconds.into();
                        rand = random(seed2 + v, 100);
                        if rand < chance {
                            if curr_item_belongs == PLAYER {
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
                                if curr_item_data.vampirismActivation == 3 {
                                    char_vampirism += curr_item_data.vampirism;
                                }
                                if curr_item_data.poisonActivation == 3 {
                                    dummy_poison += curr_item_data.poison;
                                }
                                // ====== end ======

                                if curr_item_data.energyCost > char_stamina {
                                    // Not enough stamina, skip this activation
                                    i += 1;
                                    continue;
                                }
                                // Deduct stamina
                                char_stamina -= curr_item_data.energyCost;

                                if curr_item_data.itemType == 1 && char_empower > 0 {
                                    damage += char_empower;
                                }

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
                                            player_stamina: char_stamina,
                                            dummy_stamina: dummy_stamina,
                                            player_armor_stacks: char_armor,
                                            player_regen_stacks: char_regen,
                                            player_reflect_stacks: char_reflect,
                                            player_empower_stacks: char_empower,
                                            player_vampirism_stacks: char_vampirism,
                                            player_poison_stacks: char_poison,
                                            dummy_armor_stacks: dummy_armor,
                                            dummy_regen_stacks: dummy_regen,
                                            dummy_reflect_stacks: dummy_reflect,
                                            dummy_empower_stacks: dummy_empower,
                                            dummy_vampirism_stacks: dummy_vampirism,
                                            dummy_poison_stacks: dummy_poison,
                                        })
                                    );

                                    if dummy_health == 0 {
                                        winner = PLAYER;
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
                                            } else if on_hit_item_type == EFFECT_VAMPIRISM {
                                                dummy_vampirism += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_POISON {
                                                char_poison += on_hit_item_stack;
                                            }
                                        }

                                        on_hit_items_len -= 1;
                                    };
                                    // ====== end ======

                                    if curr_item_data.itemType == 1 && damageCaused > 0 {
                                        // ====== Reflect effect: Deals 1 damage per stack when hit with a Melee weapon (up to 100% of the damage). ======
                                        if dummy_reflect > 0 {
                                            let reflect_damage = if dummy_reflect < damageCaused {
                                                dummy_reflect
                                            } else {
                                                damageCaused
                                            };

                                            // ====== Armor: used to absorb damage ======
                                            let reflectDamageCaused =  if reflect_damage <= char_armor {
                                                char_armor -= reflect_damage;
                                                0 
                                            } else {
                                                char_armor = 0;
                                                reflect_damage - char_armor
                                            };
                                            // ====== end ======

                                            if char_health <= reflectDamageCaused {
                                                char_health = 0;
                                            } else {
                                                char_health -= reflectDamageCaused;
                                            }

                                            battleLogsCount += 1;
                                            emit!(
                                                world,
                                                (BattleLogDetail {
                                                    player,
                                                    battleLogId: battleLogCounterCount,
                                                    id: battleLogsCount,
                                                    whoTriggered: DUMMY,
                                                    whichItem: 0,
                                                    damageCaused: reflectDamageCaused,
                                                    isDodged: false,
                                                    cleansePoison: 0,
                                                    buffType: EFFECT_REFLECT,
                                                    regenHP: 0,
                                                    player_remaining_health: char_health,
                                                    dummy_remaining_health: dummy_health,
                                                    player_stamina: char_stamina,
                                                    dummy_stamina: dummy_stamina,
                                                    player_armor_stacks: char_armor,
                                                    player_regen_stacks: char_regen,
                                                    player_reflect_stacks: char_reflect,
                                                    player_empower_stacks: char_empower,
                                                    player_vampirism_stacks: char_vampirism,
                                                    player_poison_stacks: char_poison,
                                                    dummy_armor_stacks: dummy_armor,
                                                    dummy_regen_stacks: dummy_regen,
                                                    dummy_reflect_stacks: dummy_reflect,
                                                    dummy_empower_stacks: dummy_empower,
                                                    dummy_vampirism_stacks: dummy_vampirism,
                                                    dummy_poison_stacks: dummy_poison,
                                                })
                                            );

                                            if char_health == 0 {
                                                winner = DUMMY;
                                                break;
                                            }
                                        }
                                        // ====== end ======

                                        // ====== Vampirism effect: Heals HP on Melee Weapon strike equal to amount of stacks, up to 100% of damage done. ======
                                        if char_vampirism > 0 {
                                            let vampirism_heal = if char_vampirism < damageCaused {
                                                char_vampirism
                                            } else {
                                                damageCaused
                                            };

                                            char_health += vampirism_heal;
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
                                                    whoTriggered: PLAYER,
                                                    whichItem: 0,
                                                    damageCaused: 0,
                                                    isDodged: false,
                                                    cleansePoison: 0,
                                                    buffType: EFFECT_VAMPIRISM,
                                                    regenHP: vampirism_heal,
                                                    player_remaining_health: char_health,
                                                    dummy_remaining_health: dummy_health,
                                                    player_stamina: char_stamina,
                                                    dummy_stamina: dummy_stamina,
                                                    player_armor_stacks: char_armor,
                                                    player_regen_stacks: char_regen,
                                                    player_reflect_stacks: char_reflect,
                                                    player_empower_stacks: char_empower,
                                                    player_vampirism_stacks: char_vampirism,
                                                    player_poison_stacks: char_poison,
                                                    dummy_armor_stacks: dummy_armor,
                                                    dummy_regen_stacks: dummy_regen,
                                                    dummy_reflect_stacks: dummy_reflect,
                                                    dummy_empower_stacks: dummy_empower,
                                                    dummy_vampirism_stacks: dummy_vampirism,
                                                    dummy_poison_stacks: dummy_poison,
                                                })
                                            );
                                        }
                                        // ====== end ======
                                    }
                                    
                                    // ====== char attack, to plus stacks ======
                                    let mut on_attack_items_len = char_on_attack_items_span.len();
                                    loop {
                                        if on_attack_items_len == 0 {
                                            break;
                                        }

                                        let (
                                            on_attack_item_type,
                                            on_attack_item_chance,
                                            on_attack_item_stack
                                        ) =
                                            *char_on_attack_items_span
                                            .at(on_attack_items_len - 1);

                                        if rand < on_attack_item_chance {
                                            if on_attack_item_type == EFFECT_ARMOR {
                                                char_armor += on_attack_item_stack;
                                            } else if on_attack_item_type == EFFECT_REGEN {
                                                char_regen += on_attack_item_stack;
                                            } else if on_attack_item_type == EFFECT_REFLECT {
                                                char_reflect += on_attack_item_stack;
                                            } else if on_attack_item_type == EFFECT_EMPOWER {
                                                char_empower += on_attack_item_stack;
                                            } else if on_attack_item_type == EFFECT_VAMPIRISM {
                                                char_vampirism += on_attack_item_stack;
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
                                                player_stamina: char_stamina,
                                                dummy_stamina: dummy_stamina,
                                                player_armor_stacks: char_armor,
                                                player_regen_stacks: char_regen,
                                                player_reflect_stacks: char_reflect,
                                                player_empower_stacks: char_empower,
                                                player_vampirism_stacks: char_vampirism,
                                                player_poison_stacks: char_poison,
                                                dummy_armor_stacks: dummy_armor,
                                                dummy_regen_stacks: dummy_regen,
                                                dummy_reflect_stacks: dummy_reflect,
                                                dummy_empower_stacks: dummy_empower,
                                                dummy_vampirism_stacks: dummy_vampirism,
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
                                if curr_item_data.vampirismActivation == 3 {
                                    dummy_vampirism += curr_item_data.vampirism;
                                }
                                if curr_item_data.poisonActivation == 3 {
                                    char_poison += curr_item_data.poison;
                                }
                                // ====== end ======

                                if curr_item_data.energyCost > dummy_stamina {
                                    // Not enough stamina, skip this activation
                                    i += 1;
                                    continue;
                                }
                                // Deduct stamina
                                dummy_stamina -= curr_item_data.energyCost;

                                if curr_item_data.itemType == 1 && dummy_empower > 0 {
                                    damage += dummy_empower;
                                }

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
                                            player_stamina: char_stamina,
                                            dummy_stamina: dummy_stamina,
                                            player_armor_stacks: char_armor,
                                            player_regen_stacks: char_regen,
                                            player_reflect_stacks: char_reflect,
                                            player_empower_stacks: char_empower,
                                            player_vampirism_stacks: char_vampirism,
                                            player_poison_stacks: char_poison,
                                            dummy_armor_stacks: dummy_armor,
                                            dummy_regen_stacks: dummy_regen,
                                            dummy_reflect_stacks: dummy_reflect,
                                            dummy_empower_stacks: dummy_empower,
                                            dummy_vampirism_stacks: dummy_vampirism,
                                            dummy_poison_stacks: dummy_poison,
                                        })
                                    );

                                    if char_health == 0 {
                                        winner = DUMMY;
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
                                            } else if on_hit_item_type == EFFECT_VAMPIRISM {
                                                char_vampirism += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_POISON {
                                                dummy_poison += on_hit_item_stack;
                                            } 
                                        }

                                        on_hit_items_len -= 1;
                                    };
                                    // ====== end ======

                                    if curr_item_data.itemType == 1 && damageCaused > 0 {
                                        // ====== Reflect effect: Deals 1 damage per stack when hit with a Melee weapon (up to 100% of the damage). ======
                                        if char_reflect > 0 {
                                            let reflect_damage = if char_reflect < damageCaused {
                                                char_reflect
                                            } else {
                                                damageCaused
                                            };

                                            // ====== Armor: used to absorb damage ======
                                            let reflectDamageCaused =  if reflect_damage <= dummy_armor {
                                                dummy_armor -= reflect_damage;
                                                0 
                                            } else {
                                                dummy_armor = 0;
                                                reflect_damage - dummy_armor
                                            };
                                            // ====== end ======

                                            if dummy_health <= reflectDamageCaused {
                                                dummy_health = 0;
                                            } else {
                                                dummy_health -= reflectDamageCaused;
                                            }

                                            battleLogsCount += 1;
                                            emit!(
                                                world,
                                                (BattleLogDetail {
                                                    player,
                                                    battleLogId: battleLogCounterCount,
                                                    id: battleLogsCount,
                                                    whoTriggered: PLAYER,
                                                    whichItem: 0,
                                                    damageCaused: reflectDamageCaused,
                                                    isDodged: false,
                                                    cleansePoison: 0,
                                                    buffType: EFFECT_REFLECT,
                                                    regenHP: 0,
                                                    player_remaining_health: char_health,
                                                    dummy_remaining_health: dummy_health,
                                                    player_stamina: char_stamina,
                                                    dummy_stamina: dummy_stamina,
                                                    player_armor_stacks: char_armor,
                                                    player_regen_stacks: char_regen,
                                                    player_reflect_stacks: char_reflect,
                                                    player_empower_stacks: char_empower,
                                                    player_vampirism_stacks: char_vampirism,
                                                    player_poison_stacks: char_poison,
                                                    dummy_armor_stacks: dummy_armor,
                                                    dummy_regen_stacks: dummy_regen,
                                                    dummy_reflect_stacks: dummy_reflect,
                                                    dummy_empower_stacks: dummy_empower,
                                                    dummy_vampirism_stacks: dummy_vampirism,
                                                    dummy_poison_stacks: dummy_poison,
                                                })
                                            );

                                            if dummy_health == 0 {
                                                winner = PLAYER;
                                                break;
                                            }
                                        }
                                        // ====== end ======

                                        // ====== Vampirism effect: Heals HP on Melee Weapon strike equal to amount of stacks, up to 100% of damage done. ======
                                        if dummy_vampirism > 0 {
                                            let vampirism_heal = if dummy_vampirism < damageCaused {
                                                dummy_vampirism
                                            } else {
                                                damageCaused
                                            };

                                            dummy_health += vampirism_heal;
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
                                                    whoTriggered: DUMMY,
                                                    whichItem: 0,
                                                    damageCaused: 0,
                                                    isDodged: false,
                                                    cleansePoison: 0,
                                                    buffType: EFFECT_VAMPIRISM,
                                                    regenHP: vampirism_heal,
                                                    player_remaining_health: char_health,
                                                    dummy_remaining_health: dummy_health,
                                                    player_stamina: char_stamina,
                                                    dummy_stamina: dummy_stamina,
                                                    player_armor_stacks: char_armor,
                                                    player_regen_stacks: char_regen,
                                                    player_reflect_stacks: char_reflect,
                                                    player_empower_stacks: char_empower,
                                                    player_vampirism_stacks: char_vampirism,
                                                    player_poison_stacks: char_poison,
                                                    dummy_armor_stacks: dummy_armor,
                                                    dummy_regen_stacks: dummy_regen,
                                                    dummy_reflect_stacks: dummy_reflect,
                                                    dummy_empower_stacks: dummy_empower,
                                                    dummy_vampirism_stacks: dummy_vampirism,
                                                    dummy_poison_stacks: dummy_poison,
                                                })
                                            );
                                        }
                                        // ====== end ======
                                    }
                                    

                                    // ====== char attack, to plus stacks ======
                                    let mut on_attack_items_len = dummy_on_attack_items_span.len();
                                    loop {
                                        if on_attack_items_len == 0 {
                                            break;
                                        }

                                        let (
                                            on_attack_item_type,
                                            on_attack_item_chance,
                                            on_attack_item_stack
                                        ) =
                                            *dummy_on_attack_items_span
                                            .at(on_attack_items_len - 1);

                                        if rand < on_attack_item_chance {
                                            if on_attack_item_type == EFFECT_ARMOR {
                                                dummy_armor += on_attack_item_stack;
                                            } else if on_attack_item_type == EFFECT_REGEN {
                                                dummy_regen += on_attack_item_stack;
                                            } else if on_attack_item_type == EFFECT_REFLECT {
                                                dummy_reflect += on_attack_item_stack;
                                            } else if on_attack_item_type == EFFECT_EMPOWER {
                                                dummy_empower += on_attack_item_stack;
                                            } else if on_attack_item_type == EFFECT_VAMPIRISM {
                                                dummy_vampirism += on_attack_item_stack;
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
                                                player_stamina: char_stamina,
                                                dummy_stamina: dummy_stamina,
                                                player_armor_stacks: char_armor,
                                                player_regen_stacks: char_regen,
                                                player_reflect_stacks: char_reflect,
                                                player_empower_stacks: char_empower,
                                                player_vampirism_stacks: char_vampirism,
                                                player_poison_stacks: char_poison,
                                                dummy_armor_stacks: dummy_armor,
                                                dummy_regen_stacks: dummy_regen,
                                                dummy_reflect_stacks: dummy_reflect,
                                                dummy_empower_stacks: dummy_empower,
                                                dummy_vampirism_stacks: dummy_vampirism,
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
                                    player_stamina: char_stamina,
                                    dummy_stamina: dummy_stamina,
                                    player_armor_stacks: char_armor,
                                    player_regen_stacks: char_regen,
                                    player_reflect_stacks: char_reflect,
                                    player_empower_stacks: char_empower,
                                    player_vampirism_stacks: char_vampirism,
                                    player_poison_stacks: char_poison,
                                    dummy_armor_stacks: dummy_armor,
                                    dummy_regen_stacks: dummy_regen,
                                    dummy_reflect_stacks: dummy_reflect,
                                    dummy_empower_stacks: dummy_empower,
                                    dummy_vampirism_stacks: dummy_vampirism,
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
                                whoTriggered: DUMMY,
                                whichItem: 0,
                                damageCaused: char_poison,
                                isDodged: false,
                                cleansePoison: 0,
                                buffType: EFFECT_POISON,
                                regenHP: 0,
                                player_remaining_health: char_health,
                                dummy_remaining_health: dummy_health,
                                player_stamina: char_stamina,
                                dummy_stamina: dummy_stamina,
                                player_armor_stacks: char_armor,
                                player_regen_stacks: char_regen,
                                player_reflect_stacks: char_reflect,
                                player_empower_stacks: char_empower,
                                player_vampirism_stacks: char_vampirism,
                                player_poison_stacks: char_poison,
                                dummy_armor_stacks: dummy_armor,
                                dummy_regen_stacks: dummy_regen,
                                dummy_reflect_stacks: dummy_reflect,
                                dummy_empower_stacks: dummy_empower,
                                dummy_vampirism_stacks: dummy_vampirism,
                                dummy_poison_stacks: dummy_poison,
                            })
                        );

                        if char_health == 0 {
                            winner = DUMMY;
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
                                whoTriggered: PLAYER,
                                whichItem: 0,
                                damageCaused: dummy_poison,
                                isDodged: false,
                                cleansePoison: 0,
                                buffType: EFFECT_POISON,
                                regenHP: 0,
                                player_remaining_health: char_health,
                                dummy_remaining_health: dummy_health,
                                player_stamina: char_stamina,
                                dummy_stamina: dummy_stamina,
                                player_armor_stacks: char_armor,
                                player_regen_stacks: char_regen,
                                player_reflect_stacks: char_reflect,
                                player_empower_stacks: char_empower,
                                player_vampirism_stacks: char_vampirism,
                                player_poison_stacks: char_poison,
                                dummy_armor_stacks: dummy_armor,
                                dummy_regen_stacks: dummy_regen,
                                dummy_reflect_stacks: dummy_reflect,
                                dummy_empower_stacks: dummy_empower,
                                dummy_vampirism_stacks: dummy_vampirism,
                                dummy_poison_stacks: dummy_poison,
                            })
                        );

                        if dummy_health == 0 {
                            winner = PLAYER;
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
                                whoTriggered: PLAYER,
                                whichItem: 0,
                                damageCaused: 0,
                                isDodged: false,
                                cleansePoison: 0,
                                buffType: EFFECT_REGEN,
                                regenHP: char_regen,
                                player_remaining_health: char_health,
                                dummy_remaining_health: dummy_health,
                                player_stamina: char_stamina,
                                dummy_stamina: dummy_stamina,
                                player_armor_stacks: char_armor,
                                player_regen_stacks: char_regen,
                                player_reflect_stacks: char_reflect,
                                player_empower_stacks: char_empower,
                                player_vampirism_stacks: char_vampirism,
                                player_poison_stacks: char_poison,
                                dummy_armor_stacks: dummy_armor,
                                dummy_regen_stacks: dummy_regen,
                                dummy_reflect_stacks: dummy_reflect,
                                dummy_empower_stacks: dummy_empower,
                                dummy_vampirism_stacks: dummy_vampirism,
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
                                whoTriggered: DUMMY,
                                whichItem: 0,
                                damageCaused: 0,
                                isDodged: false,
                                cleansePoison: 0,
                                buffType: EFFECT_REGEN,
                                regenHP: dummy_regen,
                                player_remaining_health: char_health,
                                dummy_remaining_health: dummy_health,
                                player_stamina: char_stamina,
                                dummy_stamina: dummy_stamina,
                                player_armor_stacks: char_armor,
                                player_regen_stacks: char_regen,
                                player_reflect_stacks: char_reflect,
                                player_empower_stacks: char_empower,
                                player_vampirism_stacks: char_vampirism,
                                player_poison_stacks: char_poison,
                                dummy_armor_stacks: dummy_armor,
                                dummy_regen_stacks: dummy_regen,
                                dummy_reflect_stacks: dummy_reflect,
                                dummy_empower_stacks: dummy_empower,
                                dummy_vampirism_stacks: dummy_vampirism,
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

            battleLog.winner = winner;
            battleLog.seconds = seconds;
            set!(world, (battleLog));

            if winner == PLAYER {
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
