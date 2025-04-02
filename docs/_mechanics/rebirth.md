---
title: Rebirth System
description: Detailed explanation of the rebirth mechanics
related_mechanics: [combat, items]
---

# Rebirth System

The rebirth system in Warpack Masters is a core progression mechanic that allows players to reset and start fresh after accumulating 5 losses, while maintaining certain progress aspects.

## When to Rebirth

Rebirth becomes mandatory when you reach 5 losses. At this point, you cannot participate in further battles until you go through the rebirth process.

## Rebirth Cost

Rebirth has an associated cost in STRK tokens (the game's currency):

- The cost is defined as `REBIRTH_FEE` in the game constants
- You must have enough STRK tokens in your wallet to complete the rebirth

## What Resets

The rebirth process resets several aspects of your character:

1. **Inventory**: All items in your inventory grid are removed
2. **Storage**: All items in your storage are removed
3. **Backpack Grid**: All grid spaces are disabled
4. **Shop**: Shop inventory is cleared
5. **Health**: Reset to initial health value
6. **Gold**: Reset to initial gold value plus 1 extra for shop reroll
7. **Wins/Losses**: Reset to 0
8. **Win Streak**: Reset to 0

## What Persists

Despite the reset, several important aspects of your character persist:

1. **Name**: Your character name remains the same
2. **Class**: Your chosen class is preserved
3. **Rating**: Your accumulated rating remains
4. **Total Wins**: The lifetime wins counter is preserved
5. **Total Losses**: The lifetime losses counter is preserved
6. **Birth Count**: Increases by 1 with each rebirth, tracking your progression

## Starting Fresh

After rebirth, your character begins with:

1. **Default Backpacks**: Two backpack items (Backpack and Pack)
2. **Initial Resources**: Base health and stamina
3. **Gold**: Initial gold amount (INIT_GOLD) plus 1 extra for shop reroll

## Rebirth Strategy

The rebirth system creates interesting strategic decisions:

- When to voluntarily rebirth before hitting 5 losses
- How to balance short-term success vs. long-term progression
- Whether to spend resources before rebirthing
- How to adapt your strategy based on accumulated knowledge

## Technical Implementation

The rebirth process follows these steps in the code:

1. Verify the player has reached 5 losses
2. Collect the STRK token fee
3. Save the character's persistent data (name, class, rating, etc.)
4. Clear all items from inventory and storage
5. Reset all grid spaces to disabled
6. Clear the shop inventory
7. Reset counters for inventory and storage
8. Create a fresh character with the preserved data
9. Increment the birth count
10. Add the two default backpack items
11. Place the backpack items on the grid

## Rebirth and Progression

While rebirth resets many aspects of your character, it's an essential part of the overall progression:

- Higher birth counts might unlock special features
- The persisting rating allows for matchmaking appropriate to your skill level
- Knowledge gained from previous runs helps optimize future strategies

