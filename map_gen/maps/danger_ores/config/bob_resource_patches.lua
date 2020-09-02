local b = require 'map_gen.shared.builders'
local value = b.euclidean_value

local oil_shape = b.throttle_world_xy(b.full_shape, 1, 7, 1, 7)

return {
    {
        scale = 1 / 64,
        threshold = 0.6,
        resource = b.resource(oil_shape, 'crude-oil', value(250000, 150))
    },
    {
        scale = 1 / 72,
        threshold = 0.63,
        resource = b.resource(b.full_shape, 'uranium-ore', value(200, 1))
    },
    {
        scale = 1 / 72,
        threshold = 0.63,
        resource = b.resource(b.full_shape, 'thorium-ore', value(200, 1))
    }
}
