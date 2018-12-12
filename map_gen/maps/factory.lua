local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.factory"
local pic = b.decompress(pic)
local map = b.picture(pic)

return map