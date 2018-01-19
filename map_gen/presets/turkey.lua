require "map_gen.shared.generate"

map_gen_decoratives = true
local pic = require "map_gen.data.turkey"
local pic = decompress(pic)

local shape = picture_builder(pic)
local shape = scale(shape, 4, 4)
local shape = translate(shape, -300, 500)

return shape
