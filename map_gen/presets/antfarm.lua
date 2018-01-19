require "map_gencombined.grilledham_map_gen.map_gen"
require "map_gencombined.grilledham_map_gen.builders"

local pic = require "map_gendata.antfarm"

local scale_factor = 12
local shape = picture_builder(pic.data, pic.width, pic.height)
shape = invert(shape)

local map = single_pattern_builder(shape, pic.width, pic.height)
map = translate(map, -12, 2)
map = scale(map, scale_factor, scale_factor)

--map = change_tile(map, false, "water")
--map = change_map_gen_collision_tile(map, "water-tile", "grass-1")

return map