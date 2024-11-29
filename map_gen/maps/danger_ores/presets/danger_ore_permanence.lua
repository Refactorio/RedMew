local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Permanence')
ScenarioInfo.add_map_extra_info([[
  This map is divided in quadrants of [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.

  Mined entities will create ore drops beneath them, encouraging players to strategize their factory layouts.

  Only specific machines, such as assembling machines, furnaces, roboports, chemical plants... can generate ore drops,
  while entities already allowed on ore like miners, belts, and power poles will not.

  Additionally, upgrading your base will also spawn resources, so plan and upgrade carefully!
  Transform your gameplay and embrace the permanence of your factory's footprint!
]])

DOC.scenario_name = 'danger-ore-grid-permanence'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_grid_factory'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.vanilla_ores_landfill'
DOC.map_config.spawn_tile = 'red-refined-concrete'

local permanence = require 'map_gen.maps.danger_ores.modules.permanence'
permanence({ multiplier = 1 })

return Scenario.register(DOC)