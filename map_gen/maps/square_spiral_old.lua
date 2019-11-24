local b = require "map_gen.shared.builders"
local shape = b.rectangular_spiral(128)
local map = b.change_map_gen_collision_tile(shape, 'water-tile', 'grass-1')
map = b.change_tile(shape, false, 'water')
return map
