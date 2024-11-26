local H = require 'map_gen.maps.danger_ores.modules.helper'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Very BZ')
ScenarioInfo.add_map_extra_info([[
  This map is split in 15 sectors. Each sector has a main resource.
]])

DOC.scenario_name = 'danger-ore-bz'
DOC.compatibility.redmew_data.remove_resource_patches = false
DOC.game.technology_price_multiplier = 1
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.compatibility.bz.ores'
DOC.map_config.resource_patches_config = require 'map_gen.maps.danger_ores.compatibility.bz.resource_patches'
DOC.map_config.spawn_tile = script.active_mods['alien-biomes'] and 'volcanic-green-heat-2' or 'grass-1'
DOC.rocket_launched.win_satellite_count = 100
DOC.map_gen_settings.settings = H.empty_map_settings{
  -- fluid patches
  'crude-oil',
  'gas',
  -- ore patches
  'aluminum-ore',
  'coal',
  'copper-ore',
  'gold-ore',
  'graphite',
  'iron-ore',
  'lead-ore',
  'rich-copper-ore',
  'salt',
  'stone',
  'tin-ore',
  'titanium-ore',
  'tungsten-ore',
  'uranium-ore',
  'zircon',
}

return Scenario.register(DOC)
