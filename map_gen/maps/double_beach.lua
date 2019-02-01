local b = require 'map_gen.shared.builders'
local beach = require 'map_gen.maps.beach'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local degrees = require 'utils.math'.degrees

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none
    }
)

local start_pound = b.circle(6)
start_pound = b.translate(start_pound, 0, -16)
start_pound = b.change_tile(start_pound, true, 'water')

beach = b.translate(beach, 0, -64)

local map = b.any {start_pound, beach, b.translate(b.flip_y(beach), -51200, 0)}

map = b.rotate(map, degrees(45))

return map
