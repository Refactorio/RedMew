local DOC = require 'map_gen.maps.danger_ores.configuration'
local Config = require 'config'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Christmas Tree)')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
]])

Config.day_night.enabled = true
Config.day_night.use_fixed_brightness = true
Config.day_night.fixed_brightness = 0.70

DOC.scenario_name = 'danger-ore-xmas-tree'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_xmas_tree'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.one_direction_ores_xmas'
DOC.map_config.main_ores_rotate = nil
DOC.map_config.water = nil
DOC.game.always_day = false
DOC.game.on_init = function()
  game.forces.player.technologies['landfill'].enabled = false
end
DOC.terraforming = {
  enabled = true,
  start_size = 12 * 32,
  min_pollution = 450,
  max_pollution = 24000,
  pollution_increment = 9,
}

return Scenario.register(DOC)
