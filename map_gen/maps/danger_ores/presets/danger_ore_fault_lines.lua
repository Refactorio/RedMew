local B = require 'map_gen.shared.builders'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'
local fault_lines = require 'map_gen.maps.danger_ores.modules.fault_lines'

ScenarioInfo.set_map_name('Danger Ores - Fault Lines')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal],
  broken into plates by cracks in the ground.
  Belts cross the cracks underground, but the cracks widen with distance from spawn:
  [item=underground-belt] reach the first cracks, [item=fast-underground-belt] the next,
  [item=express-underground-belt] the rest. [item=pipe-to-ground] cross every crack.
  Players and trains cross at the bridges, and every plate can be walked to.
]])

DOC.scenario_name = 'danger-ore-fault-lines'
DOC.map_config.post_map_func = function(map_shape)
  return B.any { fault_lines(DOC.map_config), map_shape }
end

return Scenario.register(DOC)
