local b = require 'map_gen.shared.builders'
local value = b.euclidean_value

return {
    {
        name = 'iron-ore',
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4',
        },
        ['start'] = value(125, 0),
        ['weight'] = 15,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 120 },
        },
    },
    {
        name = 'copper-ore',
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3',
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 120 },
        },
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
            [7] = 'dirt-7',
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 120 },
        },
    },
    {
        name = 'stone',
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3',
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 120 },
        },
    },
    {
        name = 'bob-bauxite-ore',
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4',
        },
        ['start'] = value(125, 0),
        ['weight'] = 2,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'bob-bauxite-ore', value(0, 0.5)), weight = 120 },
        },
    },
    {
        name = 'bob-cobalt-ore',
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3',
        },
        ['start'] = value(125, 0),
        ['weight'] = 0.05,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'bob-cobalt-ore', value(0, 0.5)), weight = 120 },
        },
    },
    {
        name = 'bob-gem-ore',
        ['tiles'] = {
            [1] = 'dirt-1',
            [2] = 'dirt-2',
            [3] = 'dirt-3',
            [4] = 'dirt-4',
            [5] = 'dirt-5',
            [6] = 'dirt-6',
            [7] = 'dirt-7',
        },
        ['start'] = value(125, 0),
        ['weight'] = 0.05,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'bob-gem-ore', value(0, 0.5)), weight = 120 },
        },
    },
    {
        name = 'bob-gold-ore',
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3',
        },
        ['start'] = value(125, 0),
        ['weight'] = 1,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'bob-gold-ore', value(0, 0.5)), weight = 120 },
        },
    },
    {
        name = 'bob-lead-ore',
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4',
        },
        ['start'] = value(125, 0),
        ['weight'] = 2,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'bob-lead-ore', value(0, 0.5)), weight = 120 },
        },
    },
    {
        name = 'bob-nickel-ore',
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3',
        },
        ['start'] = value(125, 0),
        ['weight'] = 2,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'bob-nickel-ore', value(0, 0.5)), weight = 120 },
        },
    },
    {
        name = 'bob-quartz',
        ['tiles'] = {
            [1] = 'dirt-1',
            [2] = 'dirt-2',
            [3] = 'dirt-3',
            [4] = 'dirt-4',
            [5] = 'dirt-5',
            [6] = 'dirt-6',
            [7] = 'dirt-7',
        },
        ['start'] = value(125, 0),
        ['weight'] = 2,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'bob-quartz', value(0, 0.5)), weight = 120 },
        },
    },
    {
        name = 'bob-rutile-ore',
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3',
        },
        ['start'] = value(125, 0),
        ['weight'] = 1,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'bob-rutile-ore', value(0, 0.5)), weight = 120 },
        },
    },
    {
        name = 'bob-silver-ore',
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4',
        },
        ['start'] = value(125, 0),
        ['weight'] = 1,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'bob-silver-ore', value(0, 0.5)), weight = 120 },
        },
    },
    {
        name = 'bob-sulfur',
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3',
        },
        ['start'] = value(125, 0),
        ['weight'] = 1,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'bob-sulfur', value(0, 0.5)), weight = 120 },
        },
    },
    {
        name = 'bob-tin-ore',
        ['tiles'] = {
            [1] = 'dirt-1',
            [2] = 'dirt-2',
            [3] = 'dirt-3',
            [4] = 'dirt-4',
            [5] = 'dirt-5',
            [6] = 'dirt-6',
            [7] = 'dirt-7',
        },
        ['start'] = value(125, 0),
        ['weight'] = 2,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'bob-tin-ore', value(0, 0.5)), weight = 120 },
        },
    },
    {
        name = 'bob-tungsten-ore',
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3',
        },
        ['start'] = value(125, 0),
        ['weight'] = 1,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'bob-tungsten-ore', value(0, 0.5)), weight = 120 },
        },
    },
    {
        name = 'bob-zinc-ore',
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4',
        },
        ['start'] = value(125, 0),
        ['weight'] = 2,
        ['ratios'] = {
            { resource = b.resource(b.full_shape, 'bob-zinc-ore', value(0, 0.5)), weight = 120 },
        },
    },
}
