local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Split')
ScenarioInfo.add_map_extra_info([[
  This map is split in multiple sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
]])

DOC.scenario_name = 'danger-ore-split'
DOC.map_config.main_ores_rotate = 0
DOC.map_config.main_ores_split_count = 4

return Scenario.register(DOC)
