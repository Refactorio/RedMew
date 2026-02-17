local b = require 'map_gen.shared.builders'

local mine_speed = 0.5 / 10 -- 0.5 ore/s per electric mining drill
local low = 60 * 60 * 4 * mine_speed -- 4h
local medium = 60 * 60 * 24 * mine_speed -- 24h

local low_value = b.exponential_value(low, 0.07, 1.45)
local medium_value = b.exponential_value(medium, 0.07, 1.45)

return {
    {
        name = 'copper-ore',
        tiles = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
        },
        start = 1,
        weight = 1,
        ratios = {
            {resource = b.resource(b.full_shape, 'iron-ore', medium_value), weight = 15},
            {resource = b.resource(b.full_shape, 'copper-ore', medium_value), weight = 70},
            {resource = b.resource(b.full_shape, 'stone', medium_value), weight = 10},
            {resource = b.resource(b.full_shape, 'coal', medium_value), weight = 5}
        }
    },
    {
        name = 'coal',
        tiles = {
            [1] = 'dirt-1',
            [2] = 'dirt-2',
            [3] = 'dirt-3',
            [4] = 'dirt-4',
            [5] = 'dirt-5',
            [6] = 'dirt-6',
            [7] = 'dirt-7'
        },
        start = 1,
        weight = 1,
        ratios = {
            {resource = b.resource(b.full_shape, 'iron-ore', low_value), weight = 18},
            {resource = b.resource(b.full_shape, 'copper-ore', low_value), weight = 9},
            {resource = b.resource(b.full_shape, 'stone', low_value), weight = 8},
            {resource = b.resource(b.full_shape, 'coal', low_value), weight = 65}
        }
    },
    {
        name = 'iron-ore',
        tiles = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        start = 1,
        weight = 1,
        ratios = {
            {resource = b.resource(b.full_shape, 'iron-ore', medium_value), weight = 75},
            {resource = b.resource(b.full_shape, 'copper-ore', medium_value), weight = 13},
            {resource = b.resource(b.full_shape, 'stone', medium_value), weight = 7},
            {resource = b.resource(b.full_shape, 'coal', medium_value), weight = 5}
        }
    },
    {
        name = 'stone',
        tiles = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        start = 1,
        weight = 1,
        ratios = {
            {resource = b.resource(b.full_shape, 'iron-ore', medium_value), weight = 25},
            {resource = b.resource(b.full_shape, 'copper-ore', medium_value), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', medium_value), weight = 60},
            {resource = b.resource(b.full_shape, 'coal', medium_value), weight = 5}
        }
    },
    {
        name = 'uranium-ore',
        start = 1,
        weight = 1,
        ratios = {
            {
                resource = b.resource(b.full_shape, 'uranium-ore', function() return 1e6 end),
                weight = 1
            },
        }
    }
}
