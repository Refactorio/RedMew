local b = require 'map_gen.shared.builders'
local start_value = b.euclidean_value(0, 0.35)
local value = b.exponential_value(0, 0.06, 1.55)
local special_resources_radius = 32 * 6

return {
    {
        name = 'copper-ore',
        ['tiles'] = {
            [1] = 'landfill'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 13},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 64},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 9},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 4},
            {resource = b.resource(b.invert(b.circle(special_resources_radius)), 'rare-metals', value), weight = 4},
            {resource = b.resource(b.invert(b.circle(special_resources_radius)), 'uranium-ore', value), weight = 2},
        }
    },
    {
        name = 'coal',
        ['tiles'] = {
            [1] = 'landfill'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 14},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 9},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 7},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 60},
            {resource = b.resource(b.invert(b.circle(special_resources_radius)), 'rare-metals', value), weight = 4},
            {resource = b.resource(b.invert(b.circle(special_resources_radius)), 'uranium-ore', value), weight = 2},
        }
    },
    {
        name = 'iron-ore',
        ['tiles'] = {
            [1] = 'landfill'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 67},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 15},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 6},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 2},
            {resource = b.resource(b.invert(b.circle(special_resources_radius)), 'rare-metals', value), weight = 4},
            {resource = b.resource(b.invert(b.circle(special_resources_radius)), 'uranium-ore', value), weight = 2},
        }
    },
    {
        name = 'stone',
        ['tiles'] = {
            [1] = 'landfill'
        },
        ['start'] = start_value,
        ['weight'] = 1,
        ['ratios'] = {
            {resource = b.resource(b.full_shape, 'iron-ore', value), weight = 23},
            {resource = b.resource(b.full_shape, 'copper-ore', value), weight = 9},
            {resource = b.resource(b.full_shape, 'stone', value), weight = 54},
            {resource = b.resource(b.full_shape, 'coal', value), weight = 4},
            {resource = b.resource(b.invert(b.circle(special_resources_radius)), 'rare-metals', value), weight = 4},
            {resource = b.resource(b.invert(b.circle(special_resources_radius)), 'uranium-ore', value), weight = 2},
        }
    },
}
