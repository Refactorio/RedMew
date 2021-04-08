local b = require 'map_gen.shared.builders'
local value = b.euclidean_value

return {
    ['copper-ore'] = {
        ['tiles'] = {
            [1] = 'landfill'
        },
        ['start'] = value(50, 0),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.75)), weight = 15},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.75)), weight = 72},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.75)), weight = 6},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.75)), weight = 7}
        }
    },
    ['coal'] = {
        ['tiles'] = {
            [1] = 'landfill'
        },
        ['start'] = value(50, 0),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.75)), weight = 21},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.75)), weight = 8},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.75)), weight = 6},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.75)), weight = 65}
        }
    },
    ['iron-ore'] = {
        ['tiles'] = {
            [1] = 'landfill'
        },
        ['start'] = value(50, 0),
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value(0, 0.75)), weight = 72},
            {resource = b.resource(b.full_shape, 'copper-ore', value(0, 0.75)), weight = 15},
            {resource = b.resource(b.full_shape, 'stone', value(0, 0.75)), weight = 6},
            {resource = b.resource(b.full_shape, 'coal', value(0, 0.75)), weight = 7}
        }
    }
}
