-- Inspired/copied from Beach.

local b = require 'map_gen.shared.builders'
local perlin = require 'map_gen.shared.perlin_noise'
local Global = require 'utils.global'
local math = require 'utils.math'

-- A "very small" starting area is advised at the default 100 width.
local play_area_width = 100 -- The approximate width of the play area
local oob_tile = 'out-of-map' -- The tiles that make up the out of bounds/world border. Recommended are out-of-map or water.

local oob_width = 233
local oob_width_inv = tau / oob_width

-- Perlin options
local noise_variance = 0.020 --The lower this number the smoother the curve is gonna be
local oob_noise_level = 15.25 --Factor for the magnitude of the curve

-- Leave nil and they will be set based on the map seed.
local perlin_seed_1 = nil
local perlin_seed_2 = nil

Global.register_init(
    {},
    function(tbl)
        local seed = game.surfaces[1].map_gen_settings.seed
        tbl.perlin_seed_1 = perlin_seed_1 or seed
        tbl.perlin_seed_2 = perlin_seed_2 or seed * 2
    end,
    function(tbl)
        perlin_seed_1 = tbl.perlin_seed_1
        perlin_seed_2 = tbl.perlin_seed_2
    end
)

local function oob_shape(x, y)
    local p = perlin.noise(x * noise_variance, y * noise_variance, perlin_seed_2) * oob_noise_level
    p = p + math.sin(x * oob_width_inv + 179) * 15
    return p > y
end

-- Turn the tiles included in the out of bounds to the oob tile.
oob_shape = b.change_tile(oob_shape, true, oob_tile)

-- Offset the oob from the middle of the map/playing area
oob_shape = b.translate(oob_shape, 0, -(play_area_width/2))

--[[ Make up the map from 3 components: the oob shape we created (which covers the NW), a copy of the oob shape which is
	flipped (to cover the SE) and then translated so that the crests and valleys of the noise creates a nice wave.
	Lastly, any part of the map that isn't in oob_shape or the oob_copy is filled by full_shape which just passes the
	vanilla mapgen through. ]]--
local map = b.any {oob_shape, b.translate(b.flip_y(oob_shape), (oob_width/2), 0), b.full_shape}

map = b.rotate(map, math.rad(45))

return map
