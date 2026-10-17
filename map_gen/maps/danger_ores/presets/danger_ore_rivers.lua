local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Rivers')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal],
  with rivers instead of lakes. They spring up around spawn and flow outward,
  meandering, widening and branching the further they go.
  Near spawn they are often narrow fords you can span with
  [item=express-underground-belt] and [item=pipe-to-ground]; further out
  they are mostly wide water that needs [item=landfill] or a way around.
  Water is never far away, wherever you build.
]])

DOC.scenario_name = 'danger-ore-rivers'
DOC.map_config.water = require 'map_gen.maps.danger_ores.modules.rivers'

return Scenario.register(DOC)
