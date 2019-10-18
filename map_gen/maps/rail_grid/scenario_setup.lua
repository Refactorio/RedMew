local ScenarioInfo = require 'features.gui.info'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

-- Setup surface and map settings
RS.set_map_gen_settings(
    {
        MGSP.cliff_none,
        MGSP.grass_disabled,
        MGSP.enable_water
    }
)

ScenarioInfo.set_map_name('Rail Grid')
ScenarioInfo.set_map_description(
    [[
Nauvis' factory planners have been disappointed with the recent trend towards
rail spaghetti. As such they have enacted rules to enforce neat grid shaped
rails and crossings.
]]
)
ScenarioInfo.add_map_extra_info(
    [[
This map has green "city blocks" to enforce construction of rail in a grid
pattern.

You cannot place rail on any tile type except landfill. There is space at the
grid intersections for junctions and turnarounds. There is space for
two stations on each side of the grid.
]]
)
