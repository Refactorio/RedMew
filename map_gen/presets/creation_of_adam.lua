require "map_gen.shared.generate"
require "map_gen.combined.grilledham_map_gen.builders"

local pic = require "map_gen.data.creation_of_adam2"

local scale_factor = 3
local shape = picture_builder(pic.data, pic.width, pic.height)
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