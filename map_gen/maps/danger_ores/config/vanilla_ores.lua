local b = require 'map_gen.shared.builders'
local value = b.euclidean_value

return {
    ['copper-ore'] = {
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
        },
        ['start'] = value(75, 0),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 65},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 3},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 12}
        }
    },
    ['coal'] = {
        ['tiles'] = {
            [1] = 'dirt-1',
            [2] = 'dirt-2',
            [3] = 'dirt-3',
            [4] = 'dirt-4',
            [5] = 'dirt-5',
            [6] = 'dirt-6',
            [7] = 'dirt-7'
        },
        ['start'] = value(75, 0),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 3},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 57}
        }
    },
    ['iron-ore'] = {
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = value(75, 0),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 65},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 3},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 12}
        }
    },
    ['stone'] = {
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = value(75, 0),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 50},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10}
        }
    }
}
