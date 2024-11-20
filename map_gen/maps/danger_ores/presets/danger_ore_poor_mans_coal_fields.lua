local B = require 'map_gen.shared.builders'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Poor man\'s coal fields')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
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

DOC.scenario_name = 'danger-ore-poor-mans-coal-fields'
DOC.game.technology_price_multiplier = 6
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_poor_mans_coal_fields'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.poor_mans_coal_fields_ores'
DOC.map_config.spawn_shape = B.rectangle(32 * 3)
DOC.map_config.spawn_water_tile = 'water-shallow'
DOC.map_config.start_ore_shape = B.rectangle(32 * 3 + 15)
DOC.rocket_launched.win_satellite_count = 300
DOC.game.on_init = function()
  game.forces.player.technologies['atomic-bomb'].enabled = false
  game.forces.player.technologies['cliff-explosives'].enabled = false
  game.forces.player.technologies['railway'].enabled = false
  game.map_settings.pollution.pollution_per_tree_damage = 0
  game.map_settings.pollution.pollution_restored_per_tree_damage = 0
end
DOC.terraforming = {
  start_size = 8 * 32,
  min_pollution = 600,
  max_pollution = 24000,
  pollution_increment = 9,
}

return Scenario.register(DOC)
