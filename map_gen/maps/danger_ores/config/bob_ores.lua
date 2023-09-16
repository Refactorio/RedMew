local b = require 'map_gen.shared.builders'
local value = b.exponential_value(0, 0.07, 1.45)
local start_value = b.euclidean_value(0, 0.35)

return {
    {
        name = 'iron-ore',
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = start_value,
        ['weight'] = 15,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 3}
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
        ['start'] = start_value,
        ['weight'] = 10,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 3}
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
        ['weight'] = 9.55,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 120},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 3}
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
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 120},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 3}
        }
    },
    {
        name = 'bauxite-ore',
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = start_value,
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 3}
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
        ['start'] = start_value,
        ['weight'] = 0.5,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 3}
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
        ['start'] = start_value,
        ['weight'] = 0.05,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 3}
        }
    },
    {
        name = 'gold-ore',
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 3}
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
        ['start'] = start_value,
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 3}
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
        ['start'] = start_value,
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 3}
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
        ['start'] = start_value,
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 120},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 3}
        }
    },
    {
        name = 'rutile-ore',
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 3}
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
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 120},
            --{resource = b.resource(b.full_shape, 'sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 3}
        }
    },
    --[[ {
        name = 'sulfur',
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'sulfur', value), weight = 120},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 3}
        }
    }, ]]
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
        ['start'] = start_value,
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 3}
        }
    },
    {
        name = 'tungsten-ore',
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 3}
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
        ['start'] = start_value,
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'zinc-ore', value), weight = 120}
        }
    }
}
