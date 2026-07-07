local b = require 'map_gen.shared.builders'
local start_value = b.euclidean_value(0, 0.35)
local value = b.exponential_value(0, 0.07, 1.45)

-- Order is significant: it maps to room ore indices 1..4 from the city_blocks module.
-- Heavier dominant ratio (85/15) than the vanilla sectors: each room is meant to be
-- one resource, so hauling between rooms by train stays essential.
return {
    {
        name = 'iron-ore',
        tiles = { 'grass-1', 'grass-2', 'grass-3', 'grass-4' },
        start = start_value,
        weight = 1,
        ratios = {
            { resource = b.resource(b.full_shape, 'iron-ore', value), weight = 85 },
            { resource = b.resource(b.full_shape, 'copper-ore', value), weight = 5 },
            { resource = b.resource(b.full_shape, 'stone', value), weight = 5 },
            { resource = b.resource(b.full_shape, 'coal', value), weight = 5 },
        },
    },
    {
        name = 'copper-ore',
        tiles = { 'red-desert-0', 'red-desert-1', 'red-desert-2', 'red-desert-3' },
        start = start_value,
        weight = 1,
        ratios = {
            { resource = b.resource(b.full_shape, 'iron-ore', value), weight = 5 },
            { resource = b.resource(b.full_shape, 'copper-ore', value), weight = 85 },
            { resource = b.resource(b.full_shape, 'stone', value), weight = 5 },
            { resource = b.resource(b.full_shape, 'coal', value), weight = 5 },
        },
    },
    {
        name = 'coal',
        tiles = { 'dirt-1', 'dirt-2', 'dirt-3', 'dirt-4', 'dirt-5', 'dirt-6', 'dirt-7' },
        start = start_value,
        weight = 1,
        ratios = {
            { resource = b.resource(b.full_shape, 'iron-ore', value), weight = 5 },
            { resource = b.resource(b.full_shape, 'copper-ore', value), weight = 5 },
            { resource = b.resource(b.full_shape, 'stone', value), weight = 5 },
            { resource = b.resource(b.full_shape, 'coal', value), weight = 85 },
        },
    },
    {
        name = 'stone',
        tiles = { 'sand-1', 'sand-2', 'sand-3' },
        start = start_value,
        weight = 1,
        ratios = {
            { resource = b.resource(b.full_shape, 'iron-ore', value), weight = 5 },
            { resource = b.resource(b.full_shape, 'copper-ore', value), weight = 5 },
            { resource = b.resource(b.full_shape, 'stone', value), weight = 85 },
            { resource = b.resource(b.full_shape, 'coal', value), weight = 5 },
        },
    },
}
