local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.contra_spiral"
pic = b.decompress(pic)
local map = b.picture(pic)

map = b.single_pattern(map, pic.width, pic.height)

return map
