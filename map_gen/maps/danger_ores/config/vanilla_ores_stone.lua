-- Vanilla ores plus stone as a fourth main ore: the three vanilla entries come straight
-- from config/vanilla_ores.lua (one source of truth for the numbers), with a factory
-- stone entry using the same distance curves. Order is significant: it maps to ore
-- indices 1..4. Used by maps whose layouts need four main ores, e.g. the clean-border
-- partition maps (Tetrominoes, Voronoi), whose region colouring requires at least
-- 4 colours.
local b = require 'map_gen.shared.builders'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'
local vanilla_ores = require 'map_gen.maps.danger_ores.config.vanilla_ores'

local by_name = {}
for _, ore in ipairs(vanilla_ores) do
    by_name[ore.name] = ore
end

return {
    by_name['iron-ore'],
    by_name['copper-ore'],
    by_name['coal'],
    Factory.entry {
        name = 'stone',
        start = b.euclidean_value(0, 0.35),
        value = b.exponential_value(0, 0.07, 1.45)
    }
}
