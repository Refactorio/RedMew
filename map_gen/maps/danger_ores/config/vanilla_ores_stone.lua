-- Vanilla ores plus stone as a fourth main ore: the three vanilla entries come straight
-- from config/vanilla_ores.lua (one source of truth for the numbers), with a stone entry
-- using the same distance curves. Order is significant: it maps to ore indices 1..4.
-- Used by maps whose layouts need four main ores, e.g. the clean-border partition maps
-- (Tetrominoes, Voronoi), whose region colouring requires at least 4 colours.
local b = require 'map_gen.shared.builders'
local vanilla_ores = require 'map_gen.maps.danger_ores.config.vanilla_ores'

local by_name = {}
for _, ore in ipairs(vanilla_ores) do
    by_name[ore.name] = ore
end

local start_value = b.euclidean_value(0, 0.35)
local value = b.exponential_value(0, 0.07, 1.45)

return {
    by_name['iron-ore'],
    by_name['copper-ore'],
    by_name['coal'],
    {
        name = 'stone',
        tiles = { 'sand-1', 'sand-2', 'sand-3' },
        start = start_value,
        weight = 1,
        ratios = {
            { resource = b.resource(b.full_shape, 'iron-ore', value), weight = 25 },
            { resource = b.resource(b.full_shape, 'copper-ore', value), weight = 10 },
            { resource = b.resource(b.full_shape, 'stone', value), weight = 60 },
            { resource = b.resource(b.full_shape, 'coal', value), weight = 5 },
        },
    },
}
