local b = require 'map_gen.shared.builders'

local pic = require 'map_gen.data.presets.vanilla'
local ore_mask = require 'map_gen.data.presets.vanilla-ore-mask'

local tiny_ores = require('map_gen.ores.tiny_ores')(256)

local map = b.picture(pic)

local ores = b.picture(ore_mask)
ores = b.choose(ores, tiny_ores, b.no_entity)

map = b.apply_entity(map, ores)

map = b.single_pattern(map, pic.width, pic.height)

map = b.change_tile(map, 'out-of-map', 'deepwater')
map = b.fish(map, 0.0025)

return map
