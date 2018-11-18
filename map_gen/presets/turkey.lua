local b = require 'map_gen.shared.builders'

local pic = require 'map_gen.data.presets.turkey'
local pic = b.decompress(pic)

local shape = b.picture(pic)
local shape = b.scale(shape, 4, 4)
local shape = b.translate(shape, -300, 500)

return shape
