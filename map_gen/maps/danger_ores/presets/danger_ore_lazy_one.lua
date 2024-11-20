local DOC = require 'map_gen.maps.danger_ores.configuration'
local Config = require 'config'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Lazy One')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
]])

ScenarioInfo.set_new_info([[
  2023-06-27:
      - disabled Crafting
      - added Starting Equipment

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

Config.permissions.presets.no_handcraft = true
Config.player_create.starting_items = {
  { count = 1,  name = 'steel-furnace' },
  { count = 1,  name = 'electric-mining-drill-2' },
  { count = 1,  name = 'medium-electric-pole' },
  { count = 1,  name = 'offshore-pump' },
  { count = 1,  name = 'boiler-2' },
  { count = 1,  name = 'steam-turbine' },
  { count = 1,  name = 'assembling-machine-2' },
  { count = 1,  name = 'fast-inserter' },
  { count = 1,  name = 'long-handed-inserter' },
  { count = 1,  name = 'steel-chest' },
  { count = 1,  name = 'storehouse-basic' },
  { count = 1,  name = 'lab' },
  { count = 1,  name = 'radar' },
  { count = 1,  name = 'rocket-fuel' },
}

DOC.scenario_name = 'danger-ore-lazy-one'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.vanilla_ores_landfill'
DOC.map_config.spawn_tile = 'landfill'
DOC.map_config.water = nil

return Scenario.register(DOC)
