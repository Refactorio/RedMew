local B = require 'map_gen.shared.builders'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Square')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
]])

local start_ore_offset = 44

DOC.scenario_name = 'danger-ore-square'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_square'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.3way_ores'
DOC.map_config.main_ores_rotate = nil
DOC.map_config.main_ores_shuffle_order = true
DOC.map_config.main_ores_start_ore_offset = start_ore_offset
DOC.map_config.no_resource_patch_shape = B.rectangle(160)
DOC.map_config.no_water_shape = B.circle(192)
DOC.map_config.spawn_shape = B.rectangle(72)
DOC.map_config.start_ore_shape = B.translate(B.rectangle(88), -start_ore_offset, start_ore_offset)
DOC.map_config.post_map_func = function(map_shape)
  local function map_bounds(x, y)
    return x > -44 and y < 44
  end
  local function water_bounds(x, y)
    return x > -46 and y < 46
  end
  local water_border = B.tile('water')
  water_border = B.choose(water_bounds, water_border, B.empty_shape)
  return B.choose(map_bounds, map_shape, water_border)
end
DOC.terraforming = {
  enabled = true,
  start_size = 8 * 32,
  min_pollution = 450,
  max_pollution = 24000,
  pollution_increment = 9,
  bounds = function(x, y)
    return x > -64 and y < 64
  end,
}

return Scenario.register(DOC)
