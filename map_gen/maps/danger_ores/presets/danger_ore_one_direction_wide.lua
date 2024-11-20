local B = require 'map_gen.shared.builders'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - One Direction Wide')
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

DOC.scenario_name = 'danger-ore-one-direction-wide'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_one_direction'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.vanilla_ores_one_direction'
DOC.map_config.main_ores_rotate = nil
DOC.map_config.no_resource_patch_shape = B.rectangle(160)
DOC.map_config.ore_width = 96
DOC.map_config.spawn_shape = B.rectangle(40, 264)
DOC.map_config.start_ore_shape = B.rectangle(56, 280)
DOC.map_config.water = nil
DOC.map_config.post_map_func = function(map_shape)
  local function map_bounds(x, y)
    return x > -28 and y > -144 and y < 144
  end
  local function water_bounds(x, y)
    return x > -30 and y > -146 and y < 146
  end
  local function line(x, y)
    return x > 256 and y > -1 and y < 1
  end
  local water_line = B.change_tile(line, true, 'water')
  local top_water_line = B.translate(water_line, 0, -48)
  local bottom_water_line = B.translate(water_line, 0, 48)
  map_shape = B.any({ top_water_line, bottom_water_line, map_shape })
  local water_border = B.tile('water')
  water_border = B.choose(water_bounds, water_border, B.empty_shape)
  return B.choose(map_bounds, map_shape, water_border)
end
DOC.terraforming.bounds = {
  enabled = true,
  start_size = 10 * 32,
  min_pollution = 450,
  max_pollution = 24000,
  pollution_increment = 9,
  bounds = function(x, y)
    return x > -64 and y > -160 and y < 160
  end,
}
table.insert(DOC.map_gen_settings.settings, { height = 32 * 10 })

return Scenario.register(DOC)
