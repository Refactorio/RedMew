local DOC = require 'map_gen.maps.danger_ores.configuration'
local Layouts = require 'map_gen.maps.danger_ores.modules.layouts'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Voronoi')
ScenarioInfo.add_map_extra_info([[
  The ore field is split into irregular Voronoi cells of
  [item=iron-ore] [item=copper-ore] [item=coal] [item=stone].
  Each cell has a main resource and the others at a lower ratio,
  and no two touching cells share the same main resource.
  Every seed lays the cells out differently.
]])

DOC.scenario_name = 'danger-ore-voronoi'
Layouts.apply(DOC.map_config, require 'map_gen.maps.danger_ores.layouts.voronoi')

return Scenario.register(DOC)
