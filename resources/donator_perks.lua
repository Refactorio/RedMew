-- TODO: implement ALL flags

local flags = {
    welcome_msg = "1",          -- T2. enables a message upon player join
    initial_items = "2",        -- T2. free fish + miners + furnaces on initial join
    team_mining = "3",          -- T3. boosts team manual mining speed while player is online
    train = "4",                -- T3. train saviour perk
    death_msg = "5",           -- T3. enables a message upon player death
    team_crafting = "6",       -- T3. boosts team manual crafting speed while player is online
    team_run = "7",            -- T4. boosts team run speed while player is online
    respawn_boost = "8",      -- T4. player runs faster for 30 seconds after respawn
    team_inventory = "9"      -- T5. boosts team inventory size for remainder of map
}
local tiers = {
    ["2"] = {
        [flags.welcome_msg] = true,
        [flags.initial_items] = true,
    },
    ["3"] = {
        [flags.train] = true,
        [flags.death_msg] = true,
        [flags.team_mining] = true
    },
    ["4"] = {
        [flags.team_crafting] = true,
    },
    ["5"] = {
        [flags.team_run] = true,
        [flags.respawn_boost] = true,
    },
    ["6"] = {
        [flags.team_inventory] = true,
    }
}

print(serpent.block({
    flags = flags,
    tiers = tiers
}))
return {
    flags = flags,
    tiers = tiers
}