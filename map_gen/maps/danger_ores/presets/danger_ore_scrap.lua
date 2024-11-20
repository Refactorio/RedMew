local B = require 'map_gen.shared.builders'
local H = require 'map_gen.maps.danger_ores.modules.helper'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Config = require 'config'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Scrapworld')
ScenarioInfo.add_map_extra_info([[
  This map is covered in [entity=scrap].
  Mine it to make room for your factory.
]])
ScenarioInfo.set_new_info([[
  2024-02-24:
      - Added Scrap preset
]])

Config.player_create.starting_items = {
  { count =  2, name = 'burner-mining-drill' },
  { count =  5, name = 'iron-chest' },
  { count = 50, name = 'wood' },
  { count =  1, name = 'reverse-factory-1' },
}

DOC.scenario_name = 'danger-ore-scrap'
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.scrap'
DOC.map_config.no_resource_patch_shape = B.square_diamond(80 * 2)
DOC.map_config.spawn_shape = B.square_diamond(36 * 2)
DOC.map_config.spawn_tile = 'landfill'
DOC.map_config.start_ore_shape = B.square_diamond(44 * 2)
DOC.game.technology_price_multiplier = 5
DOC.game.on_init = function()
  game.forces.player.technologies['automation'].researched = true
  game.forces.player.technologies['reverse-factory-1'].researched = true
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
