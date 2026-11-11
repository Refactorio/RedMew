local DOC = require 'map_gen.maps.danger_ores.configuration'
local Layouts = require 'map_gen.maps.danger_ores.modules.layouts'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Mosaic')
ScenarioInfo.add_map_extra_info([[
  The map is a monumental mosaic of space and industry: rows of panels framed in [item=coal],
  each with sunbursts, stripes or orbits and a great symbol, a rocket, sputnik, atom, gear,
  wheat, factory or pylon, set in [item=iron-ore] [item=copper-ore] and the odd field of coal.
  Spawn sits on a great iron star on a copper core, in a round medallion. The lines are pure
  coal; iron and copper have the others and [item=stone] mixed in at a lower ratio.
  Near spawn most panels are iron; further out, where the rockets get built, most are copper.
  Every seed lays out a different wall.
]])

DOC.scenario_name = 'danger-ore-mosaic'
Layouts.apply(DOC.map_config, require 'map_gen.maps.danger_ores.layouts.mosaic')

return Scenario.register(DOC)
