local b = require 'map_gen.shared.builders'
local start_value = b.exponential_value(0, 0.15, 1.3)
local value = b.exponential_value(0, 0.15, 1.3)

return {
    {
        name = 'copper-ore',
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
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
            [1] = 'dirt-1',
            [2] = 'dirt-2',
            [3] = 'dirt-3',
            [4] = 'dirt-4',
            [5] = 'dirt-5',
            [6] = 'dirt-6',
            [7] = 'dirt-7'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 14},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 6},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 10},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 70}
        }
    },
    {
        name = 'iron-ore',
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
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
    {
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
    }
}
