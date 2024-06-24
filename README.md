# Warpack Masters Dojo Jam 4 Submission

### Project Summary

Warpack Masters is a competitive Player-versus-Player (PvP) game that combines inventory management and autobattler mechanics within a captivating fantasy theme.

Engage in battles with Warpacks teeming with uniquely shaped and potent items. Strategize to assemble formidable Warpacks to outsmart and defeat other players in intense matches. Customize your arsenal with a variety of rare and legendary items to create and dominate the game's meta.

### Quick Links
Play Now: [Warpack Masters Live](impulsedao.xyz/Warpack-Masters)
Source Code: [GitHub Repository](https://github.com/0xAsten/Warpack-Masters)
Follow Us: [Twitter @WarpackMasters](https://twitter.com/WarpackMasters)

### Team members

0xAsten - leading Cairo development | [github](https://github.com/0xAsten) / [twitter](https://twitter.com/0xasten)

0xKube - product & vibes curator | [github](https://github.com/0xKube) / [twitter](https://twitter.com/0xKube)

MrTrickster - Unity client developer | [website](https://mrtrickster.net)

KahanMajmudar - Cairo developer | [github](https://github.com/KahanMajmudar) / [twitter](https://twitter.com/KahanMajmudar)

Exxcuro - artist;

### Submission Tracks

> Warpack Masters submitting to Road to Mainnet, New World, and Unity tracks.


# Warpack Masters

## Instant matchmaking using contract storage TODO :: 
In autobattles and other fastpace games, providing instant feedback to a player is crucial. 
We're creating dummy characters within the world contract, and use mirror images for instant matchmaking.


# Version Updates

## V3

- Add buffs/debuffs (Regen, Armor, Reflect, Posion)
- Add new items

## V4

- Add Backpack Expansion feature
- Add new items include bags
- Add new effect `cleanse Poison`

## Alpha

- Add player_remaining_health and dummy_remaining_health to event BattleLogDetail
- Add seconds property to BattleLog, record the duration of a battle
- Add log detail 0 with init value (like hp) of player and dummy
- Add two envents buyItem and sellItem
- Skip mirro dummy when battle
- Legendary items appear only for players with 3+ wins 
- Add Empower buff
- Mutable dummy rating