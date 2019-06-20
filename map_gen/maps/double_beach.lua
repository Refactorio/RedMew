local b = require 'map_gen.shared.builders'
local beach = require 'map_gen.maps.beach'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local ScenarioInfo = require 'features.gui.info'

local degrees = require 'utils.math'.degrees

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none
    }
)

ScenarioInfo.set_map_name('Double Beach')
ScenarioInfo.set_map_description('Double the beach, double the fun!\nEnjoy twisting your way through this ribbon world, with sandy shores of plentiful ores.\nAnd oil is not a chore, since you find it right offshore!')
ScenarioInfo.set_map_extra_info('Slanted ribbon world with variable, but fairly constant width.\nMixed ore patches, with the exception of uranium pockets and one coal patch.')

local start_pound = b.circle(6)
start_pound = b.translate(start_pound, 0, -16)
start_pound = b.change_tile(start_pound, true, 'water')

beach = b.translate(beach, 0, -64)

local map = b.any {start_pound, beach, b.translate(b.flip_y(beach), -51200, 0)}

map = b.rotate(map, degrees(45))

return map
