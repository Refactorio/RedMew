local b = require 'map_gen.shared.builders'
local value = b.euclidean_value

local full_oil_shape = b.translate(b.throttle_xy(b.full_shape, 3, 6, 3, 6), -1, -1)
full_oil_shape = b.use_world_as_local(full_oil_shape)
local oil_shape = b.throttle_world_xy(b.full_shape, 1, 6, 1, 6)

return {
  {
    scale = 1 / 64,
    threshold = 0.6,
    resource = b.any{ b.resource(oil_shape, 'crude-oil', value(100000, 2500)), full_oil_shape }
  },
  {
    scale = 1 / 64,
    threshold = 0.6,
    resource = b.any{ b.resource(oil_shape, 'gas', value(100000, 2500)), full_oil_shape }
  },
}
