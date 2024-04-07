# Warpack Masters Dojo Jam 4 Submission

### Project Summary

Warpack Masters is a competitive Player-versus-Player (PvP) game that combines inventory management and autobattler mechanics within a captivating fantasy theme.

Engage in battles with Warpacks teeming with uniquely shaped and potent items. Strategize to assemble formidable Warpacks to outsmart and defeat other players in intense matches. Customize your arsenal with a variety of rare and legendary items to create and dominate the game's meta.

### Quick Links
Play Now: [Warpack Masters Live](impulsedao.xyz/Warpack-Masters)
Source Code: [GitHub Repository](https://github.com/0xAsten/Warpack-Masters)
Follow Us: [Twitter @WarpackMasters](x.com/@Warpackmasters)

### Team members

0xAsten - leading Cairo development | [github](https://github.com/0xAsten) / [twitter](https://twitter.com/0xasten)

0xKube - product & vibes curator | [github](https://github.com/0xKube) [twitter](https://twitter.com/0xKube)

MrTrickster - Unity client developer | [website](mrtrickster.net)

KahanMajmudar - Cairo developer | [github](https://github.com/KahanMajmudar) / [twitter](https://twitter.com/KahanMajmudar)

Exxcuro - artist;

### Submission Tracks

> Warpack Masters submitting to Road to Mainnet, New World, and Unity tracks.


# Warpack Masters

## Instant matchmaking using contract storage TODO :: 
In autobattles and other fastpace games it's crucially importnant to provide instant feedback to a player. 
We're creating dummy characters within the wolrd contract, and use mirror-images for instant matchmaking.


## Backpack

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