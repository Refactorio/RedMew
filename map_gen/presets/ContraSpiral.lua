local b = require 'map_gen.shared.builders'

local pic = require 'map_gen.data.presets.CSrMap'
local pic = b.decompress(pic)
local map = b.picture(pic)

local map = b.single_pattern(map, pic.width, pic.height)

return map
