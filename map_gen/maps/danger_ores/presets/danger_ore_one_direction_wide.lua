local B = require 'map_gen.shared.builders'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - One Direction Wide')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
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
