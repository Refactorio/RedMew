local b = require 'map_gen.shared.builders'
local start_value = b.exponential_value(0, 0.15, 1.3)
local value = b.exponential_value(0, 0.15, 1.3)

return {
    {
        name = 'iron-ore',
        tiles = {'grass-1', 'grass-2', 'grass-3', 'grass-4'},
        start = start_value,
        shape = b.resource(b.full_shape, 'iron-ore', value),
        weight = function(v)
            return 4 * (v ^ 4) + 0.25
        end
    },
    {
        name = 'coal',
        tiles = {'dirt-1', 'dirt-2', 'dirt-3', 'dirt-4', 'dirt-5', 'dirt-6', 'dirt-7'},
        start = start_value,
        shape = b.resource(b.full_shape, 'coal', value),
        weight = function(v)
            return 4 * (v ^ 4) + 0.2
        end
    },
    {
        name = 'copper-ore',
        tiles = {'red-desert-0', 'red-desert-1', 'red-desert-2', 'red-desert-3'},
        start = start_value,
        shape = b.resource(b.full_shape, 'copper-ore', value),
        weight = function(v)
            return 4 * (v ^ 4) + 0.2
        end
    },
    {
        name = 'stone',
        tiles = {'sand-1', 'sand-2', 'sand-3'},
        start = start_value,
        shape = b.resource(b.full_shape, 'stone', value),
        weight = function(v)
            return 0.5 * (v ^ 8) + 0.1
        end
    }
}
