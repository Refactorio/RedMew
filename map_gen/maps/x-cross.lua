--TODO:
--Make sure all resources are found in the starting area, regardless of coverup due to void.
--Small parts of the map are unreachable due to void and the pattern - unsure to fix or leave.
-- -Orange 27 May 2019

local b = require "map_gen.shared.builders"
local ScenarioInfo = require 'features.gui.info'

--Special thanks to the following beta testers for their help with the map and map info: T-A-R
ScenarioInfo.set_map_name('X-Cross')
ScenarioInfo.set_map_description('Starting on the crossroads, you must choose wise to find a to escape.\nDo not get lost in this infinite maze of crosses.\nAnd careful not to hurt your neck, since this time, the maze is slightly on an angle.')
ScenarioInfo.add_map_extra_info('Confined, but predicatable space provides a moderate challenge.')

local scale_factor = 64

local pic = require "map_gen.data.presets.crosses3"
local degrees = require "utils.math".degrees
pic = b.decompress(pic)

local shape = b.picture(pic)
shape = b.scale(shape, scale_factor, scale_factor)

local map = b.single_pattern(shape, (pic.width - 24.5 ) * scale_factor + 6, (pic.height - 21.5) * scale_factor  - 6)
map = b.rotate(map, degrees(45))
map = b.translate(map, 48, -176)

return map
