local Command = require 'utils.command'
local Event = require 'utils.event'
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
local RocketSilo = require 'map_gen.maps.frontier.modules.rocket_silo'
local SpawnShop = require 'map_gen.maps.frontier.modules.spawn_shop'
local Terrain = require 'map_gen.maps.frontier.modules.terrain'
local this = Public.get()
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
local Config = global.config
Config.redmew_surface.enabled = true
Config.market.enabled = false
Config.player_rewards.enabled = false
Config.player_shortcuts.enabled = true
Config.player_create.starting_items = {
  { name = 'burner-mining-drill', count = 1 },
  { name = 'stone-furnace', count = 1 },
  { name = 'pistol', count = 1 },
  { name = 'firearm-magazine', count = 10 },
  { name = 'wood', count = 1 },
}

do
  local global_to_show = Config.score.global_to_show
  for k, v in pairs(Public.scores) do
    global_to_show[#global_to_show + 1] = v.name
    ScoreTracker.register(v.name, v.tooltip, v.sprite)
  end
end

-- == EVENTS ==================================================================

local function on_init()
  Lobby.on_init()
  RocketSilo.on_game_started()
  RocketSilo.reveal_spawn_area()
  SpawnShop.on_game_started()

  this.lobby_enabled = false
  Lobby.teleport_all_from()
end
Event.on_init(on_init)

local function on_game_started()
  RocketSilo.on_game_started()
  RocketSilo.reveal_spawn_area()
  SpawnShop.on_game_started()

  this.lobby_enabled = false
  Lobby.teleport_all_from()
end
Event.add(Public.events.on_game_started, on_game_started)

local function on_game_finished()
  for _, player in pairs(game.players) do
    SpawnShop.destroy_gui(player)
    Lobby.teleport_to(player)
  end
  RocketSilo.on_game_finished()
end
Event.add(Public.events.on_game_finished, on_game_finished)

local function on_player_created(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  if this.lobby_enabled then
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

  if surface.name ~= this.surface.name then
    return
  end

  -- kill off biters inside the wall
  Terrain.clear_enemies_inside_wall(surface, area)

  -- scale freshly generated ore by a scale factor
  Terrain.scale_resource_richness(surface, area)

  -- add mixed patches
  Terrain.mixed_resources(surface, area)

  -- add extra rocks
  Terrain.rich_rocks(surface, area)
end
Event.add(defines.events.on_chunk_generated, on_chunk_generated)

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
  local recipes = event.research.force.recipes
  if recipes['rocket-silo'] then
    recipes['rocket-silo'].enabled = false
  end
end
Event.add(defines.events.on_research_finished, on_research_finished)

local function on_player_died(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  SpawnShop.destroy_gui(player)

  local cause = event.cause
  if not cause or not cause.valid then
    return
  end
  if cause.force == player.force then
    return
  end

  if this.rockets_per_death <= 0 then
    return
  end

  local player_name = 'a player'
  if player then
    player_name = player.name
    this.death_contributions[player_name] = (this.death_contributions[player_name] or 0) + 1
  end

  this.rockets_to_win = this.rockets_to_win + this.rockets_per_death
  ScoreTracker.set_for_global(RocketSilo.scores.rocket_launches.name, this.rockets_to_win - this.rockets_launched)

  game.print({'frontier.add_rocket', this.rockets_per_death, player_name, (this.rockets_to_win - this.rockets_launched)})
end
Event.add(defines.events.on_player_died, on_player_died)

local function on_player_changed_position(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  if player.position.x < (-this.left_boundary * 32 - this.kraken_distance) then
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
  local entity = event.created_entity
  if not (entity and entity.valid) then
    return
  end

  if entity.name == 'entity-ghost' then
    return
  end

  Enemy.start_tracking(entity)
end
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, on_built_entity)

local function on_entity_destroyed(event)
  local unit_number = event.unit_number
  --local registration_number = event.registration_number

  Enemy.stop_tracking({ unit_number = unit_number })
end
Event.add(defines.events.on_entity_destroyed, on_entity_destroyed)

local function on_ai_command_completed(event)
  if not event.was_distracted then
    local data = this.unit_groups[event.unit_number]
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

  if entity.unit_number == this.spawn_shop.unit_number then
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

-- == COMMANDS ================================================================

Command.add('ping-silo',
  {
    description = 'Pings the silo\'s position on map',
    allowed_by_server = true
  },
  function(_, player)
    local surface = this.surface
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
    description = 'Toggle ON/OFF AI debug mode',
    allowed_by_server = true,
    required_rank = Ranks.admin,
  },
  function()
    this._DEBUG_AI = not this._DEBUG_AI
  end
)

Command.add('toggle-debug-shop',
  {
    description = 'Toggle ON/OFF Shop debug mode',
    allowed_by_server = true,
    required_rank = Ranks.admin,
  },
  function()
    this._DEBUG_SHOP = not this._DEBUG_SHOP
  end
)

Command.add('print-global',
  {
    description = 'Prints the global table',
    allowed_by_server = false,
    required_rank = Ranks.admin,
  },
  function(_, player)
    player.print(serpent.line(this))
  end
)

Command.add('log-global',
  {
    description = 'Logs the global table',
    allowed_by_server = true,
    required_rank = Ranks.admin,
  },
  function()
    Debug.log(this)
  end
)

-- ============================================================================

return Terrain.get_map()
