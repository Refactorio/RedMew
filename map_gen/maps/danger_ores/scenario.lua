local Config = require 'config'
local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.add_extra_rule({ 'info.rules_text_danger_ore' })
ScenarioInfo.set_map_description([[
  Clear the ore to expand the base, focus mining efforts on specific sectors to ensure proper material ratios.

  You may not build the factory on ore patches. Exceptions:
      - pipes, underground pipes & pumps
      - belts & underground belts
      - rails, stations, trains and vehicles
      - power poles
      - mining drills and pumpjacks

  The map size is restricted to the pollution generated.
  A significant amount of pollution must affect a section of the map before it is revealed.
  Pollution does not affect biter evolution.
]])

Config.apocalypse.enabled = false
Config.dump_offline_inventories = {
  enabled = true,
  offline_timeout_mins = 30, -- time after which a player logs off that their inventory is provided to the team
  startup_gear_drop_hours = 24, -- time after which players will keep at least their armor when disconnecting
}
Config.market.enabled = false
Config.paint.enabled = false
Config.permissions.presets.no_blueprints = true
Config.player_create.starting_items = {
  { count = 4,  name = 'burner-mining-drill' },
  { count = 4,  name = 'stone-furnace' },
  { count = 8,  name = 'iron-gear-wheel' },
  { count = 16, name = 'iron-plate' },
}
Config.player_rewards.enabled = false
Config.player_shortcuts.enabled = true
Config.player_shortcuts.shortcuts.battery_charge = false
Config.reactor_meltdown.enabled = false

local allowed_entities       = require 'map_gen.maps.danger_ores.modules.banned_entities'
local concrete_on_landfill   = require 'map_gen.maps.danger_ores.modules.concrete_on_landfill'
local container_dump         = require 'map_gen.maps.danger_ores.modules.container_dump'
local map_builder            = require 'map_gen.maps.danger_ores.modules.map'
local mining_productivity    = require 'map_gen.maps.danger_ores.modules.mining_productivity'
local restart_command        = require 'map_gen.maps.danger_ores.modules.restart_command'
local rocket_launched        = require 'map_gen.maps.danger_ores.modules.rocket_launched_simple'
local terraforming           = require 'map_gen.maps.danger_ores.modules.terraforming'

local Public = {}

Public.register = function(danger_ores_config)
  local _C = danger_ores_config

  if _C.allowed_entities.enabled then
    allowed_entities(_C.allowed_entities.entities, _C.allowed_entities.message)
  end
  if _C.biter_drops.enabled then
    require 'map_gen.maps.danger_ores.modules.biter_drops'
  end
  if _C.compatibility.aai_loaders.enabled then
    require 'map_gen.maps.danger_ores.compatibility.aai_loaders.disable_vanilla_loaders'
  end
  if _C.compatibility.deadlock.enabled then
    require 'map_gen.maps.danger_ores.compatibility.deadlock.allow_stacked_recipes'(_C.compatibility.deadlock.items)
  end
  if _C.compatibility.early_construction.enabled then
    require 'map_gen.maps.danger_ores.compatibility.early_construction.starting_items'
  end
  if _C.compatibility.redmew_data.enabled then
    if _C.compatibility.redmew_data.remove_resource_patches then
      _C.map_config.resource_patches = nil
    end
  end
  if _C.concrete_on_landfill.enabled then
    concrete_on_landfill(_C.concrete_on_landfill)
  end
  if _C.container_dump.enabled then
    container_dump(_C.container_dump)
  end
  if _C.disable_mining_productivity.enabled then
    mining_productivity(_C.disable_mining_productivity)
  end
  if _C.map_poll.enabled then
    require 'map_gen.maps.danger_ores.modules.map_poll'
  end
  if _C.map_gen_settings.enabled then
    RS.set_map_gen_settings(_C.map_gen_settings.settings or {})
  end
  if _C.prevent_quality_mining.enabled then
    require 'map_gen.maps.danger_ores.modules.prevent_quality_mining'
  end
  if _C.restart_command.enabled then
    restart_command({ scenario_name = _C.scenario_name })
  end
  if _C.rocket_launched.enabled then
    rocket_launched(_C.rocket_launched)
  end
  if _C.terraforming.enabled then
    terraforming(_C.terraforming)
  end

  Event.on_init(function()
    game.draw_resource_selection = _C.game.draw_resource_selection or false
    if _C.game.manual_mining_speed_modifier then
      game.forces.player.manual_mining_speed_modifier = _C.game.manual_mining_speed_modifier
    end
    if _C.game.technology_price_multiplier then
      game.difficulty_settings.technology_price_multiplier = game.difficulty_settings.technology_price_multiplier * _C.game.technology_price_multiplier
    end
    if _C.game.enemy_evolution then
      game.map_settings.enemy_evolution = _C.game.enemy_evolution
    end
    RS.get_surface().always_day = _C.game.always_day or false
    RS.get_surface().peaceful_mode = _C.game.peaceful_mode or false
    if _C.game.on_init then
      _C.game.on_init()
    end
  end)

  return map_builder(_C.map_config)
end

return Public