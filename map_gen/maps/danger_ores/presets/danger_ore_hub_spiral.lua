local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'
local sqrt = math.sqrt

ScenarioInfo.set_map_name('Danger Ores - Hub Spiral')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
]])

DOC.scenario_name = 'danger-ore-hub-spiral'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_hub_spiral'
DOC.map_config.water_scale = function(x, y)
  local d = sqrt(x * x + y * y)
  return 1 / (24 + (0.1 * d))
end

return Scenario.register(DOC)
