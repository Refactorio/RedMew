local B = require 'map_gen.shared.builders'
local H = require 'map_gen.maps.danger_ores.modules.helper'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'
local Config = require 'config'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Scrapworld Maze')
ScenarioInfo.add_map_extra_info([[
  This maze is covered in [entity=scrap], with occasional dense patches of
  [item=stone] for landfill.
  Mine it to make room for your factory, and explore the corridors to expand.
]])

Config.player_create.starting_items = {
  { count =  2, name = 'burner-mining-drill' },
  { count =  5, name = 'iron-chest' },
  { count = 50, name = 'wood' },
  { count =  1, name = 'recycler' },
}

DOC.scenario_name = 'danger-ore-scrap-maze'
DOC.map_config.main_ore_resource_patches_config = Factory.patches()
    :add_patch('stone', {scale = 1 / 32, threshold = 0.6, richness = {mult = 0.7, pow = 1.45}})
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_patches'
DOC.map_config.main_ores = require('map_gen.maps.danger_ores.config.scrap'):scale_richness(0.25)
DOC.map_config.main_ores_rotate = nil
DOC.map_config.no_resource_patch_shape = B.translate(B.rectangle(80), 2, 2)
DOC.map_config.spawn_shape = B.translate(B.rectangle(64), 2, 2)
DOC.map_config.spawn_tile = 'landfill'
DOC.map_config.start_ore_shape = B.translate(B.rectangle(68), 2, 2)
DOC.maze.enabled = true
DOC.terraforming.enabled = false
DOC.game.technology_price_multiplier = 5
DOC.game.on_init = function()
  game.forces.player.technologies['automation'].researched = true
  game.forces.player.technologies['recycling'].researched = true
end
DOC.map_gen_settings.settings = H.empty_map_settings{
  -- fluid patches
  'crude-oil',
  -- ore patches
  'coal',
  'copper-ore',
  'iron-ore',
  'scrap',
  'stone',
  'uranium-ore',
}

return Scenario.register(DOC)
