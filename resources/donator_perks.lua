return {
    rank = 0x1,                 -- T1
    train = 0x2,                -- T3. train saviour perk
    welcome_msg = 0x4,          -- T2. enables a message upon player join
    team_mining = 0x8,          -- T2. boosts team manual mining speed while player is online
    death_msg = 0x10,           -- T3. enables a message upon player death
    team_crafting = 0x20,       -- T3. boosts team manual crafting speed while player is online
    team_run = 0x40,            -- T4. boosts team run speed while player is online
    respawn_boost = 0x80,      -- T4. player runs faster for 30 seconds after respawn
    team_inventory = 0x160      -- T5. boosts team inventory size for remainder of map
}

-- 2021-12-30
-- Tier 1 = 1
-- Tier 2 = 8 + 4 + 1 = 21
-- Tier 3 = 8 + 4 + 1 + 16 + 32 + 2=  63
-- Tier 4 = 63 + 64 + 128 = 255
-- Tier 5 = 255 + 256 = 511