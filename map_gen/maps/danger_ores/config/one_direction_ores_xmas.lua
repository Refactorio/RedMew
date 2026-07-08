-- The xmas variant of the One Direction ores: exponential start (no guaranteed-rich
-- spawn), and the darkest dirt/grass shades dropped for a snowier look.
local b = require 'map_gen.shared.builders'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

local value = b.exponential_value(0, 0.15, 1.3)

return Factory.main_ores {
    ores = {
        'copper-ore',
        {name = 'coal', tiles = {'dirt-1', 'dirt-2', 'dirt-3', 'dirt-5', 'dirt-6', 'dirt-7'}},
        {name = 'iron-ore', tiles = {'grass-2', 'grass-3', 'grass-4'}}
    },
    start = value,
    value = value
}
