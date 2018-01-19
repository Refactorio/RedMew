require "map_gen.shared.generate"
require "map_gen.shared.builders"
map_gen_decoratives = true
local pic = require "map_gen.data.presets.GoT"
local pic = decompress(pic)

local shape = picture_builder(pic)
local shape = translate(shape, 752, -408)

return shape
