local b = require "map_gen.shared.builders"
local ScenarioInfo = require 'features.gui.info'

--Special thanks to the following beta testers for their help with the map and map info: T-A-R
ScenarioInfo.set_map_name('Broken Web')
ScenarioInfo.set_map_description('This map is spanning the void like a Broken Web!\nIn order to launch a rocket into space, you must collaborate like ants to build a breathtaking ant cave.')
ScenarioInfo.set_map_extra_info('Confined space map with predictable terrain generation.\nA good way to challenge yourself with building in confined spaces.')

local pic = require "map_gen.data.presets.broken_web"
pic = b.decompress(pic)

local shape = b.picture(pic)
shape = b.invert(shape)

local map = b.single_pattern(shape, pic.width, pic.height - 1)
map = b.translate(map, 10, -27)
map = b.scale(map, 12, 12)

return map
