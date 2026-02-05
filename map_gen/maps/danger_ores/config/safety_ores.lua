local MGSP = require 'resources.map_gen_settings'

local Public = {}

-- == ALLOWED ENTITIES ========================================================

local allowed_types = require 'map_gen.maps.danger_ores.config.vanilla_allowed_entities'
-- + Allowed
allowed_types['combat-robot'] = true
allowed_types['construction-robot'] = true
allowed_types['logistic-robot'] = true
allowed_types['offshore-pump'] = true
-- - Allowed
allowed_types['transport-belt'] = nil
allowed_types['underground-belt'] = nil
allowed_types['tile-ghost'] = nil

local allowed_entities = {}

for entity_type in pairs(allowed_types) do
    for name in pairs(prototypes.get_entity_filtered{{ filter = 'type', type = entity_type }}) do
        allowed_entities[#allowed_entities+1] = name
    end
end

Public.allowed_entities = allowed_entities

-- == MAP GEN SETTINGS ========================================================

--- Ore Settings. Since we can only build on ore patches high size is recommended.
--- With high size, lower richness seems intuitive. Frequency is the big ???
local ore_size = 6
local ore_richness = 0.166
local ore_freq = 0.166

--- Create map_gen table for ores
local ore_settings = {
    autoplace_controls = {
        coal = {
            frequency = ore_freq,
            richness = ore_richness,
            size = ore_size,
        },
        ['copper-ore'] = {
            frequency = ore_freq,
            richness = ore_richness,
            size = ore_size,
        },
        ['crude-oil'] = {
            frequency = 0.25,
            richness = 2,
            size = 0.25,
        },
        ['iron-ore'] = {
            frequency = ore_freq,
            richness = ore_richness,
            size = ore_size,
        },
        stone = {
            frequency = ore_freq,
            richness = ore_richness,
            size = ore_size,
        },
        ['uranium-ore'] = {
            frequency = ore_freq,
            richness = ore_richness,
            size = ore_size,
        },
    },
}

--- Enemy autoplace controls
local enemy_settings = {
    autoplace_controls = {
        ['enemy-base'] = {
            frequency = 0.25,
            richness = 1,
            size = 1,
        },
    },
}

Public.map_gen_settings = {
    MGSP.default,
    ore_settings,
    enemy_settings,
}

-- ============================================================================

return Public
