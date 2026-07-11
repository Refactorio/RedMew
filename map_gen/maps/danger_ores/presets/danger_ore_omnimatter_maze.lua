local B = require 'map_gen.shared.builders'
local H = require 'map_gen.maps.danger_ores.modules.helper'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local Event = require 'utils.event'
local Config = require 'config'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Omnimatter Maze')
ScenarioInfo.add_map_extra_info([[
  This maze is covered in [item=omnite].
  Mine it to make room for your factory, and explore the corridors to expand.
]])

Config.player_create.starting_items = {
  { count =  1, name = 'stone-furnace' },
  { count =  2, name = 'burner-mining-drill' },
  { count = 50, name = 'wood' },
  { count =  1, name = 'burner-omnitractor' },
  { count =  1, name = 'burner-omniphlog' },
}

DOC.scenario_name = 'danger-ore-omnimatter-maze'
DOC.concrete_on_landfill.refund_tile = 'omnite-refined-concrete'
DOC.game.technology_price_multiplier = 1
DOC.map_config.main_ores = require('map_gen.maps.danger_ores.compatibility.omnimatter.ores'):scale_richness(0.25)
DOC.map_config.main_ores_rotate = nil
DOC.map_config.no_resource_patch_shape = B.translate(B.rectangle(80), 2, 2)
DOC.map_config.spawn_shape = B.translate(B.rectangle(64), 2, 2)
DOC.map_config.spawn_tile = 'landfill'
DOC.map_config.start_ore_shape = B.translate(B.rectangle(68), 2, 2)
DOC.maze.enabled = true
DOC.terraforming.enabled = false
DOC.rocket_launched.win_satellite_count = 100
DOC.map_gen_settings.settings = H.empty_map_settings{
  'infinite-omnite',
  'omnite',
}

local hide_mining_prod = function()
  local p = game.forces.player
  for _, name in pairs({
    'omnipressed-mining-productivity-1',
    'omnipressed-mining-productivity-2',
    'omnipressed-mining-productivity-3',
    'omnipressed-mining-productivity-4',
  }) do
    if p.technologies[name] then
      p.technologies[name].enabled = false
    end
  end
end

Event.on_init(hide_mining_prod)
Event.on_configuration_changed(hide_mining_prod)

return Scenario.register(DOC)
