local H = require 'map_gen.maps.danger_ores.modules.helper'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Exotic Industries Spiral')
ScenarioInfo.add_map_extra_info([[
  This map is split in 3 sectors. Each sector has a main resource.
  Resource veins are scattered across the map.
]])

storage.config.redmew_qol.loaders = false

DOC.scenario_name = 'danger-ore-exotic-industries-spiral'
DOC.compatibility.redmew_data.remove_resource_patches = false
DOC.game.technology_price_multiplier = 1
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_spiral'
DOC.map_config.no_resource_patch_shape = nil
DOC.map_config.resource_patches_config = require 'map_gen.maps.danger_ores.compatibility.exotic_industries.resource_patches'
DOC.map_config.spawn_tile = 'landfill'
DOC.allowed_entities.allowed_entities['ei_alien-stabilizer'] = true
DOC.map_gen_settings.settings = H.empty_map_settings{
  -- point patches
  'crude-oil',
  'ei_coal-patch',
  'ei_copper-patch',
  'ei_gold-patch',
  'ei_iron-patch',
  'ei_lead-patch',
  'ei_neodym-patch',
  'ei_sulfur-patch',
  'ei_uranium-patch',
  -- ore patches
  'coal',
  'copper-ore',
  'iron-ore',
}

DOC.biter_drops.enabled = false
require 'map_gen.maps.danger_ores.compatibility.exotic_industries.biter_drops'

DOC.rocket_launched.enabled = false
local rocket_launched = require 'map_gen.maps.danger_ores.compatibility.exotic_industries.rocket_launched'
rocket_launched()

return Scenario.register(DOC)
