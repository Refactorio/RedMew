local B = require 'map_gen.shared.builders'
local H = require 'map_gen.maps.danger_ores.modules.helper'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Bobs & Angels')
ScenarioInfo.add_map_extra_info([[
  This map is split in 6 sectors. Each sector has a main resource.
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

DOC.scenario_name = 'danger-ore-bob-angel'
DOC.compatibility.redmew_data.remove_resource_patches = false
DOC.game.technology_price_multiplier = 5
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.compatibility.bob_angel.ores'
DOC.map_config.resource_patches_config = require 'map_gen.maps.danger_ores.compatibility.bob_angel.resource_patches'
DOC.map_config.spawn_shape = B.circle(80)
DOC.map_config.start_ore_shape = B.circle(86)
DOC.rocket_launched.enabled = false
DOC.allowed_entities.entities = table.merge{
  DOC.allowed_entities.entities,
  require 'map_gen.maps.danger_ores.compatibility.bob_angel.allowed_entities'
}
DOC.map_gen_settings.settings = H.empty_map_settings{
  'angels-ore1', -- Saphirite
  'angels-ore2', -- Jivolite
  'angels-ore3', -- stiratite
  'angels-ore4', -- Crotinium
  'angels-ore5', -- rubyte
  'angels-ore6', -- bobmonium
  'angels-fissure',
  'angels-natural-gas', -- gas well
  'coal',
  'crude-oil',
}

local rocket_launched = require 'map_gen.maps.danger_ores.modules.rocket_launched'
rocket_launched{
  recent_chunks_max = 10,
  ticks_between_waves = 60 * 30,
  enemy_factor = 5,
  max_enemies_per_wave_per_chunk = 60,
  extra_rockets = 100,
}

return Scenario.register(DOC)
