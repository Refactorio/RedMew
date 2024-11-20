local b = require 'map_gen.shared.builders'
local value = b.euclidean_value

return {
    {
        -- Saphirite
        name = 'angels-ore1',
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2',
            [3] = 'grass-3',
            [4] = 'grass-4'
        },
        ['start'] = value(125, 0),
        ['weight'] = 15,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'angels-ore1', value(0, 0.5)), weight = 1}
        }
    },
    {
        -- Jivolite
        name = 'angels-ore2',
        ['tiles'] = {
            [1] = 'dirt-1',
            [2] = 'dirt-2',
            [3] = 'dirt-3'
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'angels-ore2', value(0, 0.5)), weight = 1}
        }
    },
    {
        -- Stiratite
        name = 'angels-ore3',
        ['tiles'] = {
            [1] = 'red-desert-0',
            [2] = 'red-desert-1',
            [3] = 'red-desert-2',
            [4] = 'red-desert-3'
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'angels-ore3', value(0, 0.5)), weight = 1}
        }
    },
    {
        -- crotinnium
        name = 'angels-ore4',
        ['tiles'] = {
            [1] = 'grass-3',
            [2] = 'grass-4'
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'angels-ore4', value(0, 0.5)), weight = 1}
        }
    },
    {
        -- rubyte
        name = 'angels-ore5',
        ['tiles'] = {
            [1] = 'grass-1',
            [2] = 'grass-2'
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'angels-ore5', value(0, 0.5)), weight = 1}
        }
    },
    {
        -- bobmonium-ore
        name = 'angels-ore6',
        ['tiles'] = {
            [1] = 'sand-1',
            [2] = 'sand-2',
            [3] = 'sand-3'
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'angels-ore6', value(0, 0.5)), weight = 1}
        }
    },
    {
        name = 'coal',
        ['tiles'] = {
            [1] = 'dirt-5',
            [2] = 'dirt-6',
            [3] = 'dirt-7'
        },
        ['start'] = value(125, 0),
        ['weight'] = 10,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.5)), weight = 1}
        }
    }
}
