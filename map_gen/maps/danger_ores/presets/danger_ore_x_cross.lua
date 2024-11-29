local B = require 'map_gen.shared.builders'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - X Cross')
ScenarioInfo.add_map_extra_info([[
  This map is split in four sectors [item=iron-ore] [item=copper-ore] [item=coal] [item=stone].
  Each sector has a main resource and the other resources at a lower ratio.
]])

local h_bound, v_bound = B.line_x(182), B.line_y(182)
local cross = B.rotate(B.any{ h_bound, v_bound }, math.rad(135))

DOC.scenario_name = 'danger-ore-x-cross'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_x_cross'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.x_cross_ores'
DOC.map_config.main_ores_rotate = 135
DOC.map_config.spawn_shape = B.rectangle(100)
DOC.map_config.start_ore_shape = B.rotate(B.rectangle(116), math.rad(135))
DOC.map_config.water = nil
DOC.terraforming.bounds = cross

return Scenario.register(DOC)
