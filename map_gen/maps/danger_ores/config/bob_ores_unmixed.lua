local b = require 'map_gen.shared.builders'
local value = b.euclidean_value

return {
    {
        name = 'iron-ore',
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = value(125, 0),
        ['weight'] = 15,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 120}
        }
    },
    {
        name = 'copper-ore',
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 120}
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
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 120}
        }
    },
    {
        name = 'stone',
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 120}
        }
    },
    {
        name ='bauxite-ore',
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = value(125, 0),
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 120}
        }
    },
    {
        name = 'cobalt-ore',
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
        },
        ['start'] = value(125, 0),
        ['weight'] = 0.05,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 120}
        }
    },
    {
        name = 'gem-ore',
        ['tiles'] = {
            [1] = 'dirt-1',
            [2] = 'dirt-2',
            [3] = 'dirt-3',
            [4] = 'dirt-4',
            [5] = 'dirt-5',
            [6] = 'dirt-6',
            [7] = 'dirt-7'
        },
        ['start'] = value(125, 0),
        ['weight'] = 0.05,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 120}
        }
    },
    {
        name = 'gold-ore',
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = value(125, 0),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 120}
        }
    },
    {
        name = 'lead-ore',
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = value(125, 0),
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 120}
        }
    },
    {
        name = 'nickel-ore',
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
        },
        ['start'] = value(125, 0),
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 120}
        }
    },
    {
        name = 'quartz',
        ['tiles'] = {
            [1] = 'dirt-1',
            [2] = 'dirt-2',
            [3] = 'dirt-3',
            [4] = 'dirt-4',
            [5] = 'dirt-5',
            [6] = 'dirt-6',
            [7] = 'dirt-7'
        },
        ['start'] = value(125, 0),
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 120}
        }
    },
    {
        name = 'rutile-ore',
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = value(125, 0),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 120}
        }
    },
    {
        name = 'silver-ore',
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = value(125, 0),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 120}
        }
    },
    {
        name = 'sulfur',
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
        },
        ['start'] = value(125, 0),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 120}
        }
    },
    {
        name = 'tin-ore',
        ['tiles'] = {
            [1] = 'dirt-1',
            [2] = 'dirt-2',
            [3] = 'dirt-3',
            [4] = 'dirt-4',
            [5] = 'dirt-5',
            [6] = 'dirt-6',
            [7] = 'dirt-7'
        },
        ['start'] = value(125, 0),
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 120}
        }
    },
    {
        name = 'tungsten-ore',
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = value(125, 0),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 120}
        }
    },
    {
        name = 'zinc-ore',
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = value(125, 0),
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 120}
        }
    }
}
