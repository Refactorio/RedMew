require "map_gencombined.grilledham_map_gen.map_gen"
require "map_gencombined.grilledham_map_gen.builders"
map_gen_decoratives = true
local pic = require "map_gendata.GoT"
local pic = decompress(pic)

local shape = picture_builder(pic)
local shape = translate(shape, 752, -408)

return shape
