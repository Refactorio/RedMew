local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.GoT"
local pic = b.decompress(pic)

local shape = b.picture(pic)
local shape = b.translate(shape, 752, -408)

return shape
