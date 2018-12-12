local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.antfarm"
pic = b.decompress(pic)

local scale_factor = 12
local shape = b.picture(pic)
--shape = b.invert(shape)

local map = b.single_pattern(shape, pic.width, pic.height)
map = b.translate(map, -12, 2)
map = b.scale(map, scale_factor, scale_factor)

return map
