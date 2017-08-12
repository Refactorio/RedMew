require "locale.gen_combined.grilledham_map_gen.map_gen"
require "locale.gen_combined.grilledham_map_gen.builders"

local pic = require "locale.gen_combined.grilledham_map_gen.data.color_mona_lisa"

local scale_factor = 1
local shape = picture_builder(pic.data, pic.width, pic.height)
shape = scale(shape, scale_factor, scale_factor)

local map = single_pattern_builder(shape, pic.width * scale_factor, pic.height * scale_factor)

return map