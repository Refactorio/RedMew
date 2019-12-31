local b = require "map_gen.shared.builders"
local shape = b.rectangular_spiral(128)
local map = b.change_tile(shape, false, 'water')
return map
