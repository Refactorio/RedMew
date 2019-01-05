local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.goat"
pic = b.decompress(pic)

local shape = b.picture(pic)
shape = b.translate(shape, 10, -96)
shape = b.scale(shape,2,2)
return shape
