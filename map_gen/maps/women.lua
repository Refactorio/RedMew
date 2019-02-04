local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.woman"
pic = b.decompress(pic)
local shape = b.picture(pic)

local map = b.single_pattern_overlap(shape, pic.width - 50, pic.height - 120)

map = b.translate(map, 135, -65)
--map = b.change_tile(map, false, "deepwater")

--map = b.scale(map, 2, 2)

return map
