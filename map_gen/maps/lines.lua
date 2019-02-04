local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.lines"
pic= b.decompress(pic)

local shape = b.picture(pic)

local map = b.single_pattern(shape, pic.width, pic.height)

--map = b.translate(map, 10, -96)
map = b.scale(map,10,10)

return map