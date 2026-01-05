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
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 3}
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
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 3}
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
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 3}
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
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 3}
        }
    },
    {
        name = 'bob-bauxite-ore',
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
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 3}
        }
    },
    {
        name = 'bob-cobalt-ore',
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
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 3}
        }
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
            [7] = 'dirt-7'
        },
        ['start'] = start_value,
        ['weight'] = 0.05,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 3}
        }
    },
    {
        name = 'bob-gold-ore',
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
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 3}
        }
    },
    {
        name = 'bob-lead-ore',
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
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 3}
        }
    },
    {
        name = 'bob-nickel-ore',
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
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 3}
        }
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
            [7] = 'dirt-7'
        },
        ['start'] = start_value,
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 20},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 20},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 20},
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 120},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 3}
        }
    },
    {
        name = 'bob-rutile-ore',
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
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 3}
        }
    },
    {
        name = 'bob-silver-ore',
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
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 120},
            --{resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 3}
        }
    },
    --[[ {
        name = 'bob-sulfur',
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
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 120},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 3}
        }
    }, ]]
    {
        name = 'bob-tin-ore',
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
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 3}
        }
    },
    {
        name = 'bob-tungsten-ore',
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
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 120},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 3}
        }
    },
    {
        name = 'bob-zinc-ore',
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
            {resource = b.resource(b.full_shape, 'bob-bauxite-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-cobalt-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gem-ore', value), weight = 0.1},
            {resource = b.resource(b.full_shape, 'bob-gold-ore', value), weight = 7},
            {resource = b.resource(b.full_shape, 'bob-lead-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-nickel-ore', value), weight = 3},
            {resource = b.resource(b.full_shape, 'bob-quartz', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-rutile-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-silver-ore', value), weight = 5},
            --{resource = b.resource(b.full_shape, 'bob-sulfur', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-tin-ore', value), weight = 10},
            {resource = b.resource(b.full_shape, 'bob-tungsten-ore', value), weight = 5},
            {resource = b.resource(b.full_shape, 'bob-zinc-ore', value), weight = 120}
        }
    }
}
