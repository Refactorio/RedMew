local b = require 'map_gen.shared.builders'
local start_value = b.euclidean_value(0, 0.35)
local value = b.exponential_value(0, 0.06, 1.55)

return {
    {
        name = 'copper-ore',
        ['tiles'] = {
            [1] = 'landfill'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 15},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 70},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 10},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 5}
        }
    },
    {
        name = 'coal',
        ['tiles'] = {
            [1] = 'landfill'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 18},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 9},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 8},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 65}
        }
    },
    {
        name = 'iron-ore',
        ['tiles'] = {
            [1] = 'landfill'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 75},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 13},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 7},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 5}
        }
    },
    --[[ {
        name = 'stone',
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 25},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 60},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 5}
        }
    } ]]
}
