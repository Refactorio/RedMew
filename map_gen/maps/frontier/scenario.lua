local Command = require 'utils.command'
local Event = require 'utils.event'
local DebugTerrain = require 'map_gen.maps.frontier.shared.debug_terrain'
local math = require 'utils.math'
local Ranks = require 'resources.ranks'
local ScenarioInfo = require 'features.gui.info'
local ScoreTracker = require 'utils.score_tracker'
local Task = require 'utils.task'
local Debug = require 'map_gen.maps.frontier.shared.debug'
local Public = require 'map_gen.maps.frontier.shared.core'
local Enemy = require 'map_gen.maps.frontier.modules.enemy'
local Lobby = require 'map_gen.maps.frontier.modules.lobby'
local Market = require 'map_gen.maps.frontier.modules.market'
local Restart = require 'map_gen.maps.frontier.modules.restart'
local RocketSilo = require 'map_gen.maps.frontier.modules.rocket_silo'
local SpawnShop = require 'map_gen.maps.frontier.modules.spawn_shop'
local Terrain = require 'map_gen.maps.frontier.modules.terrain'
local math_random = math.random

--[[
  Scenario info: Frontier
  From 'Frontier Extended' mod: https://mods.factorio.com/mod/Frontier-Extended
]]

ScenarioInfo.set_map_name('Frontier')
ScenarioInfo.set_map_description([[
  Key features:
  -[font=default-bold]The Abyssal Waters[/font]: navigate the left side's vast oceans, where you can gather exotic materials and discover hidden treasures beneath the surface. Beware of the creatures that call this watery home, for they are unpredictable and vicious.

  -[font=default-bold]The Impenetrable Wall[/font]: this colossal barrier stands as both a shield and a menace. It represents safety from the constant threats of the biters, yet it is also a reminder of the dangers that lie just out of reach. Use it to your advantage—duel with enemies at the wall to protect your territory.

  -[font=default-bold]The Biter Swamplands[/font]: venture to the right at your peril, where the land bleeds into shifting, hostile territory ruled by the biters. Strategically plan your defenses to unleash devastating counterattacks and provide a path for resource gathering.

  -[font=default-bold]The Rocket Silo[/font]: strategically positioned amidst the turmoil, the Rocket Silo embodies your ambition and hope for escape. Get there and launch your escape plan, or watch as your dreams are devoured by the insatiable swarms.

  Prepare yourself—your journey begins now. Welcome to Frontier!

  The [color=red]RedMew[/color] team
]])
ScenarioInfo.set_map_extra_info([[
  As you emerge in the center of this striking ribbon world, an expansive body of shimmering water stretches to your left, a serene yet foreboding reminder of the untouchable depth that lies beyond. The aquatic expanse is teeming with alien flora and fauna, a biodiversity that seems both mesmerizing and perilous. Use the resources from this lush environment wisely—freshwater and unique aquatic materials could be the keys to your survival and civilization.

  To the right, however, lies an ominous fate. Towering endlessly, an unforgiving wall of stone rises beneath a swirling sky, marking the boundary between your fledgling civilization and an unforgiving deathworld beyond. Beyond this monumental barrier swarms a frenzied population of biters—ferocious creatures drawn to your very existence. The relentless horde thrives in the chaotic biome that is both beautiful and horrifying, embodying the resilience and danger of an alien ecosystem. They sense the life you're trying to cultivate and will stop at nothing to obliterate your efforts.

  Your mission, should you choose to accept it, is to journey through this ribbon of civilization, gathering resources from your surroundings, forging alliances with the unique native species, and constructing an array of machines and defenses. Your ultimate goal is to reach the Rocket Silo located daringly in the heart of the enemy territory—a beacon of hope amidst chaos.

  In [font=default-bold]Frontier[/font], your wits will be tested as you evolve from a mere survivor to an engineering genius capable of taming the land and launching your final escape. Build a thriving factory, and prepare to conquer both nature and the relentless horde in a race against time. But remember, the frontier waits for no one. Will you make your mark on this alien world or become another lost tale in the void of space?
]])
ScenarioInfo.set_new_info([[
  2024-08-16:
    - Added random markets
    - Added spawn shop
    - Tweaked resources distribution
    - Tweaked rocket launches requirements
  2024-08-15:
    - Fixed desyncs
    - Fixed biter waves
  2024-08-10:
    - Added enemy turrets
    - Added soft reset
    - Added shortcuts gui
    - Added score tracker for rockets to win
    - Deaths no longer contribute to rocket to win, instead, a rng value is rolled at the beginning of the game
  2024-07-31:
    - Added Frontier
]])

--- Config
local Config = storage.config
Config.redmew_surface.enabled = false
Config.market.enabled = false
Config.player_rewards.enabled = false
Config.player_shortcuts.enabled = true
Config.dump_offline_inventories.enabled = true
Config.market_chest.enabled = true
Config.train_station_teleport.enabled = true
Config.player_create.starting_items = {
  { name = 'burner-mining-drill', count = 1 },
  { name = 'stone-furnace', count = 1 },
  { name = 'pistol', count = 1 },
  { name = 'firearm-magazine', count = 10 },
  { name = 'wood', count = 1 },
}


if script.active_mods['Krastorio2'] then
  Config.paint.enabled = false
  storage.config.redmew_qol.loaders = false
  table.insert(Config.player_create.starting_items, { name = 'kr-crash-site-generator', count = 1 })
  table.insert(Config.player_create.starting_items, { name = 'kr-crash-site-lab-repaired', count = 1 })
  table.insert(Config.player_create.starting_items, { name = 'kr-crash-site-assembling-machine-1-repaired', count = 1 })
  table.insert(Config.player_create.starting_items, { name = 'kr-crash-site-assembling-machine-2-repaired', count = 1 })
  table.insert(Config.player_create.starting_items, { name = 'kr-medium-container', count = 1 })
  table.insert(Config.player_create.starting_items, { name = 'kr-sentinel', count = 2 })
  table.insert(Config.player_create.starting_items, { name = 'kr-wind-turbine', count = 5 })
  table.insert(Config.player_create.starting_items, { name = 'copper-cable', count = 200 })
  table.insert(Config.player_create.starting_items, { name = 'electronic-circuit', count = 25 })
  table.insert(Config.player_create.starting_items, { name = 'iron-gear-wheel', count = 35 })
  table.insert(Config.player_create.starting_items, { name = 'iron-plate', count = 400 })
  table.insert(Config.player_create.starting_items, { name = 'medium-electric-pole', count = 5 })
  table.insert(Config.player_create.starting_items, { name = 'steel-chest', count = 1 })
  table.insert(Config.player_create.starting_items, { name = 'wood', count = 49 })
end

do
  local global_to_show = Config.score.global_to_show
  for k, v in pairs(Public.scores) do
    global_to_show[#global_to_show + 1] = v.name
    ScoreTracker.register(v.name, v.tooltip, v.sprite)
  end
end

-- == EVENTS ==================================================================

local function on_tick()
  local tick = game.tick

  if (tick - 1) % 90 == 0 then
    Terrain.pop_chunk_request(24)
  end
end
Event.add(defines.events.on_tick, on_tick)

local function on_game_started()
  Public.reset()
  Restart.announce_new_map()
  Restart.apply_modifiers()
  Terrain.reveal_spawn_area()
  Terrain.queue_reveal_map()
  RocketSilo.init_silo()
  SpawnShop.on_game_started()

  Public.get().lobby_enabled = false
  Lobby.teleport_all_from()
end
Event.add(Public.events.on_game_started, on_game_started)

local function on_game_finished()
  local this = Public.get()
  local cmd = this.server_commands

  if cmd.restarting then
    Restart.print_endgame_statistics()
    if this.rounds >= 5 then
      cmd.mode = Public.restart_mode.restart
    end
    if cmd.mode ~= Public.restart_mode.none then
      Terrain.prepare_next_surface()
      for _, player in pairs(game.players) do
        SpawnShop.destroy_gui(player)
        Lobby.teleport_to(player)
      end
    end
  end
  Restart.execute_server_command()
end
Event.add(Public.events.on_game_finished, on_game_finished)

local function on_player_created(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  if Public.get().lobby_enabled then
    Lobby.teleport_to(player)
  end
end
Event.add(defines.events.on_player_created, on_player_created)

local function on_chunk_generated(event)
  local area = event.area
  local surface = event.surface

  if surface.name == Lobby.name then
    Lobby.on_chunk_generated(event)
  end

  if surface.name ~= Public.surface().name then
    return
  end

  if Public.get()._DEBUG_NOISE then
    DebugTerrain.on_chunk_generated(event)
    return
  end

  -- scale freshly generated ore by a scale factor
  Terrain.scale_resource_richness(surface, area)

  -- add mixed patches
  Terrain.mixed_resources(surface, area)

  -- add extra rocks
  Terrain.rich_rocks(surface, area)

  -- special tiles
  Terrain.reshape_land(surface, area)
end
Event.add(defines.events.on_chunk_generated, on_chunk_generated)

local function on_tile_built(event)
  Terrain.block_tile_placement(event)
end
Event.add(defines.events.on_player_built_tile, on_tile_built)
Event.add(defines.events.on_robot_built_tile, on_tile_built)

local function on_entity_died(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end

  local entity_type = entity.type
  if entity.force.name == 'enemy' then
    if entity_type == 'unit-spawner' then
      if math_random(1, 256) == 1 then
        Market.spawn_exchange_market(entity.position)
      elseif math_random(1, 16) == 1 then
        Enemy.on_spawner_died(event)
      elseif math_random(1, 1024) == 1 then
        SpawnShop.earn_coin()
      end
    elseif entity_type == 'unit' or entity_type == 'turret' then
      Enemy.on_enemy_died(entity)
    end
  elseif entity_type == 'simple-entity' then
    Enemy.spawn_turret_outpost(entity.position)
  elseif entity_type == 'market' then
    Task.set_timeout_in_ticks(1, Enemy.nuclear_explosion_token, entity.position)
    Task.set_timeout(3, RocketSilo.set_game_state_token, false)
  end
end
Event.add(defines.events.on_entity_died, on_entity_died)

local function on_research_finished(event)
  local technology = event.research
  if not (technology and technology.valid) then
    return
  end
  if technology.force.name == 'player' then
    RocketSilo.on_research_finished(technology)
    Enemy.on_research_finished(technology)
  end
end
Event.add(defines.events.on_research_finished, on_research_finished)

local function on_player_died(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  SpawnShop.destroy_gui(player)
  RocketSilo.on_player_died(event)
end
Event.add(defines.events.on_player_died, on_player_died)

local function on_player_changed_position(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  local this = Public.get()
  if player.physical_position.x < (-this.left_boundary * 32 - this.kraken_distance) then
    local player_name = 'a player'
    if player.character ~= nil then
      player_name = player.name
    end
    game.print({'frontier.kraken_eat', player_name}, { sound_path = 'utility/game_lost' })
    if player.character ~= nil then
      player.character.die()
      this.kraken_contributors[player_name] = true
    end
  end
end
Event.add(defines.events.on_player_changed_position, on_player_changed_position)

local function on_rocket_launched(event)
  RocketSilo.on_rocket_launched(event)
end
Event.add(defines.events.on_rocket_launched, on_rocket_launched)

local function on_entity_mined(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end

  if entity.type == 'simple-entity' then
    Enemy.spawn_turret_outpost(entity.position)
  end
end
Event.add(defines.events.on_robot_mined_entity, on_entity_mined)
Event.add(defines.events.on_player_mined_entity, on_entity_mined)

local function on_built_entity(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end

  if entity.name == 'entity-ghost' then
    return
  end

  local this = Public.get()
  if entity.position.x < -(this.kraken_distance + this.left_boundary * 32) then
    RocketSilo.kraken_eat_entity(entity)
    return
  end
  Enemy.start_tracking(entity)
end
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, on_built_entity)

local function on_entity_damaged(event)
  SpawnShop.on_entity_damaged(event)
end
Event.add(defines.events.on_entity_damaged, on_entity_damaged)

local function on_object_destroyed(event)
  if not event.useful_id then
    return
  end
  Enemy.stop_tracking({ unit_number = event.useful_id })
end
Event.add(defines.events.on_object_destroyed, on_object_destroyed)

local function on_ai_command_completed(event)
  if not event.was_distracted then
    local data = Public.get().unit_groups[event.unit_number]
    if data and data.unit_group and data.unit_group.valid then
      Enemy.ai_processor(data.unit_group, event.result)
    end
  end
end
Event.add(defines.events.on_ai_command_completed, on_ai_command_completed)

local function on_gui_opened(event)
  if not event.gui_type == defines.gui_type.entity then
    return
  end

  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end

  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  if entity.unit_number == Public.get().spawn_shop.unit_number then
    SpawnShop.draw_gui(player)
  end
end
Event.add(defines.events.on_gui_opened, on_gui_opened)

local function on_gui_closed(event)
  local element = event.element
  if not (element and element.valid) then
    return
  end

  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  if element.name == SpawnShop.main_frame_name then
    SpawnShop.destroy_gui(player)
  end
end
Event.add(defines.events.on_gui_closed, on_gui_closed)

local function on_gui_click(event)
  local element = event.element
  if not (element and element.valid) then
    return
  end

  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  local name = element.name
  if name == SpawnShop.close_button_name then
    SpawnShop.destroy_gui(player)
  elseif name == SpawnShop.refresh_button_name then
    SpawnShop.on_player_refresh(player)
  elseif name == SpawnShop.upgrade_button_name then
    SpawnShop.on_player_purchase(player, element.tags.name)
  end
end
Event.add(defines.events.on_gui_click, on_gui_click)

local function on_init()
  Lobby.on_init()
  on_game_started()
end
Event.on_init(on_init)

-- == COMMANDS ================================================================

Command.add('ping-silo',
  {
    description = {'command_description.frontier_ping_silo'},
    allowed_by_server = true
  },
  function(_, player)
    local surface = Public.surface()
    local msg = '[color=blue][Mapkeeper][/color] Here you\'ll find a silo:'
    local silos = surface.find_entities_filtered { name = 'rocket-silo' }
    for _, s in pairs(silos) do
      msg = msg .. string.format(' [gps=%d,%d,%s]', s.position.x, s.position.y, surface.name)
    end
    if player then
      player.print(msg)
    else
      game.print(msg)
    end
  end
)

Command.add('toggle-debug-ai',
  {
    description = {'command_description.frontier_toggle_debug_ai'},
    allowed_by_server = true,
    required_rank = Ranks.admin,
  },
  function()
    local this = Public.get()
    this._DEBUG_AI = not this._DEBUG_AI
  end
)

Command.add('toggle-debug-shop',
  {
    description = {'command_description.frontier_toggle_debug_shop'},
    allowed_by_server = true,
    required_rank = Ranks.admin,
  },
  function()
    local this = Public.get()
    this._DEBUG_SHOP = not this._DEBUG_SHOP
  end
)

Command.add('print-global',
  {
    description = {'command_description.frontier_print_global'},
    allowed_by_server = false,
    required_rank = Ranks.admin,
  },
  function(_, player)
    player.print(serpent.line(Public.get()))
  end
)

Command.add('log-global',
  {
    description = {'command_description.frontier_log_global'},
    allowed_by_server = true,
    required_rank = Ranks.admin,
  },
  function()
    Debug.log(Public.get())
  end
)

-- ============================================================================

return Terrain.get_map()
