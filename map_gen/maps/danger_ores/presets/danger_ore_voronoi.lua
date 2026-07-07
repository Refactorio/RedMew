local DOC = require 'map_gen.maps.danger_ores.configuration'
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
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_voronoi'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.voronoi_ores'
DOC.map_config.main_ores_rotate = nil

return Scenario.register(DOC)
