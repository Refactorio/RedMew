local H = require 'map_gen.maps.danger_ores.modules.helper'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Config = require 'config'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Krastorio2')
ScenarioInfo.add_map_extra_info([[
  This map is split in four sectors [item=iron-ore] [item=copper-ore] [item=coal] [item=stone].
  Each sector has a main resource and the other resources at a lower ratio.
]])

Config.redmew_qol.loaders = false
Config.player_create.starting_items = {
  { count =   1, name = 'assembling-machine-1' },
  { count =   1, name = 'burner-mining-drill' },
  { count = 200, name = 'copper-cable' },
  { count =  25, name = 'electronic-circuit' },
  { count =  35, name = 'iron-gear-wheel' },
  { count = 400, name = 'iron-plate' },
  { count =   1, name = 'kr-medium-container' },
  { count =   5, name = 'kr-sentinel' },
  { count =   5, name = 'kr-wind-turbine' },
  { count =   1, name = 'lab' },
  { count =   5, name = 'medium-electric-pole' },
  { count =   1, name = 'steel-chest' },
  { count =   1, name = 'stone-furnace' },
  { count =  50, name = 'wood' },
}

DOC.scenario_name = 'danger-ore-krastorio2'
DOC.compatibility.deadlock.items = require 'map_gen.maps.danger_ores.compatibility.krastorio2.allowed_items'
DOC.game.technology_price_multiplier = 5
DOC.map_config.spawn_tile = 'landfill'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.compatibility.krastorio2.ores'
DOC.map_config.resource_patches_config = require 'map_gen.maps.danger_ores.compatibility.krastorio2.resource_patches'
DOC.map_gen_settings.settings = H.empty_map_settings{
  'coal',
  'copper-ore',
  'crude-oil',
  'imersite',
  'iron-ore',
  'mineral-water',
  'rare-metals',
  'stone',
  'uranium-ore',
}
DOC.terraforming = {
  enabled = true,
  start_size = 10 * 32,
  min_pollution = 400,
  max_pollution = 16000,
  pollution_increment = 8,
}

--[[ Win condition in K2: build intergalactic transceiver ]]
DOC.rocket_launched.enabled = false
local rocket_launched = require 'map_gen.maps.danger_ores.compatibility.krastorio2.rocket_launched'
rocket_launched()

return Scenario.register(DOC)
