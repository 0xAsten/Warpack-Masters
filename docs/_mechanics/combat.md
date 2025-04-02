---
title: Combat System
description: Detailed explanation of the combat mechanics
related_mechanics: [status-effects, items, rebirth]
---

# Combat System

The combat system in Warpack Masters is an automated turn-based system that runs for up to 25 seconds per battle. Your preparation before the battle determines your success.

## Core Mechanics

### Battle Flow

1. **Preparation Phase**: Before combat, you place items in your grid
2. **Battle Execution**: Click "Fight" to execute the automated battle
3. **Resolution**: Battle ends when one character reaches 0 health or time runs out

### Time and Turns

- Battles last up to 25 seconds
- Each second is treated as a turn in the combat system
- Item cooldowns are measured in seconds
- If time runs out, the character with more health wins

### Resources

#### Health
- Character health increases as you progress (win battles)
- At wins < 5, you gain +10 health per win
- At win 5, you gain +15 health

#### Stamina
- Initial stamina is 100 (defined as `INIT_STAMINA`)
- Regenerates at 10 points per second after the first second
- Each item activation consumes stamina
- If you don't have enough stamina, the item won't activate

## Item Activation

Items are the core of combat in Warpack Masters. There are four ways items can activate:

1. **On Start (1)**: Applies at the beginning of battle (usually buffs/debuffs)
2. **On Hit (2)**: Triggers when the character is hit by an enemy
3. **On Cooldown (3)**: Activates every X seconds (where X is the cooldown value)
4. **On Attack (4)**: Triggers when the character attacks an enemy

The code representation is shown in parentheses.

### Cooldown Mechanics

Items with cooldowns (usually 4, 5, 6, or 7 seconds) will activate periodically:

```
if seconds % cooldown == 0 && rand < chance {
    // Item activates
}
```

Where:
- `seconds` is the current battle second
- `cooldown` is the item's cooldown value
- `chance` is the activation chance percentage
- `rand` is a random number between 0-100

## Status Effects

Status effects are applied by items and stack with each other:

| Effect Type | Code Value | Description |
|-------------|------------|-------------|
| Damage | 1 | Direct damage to opponent's health (after armor) |
| Cleanse Poison | 2 | Removes poison stacks |
| Armor | 3 | Absorbs damage until depleted |
| Regen | 4 | Heals 1 HP per stack every 2 seconds |
| Reflect | 5 | Returns damage when hit by melee (up to 100% of damage) |
| Poison | 6 | Deals 1 damage per stack every 2 seconds |
| Empower | 7 | Increases weapon damage |
| Vampirism | 8 | Heals when dealing melee damage (up to 100% of damage) |

### Periodic Effects

Some effects trigger every 2 seconds:

- **Poison**: Damages the affected character by [stacks] amount
- **Regen**: Heals the affected character by [stacks] amount

## Damage Calculation

Damage is calculated in this order:

1. Base damage from the attacking item
2. Add Empower bonus if applicable
3. Apply plugin effects if activated (by chance)
4. Subtract target's armor (armor is depleted first)
5. Apply remaining damage to target's health
6. If target has Reflect and attacked by melee, apply reflect damage
7. If attacker has Vampirism and using melee, heal based on damage dealt

## Rewards and Progression

### Victory Rewards
- 5 gold
- Rating increase (base 25 + win streak bonus)
- Health increase (for early progression)
- Win streak bonus increases with consecutive wins

### Defeat Penalties
- 2 gold
- Rating decrease (10 points)
- Loss counter increases
- Win streak resets to 0

After 5 losses, a character must use the rebirth system to continue.