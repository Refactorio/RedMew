local B = require 'map_gen.shared.builders'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'
local citadel = require 'map_gen.maps.danger_ores.modules.citadel'

ScenarioInfo.set_map_name('Danger Ores - Citadel')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal],
  ringed by concentric walls around spawn.
  The walls are too thick to pass under: belts, pipes and trains
  can only cross them at the gates, and every ring's gates sit at
  different angles, so the way out winds from gate to gate.
]])

DOC.scenario_name = 'danger-ore-citadel'
DOC.map_config.post_map_func = function(map_shape)
  return B.any { citadel(DOC.map_config), map_shape }
end

return Scenario.register(DOC)
