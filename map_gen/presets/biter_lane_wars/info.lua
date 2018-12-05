--[[ GAMEMODE BACKGROUND

    Map:        Each team spawns on a fighting lane. They MUST protect their building (electric smelter) from the hoarde of biters.
    Rounds:     Before a round starts, each player is placed on the starting island. A GUI lets them vote on the mode.
                To start with this will just be equal teams, with leftover players spectating.
                Aiming to balance so each round is 30-45 minutes.
    Periods:    Each period lasts 30 seconds. At the start of each period
    Markets: Each force/team has 3 markets at their defending end, around their smelter. These allow play to progress.
            Creep market
                Items: Small, medium, big, behemoth biters. Small, medium, big, behemoth spitters.
                Each creep you add costs the player gold but contributes to their force.
                Purchasing an additional creep has 2 effects:
                    Adds to the player's team's gold delivery per player
            Item market
                Items: repair packs,
            Tome market
                Kill All (100g)             Kills all biters this wave for a brief respite
                Team Run Speed (100g)       + 10% run speed
                Loot (500g)                 + 10% coin drops

    Comments: I don't want it to turn into tower defence. I'm considering adding no placable buildings in the first iteration.
                   Maybe there will be some high health, low damage static turrets that the players can give ammo and repair, but not move. Not sure yet.


-- GAMEPLAY FLOW


-- DEV FLOW
-- v1 - Static 4v4, 5v5 or 6v6 game of two teams. Extras must spectate.
    -- No team selection panel/voting. Just a start button.
    -- consider balance
-- v2 - Dynamic team selection.
    -- Add multiple forces.
    -- Add dynamic team selection GUI. N teams of M players each, selected upon in-game team reset after victory of the previous match.
    ]]--