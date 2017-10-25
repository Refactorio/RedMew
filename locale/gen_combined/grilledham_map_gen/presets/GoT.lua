require "locale.gen_combined.grilledham_map_gen.map_gen"
require "locale.gen_combined.grilledham_map_gen.builders"

local pic = require "locale.gen_combined.grilledham_map_gen.data.GoT"
local pic = decompress(pic)

local shape = picture_builder(pic)
local shape = translate(shape, 752, -408)

return shape
