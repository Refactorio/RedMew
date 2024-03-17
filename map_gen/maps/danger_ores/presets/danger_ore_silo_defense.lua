local b = require 'map_gen.shared.builders'
local Config = require 'config'
local Event = require 'utils.event'
local MGSP = require 'resources.map_gen_settings'
local RS = require 'map_gen.shared.redmew_surface'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Global = require 'utils.global'
local Server = require 'features.server'
local ShareGlobals = require 'map_gen.maps.danger_ores.modules.shared_globals'

local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name('Danger Ore Silo Defense')
ScenarioInfo.set_map_description([[
  Clear the ore to expand the base,
  focus mining efforts on specific sectors to ensure
  proper material ratios, expand the map with pollution!
]])
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.

  You may not build the factory on ore patches. Exceptions:
  [item=burner-mining-drill] [item=electric-mining-drill] [item=pumpjack] [item=small-electric-pole] [item=medium-electric-pole] [item=big-electric-pole] [item=substation] [item=car] [item=tank] [item=spidertron] [item=locomotive] [item=cargo-wagon] [item=fluid-wagon] [item=artillery-wagon]
  [item=transport-belt] [item=fast-transport-belt] [item=express-transport-belt] [item=underground-belt] [item=fast-underground-belt] [item=express-underground-belt] [item=rail] [item=rail-signal] [item=rail-chain-signal] [item=train-stop]

  The map size is restricted to the pollution generated. A significant amount of
  pollution must affect a section of the map before it is revealed. Pollution
  does not affect biter evolution.
]])

ScenarioInfo.set_new_info([[
  2024-03-17:
    - initial relese DO/Silo Defense
]])

ScenarioInfo.add_extra_rule({ 'info.rules_text_danger_ore' })

local this = {
  groups = {}
}

local map = require 'map_gen.maps.danger_ores.modules.map'
local main_ores_config = require 'map_gen.maps.danger_ores.config.deadlock_beltboxes_ores_landfill'
local trees = require 'map_gen.maps.danger_ores.modules.trees'
local enemy = require 'map_gen.maps.danger_ores.modules.enemy'

local banned_entities = require 'map_gen.maps.danger_ores.modules.banned_entities'
local allowed_entities = require 'map_gen.maps.danger_ores.config.deadlock_beltboxes_allowed_entities'
banned_entities(allowed_entities)

RS.set_map_gen_settings({
  MGSP.grass_only,
  MGSP.enable_water,
  { terrain_segmentation = 'normal', water = 'normal' },
  { starting_area = 1.75 },
  MGSP.ore_oil_none,
  MGSP.enemy_none,
  MGSP.cliff_none,
  MGSP.tree_none,
})

Config.market.enabled = false
Config.player_rewards.enabled = false
Config.redmew_qol.loaders = false
Config.dump_offline_inventories = {
    enabled = true,
    offline_timout_mins = 30 -- time after which a player logs off that their inventory is provided to the team
}
Config.paint.enabled = false
Config.permissions.presets.no_blueprints = true
Config.player_create.starting_items = {
  { count = 5,   name = 'stone-furnace' },
  { count = 5,   name = 'burner-mining-drill' },
  { count = 100, name = 'wood' },
  { count = 1,   name = 'pistol' },
  { count = 20,  name = 'firearm-magazine' },
}

---@param entity LuaEntity
local fill_turret_callback = Token.register(function(entity)
  if not (entity and entity.valid) then
    return
  end

  entity.insert({name = 'firearm-magazine', count = 35})
end)

---@param data
---@field name string, prototype name
---@field position MapPosition
---@field callback? TokenID
local place_entity_callback = Token.register(function(data)
  local surface = RS.get_surface()
  local position = surface.find_non_colliding_position(data.name, data.position, 5, 1)
  if not position then
    return
  end

  local entity = surface.create_entity{
    name = data.name,
    position = position,
    force = 'player',
    create_build_effect_smoke = true,
    move_stuck_players = true
  }

  if entity.name == 'rocket-silo' and not this.silo_created then
    entity.minable = false
    this.silo = entity
    this.silo_created = true
    this.silo_position = entity.position
    this.silo_id = script.register_on_entity_destroyed(entity)
  end

  if data.callback then
    Task.queue_task(data.callback, entity)
  end
end)

local set_game_lost = Token.register(function()
  ShareGlobals.data.map_won = true
  ShareGlobals.data.map_won_objective = false
  local message = 'Alas! Unfortunately, the map has been lost. Restart the map with /restart'
  game.print({'danger_ores.lose'})
  Server.to_discord_bold(message)

  game.set_game_state({
    game_finished = true,
    player_won = false,
    can_continue = true,
    victorious_force = game.forces.enemy,
  })
end)

Global.register_init(
  { this = this },
  function(tbl)
    tbl.this = this

    game.draw_resource_selection = false
    game.forces.player.manual_mining_speed_modifier = 1
    game.difficulty_settings.technology_price_multiplier = game.difficulty_settings.technology_price_multiplier * 20

    local techs = game.forces.player.technologies
    techs['mining-productivity-1'].enabled = false
    techs['mining-productivity-2'].enabled = false
    techs['mining-productivity-3'].enabled = false
    techs['mining-productivity-4'].enabled = false
    techs['logistics'].researched = true
    techs['automation'].researched = true
    techs['gun-turret'].researched = true
    techs['stone-wall'].researched = true

    local path_finder = game.map_settings.path_finder
    path_finder.fwd2bwd_ratio = 2
    path_finder.goal_pressure_ratio = 3
    path_finder.short_cache_size = 30
    path_finder.long_cache_size = 50
    path_finder.short_cache_min_cacheable_distance = 8
    path_finder.long_cache_min_cacheable_distance = 60
    path_finder.max_clients_to_accept_any_new_request = 4
    path_finder.max_clients_to_accept_short_new_request = 150
    path_finder.start_to_goal_cost_multiplier_to_terminate_path_find = 10000

    Task.queue_task(place_entity_callback, { name = 'rocket-silo', position = {17, -17}})
    Task.queue_task(place_entity_callback, { name = 'gun-turret', position = {18, -24}, callback = fill_turret_callback})
    Task.queue_task(place_entity_callback, { name = 'gun-turret', position = {24, -23}, callback = fill_turret_callback})
    Task.queue_task(place_entity_callback, { name = 'gun-turret', position = {25, -16}, callback = fill_turret_callback})
    Task.queue_task(place_entity_callback, { name = 'gun-turret', position = {24, -10}, callback = fill_turret_callback})
    Task.queue_task(place_entity_callback, { name = 'gun-turret', position = {17, -09}, callback = fill_turret_callback})
    Task.queue_task(place_entity_callback, { name = 'gun-turret', position = {11, -10}, callback = fill_turret_callback})
    Task.queue_task(place_entity_callback, { name = 'gun-turret', position = {10, -17}, callback = fill_turret_callback})
    Task.queue_task(place_entity_callback, { name = 'gun-turret', position = {11, -23}, callback = fill_turret_callback})
  end,
  function(tbl)
    this = tbl.this
  end
)

Event.add(defines.events.on_unit_group_finished_gathering, function(event)
  local group = event.group
  if not (group and group.valid and group.surface.index == RS.get_surface().index) then
    return
  end

  group.set_command{
    type = defines.command.go_to_location,
    destination_entity = this.silo,
    distraction = defines.distraction.by_enemy,
    radius = 8,
  }
  group.start_moving()
  this.groups[group.group_number] = group
end)

Event.add(defines.events.on_ai_command_completed, function(event)
  if event.was_distracted then
    return
  end

  local id = event.unit_number
  local result = event.result
  local group = this.groups[id]
  if not (group and group.valid) then
    this.groups[id] = nil
    return
  end

  if result == defines.behavior_result.success then
    group.set_command{
      type = defines.command.attack,
      target = this.silo,
      distraction = defines.distraction.by_damage,
    }
  elseif result == defines.behavior_result.fail or result == defines.behavior_result.deleted then
    this.groups[id] = nil
  end
end)

Event.add(defines.events.on_entity_destroyed, function(event)
  local registration_number = event.registration_number
  if registration_number ~= this.silo_id then
    return
  end

  local spawn = RS.get_surface().create_entity
  local target = spawn{
    name = 'rocket-silo',
    position = this.silo_position,
    force = 'player',
    create_build_effect_smoke = false,
    move_stuck_players = true,
  }
  local _ = spawn{
    name = 'atomic-rocket',
    position = this.silo_position,
    target = target,
    speed = 0.5,
  }

  Task.set_timeout(8, set_game_lost)
end)

--- Map expansion limited by biters
-- local terraforming = require 'map_gen.maps.danger_ores.modules.terraforming'
-- terraforming({ start_size = 8 * 32, min_pollution = 600, max_pollution = 24000, pollution_increment = 9 })

local rocket_launched = require 'map_gen.maps.danger_ores.modules.rocket_launched'
rocket_launched({
  recent_chunks_max = 10,
  ticks_between_waves = 60 * 30,
  enemy_factor = 5,
  max_enemies_per_wave_per_chunk = 60,
  extra_rockets = 666
})

local restart_command = require 'map_gen.maps.danger_ores.modules.restart_command'
restart_command({ scenario_name = 'danger-ore-silo-defense' })

local container_dump = require 'map_gen.maps.danger_ores.modules.container_dump'
container_dump({ entity_name = 'coal' })

--- Already all landfill tiles
-- local concrete_on_landfill = require 'map_gen.maps.danger_ores.modules.concrete_on_landfill'
-- concrete_on_landfill({tile = 'blue-refined-concrete'})

local remove_non_ore_stacked_recipes = require 'map_gen.maps.danger_ores.modules.remove_non_ore_stacked_recipes'
remove_non_ore_stacked_recipes()

-- require 'map_gen.maps.danger_ores.modules.biter_drops'
require 'map_gen.maps.danger_ores.modules.map_poll'
require 'map_gen.maps.danger_ores.modules.memory_storage_control'

local config = {
  spawn_shape = b.translate(b.rectangle(48), 5, -5),
  start_ore_shape = b.translate(b.rectangle(56), 5, -5),
  no_resource_patch_shape = b.translate(b.rectangle(92), 5, -5),
  spawn_tile = 'landfill',
  main_ores = main_ores_config,
  main_ores_shuffle_order = true,
  main_ores_rotate = 30,
  water_scale = 1 / 96,
  water_threshold = 0.4,
  deepwater_threshold = 0.45,
  trees = trees,
  trees_scale = 1 / 32,
  trees_threshold = 0.4,
  trees_chance = 0.875,
  enemy = enemy,
  enemy_factor = 10 / (768 * 32),
  enemy_max_chance = 1 / 6,
  enemy_scale_factor = 32,
  enemy_radius = 58,
  fish_spawn_rate = 0.05,
  dense_patches_scale = 1 / 48,
  dense_patches_threshold = 0.55,
  dense_patches_multiplier = 25,
}

return map(config)
