require "locale.gen_combined.grilledham_map_gen.map_gen"

local pic = require "locale.gen_combined.grilledham_map_gen.data.biome_test"

local shape = picture_builder(pic.data, pic.width, pic.height)

shape = change_tile(shape, false, "out-of-map")

return shape
