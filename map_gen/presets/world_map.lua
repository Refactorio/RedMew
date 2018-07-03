local b = require 'map_gen.shared.builders'

local pic = require 'map_gen.data.presets.world-map'
local map = b.picture(pic)

map = b.single_x_pattern(map, pic.width)

map = b.translate(map, -369, 46)

map = b.scale(map, 2, 2)

return map
