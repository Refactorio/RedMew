require "locale.gen_combined.grilledham_map_gen.map_gen"

map_gen_decoratives = true
local pic = require "locale.gen_combined.grilledham_map_gen.data.turkey"
local pic = decompress(pic)

local shape = picture_builder(pic)
local shape = scale(shape, 4, 4)
local shape = translate(shape, -300, 500)

return shape
