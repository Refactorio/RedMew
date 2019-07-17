local b = require "map_gen.shared.builders"
local ScenarioInfo = require 'features.gui.info'

local pic = require "map_gen.data.presets.antfarm"
pic = b.decompress(pic)

local scale_factor = 12
local shape = b.picture(pic)
--shape = b.invert(shape)

ScenarioInfo.set_map_name('Antfarm')
ScenarioInfo.set_map_description('Relive your childhood memories as an antfarm of belts and inserters comes to life, in Factorio')
ScenarioInfo.set_map_extra_info('An unpredictable mix of terrain and void walls renders many blueprints useless.\nA good challenge for building in confined spaces.The challenges of a ribbon world without the wasted space - styled by ants!')

local map = b.single_pattern(shape, pic.width, pic.height)
map = b.translate(map, -12, 2)
map = b.scale(map, scale_factor, scale_factor)

return map
