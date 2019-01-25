local b = require "map_gen.shared.builders"
local pic = require "map_gen.data.presets.turkey"
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

RS.set_map_gen_settings(
    {
        MGSP.cliff_none
    }
)

pic = b.decompress(pic)

local shape = b.picture(pic)
shape = b.scale(shape, 4, 4)
shape = b.translate(shape, -300, 500)

return shape
