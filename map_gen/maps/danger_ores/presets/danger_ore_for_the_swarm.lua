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
ScenarioInfo.set_new_info([[
  2019-04-24:
      - Stone ore density reduced by 1/2
      - Ore quadrants randomized
      - Increased time factor of biter evolution from 5 to 7
      - Added win conditions (+5% evolution every 5 rockets until 100%, +100 rockets until biters are wiped)

  2019-03-30:
      - Uranium ore patch threshold increased slightly
      - Bug fix: Cars and tanks can now be placed onto ore!
      - Starting minimum pollution to expand map set to 650
        View current pollution via Debug Settings [F4] show-pollution-values,
        then open map and turn on pollution via the red box.
      - Starting water at spawn increased from radius 8 to radius 16 circle.

  2019-03-27:
      - Ore arranged into quadrants to allow for more controlled resource gathering.

  2020-09-02:
      - Destroyed chests dump their content as coal ore.

  2020-12-28:
      - Changed win condition. First satellite kills all biters, launch 500 to win the map.

  2021-04-06:
      - Rail signals and train stations now allowed on ore.
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
