local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Archipelago')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal],
  scattered over islands in an open sea.
  The islands are all ore, as usual, but the sea can be [item=landfill]ed:
  building space costs [item=stone], which is mixed into every sector,
  instead of ore you have to mine out.
  Spawn sits on its own island with every ore close by.
]])

DOC.scenario_name = 'danger-ore-archipelago'
DOC.map_config.water = require 'map_gen.maps.danger_ores.modules.archipelago'

return Scenario.register(DOC)
