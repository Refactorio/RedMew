local MGSP = require 'resources.map_gen_settings'
local config = {
    scenario_name = 'square_spiral_old',
    map_gen_settings = {
        MGSP.sand_only,
        MGSP.starting_area_very_low,
        MGSP.ore_oil_none,
        MGSP.enemy_high,
        MGSP.cliff_none,
	MGSP.tree_none,
    }
}
local b = require "map_gen.shared.builders"
local shape = b.rectangular_spiral(128)
map = b.change_map_gen_collision_tile(shape, 'water-tile', 'grass-1')
map = b.change_tile(shape, false, 'water')
return map
