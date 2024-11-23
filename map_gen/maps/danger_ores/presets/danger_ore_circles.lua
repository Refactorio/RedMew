local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Circles')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
]])

DOC.scenario_name = 'danger-ore-circles'
DOC.map_config.circle_thickness = 16 -- Thickness of the rings at weight 1
DOC.map_config.circle_grow_factor = 768 -- How much distance before the thickness doubles.
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_circles'

return Scenario.register(DOC)
