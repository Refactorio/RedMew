local b = require "map_gen.shared.builders"
local pic = require "map_gen.data.presets.gears"

local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local ScenarioInfo = require 'features.gui.info'

RS.set_map_gen_settings(
    {
        MGSP.water_none,
        MGSP.cliff_none
    }
)

ScenarioInfo.set_map_name('Gears')
ScenarioInfo.set_map_description(
    [[
Large gear shaped islands

This is like a huge maze of never ending gears!
]]
)
ScenarioInfo.add_map_extra_info(
    [[
Vanilla play on a gear shaped map.
]]
)

ScenarioInfo.set_new_info(
    [[
2019-09-11 - Jayefuu
- Updated map descriptions
]]
)

pic = b.decompress(pic)

local shape = b.picture(pic)

local map = b.single_pattern(shape, pic.width, pic.height)
map = b.translate(map, -20, 20)
map = b.scale(map, 4, 4)

map = b.change_tile(map, false, "water")
map = b.change_map_gen_collision_tile(map, "water-tile", "grass-1")

return map
