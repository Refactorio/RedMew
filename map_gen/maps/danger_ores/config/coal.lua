local b = require 'map_gen.shared.builders'
local start_value = b.euclidean_value(50, 0)
local value = b.exponential_value(0, 0.035, 1.45)

local tiles = {
    [1] = 'dirt-1',
    [2] = 'dirt-2',
    [3] = 'dirt-3',
    [4] = 'dirt-4',
    [5] = 'dirt-5',
    [6] = 'dirt-6',
    [7] = 'dirt-7'
}

return {
    {
        name = 'coal',
        ['tiles'] = tiles,
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {{resource = b.resource(b.full_shape, 'coal', value), weight = 1}}
    },
    {
        name = 'copper-ore',
        ['tiles'] = tiles,
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {{resource = b.resource(b.full_shape, 'coal', value), weight = 1}}
    },
    {
        name = 'iron-ore',
        ['tiles'] = tiles,
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {{resource = b.resource(b.full_shape, 'coal', value), weight = 1}}
    },
    {
        name = 'stone',
        ['tiles'] = tiles,
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {{resource = b.resource(b.full_shape, 'coal', value), weight = 1}}
    }
}
