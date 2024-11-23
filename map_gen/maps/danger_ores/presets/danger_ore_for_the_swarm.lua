local DOC = require 'map_gen.maps.danger_ores.configuration'
local Config = require 'config'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores For The Swarm')
ScenarioInfo.add_map_extra_info([[
  The Swarm hungers [item=spidertron], feed it all the ore to expand the base,
  focus mining efforts on specific sectors to ensure
  proper material ratios, expand the map with pollution!

  This map is split in four sectors [item=iron-ore] [item=copper-ore] [item=coal] [item=stone].
  Each sector has a main resource and the other resources at a lower ratio.
]])

Config.player_create.starting_items = {
  { count =    1, name = 'power-armor' },
  { count =    9, name = 'personal-roboport-equipment' },
  { count =   13, name = 'solar-panel-equipment' },
  { count = 1000, name = 'early-construction-robot' },
  { count =    1, name = 'spidertron' },
  { count =    1, name = 'spidertron-powersource' },
  { count =   10, name = 'spidertron-battery' },
  { count =    3, name = 'spidertron-leg-augment' },
}

DOC.scenario_name = 'danger-ore-for-the-swarm'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_honeycomb'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.vanilla_gradient_ores'

return Scenario.register(DOC)
