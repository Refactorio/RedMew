local b = require "map_gen.shared.builders"

local scale_factor = 64

local pic = require "map_gen.data.presets.crosses3"
local degrees = require "utils.math".degrees
pic = b.decompress(pic)

local shape = b.picture(pic)
shape = b.scale(shape, scale_factor, scale_factor)

local map = b.single_pattern(shape, (pic.width - 24.5 ) * scale_factor + 6, (pic.height - 21.5) * scale_factor  - 6)
map = b.rotate(map, degrees(45))
map = b.translate(map, 48, -176)

return map
