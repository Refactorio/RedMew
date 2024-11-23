local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Terraforming')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
]])

DOC.scenario_name = 'danger-ore-terraforming'
DOC.terraforming = {
  enabled = true,
  start_size = 8 * 32,
  min_pollution = 400,
  max_pollution = 16000,
  pollution_increment = 4,
}

return Scenario.register(DOC)
