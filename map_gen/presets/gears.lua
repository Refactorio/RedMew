local b = require "map_gen.shared.builders"
local pic = require "map_gen.data.presets.gears"

local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

RS.set_map_gen_settings(
    {
        MGSP.water_none,
        MGSP.cliff_none
    }
)

pic = b.decompress(pic)

local shape = b.picture(pic)

local map = b.single_pattern(shape, pic.width, pic.height)
map = b.translate(map, -20, 20)
map = b.scale(map, 4, 4)

map = b.change_tile(map, false, "water")
map = b.change_map_gen_collision_tile(map, "water-tile", "grass-1")

return map
