local b = require 'map_gen.shared.builders'
local value = b.euclidean_value

local full_oil_shape = b.translate(b.throttle_xy(b.full_shape, 3, 6, 3, 6), -1, -1)
full_oil_shape = b.use_world_as_local(full_oil_shape)
local oil_shape = b.throttle_world_xy(b.full_shape, 1, 6, 1, 6)

local full_patch_shape = b.throttle_xy(b.full_shape, 5, 10, 5, 10)
full_patch_shape = b.use_world_as_local(full_patch_shape)
local patch_shape = b.throttle_world_xy(b.full_shape, 4, 10, 4, 10)

local function generate_patch(name, data)
  return {
    scale = data.scale,
    threshold = data.t,
    resource = b.any{ b.resource(data.shape, name, value(data.base, data.mult)), data.full_shape }
  }
end

return {
  generate_patch('crude-oil',        { scale = 1 / 64, base = 100000, mult =  2500, t = 0.60, shape = oil_shape,   full_shape = full_oil_shape,   rarity = 'common'    }),
  generate_patch('ei_coal-patch',    { scale = 1 / 56, base =  25000, mult =   100, t = 0.60, shape = patch_shape, full_shape = full_patch_shape, rarity = 'common'    }),
  generate_patch('ei_copper-patch',  { scale = 1 / 56, base =  25000, mult =   100, t = 0.60, shape = patch_shape, full_shape = full_patch_shape, rarity = 'common'    }),
  generate_patch('ei_gold-patch',    { scale = 1 / 64, base =  60000, mult =   750, t = 0.65, shape = patch_shape, full_shape = full_patch_shape, rarity = 'rare'      }),
  generate_patch('ei_iron-patch',    { scale = 1 / 56, base =  25000, mult =   100, t = 0.60, shape = patch_shape, full_shape = full_patch_shape, rarity = 'common'    }),
  generate_patch('ei_lead-patch',    { scale = 1 / 56, base =  25000, mult =   100, t = 0.60, shape = patch_shape, full_shape = full_patch_shape, rarity = 'common'    }),
  generate_patch('ei_neodym-patch',  { scale = 1 / 64, base =  80000, mult =  1500, t = 0.67, shape = patch_shape, full_shape = full_patch_shape, rarity = 'very-rare' }),
  generate_patch('ei_sulfur-patch',  { scale = 1 / 56, base =  25000, mult =   100, t = 0.60, shape = patch_shape, full_shape = full_patch_shape, rarity = 'common'    }),
  generate_patch('ei_uranium-patch', { scale = 1 / 64, base =  60000, mult =   750, t = 0.65, shape = patch_shape, full_shape = full_patch_shape, rarity = 'rare'      }),
  -- Gaia surface
  -- ['ei_core-patch']     = { rarity = 'gaia', },
  -- ['ei_cryoflux-patch'] = { rarity = 'gaia', },
  -- ['ei_phytogas-patch'] = { rarity = 'gaia', },
}
