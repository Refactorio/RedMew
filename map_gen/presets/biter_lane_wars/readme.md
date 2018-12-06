--

UPDATE THIS PROPERLY FOR GIT, REPLACE INFO.LUA




--[[ 
    Factorio Biter Lane Wars
    GAMEMODE BACKGROUND

    Map:        Each team spawns on a fighting lane. They MUST protect their building (electric smelter) from the wave of biters.
    Rounds:     Before a round starts, each player is placed on the starting island. Later a GUI will let them vote on the mode.
                To start with this will just be equal teams, with leftover players spectating.
                Aiming to balance so each round is 30-45 minutes.
    Waves:      Each wave lasts 30 seconds.
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

    Markets:    Each force/team has 3 markets at their defending end, around their smelter. These allow play to progress.
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
]]--

--[[

    Comments: I (Jay) don't want it to turn into tower defence. I'm considering adding no placable buildings in the first iteration. 
                   Maybe there will be some high health, low damage static turrets that the players can give ammo and repair, but not move. Not sure yet.


-- DEV FLOW
-- v1 - Static 4v4, 5v5 or 6v6 game of two teams. Extras must spectate.
    -- No team selection panel/voting. Just a start button.
    -- consider balance
-- v2 - Dynamic team selection. 
    -- Add multiple forces. 
    -- Add dynamic team selection GUI. N teams of M players each, selected upon in-game team reset after victory of the previous match.
    ]]--