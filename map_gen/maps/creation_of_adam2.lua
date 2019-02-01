local b = require 'map_gen.shared.builders'
local pic = require 'map_gen.data.presets.creation_of_adam2'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
--local pic = require "map_gen.data.presets.sistine_chapel_ceiling"

local degrees = require "utils.math".degrees

RS.set_map_gen_settings(
    {
        MGSP.ore_none,
        MGSP.cliff_none
    }
)

pic = b.decompress(pic)

local shape = b.picture(pic)

--map = b.change_map_gen_collision_tile(map, "water-tile", "grass-1")

local pattern = {
    {shape, b.flip_x(shape)},
    {b.flip_y(shape), b.flip_xy(shape)}
}

local map = b.grid_pattern(pattern, 2, 2, pic.width - 1, pic.height - 1)

map = b.translate(map, 222, 64)

local rainbows = require 'map_gen.ores.fluffy_rainbows'

local rainbow1 = b.translate(rainbows, 1000000, 1000000)
local rainbow2 = b.translate(rainbows, 2000000, 2000000)
rainbow2 = b.rotate(rainbow2, degrees(45))
rainbow2 = b.scale(rainbow2, 0.5)

map = b.apply_entities(map, {rainbow1, rainbow2})

map = b.fish(map, 0.00125)

return map
