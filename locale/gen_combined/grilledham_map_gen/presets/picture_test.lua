require "locale.gen_combined.grilledham_map_gen.map_gen"
require "locale.gen_combined.grilledham_map_gen.builders"

local pic = require "locale.gen_combined.grilledham_map_gen.data.crosses3"

local scale_factor = 4
local shape = picture_builder(pic.data, pic.width, pic.height)
shape = scale(shape, scale_factor, scale_factor)
--shape = rotate(shape, degrees(45))
shape = invert(shape)

local map = single_pattern_builder(shape, pic.width * scale_factor, pic.height * scale_factor)
map = rotate(map, degrees(45))

return map