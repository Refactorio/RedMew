local b = require 'map_gen.shared.builders'
local value = b.euclidean_value

local oil_shape = b.throttle_xy(b.full_shape, 3, 6, 3, 6)
oil_shape = b.use_world_as_local(oil_shape)

local fissure_shape = b.throttle_xy(b.full_shape, 9, 12, 9, 12)
fissure_shape = b.use_world_as_local(fissure_shape)

return {
    {
        scale = 1 / 100,
        threshold = 0.6,
        resource = b.any{b.resource(fissure_shape, 'angels-fissure', value(1250, 1))}
    },
    {
        scale = 1 / 64,
        threshold = 0.65,
        resource = b.any{b.resource(oil_shape, 'angels-natural-gas', value(1250, 1))}
    },
    {
        scale = 1 / 64,
        threshold = 0.6,
        resource = b.any{b.resource(b.translate(oil_shape, 1, 1), 'crude-oil', value(250000, 150))}
    },
}
