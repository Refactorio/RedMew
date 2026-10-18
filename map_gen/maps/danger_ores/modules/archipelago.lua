-- Archipelago: ore islands in a sea, in place of the usual perlin lakes. Each coast shades
-- from mud into walkable shallows, then water, then deep open sea. Landfill works on all of
-- them, so the sea is building space that costs stone instead of ore that has to be mined
-- out. Islands close enough together are joined only by shallows: walkable, but building
-- across still needs landfill.
--
-- Spawn always sits on land out to spawn_island_radius, so every ore sector reaches the
-- spawn island; beyond it the push toward land fades out over spawn_island_fade.
--
-- Two octaves of noise give large islands with ragged coasts. With the sea as the majority
-- the land falls below the point where it joins up, so it breaks into separate islands of
-- all sizes rather than a continent with lakes.
local Perlin = require 'map_gen.shared.perlin_noise'
local seed_provider = require 'map_gen.maps.danger_ores.modules.seed_provider'

local perlin_noise = Perlin.noise
local sqrt = math.sqrt

return function(config)
    local island_scale = config.archipelago_island_scale or 1 / 256
    local coast_scale = config.archipelago_coast_scale or 1 / 64
    local coast_weight = config.archipelago_coast_weight or 0.25
    -- the two octaves sum to roughly normal noise with a median of 0 that changes by about
    -- 0.01 per tile: -0.073 leaves about 62% of the map as sea; its first ~1.5 tiles are mud,
    -- the next ~6 walkable shallows, then a thin band of water before the deep sea at 0.02
    local mud_threshold = config.archipelago_mud_threshold or -0.073
    local shallow_threshold = config.archipelago_shallow_threshold or -0.058
    local water_threshold = config.archipelago_water_threshold or 0.005
    local deepwater_threshold = config.archipelago_deepwater_threshold or 0.02
    local spawn_island_radius = config.archipelago_spawn_island_radius or 120
    local spawn_island_fade = config.archipelago_spawn_island_fade or 120
    local island_seed = config.archipelago_island_seed or seed_provider()
    local coast_seed = config.archipelago_coast_seed or seed_provider()

    local island_weight = 1 - coast_weight
    local spawn_island_radius_sq = spawn_island_radius * spawn_island_radius
    local spawn_reach = spawn_island_radius + spawn_island_fade
    local spawn_reach_sq = spawn_reach * spawn_reach

    return function(x, y)
        local r_sq = x * x + y * y
        if r_sq < spawn_island_radius_sq then
            return false
        end

        local n = island_weight * perlin_noise(x * island_scale, y * island_scale, island_seed)
            + coast_weight * perlin_noise(x * coast_scale, y * coast_scale, coast_seed)

        -- push toward land, from enough to beat any noise at the island's edge down to nothing,
        -- so the coast eases out of the circle instead of following it
        if r_sq < spawn_reach_sq then
            n = n - (spawn_reach - sqrt(r_sq)) / spawn_island_fade
        end

        if n >= deepwater_threshold then
            return 'deepwater'
        elseif n >= water_threshold then
            return 'water'
        elseif n >= shallow_threshold then
            return 'water-shallow'
        elseif n >= mud_threshold then
            return 'water-mud'
        end

        return false
    end
end
