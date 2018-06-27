local b = require 'map_gen.shared.builders'

local pic = require 'map_gen.data.presets.world-map'
local map = b.picture(pic)

map = b.single_x_pattern(map, pic.width)

return map
