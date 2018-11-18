local b = require 'map_gen.shared.builders'

local pic = require 'map_gen.data.presets.honeycomb'
local pic = b.decompress(pic)
local map = b.picture(pic)

-- this builds the map by duplicating the pic in every direction
map = b.single_pattern(map, pic.width - 1, pic.height - 1)

return map
