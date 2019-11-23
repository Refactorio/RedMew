local b = require 'map_gen.shared.builders'
local spiral = b.rectangular_spiral(128)
require "map_gen.entities.deathworld"
local map = b.apply_entity(spiral, patches)
map = b.choose(b.rectangle(96), start_spiral, map)
map = b.change_map_gen_collision_tile(map, 'water-tile', 'grass-1')
local sea = b.tile('water')
sea = b.fish(sea, 0.00125)
map = b.if_else(map, sea)
return map
