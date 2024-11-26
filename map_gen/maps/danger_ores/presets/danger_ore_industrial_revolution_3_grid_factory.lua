local H = require 'map_gen.maps.danger_ores.modules.helper'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Config = require 'config'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Industrial Revolution 3 Grid Factory')
ScenarioInfo.add_map_extra_info([[
  This map is split in 6 sectors. Each sector has a main resource. Gas fissures are scattered across the map.
]])

Config.redmew_qol.loaders = false
Config.player_create.starting_items = {
  { count =   1, name = 'shotgun' },
  { count =   4, name = 'burner-mining-drill' },
  { count =   4, name = 'stone-furnace' },
  { count =  25, name = 'copper-rivet' },
  { count =  25, name = 'copper-rod' },
  { count =  25, name = 'tin-gear-wheel' },
  { count =  25, name = 'tin-plate' },
  { count =  25, name = 'tin-rod' },
  { count =  50, name = 'copper-gear-wheel' },
  { count =  50, name = 'copper-plate' },
  { count =  50, name = 'shotgun-shell' },
  { count = 100, name = 'tin-scrap' },
  { count = 150, name = 'copper-scrap' },
}

DOC.scenario_name = 'danger-ore-industrial-revolution-3-grid-factory'
DOC.game.technology_price_multiplier = 5
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_grid_factory'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.compatibility.industrial_revolution_3.ores_grid_factory'
DOC.map_config.resource_patches_config = require 'map_gen.maps.danger_ores.compatibility.industrial_revolution_3.resource_patches'
DOC.map_config.spawn_tile = 'tarmac'
DOC.map_gen_settings.settings = H.empty_map_settings{
  -- point patches
  'crude-oil',
  'dirty-steam-fissure',
  'natural-gas-fissure',
  'steam-fissure',
  'sulphur-gas-fissure',
  -- ore patches
  'coal',
  'copper-ore',
  'iron-ore',
  'stone',
  'uranium-ore',
  'gold-ore',
  'tin-ore',
}

return Scenario.register(DOC)
