local b = require 'map_gen.shared.builders'
local Perlin = require 'map_gen.shared.perlin_noise'
local table = require 'utils.table'

local random = math.random
local floor = math.floor
local value = b.euclidean_value
local binary_search = table.binary_search
local bnot = bit32.bnot
local perlin_noise = Perlin.noise

local mixed_ores = false

local tile_scale = 1 / 64
local spawn_zone = b.circle(102)

local oil_scale = 1 / 64
local oil_threshold = 0.6

local uranium_scale = 1 / 72
local uranium_threshold = 0.63

local thorium_scale = 1 / 72
local thorium_threshold = 0.63

local density_scale = 1 / 48
local density_threshold = 0.5
local density_multiplier = 50

local ores = {
    ['iron-ore'] = {
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 10,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 150},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 10}
        }
    },
    ['copper-ore'] = {
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 10,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 150},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 10}
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
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 10,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 67},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 10}
        }
    },
    ['stone'] = {
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 10,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 67},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 10}
        }
    },
    ['bauxite-ore'] = {
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 100},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 10}
        }
    },
    ['cobalt-ore'] = {
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 0.05,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 100},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 10}
        }
    },
    ['gem-ore'] = {
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
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 0.05,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 100},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 10}
        }
    },
    ['gold-ore'] = {
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 100},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 10}
        }
    },
    ['lead-ore'] = {
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 100},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 10}
        }
    },
    ['nickel-ore'] = {
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 100},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 10}
        }
    },
    ['quartz'] = {
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
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 100},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 10}
        }
    },
    ['rutile-ore'] = {
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 100},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 10}
        }
    },
    ['silver-ore'] = {
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 100},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 10}
        }
    },
    ['sulfur'] = {
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 100},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 10}
        }
    },
    ['tin-ore'] = {
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
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 100},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 10}
        }
    },
    ['tungsten-ore'] = {
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 100},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 10}
        }
    },
    ['zinc-ore'] = {
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = value(125, 0),
        ['non_mixed_value'] = value(0, 0.5),
        ['weight'] = 2,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.5)), weight = 2},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'bauxite-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'cobalt-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gem-ore', value(0, 0.5)), weight = 1},
            {resource = b.resource(b.full_shape, 'gold-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'lead-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'nickel-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'quartz', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'rutile-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'silver-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'sulfur', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tin-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'tungsten-ore', value(0, 0.5)), weight = 10},
            {resource = b.resource(b.full_shape, 'zinc-ore', value(0, 0.5)), weight = 100}
        }
    }
}

local oil_shape = b.throttle_world_xy(b.full_shape, 1, 7, 1, 7)
local oil_resource = b.resource(oil_shape, 'crude-oil', value(250000, 150))

local uranium_resource = b.resource(b.full_shape, 'uranium-ore', value(200, 1))
local thorium_resource = b.resource(b.full_shape, 'thorium-ore', value(200, 1))

local function init(seed)
    local oil_seed = seed * 2
    local uranium_seed = seed * 3
    local density_seed = seed * 4
    local thorium_seed = seed * 5

    local function tile_builder(tiles)
        local count = #tiles / 2
        return function(x, y)
            x, y = x * tile_scale, y * tile_scale
            local v = perlin_noise(x, y, seed)
            v = ((v + 1) * count) + 1
            v = floor(v)
            return tiles[v]
        end
    end

    local function ore_builder(ore_name, amount, ratios, weighted)
        local start_ore = b.resource(b.full_shape, ore_name, amount)
        local total = weighted.total
        return function(x, y, world)
            if spawn_zone(x, y) then
                return start_ore(x, y, world)
            end

            local oil_x, oil_y = x * oil_scale, y * oil_scale
            local oil_noise = perlin_noise(oil_x, oil_y, oil_seed)
            if oil_noise > oil_threshold then
                return oil_resource(x, y, world)
            end

            local uranium_x, uranium_y = x * uranium_scale, y * uranium_scale
            local uranium_noise = perlin_noise(uranium_x, uranium_y, uranium_seed)
            if uranium_noise > uranium_threshold then
                return uranium_resource(x, y, world)
            end

            local thorium_x, thorium_y = x * thorium_scale, y * thorium_scale
            local thorium_noise = perlin_noise(thorium_x, thorium_y, thorium_seed)
            if thorium_noise > thorium_threshold then
                return thorium_resource(x, y, world)
            end

            local i = random() * total
            local index = binary_search(weighted, i)
            if index < 0 then
                index = bnot(index)
            end

            local resource = ratios[index].resource

            local entity = resource(x, y, world)
            local density_x, density_y = x * density_scale, y * density_scale
            local density_noise = perlin_noise(density_x, density_y, density_seed)

            if density_noise > density_threshold then
                entity.amount = entity.amount * density_multiplier
            end

            entity.enable_tree_removal = false

            return entity
        end
    end

    local function non_mixed_ore_builder(ore_name, amount)
        local resource = b.resource(b.full_shape, ore_name, amount)
        return function(x, y, world)
            if spawn_zone(x, y) then
                return resource(x, y, world)
            end

            local oil_x, oil_y = x * oil_scale, y * oil_scale
            local oil_noise = perlin_noise(oil_x, oil_y, oil_seed)
            if oil_noise > oil_threshold then
                return oil_resource(x, y, world)
            end

            local uranium_x, uranium_y = x * uranium_scale, y * uranium_scale
            local uranium_noise = perlin_noise(uranium_x, uranium_y, uranium_seed)
            if uranium_noise > uranium_threshold then
                return uranium_resource(x, y, world)
            end

            local thorium_x, thorium_y = x * thorium_scale, y * thorium_scale
            local thorium_noise = perlin_noise(thorium_x, thorium_y, thorium_seed)
            if thorium_noise > thorium_threshold then
                return thorium_resource(x, y, world)
            end

            local entity = resource(x, y, world)
            local density_x, density_y = x * density_scale, y * density_scale
            local density_noise = perlin_noise(density_x, density_y, density_seed)

            if density_noise > density_threshold then
                entity.amount = entity.amount * density_multiplier
            end

            entity.enable_tree_removal = false

            return entity
        end
    end

    local shapes = {}

    for ore_name, v in pairs(ores) do
        local tiles = v.tiles
        local land = tile_builder(tiles)

        local ore
        if mixed_ores then
            local ratios = v.ratios
            local weighted = b.prepare_weighted_array(ratios)
            local amount = v.start

            ore = ore_builder(ore_name, amount, ratios, weighted)
        else
            local amount = v.non_mixed_value

            ore = non_mixed_ore_builder(ore_name, amount)
        end

        local shape = b.apply_entity(land, ore)
        shapes[#shapes + 1] = {shape = shape, weight = v.weight}
    end

    return shapes
end

return init
