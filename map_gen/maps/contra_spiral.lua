-- TODO:
-- make sure all resources are guranteed in starting area, not covered by void
--A better description if someone can top my spur of the moment one on line 17.

local b = require "map_gen.shared.builders"
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local ScenarioInfo = require 'features.gui.info'

RS.set_map_gen_settings(
    {
        MGSP.cliff_none
    }
)

ScenarioInfo.set_map_name('Contra Spiral')
ScenarioInfo.set_map_description('Like a star flying into a net, this map might catch you by surprise\nShape your base around the spaghetti, but do not let it spiral out of control.')
ScenarioInfo.add_map_extra_info('Whacky, unpredicable mix of terrain and void.\nA good way to challenge yourself with building in confined spaces.')

local pic = require "map_gen.data.presets.contra_spiral"
pic = b.decompress(pic)
local map = b.picture(pic)

map = b.single_pattern(map, pic.width, pic.height)

return map
