local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.GoT"
pic = b.decompress(pic)

local shape = b.picture(pic)
shape = b.translate(shape, 752, -408)

return shape
