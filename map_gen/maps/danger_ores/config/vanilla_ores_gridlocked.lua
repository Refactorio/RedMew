local b = require 'map_gen.shared.builders'
local start_value = b.euclidean_value(50, 0.75)
local value = b.exponential_value(50, 0.003, 2.25)

return {
    {
        name = 'iron-ore',
        tiles = {
            [1] = 'landfill',
        },
        start = start_value,
        weight = 10,
        ratios = {
            { resource = b.resource(b.full_shape, 'iron-ore',   value), weight = 75 },
            { resource = b.resource(b.full_shape, 'copper-ore', value), weight = 13 },
            { resource = b.resource(b.full_shape, 'stone',      value), weight =  7 },
            { resource = b.resource(b.full_shape, 'coal',       value), weight =  5 },
        },
    },
    {
        name = 'coal',
        tiles = {
            [1] = 'landfill',
        },
        start = start_value,
        weight = 8,
        ratios = {
            { resource = b.resource(b.full_shape, 'iron-ore',   value), weight = 18 },
            { resource = b.resource(b.full_shape, 'copper-ore', value), weight =  9 },
            { resource = b.resource(b.full_shape, 'stone',      value), weight =  8 },
            { resource = b.resource(b.full_shape, 'coal',       value), weight = 65 },
        },
    },
    {
        name = 'copper-ore',
        tiles = {
            [1] = 'landfill',
        },
        start = start_value,
        weight = 7,
        ratios = {
            { resource = b.resource(b.full_shape, 'iron-ore',   value), weight = 15 },
            { resource = b.resource(b.full_shape, 'copper-ore', value), weight = 70 },
            { resource = b.resource(b.full_shape, 'stone',      value), weight = 10 },
            { resource = b.resource(b.full_shape, 'coal',       value), weight =  5 },
        },
    },
    {
        name = 'stone',
        tiles = {
            [1] = 'landfill',
        },
        start = start_value,
        weight = 2,
        ratios = {
            { resource = b.resource(b.full_shape, 'iron-ore',   value), weight = 25 },
            { resource = b.resource(b.full_shape, 'copper-ore', value), weight = 10 },
            { resource = b.resource(b.full_shape, 'stone',      value), weight = 60 },
            { resource = b.resource(b.full_shape, 'coal',       value), weight =  5 },
        },
    },
}
