local B = require 'map_gen.shared.builders'
local H = require 'map_gen.maps.danger_ores.modules.helper'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Pyanodon Fusion Energy')
ScenarioInfo.add_map_extra_info([[
  This map is split in 6 sectors.
  Each sector has a main resource.
]])

DOC.scenario_name = 'danger-ore-pyfe'
DOC.compatibility.redmew_data.remove_resource_patches = false
DOC.map_config.enemy = nil
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.compatibility.pyanodon.pyfe_ores'
DOC.map_config.ore_builder = require 'map_gen.maps.danger_ores.modules.ore_builder_without_gaps'
DOC.map_config.resource_patches_config = require 'map_gen.maps.danger_ores.compatibility.pyanodon.pyfe_resource_patches'
DOC.map_config.spawn_shape = B.rectangle(100)
DOC.map_config.spawn_tile = 'landfill'
DOC.map_config.start_ore_shape = B.empty_shape
DOC.allowed_entities.types['inserter'] = true
DOC.allowed_entities.types['splitter'] = true
DOC.game.technology_price_multiplier = 1
DOC.game.on_init = function()
  game.map_settings.pollution.diffusion_ratio = 0.01
  game.map_settings.pollution.min_to_diffuse = 300
end
DOC.map_gen_settings.settings = H.empty_map_settings{
  -- point patches
  'crude-oil',
  'regolites',
  'volcanic-pipe',
  -- ore patches
  'coal',
  'stone',
  'copper-ore',
  'uranium-ore',
  'iron-ore',
  'borax',
  'molybdenum-ore',
  'niobium',
}
DOC.terraforming = {
  enabled = true,
  start_size = 12 * 32,
  min_pollution = 300,
  max_pollution = 16000,
  pollution_increment = 2,
}

DOC.rocket_launched.enabled = false
local rocket_launched = require 'map_gen.maps.danger_ores.compatibility.pyanodon.rocket_launched'
rocket_launched()

local tech_scaling = require 'map_gen.maps.danger_ores.modules.tech_scaling'
tech_scaling({
  effects = {
    ['automation-science-pack'] = 1.00,
    ['logistic-science-pack']   = 0.75,
    ['chemical-science-pack']   = 0.50,
    ['production-science-pack'] = 0.25,
    ['utility-science-pack']    = 0.20,
    ['space-science-pack']      = 0.10,
  },
})

return Scenario.register(DOC)
