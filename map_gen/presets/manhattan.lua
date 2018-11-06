local b = require "map_gen.shared.builders"
local degrees = require "utils.math".degrees
local pic = require "map_gen.data.presets.manhattan"
pic = b.decompress(pic)

local shape = b.picture(pic)
shape = b.translate(shape, 10, -96)
shape = b.scale(shape,2,2)
shape = b.rotate(shape, degrees(-22.5))

shape = b.change_tile(shape, false, "deepwater")

return shape
