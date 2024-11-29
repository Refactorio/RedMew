local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Grid Factory')
ScenarioInfo.add_map_extra_info([[
  This map is divided in quadrants of [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
]])

DOC.scenario_name = 'danger-ore-grid-factory'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_grid_factory'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.vanilla_ores_landfill'
DOC.map_config.spawn_tile = 'orange-refined-concrete'

return Scenario.register(DOC)
