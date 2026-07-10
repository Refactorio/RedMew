local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Tetrominoes')
ScenarioInfo.add_map_extra_info([[
  The ore field is tiled by interlocking tetromino pieces of
  [item=iron-ore] [item=copper-ore] [item=coal] [item=stone].
  Each piece has a main resource and the others at a lower ratio,
  and no two touching pieces share the same main resource.
  Every seed lays the pieces out differently.
]])

DOC.scenario_name = 'danger-ore-tetrominoes'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_tetrominoes'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.vanilla_ores_stone'
DOC.map_config.main_ores_rotate = nil

return Scenario.register(DOC)
