local DOC = require 'map_gen.maps.danger_ores.configuration'
local Layouts = require 'map_gen.maps.danger_ores.modules.layouts'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Riches')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
  How rich each sector is changes with distance, to match what 1000 satellites on coal power use:
  iron is rich around spawn for research and building, copper and coal further out for rockets.
]])

DOC.scenario_name = 'danger-ore-riches'
Layouts.apply(DOC.map_config, require 'map_gen.maps.danger_ores.layouts.riches')

return Scenario.register(DOC)
