local B = require 'map_gen.shared.builders'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - 3way')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
]])

DOC.scenario_name = 'danger-ore-3way'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_3way'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.3way_ores'
DOC.map_config.main_ores_rotate = nil
DOC.map_config.spawn_shape = B.rectangle(72)
DOC.map_config.start_ore_shape = B.rotate(B.rectangle(88), math.rad(135))
DOC.map_config.water = nil

local t_h_bound, t_v_bound = B.line_x(128), B.line_y(128)
local t_crop = function(_, y)
  return y < -64
end
local t_cross = B.any { t_h_bound, t_v_bound }
local terraforming_bounds = B.subtract(t_cross, t_crop)

DOC.terraforming = {
  enabled = true,
  start_size = 10 * 32,
  min_pollution = 600,
  max_pollution = 24000,
  pollution_increment = 9,
  bounds = terraforming_bounds,
}

return Scenario.register(DOC)
