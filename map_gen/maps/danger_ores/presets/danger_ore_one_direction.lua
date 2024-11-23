local B = require 'map_gen.shared.builders'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - One Direction')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
]])

DOC.scenario_name = 'danger-ore-one-direction'
DOC.rocket_launched.win_satellite_count = 250
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_one_direction'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.vanilla_ores_one_direction'
DOC.map_config.main_ores_rotate = nil
DOC.map_config.no_resource_patch_shape = B.rectangle(160)
DOC.map_config.spawn_shape = B.rectangle(72)
DOC.map_config.start_ore_shape = B.rectangle(88)
DOC.map_config.water = nil
DOC.map_config.post_map_func = function(map_shape)
  local function map_bounds(x, y)
    return x > -44 and y > -48 and y < 48
  end
  local function water_bounds(x, y)
    return x > -46 and y > -50 and y < 50
  end
  local water_border = B.tile('water')
  water_border = B.choose(water_bounds, water_border, B.empty_shape)
  return B.choose(map_bounds, map_shape, water_border)
end
DOC.terraforming.bounds = {
  enabled = true,
  start_size = 12 * 32,
  min_pollution = 200,
  max_pollution = 16000,
  pollution_increment = 4,
  bounds = function(x, y)
    return x > -64 and y > -64 and y < 64
  end,
}
table.insert(DOC.map_gen_settings.settings, { height = 32 * 3 })

return Scenario.register(DOC)
