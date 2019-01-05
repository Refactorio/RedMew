local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.creation_of_adam"
pic = b.decompress(pic)

local scale_factor = 3
local shape = b.picture(pic)
shape = b.scale(shape, scale_factor, scale_factor)

local pattern =
{
    { shape , b.flip_x(shape) },
    { b.flip_y(shape), b.flip_xy(shape) }
}

local map = b.grid_pattern(pattern, 2, 2, pic.width * scale_factor, pic.height * scale_factor)
map = b.translate(map, 128 * scale_factor, 26 * scale_factor)

map = b.change_map_gen_collision_tile(map, "water-tile", "grass-1")

return map
