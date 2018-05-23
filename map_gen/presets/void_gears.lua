local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.void_gears"
pic = b.decompress(pic)

local shape = b.picture(pic)
shape = b.invert(shape)

local map = b.single_pattern(shape, pic.width, pic.height)
map = b.translate(map, -100, 120)
map = b.scale(map, 2, 2)

return map