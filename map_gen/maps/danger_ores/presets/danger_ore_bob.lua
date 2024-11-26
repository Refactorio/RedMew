local B = require 'map_gen.shared.builders'
local H = require 'map_gen.maps.danger_ores.modules.helper'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Bobs')
ScenarioInfo.add_map_extra_info([[
  This map is split in 17 sectors. Each sector has a main resource.
]])

DOC.scenario_name = 'danger-ore-bob'
DOC.compatibility.redmew_data.remove_resource_patches = false
DOC.game.technology_price_multiplier = 10
DOC.game.peaceful_mode = false
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.compatibility.bob.ores'
DOC.map_config.resource_patches_config = require 'map_gen.maps.danger_ores.compatibility.bob.resource_patches'
DOC.map_config.spawn_shape = B.circle(40)
DOC.map_config.start_ore_shape = B.circle(48)
DOC.rocket_launched.win_satellite_count = 2500
DOC.map_gen_settings.settings = H.empty_map_settings{
  'bauxite-ore',
  'coal',
  --'cobalt-ore',
  'copper-ore',
  'crude-oil',
  'gem-ore',
  'gold-ore',
  'iron-ore',
  'lead-ore',
  'nickel-ore',
  'quartz',
  'rutile-ore',
  'silver-ore',
  'stone',
  --'sulfur',
  'thorium-ore',
  'tin-ore',
  'tungsten-ore',
  'uranium-ore',
  'zinc-ore',
}
DOC.terraforming = {
  enabled = true,
  start_size = 10 * 32,
  min_pollution = 600,
  max_pollution = 30000,
  pollution_increment = 9,
}

return Scenario.register(DOC)
