local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.maori"
pic= b.decompress(pic)

local shape = b.picture(pic)
shape = b.invert(shape)
local crop = b.rectangle(pic.width, pic.height)
shape = b.all{shape, crop}

local map = b.single_pattern(shape, pic.width, pic.height)

map = b.translate(map, 10, -96)
map = b.scale(map,12,12)

return map