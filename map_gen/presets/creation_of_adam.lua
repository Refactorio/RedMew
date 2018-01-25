map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
require "map_gen.shared.generate_not_threaded"
--require "map_gen.shared.generate"

local pic = require "map_gen.data.presets.creation_of_adam"
local pic = decompress(pic)

local scale_factor = 3
local shape = picture_builder(pic)
shape = scale(shape, scale_factor, scale_factor)

local pattern =
{
    { shape , flip_x(shape) },
    { flip_y(shape), flip_xy(shape) }
}

local map = grid_pattern_builder(pattern, 2, 2, pic.width * scale_factor, pic.height * scale_factor)
map = translate(map, 128 * scale_factor, 26 * scale_factor)

map = change_map_gen_collision_tile(map, "water-tile", "grass-1")

return map