local b = require 'map_gen.shared.builders'
local value = b.euclidean_value

local full_oil_shape = b.throttle_xy(b.full_shape, 3, 6, 3, 6)
full_oil_shape = b.use_world_as_local(full_oil_shape)

local full_patch_shape = b.throttle_xy(b.full_shape, 7, 12, 7, 12)
full_patch_shape = b.use_world_as_local(full_patch_shape)

local function generate_patch(name, data)
  return {
    scale = data.scale,
    threshold = data.t,
    resource = b.resource(data.shape, name, value(data.base, data.mult))
  }
end

return {
  generate_patch('crude-oil',     { scale = 1/32, base = 100000, mult = 2500, t = 0.60, shape = full_oil_shape }),
  generate_patch('volcanic-pipe', { scale = 1/32, base =  25000, mult =  750, t = 0.60, shape = full_patch_shape }),
  generate_patch('regolites',     { scale = 1/32, base =  25000, mult =  750, t = 0.60, shape = full_patch_shape }),
  generate_patch('uranium-ore',   { scale = 1/96, base =    500, mult =  1.5, t = 0.66, shape = b.full_shape }),
}
