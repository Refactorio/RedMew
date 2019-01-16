local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.venice"
pic = b.decompress(pic)
local map = b.picture(pic)

map = b.translate(map, 90, 190)

map = b.scale(map, 2, 2)

map = b.change_tile(map, false, "deepwater")

return map
