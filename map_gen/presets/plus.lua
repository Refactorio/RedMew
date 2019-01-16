local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.plus" --or whatever you called it in data->presets
pic = b.decompress(pic)
local map = b.picture(pic)

map = b.single_pattern(map, pic.width-1, pic.height-1)

map = b.translate(map, 86, 0)

-- uncomment the line below to change the size of the map b.scale(x, y)
map = b.scale(map, 1.5, 1.5)

return map
