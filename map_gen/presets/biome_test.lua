require "map_gen.shared.generate"

map_gen_decoratives = true

local pic = require "map_gen.data.biome_test"

local shape = picture_builder(pic)

--shape = change_tile(shape, false, "out-of-map")

return shape
