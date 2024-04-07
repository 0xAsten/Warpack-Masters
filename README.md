# Warpack Masters Dojo Jam 4 Submission

### Project Summary

Warpack Masters - Player-versus-Player (PvP) inventory management & autobattler game in the fantasy setting!

Fight with your Warpacks filled with items. Items have different shapes and effects.
Assemble the best Warpack and fight other players!
Customise your build with rare and legendary items. Create the meta.


### GitHub

> [Github - Warpack Masters ](https://github.com/0xAsten/Warpack-Masters)

### Play
Game is live at (impulsedao.xyz/Warpack-Masters)

### Twitter

> (x.com/@Warpackmasters)

### Team members

0xAsten - leading Cairo development
[github](https://github.com/0xAsten) / [twitter](https://twitter.com/0xasten)

KahanMajmudar - Cairo developer

[github](https://github.com/KahanMajmudar) / [twitter](https://twitter.com/KahanMajmudar)


MrTrickster - Unity client developer;

[site]()

Exxcuro - artist;


0xKube - product & vibes curator;

[github](https://github.com/0xKube) / [twitter](https://twitter.com/0xKube)


### Submission Tracks

> Warpack Masters submitting to Road to Mainnet, New World, and Unity tracks.

# Warpack Masters

## Backpack

The bag of the player. The default size is 9x7.

## Items property

- width
   
   Grids occupied by the item in the x-axis. The minimun is 1.

- height
   
   Grid occupied by the item in the y-axis. The minimun is 1.

- price

   The gold cost of the item.

- damage

   The damage the item does.

- armor

   The armor the item gives.

- chance

   The accuracy for damage if the item is a weapon. The chance to dodge if the item is armor.

- cooldown

   The time in seconds the item takes to be used again. The item only be used once if the cooldown is 0.

- heal

   The amount of health the item heals.

## Items extra property after bought

- where

   Placed in the inventory or in the storage

- position

   The first grid (x, y) occupied by the item in the inventory

- rotation

   Possible values: 0, 90, 180, 270.


## Models

### Backpack

purpose: To store the grid size of the player's backpack.

indexed: `player` type of `ContractAddress`

value: `grid` type of `Grid`

```
struct Grid {
    x: usize,
    y: usize
}
```

### BackpackGrids

purpose: To store the backpack grids indicating if they are occupied or not.

indexed:
- `player` type of `ContractAddress`
- `x` type of `usize`
- `y` type of `usize`

value: `occupied` type of `bool`