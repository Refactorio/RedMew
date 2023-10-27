local b = require 'map_gen.shared.builders'
local value = b.euclidean_value

local full_oil_shape = b.translate(b.throttle_xy(b.full_shape, 3, 6, 3, 6), -1, -1)
full_oil_shape = b.use_world_as_local(full_oil_shape)
local oil_shape = b.throttle_world_xy(b.full_shape, 1, 6, 1, 6)

local function generate_patch(name, data)
  return {
    scale = data.scale,
    threshold = data.t,
    resource = b.any{ b.resource(data.shape, name, value(data.base, data.mult)), data.full_shape }
  }
end

return {
  generate_patch('crude-oil',           { scale = 1/48, base = 100000, mult = 2500, t = 0.60, shape = oil_shape, full_shape = full_oil_shape }),
  generate_patch('dirty-steam-fissure', { scale = 1/12, base =  25000, mult =    1, t = 0.70, shape = oil_shape, full_shape = full_oil_shape }),
  generate_patch('natural-gas-fissure', { scale = 1/12, base =  25000, mult =    1, t = 0.70, shape = oil_shape, full_shape = full_oil_shape }),
  generate_patch('steam-fissure',       { scale = 1/12, base =  25000, mult =    1, t = 0.70, shape = oil_shape, full_shape = full_oil_shape }),
  generate_patch('sulphur-gas-fissure', { scale = 1/12, base =  25000, mult =    1, t = 0.70, shape = oil_shape, full_shape = full_oil_shape }),
}
