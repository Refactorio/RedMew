local b = require 'map_gen.shared.builders'
local pic = require 'map_gen.data.presets.fox'

pic = b.decompress(pic)
local shape = b.any{ b.picture(pic), b.full_shape }

return shape
