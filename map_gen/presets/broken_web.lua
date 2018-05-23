local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.broken_web"
pic = b.decompress(pic)

local shape = b.picture(pic)
shape = b.invert(shape)

local map = b.single_pattern(shape, pic.width, pic.height - 1)
map = b.translate(map, 10, -27)
map = b.scale(map, 12, 12)

return map