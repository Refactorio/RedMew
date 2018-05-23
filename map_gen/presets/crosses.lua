local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.crosses"
pic = b.decompress(pic)

local shape = b.picture(pic)
local map = b.single_pattern(shape, pic.width, pic.height)
map = b.translate(map, 10, -4)
map = b.scale(map, 12, 12)

return map