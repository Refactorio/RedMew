-- Size of the logo.
local scale_factor = 6

-- Distance between islands.
local island_distance_x = 256
local island_distance_y = 128

local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.factorio_logo"
pic = b.decompress(pic)

local shape = b.picture(pic)
shape = b.scale(shape, scale_factor, scale_factor)

local pattern_width = scale_factor * pic.width + island_distance_x
local pattern_height = scale_factor * pic.height + island_distance_y
shape = b.single_pattern(shape, pattern_width, pattern_height)

shape = b.change_tile(shape, false, "deepwater")

return shape
