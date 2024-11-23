local B = require 'map_gen.shared.builders'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Poor man\'s coal fields')
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.
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
