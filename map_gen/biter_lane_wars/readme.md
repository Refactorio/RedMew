#Factorio Biter Lane Wars

##Summary
Biter lane wars is a competitive player vs biter scenario. Each team is segregated from the others and must defend their building from waves of biters. Coin rewards from killing biters and

##Map
```
000000000000000000000000000
0 X 0 X 0 X 000 X 0 X 0 X 0
0   0   0   000   0   0   0
0TTT0TTT0TTT000TTT0TTT0TTT0
0   0   0   000   0   0   0
0   0   0   000   0   0   0
0   0   0   000   0   0   0
0   0   0   000   0   0   0
0   0   0   000   0   0   0
0   0   0   000   0   0   0
0           000           0
0     W     000     W     0
0     M     000     M     0
000000000000000000000000000
```

0 - void or water
T - indestructible, infinite-damage, enemy turrets
X - biter spawn locations
M - per-team market/spawn
W - the building the biters want to destroy/the players must protect

Each team has their own vertical strip of land. Each team's strip of land has 3 lanes that they must protect. Each team has a building they must protect. Destruction of this building is the loss condition for a team. Waves of biters periodically spawn at the tops of each lane.

##Waves

Waves are sent priodically.
At the start of a wave:
1) Each team gets their gold earnings determined by the amount of biters they have purchased for sending to opposing team
This makes them weigh up how much they want to spend early vs. how much they will earn back over time
It makes buying new weapons/armour/items/buffs a tactical choice of getting left behind in earnings and biter attack power
2) A group of biters spawn at the opposite end of the lane to the team's markets.
The amount and type of biters are determined by the buffs purchased from the creep market by the opposing team(s).
Each team must kill these biters before they reach and destroy their smelter.
Items/armour/weapons can be bought to make this easier.
Team-based buffs can be bought to increase kill/survival rate of the players or increase enemy difficulty for other teams.
As biters die they drop a small amount of gold. This mecehanic rewards team players who stay at the front and varies each player's gold slightly
Deaths:     Players may die as many times as needed to defeat the waves of biters. Each death adds 1 second to their respawn counter.
No corpse is left behind. The player respawns with all their items/armour at the markets. This stops tedium of having to go retrieve items.

##Markets
Each force/team has 3 markets at their defending end, around their smelter. These allow play to progress.
They are split into 3 markets to make their use clearer and quicker. They don't need to be visually different though.
Creep market
Items: Small, medium, big, behemoth biters. Small, medium, big, behemoth spitters. (Use the red crosses with descriptions)
Each creep you add costs the player gold but contributes to their attacking force and the team's wave earnings.
Purchasing an additional creep has 2 effects:
Adds to the player's team's gold delivery per player
Adds to the force attacking the enemy teams.
Item market
Items: repair packs, armour, weapons, ammo, capsules, land mines
Tome market
Description:
Items: team health buffs, recharge rate buffs, run speed modifiers, weapon damage buffs, etc.
We could do some of these buffs by selling science packs. We put the research speed up to v high so the second the science flasks are added
the science completes.
Comments: I (Jay) don't want it to turn into tower defence. I'm considering adding no placable buildings in the first iteration.
Maybe there will be some high health, low damage static turrets that the players can give ammo and repair, but not move. Not sure yet.


## Dev Milestones
###v1.0.0
- At the end of the warmup/setup period, players get assigned to teams and the map is generated with lanes for each team.
- No team selection panel/voting. The game starts 90 secs after the first player joins.

###v1.1.0
- Add dynamic team selection GUI. N teams of M players each, selected upon in-game team reset after victory of the previous match.
