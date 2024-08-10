local b = require 'map_gen.shared.builders'
local Color = require 'resources.color_presets'
local Command = require 'utils.command'
local Event = require 'utils.event'
local EnemyTurret = require 'features.enemy_turret'
local Global = require 'utils.global'
local math = require 'utils.math'
local MGSP = require 'resources.map_gen_settings'
local Noise = require 'map_gen.shared.simplex_noise'
local PriceRaffle = require 'features.price_raffle'
local RS = require 'map_gen.shared.redmew_surface'
local ScenarioInfo = require 'features.gui.info'
local ScoreTracker = require 'utils.score_tracker'
local Sounds = require 'utils.sounds'
local Toast = require 'features.gui.toast'
local Token = require 'utils.token'
local Task = require 'utils.task'

local math_random = math.random
local math_max = math.max
local math_min = math.min
local math_abs = math.abs
local math_ceil = math.ceil
local math_floor = math.floor
local math_clamp = math.clamp
local math_sqrt = math.sqrt
local simplex = Noise.d2
local SECOND = 60
local MINUTE =  SECOND * 60

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
Config.player_create.starting_items = {
  { name = 'burner-mining-drill', count = 1 },
  { name = 'stone-furnace', count = 1 },
  { name = 'pistol', count = 1 },
  { name = 'firearm-magazine', count = 10 },
  { name = 'wood', count = 1 },
}

local this = {
  rounds = 0,
  -- Map gen
  silo_starting_x = 1700,

  height = 36,              -- in chunks, height of the ribbon world
  left_boundary = 8,        -- in chunks, distance to water body
  right_boundary = 11,      -- in chunks, distance to wall/biter presence
  wall_width = 5,           -- in tiles
  rock_richness = 1,        -- how many rocks/chunk

  ore_base_quantity = 61,   -- base ore quantity, everything is scaled up from this
  ore_chunk_scale = 32,     -- sets how fast the ore will increase from spawn, lower = faster

  -- Kraken handling
  kraken_distance = 25,     -- where the kraken lives past the left boundary
  kraken_contributors = {}, -- list of players eaten by kraken
  death_contributions = {}, -- list of all players deaths

  -- Satellites to win
  rockets_to_win = 1,
  rockets_launched = 0,
  rockets_per_death = 0,    -- how many extra launch needed for each death
  scenario_finished = false,

  -- Loot chests
  loot_budget = 48,
  loot_chance = 1 / 16,
  loot_richness = 1,

  -- Rocket silo position management
  x = 0,
  y = 0,
  rocket_silo = nil,
  move_buffer = 0,
  rocket_step = 500,        -- rocket/tiles ratio
  min_step = 500,           -- minimum tiles to move
  max_distance = 100000,    -- maximum x distance of rocket silo

  -- Revived enemies
  invincible = {}
}

Global.register(this, function(tbl) this = tbl end)

local noise_weights = {
  { modifier = 0.0042, weight = 1.000 },
  { modifier = 0.0310, weight = 0.080 },
  { modifier = 0.1000, weight = 0.025 },
}
local mixed_ores = { 'iron-ore', 'copper-ore', 'iron-ore', 'stone', 'copper-ore', 'iron-ore', 'copper-ore', 'iron-ore', 'coal', 'iron-ore', 'copper-ore', 'iron-ore', 'stone', 'copper-ore', 'coal'}

local Main = {
  events = {
    on_game_started = Event.generate_event_name('on_game_started'),
    on_game_finished = Event.generate_event_name('on_game_finished'),
  }
}

local rocket_launches_name = 'rockets-launches-frontier'
local global_to_show = Config.score.global_to_show
global_to_show[#global_to_show + 1] = rocket_launches_name
ScoreTracker.register(rocket_launches_name, {'frontier.rockets_to_launch'}, '[img=item.rocket-silo]')

local escape_player = false

-- == LOBBY ===================================================================

local Lobby = {}

Lobby.enabled = false
Lobby.name = 'nauvis'
Lobby.mgs = {
  water = 0,
  default_enable_all_autoplace_controls = false,
  width = 64,
  height = 64,
  peaceful_mode = true,
}

function Lobby.get_surface()
  local surface = game.get_surface(Lobby.name)
  if not surface then
    surface = game.create_surface(Lobby.name, Lobby.mgs)
  end
  return surface
end

function Lobby.teleport_to(player)
  for k = 1, player.get_max_inventory_index() do
    local inv = player.get_inventory(k)
    if inv and inv.valid then
      inv.clear()
    end
  end

  local surface = Lobby.get_surface()
  local position = surface.find_non_colliding_position('character', {0, 0}, 0, 0.2)
  player.teleport(position, surface, true)
end

function Lobby.teleport_from(player, destination)
  for _, stack in pairs(Config.player_create.starting_items) do
    if game.item_prototypes[stack.name] then
      player.insert(stack)
    end
  end
  local surface = RS.get_surface()
  local position = surface.find_non_colliding_position('character', destination or {0, 0}, 0, 0.2)
  player.teleport(position, surface, true)
end

function Lobby.teleport_all_to()
  for _, player in pairs(game.players) do
    Lobby.teleport_to(player)
  end
end

function Lobby.teleport_all_from(destination)
  for _, player in pairs(game.players) do
    Lobby.teleport_from(player, destination)
  end
end

function Lobby.on_chunk_generated(event)
  local area = event.area
  local surface = event.surface

  surface.build_checkerboard(area)
  for _, e in pairs(surface.find_entities_filtered{ area = area }) do
    if e.type ~= 'character' then
      e.destroy()
    end
  end
end

function Lobby.on_init()
  local surface = Lobby.get_surface()
  surface.map_gen_settings = Lobby.mgs
  Lobby.on_chunk_generated({ area = {left_top = {-64, -64}, right_bottom = {64, 64}}, surface = surface })
end

-- == MAP GEN =================================================================

local map, water, green_water

RS.set_map_gen_settings({
  {
    autoplace_controls = {
      ['coal']        = { frequency = 3,   richness = 1, size = 0.75 },
      ['copper-ore']  = { frequency = 3,   richness = 1, size = 0.75 },
      ['crude-oil']   = { frequency = 1,   richness = 1, size = 0.75 },
      ['enemy-base']  = { frequency = 6,   richness = 1, size = 4    },
      ['iron-ore']    = { frequency = 3,   richness = 1, size = 0.75 },
      ['stone']       = { frequency = 3,   richness = 1, size = 0.75 },
      ['trees']       = { frequency = 1,   richness = 1, size = 1    },
      ['uranium-ore'] = { frequency = 0.5, richness = 1, size = 0.5  },
    },
    cliff_settings = { name = 'cliff', cliff_elevation_0 = 20, cliff_elevation_interval = 40, richness = 1 / 3 },
    height = this.height * 32,
    property_expression_names = {
      ['control-setting:aux:frequency:multiplier'] = '1.333333',
      ['control-setting:moisture:bias'] = '-0.250000',
      ['control-setting:moisture:frequency:multiplier'] = '3.000000',
    },
    starting_area = 3,
    terrain_segmentation = 1,
  },
  MGSP.water_none,
})

local bounds = function(x, y)
  return x > (-this.left_boundary * 32 - 320) and not ((y < -this.height * 16) or (y > this.height * 16))
end

water = b.change_tile(bounds, true, 'water')
water = b.fish(water, 0.075)

green_water = b.change_tile(bounds, true, 'deepwater-green')

map = b.choose(function(x) return x < -this.left_boundary * 32 end, water, bounds)
map = b.choose(function(x) return math_floor(x) == -(this.kraken_distance + this.left_boundary * 32 + 1) end, green_water, map)

-- == TERRAIN ==================================================================

local Terrain = {}

function Terrain.noise_pattern(position, seed)
  local noise, d = 0, 0
  for i = 1, #noise_weights do
    local nw = noise_weights[i]
    noise = noise + simplex(position.x * nw.modifier, position.y * nw.modifier, seed) * nw.weight
    d = d + nw.weight
    seed = seed + 10000
  end
  noise = noise / d
  return noise
end

function Terrain.mixed_resources(surface, area)
  local left_top = { x = math_max(area.left_top.x, this.right_boundary * 32), y = area.left_top.y }
  local right_bottom = area.right_bottom
  if left_top.x >= right_bottom.x then
    return
  end

  local seed = surface.map_gen_settings.seed
  local create_entity = surface.create_entity
  local can_place_entity = surface.can_place_entity
  local find_entities_filtered = surface.find_entities_filtered

  local function clear_ore(position)
    for _, resource in pairs(find_entities_filtered{
      position = position,
      type = 'resource'
    }) do
      if resource.name ~= 'uranium-ore' and resource.name ~= 'crude-oil' then
        resource.destroy() end
      end
  end

  local chunks = math_clamp(math_abs((left_top.x - this.right_boundary * 32) / this.ore_chunk_scale), 1, 100)
  chunks = math_random(chunks, chunks + 4)
  for x = 0, 31 do
    for y = 0, 31 do
      local position = { x = left_top.x + x, y = left_top.y + y }
      if can_place_entity({ name = 'iron-ore', position = position }) then
        local noise = Terrain.noise_pattern(position, seed)
        if math_abs(noise) > 0.67 then
          local idx = math_floor(noise * 25 + math_abs(position.x) * 0.05) % #mixed_ores + 1
          local amount = this.ore_base_quantity * chunks * 3
          clear_ore(position)
          create_entity({ name = mixed_ores[idx], position = position, amount = amount })
        end
      end
    end
  end
end

function Terrain.clear_enemies_inside_wall(surface, area)
  if area.right_bottom.x < (this.right_boundary * 32 + 96) then
    for _, entity in pairs(surface.find_entities_filtered { area = area, force = 'enemy' }) do
      entity.destroy()
    end
  end
end

function Terrain.scale_resource_richness(surface, area)
  for _, resource in pairs(surface.find_entities_filtered { area = area, type = 'resource' }) do
    if resource.position.x > this.right_boundary * 32 then
      local chunks = math.clamp(math_abs((resource.position.x - this.right_boundary * 32) / this.ore_chunk_scale), 1, 100)
      chunks = math_random(chunks, chunks + 4)
      if resource.prototype.resource_category == 'basic-fluid' then
        resource.amount = 3000 * 3 * chunks
      elseif resource.prototype.resource_category == 'basic-solid' then
        resource.amount = this.ore_base_quantity * chunks
      end
    end
  end
end

function Terrain.rich_rocks(surface, area)
  local left_top = { x = math_max(area.left_top.x, this.right_boundary * 32), y = area.left_top.y }
  local right_bottom = area.right_bottom
  if left_top.x >= right_bottom.x then
    return
  end

  local function place_rock(rock_name)
    local search = surface.find_non_colliding_position
    local place = surface.create_entity

    for _ = 1, 10 do
      local x, y = math_random(1, 31) + math_random(), math_random(1, 31) + math_random()
      local rock_pos = search(rock_name, {left_top.x + x, left_top.y + y}, 4, 0.4)
      if rock_pos then
        local rock = place{
          name = rock_name,
          position = rock_pos,
          direction = math_random(1, 4)
        }
        rock.graphics_variation = math_random(16)
        return
      end
    end
  end

  for _ = 1, this.rock_richness do
    local rock_name = math_random() < 0.4 and 'rock-huge' or 'rock-big'
    place_rock(rock_name)
  end
end

function Terrain.set_silo_tiles(entity)
  local pos = entity.position
  local surface = entity.surface
  surface.request_to_generate_chunks(pos, 1)
  surface.force_generate_chunk_requests()

  local tiles = {}
  for x = -12, 12 do
    for y = -12, 12 do
      tiles[#tiles +1] = { name = 'hazard-concrete-left', position = { pos.x + x, pos.y + y}}
    end
  end
  for x = -8, 8 do
    for y = -8, 8 do
      tiles[#tiles +1] = { name = 'concrete', position = { pos.x + x, pos.y + y}}
    end
  end
  entity.surface.set_tiles(tiles, true)
end

function Terrain.create_wall(x, w)
  local surface = RS.get_surface()
  local area = { { x, -this.height * 16 }, { x + w, this.height * 16 } }
  for _, entity in pairs(surface.find_entities_filtered { area = area, collision_mask = 'player-layer' }) do
    entity.destroy()
  end

  for y = -this.height * 16, this.height * 16 do
    for j = 0, w do
      local e = surface.create_entity {
        name = 'stone-wall',
        position = { x + j, y },
        force = 'player',
        move_stuck_players = true,
      }
      e.destructible = false
    end
  end
end

-- == MAIN ====================================================================

function Main.nuclear_explosion(entity)
  local surface = entity.surface
  local center_position = entity.position
  local force = entity.force
  surface.create_entity {
    name = 'atomic-rocket',
    position = center_position,
    force = force,
    source = center_position,
    target = center_position,
    max_range = 1,
    speed = 0.1
  }
end

function Main.spawn_enemy_wave(position)
  local surface = RS.get_surface()
  local find_position = surface.find_non_colliding_position
  local spawn = surface.create_entity
  local current_tick = game.tick

  local max_time = math_max(MINUTE, MINUTE * math_ceil(0.5 * (this.rockets_launched ^ 0.5)))

  local radius = 20
  for _ = 1, 24 do
    local name = math_random() > 0.15 and 'behemoth-worm-turret' or 'big-worm-turret'
    local about = find_position(name, { x = position.x + math_random(), y = position.y + math_random() }, radius, 0.2)
    if about then
      local worm = spawn { name = name, position = about, force = 'enemy', move_stuck_players = true }
      this.invincible[worm.unit_number] = {
        time_to_live = current_tick + math_random(MINUTE, max_time)
      }
    end
  end

  radius = 32
  for _ = 1, 20 do
    local name = math_random() > 0.3 and 'behemoth-biter' or 'behemoth-spitter'
    local about = find_position(name, { x = position.x + math_random(), y = position.y + math_random() }, radius, 0.6)
    if about then
      local unit = spawn { name = name, position = about, force = 'enemy', move_stuck_players = true }
      this.invincible[unit.unit_number] = {
        time_to_live = current_tick + math_random(MINUTE, max_time)
      }
    end
  end
end
Main.spawn_enemy_wave_token = Token.register(Main.spawn_enemy_wave)

function Main.spawn_turret_outpost(position)
  if position.x < this.right_boundary + this.wall_width then
    return
  end

  local max_chance = math_clamp(0.02 * math_sqrt(position.x), 0.01, 0.04)
  if math_random() > max_chance then
    return
  end

  local surface = RS.get_surface()

  if escape_player then
    for _, player in pairs(surface.find_entities_filtered{type = 'character'}) do
      local pos = surface.find_non_colliding_position('character', { position.x -10, position.y }, 5, 0.5)
      if pos then
        player.teleport(pos, surface)
      end
    end
  end

  local evolution = game.forces.enemy.evolution_factor
  local ammo = 'firearm-magazine'
  if math_random() < evolution then
    ammo = 'piercing-rounds-magazine'
  end
  if math_random() < evolution then
    ammo = 'uranium-rounds-magazine'
  end

  for _, v in pairs({
    { x = -5, y =  0 },
    { x =  5, y =  0 },
    { x =  0, y =  5 },
    { x =  0, y = -5 },
  }) do
      local pos = surface.find_non_colliding_position('gun-turret', { position.x + v.x, position.y + v.y }, 2, 0.5)
      if pos then
        local turret = surface.create_entity {
          name = 'gun-turret',
          position = pos,
          force = 'enemy',
          move_stuck_players = true,
          create_build_effect_smoke = true,
        }
        if turret and turret.valid then
          EnemyTurret.register(turret, ammo)
        end
      end
  end
end

function Main.win()
  this.scenario_finished = true
  game.set_game_state { game_finished = true, player_won = true, can_continue = true, victorious_force = 'player' }

  Task.set_timeout( 1, Main.restart_message_token, 90)
  Task.set_timeout(31, Main.restart_message_token, 60)
  Task.set_timeout(61, Main.restart_message_token, 30)
  Task.set_timeout(81, Main.restart_message_token, 10)
  Task.set_timeout(86, Main.restart_message_token,  5)
  Task.set_timeout(91, Main.end_game_token)
  Task.set_timeout(92, Main.restart_game_token)
end

function Main.on_spawner_died(event)
  local entity = event.entity
  local chance = math_random()
  if chance > this.loot_chance then
    return
  end

  local budget = this.loot_budget + entity.position.x * 2.75
  budget = budget * math_random(25, 175) * 0.01

  local player = false
  if event.cause and event.cause.type == 'character' then
    player = event.cause.player
  end
  if player and player.valid then
    budget = budget + (this.death_contributions[player.name] or 0) * 80
  end

  if math_random(1, 128) == 1 then budget = budget * 4 end
  if math_random(1, 256) == 1 then budget = budget * 4 end
  budget = budget * this.loot_richness

  local chest = entity.surface.create_entity { name = 'steel-chest', position = entity.position, force = 'player', move_stuck_players = true }
  chest.destructible = false
  for i = 1, 3 do
    local item_stacks = PriceRaffle.roll(math_floor(budget / 3 ) + 1, 48)
    for _, item_stack in pairs(item_stacks) do
      chest.insert(item_stack)
    end
  end
  if player then
    Toast.toast_player(player, nil, {'frontier.loot_chest'})
  end
end

function Main.on_enemy_died(entity)
  local uid = entity.unit_number
  local data = this.invincible[uid]
  if not data then
    return
  end

  if game.tick > data.time_to_live then
    this.invincible[uid] = nil
    return
  end

  local new_entity = entity.surface.create_entity {
    name = entity.name,
    position = entity.position,
    force = entity.force,
  }

  this.invincible[new_entity.unit_number] = {
    time_to_live = data.time_to_live,
  }
  this.invincible[uid] = nil

  if new_entity.type == 'unit' then
    new_entity.set_command(entity.command)
  end
end

Main.play_sound_token = Token.register(Sounds.notify_all)

Main.restart_message_token = Token.register(function(seconds)
  game.print({'frontier.restart', seconds}, Color.success)
end)

function Main.move_silo(position)
  local surface = RS.get_surface()
  local old_silo = this.rocket_silo
  local old_position = old_silo and old_silo.position or { x = 0, y = 0 }
  local new_silo
  local new_position = position or { x = this.x, y = this.y }

  if old_silo and math_abs(new_position.x - old_position.x) < this.min_step then
    this.move_buffer = this.move_buffer + new_position.x - old_position.x
    return
  end

  for _, e in pairs(surface.find_entities_filtered{ position = new_position, radius = 15 }) do
    if e.type == 'character' then
      local pos = surface.find_non_colliding_position('character', { new_position.x + 12, new_position.y }, 5, 0.5)
      if pos then
        e.teleport(pos)
      else
        e.character.die()
      end
    else
      e.destroy()
    end
  end

  if old_silo then
    local result_inventory = old_silo.get_output_inventory().get_contents()
    new_silo = old_silo.clone { position = new_position, force = old_silo.force, create_build_effect_smoke = true }
    old_silo.destroy()
    local chest = surface.create_entity { name = 'steel-chest', position = old_position, force = 'player', move_stuck_players = true }
    if table_size(result_inventory) > 0 then
      chest.destructible = false
      for name, count in pairs(result_inventory) do
        chest.insert({ name = name, count = count })
      end
    end
    local spill_item_stack = surface.spill_item_stack
    for x = -15, 15 do
      for y = -15, 15 do
        for _ = 1, 4 do
          spill_item_stack({ x = old_position.x + x + math_random(), y = old_position.y + y + math_random()}, { name = 'raw-fish', count = 1 }, false, nil, true)
        end
      end
    end
    game.print({'frontier.empty_rocket'})
    Main.nuclear_explosion(chest)
    Task.set_timeout(5, Main.spawn_enemy_wave_token, old_position)

    game.forces.enemy.reset_evolution()
    local enemy_evolution = game.map_settings.enemy_evolution
    enemy_evolution.time_factor = enemy_evolution.time_factor * 1.01
  else
    new_silo = surface.create_entity { name = 'rocket-silo', position = new_position, force = 'player', move_stuck_players = true }
  end

  if new_silo and new_silo.valid then
    new_silo.destructible = false
    new_silo.minable = false
    new_silo.active = true
    new_silo.get_output_inventory().clear()
    this.rocket_silo = new_silo
    this.x = new_silo.position.x
    this.y = new_silo.position.y
    this.move_buffer = 0
    Terrain.set_silo_tiles(new_silo)

    local x_diff = math.round(new_position.x - old_position.x)
    if x_diff > 0 then
      game.print({'frontier.silo_forward', x_diff})
    else
      game.print({'frontier.silo_backward', x_diff})
    end
  end
end
Main.move_silo_token = Token.register(Main.move_silo)

function Main.compute_silo_coordinates(step)
  this.move_buffer = this.move_buffer + (step or 0)

  if this.x + this.move_buffer > this.max_distance then
    -- Exceeding max right direction, move to max (if not already) and add rockets to win
    local remainder = this.x + this.move_buffer - this.max_distance
    local add_rockets = math_floor(remainder / this.rocket_step)
    if add_rockets > 0 then
      this.rockets_to_win = this.rockets_to_win + add_rockets
      game.print({'frontier.warning_max_distance', this.rocket_step})
    end
    this.x = math_min(this.max_distance, this.x + this.move_buffer)
    this.move_buffer = remainder % this.rocket_step
  elseif this.x + this.move_buffer < -(this.left_boundary * 32) + 12 then
    -- Exceeding min left direction, move to min (if not already) and remove rockets to win
    local min_distance = -(this.left_boundary * 32) + 12
    local remainder = this.x + this.move_buffer - min_distance -- this is negative
    local remove_rockets = math_floor(-remainder / this.rocket_step)
    if remove_rockets > 0 then
      this.rockets_to_win = this.rockets_to_win - remove_rockets
      if this.rockets_to_win < 1 then this.rockets_to_win = 1 end
      if this.rockets_launched >= this.rockets_to_win then
        Main.win()
        return
      else
        game.print({'frontier.warning_min_distance', this.rocket_step})
      end
    end
    this.x = math_max(min_distance, this.x + this.move_buffer)
    this.move_buffer = remainder % this.rocket_step
  else
    this.x = this.x + this.move_buffer
    this.move_buffer = 0
  end

  local max_height = (this.height * 16) - 16
  this.y = math_random(-max_height, max_height)
end

function Main.reveal_spawn_area()
  local surface = RS.get_surface()
  local far_left, far_right = this.kraken_distance + this.left_boundary * 32 + 1, this.right_boundary * 32 + this.wall_width
  surface.request_to_generate_chunks({ x = 0, y = 0 }, math.ceil(math_max(far_left, far_right, this.height * 32) / 32))
  surface.force_generate_chunk_requests()

  Main.compute_silo_coordinates(this.silo_starting_x + math_random(100))
  Main.move_silo()
  Terrain.create_wall(this.right_boundary * 32, this.wall_width)

  game.forces.player.chart(surface, { { -far_left - 32, -this.height * 16 }, { far_right + 32, this.height * 16 } })
end

function Main.on_game_started()
  local ms = game.map_settings
  ms.enemy_expansion.friendly_base_influence_radius = 0
  ms.enemy_expansion.min_expansion_cooldown = SECOND * 30
  ms.enemy_expansion.max_expansion_cooldown = MINUTE * 4
  ms.enemy_expansion.max_expansion_distance = 5
  ms.enemy_evolution.destroy_factor = 0.0001
  ms.enemy_evolution.time_factor = 0.000004

  this.rounds = this.rounds + 1
  this.kraken_contributors = {}
  this.death_contributions = {}
  this.rockets_to_win = 3 + math_random(12 + this.rounds)
  this.rockets_launched = 0
  this.scenario_finished = false
  this.x = 0
  this.y = 0
  this.rocket_silo = nil
  this.move_buffer = 0
  this.invincible = {}

  if _DEBUG then
    this.silo_starting_x = 30
    this.rockets_to_win = 1
  end

  for _, force in pairs(game.forces) do
    force.reset()
    force.reset_evolution()
  end

  game.speed = 1
  game.reset_game_state()
  game.reset_time_played()

  ScoreTracker.reset()
end

Main.restart_game_token = Token.register(function()
  script.raise_event(Main.events.on_game_started, {})
end)

function Main.on_game_finished()
  Lobby.enabled = true
  Lobby.teleport_all_to()

  local surface = RS.get_surface()
  surface.clear(true)
  surface.map_gen_settings.seed = surface.map_gen_settings.seed + 1
end

Main.end_game_token = Token.register(function()
  script.raise_event(Main.events.on_game_finished, {})
end)

-- == EVENTS ==================================================================

local function on_init()
  Lobby.on_init()
  Main.on_game_started()
  Main.reveal_spawn_area()

  Lobby.enabled = false
  Lobby.teleport_all_from()
end
Event.on_init(on_init)

local function on_game_started()
  Main.on_game_started()
  Main.reveal_spawn_area()

  Lobby.enabled = false
  Lobby.teleport_all_from()
end
Event.add(Main.events.on_game_started, on_game_started)

local function on_game_finished()
  Main.on_game_finished()
end
Event.add(Main.events.on_game_finished, on_game_finished)

local function on_player_created(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  if Lobby.enabled then
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

  if surface.name ~= RS.get_surface_name() then
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
  if entity_type == 'unit-spawner' then
    Main.on_spawner_died(event)
  elseif entity_type == 'unit' or entity.type == 'turret' then
    if entity.force.name == 'enemy' then
      Main.on_enemy_died(entity)
    end
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
  ScoreTracker.set_for_global(rocket_launches_name, this.rockets_to_win - this.rocket_launched)

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
  local rocket = event.rocket
  if not (rocket and rocket.valid) then
    return
  end

  if this.scenario_finished then
    return
  end

  this.rockets_launched = this.rockets_launched + 1
  if this.rockets_launched >= this.rockets_to_win then
    Main.win()
    return
  end

  game.print({'frontier.rocket_launched', this.rockets_launched, (this.rockets_to_win - this.rockets_launched) })
  Main.compute_silo_coordinates(500)

  local ticks = 60
  for _, delay in pairs{60, 40, 20} do
    for i = 1, 30 do
      ticks = ticks + math_random(math_ceil(delay/5), delay)
      Task.set_timeout_in_ticks(ticks, Main.play_sound_token, 'utility/alert_destroyed')
    end
  end
  Task.set_timeout_in_ticks(ticks + 30, Main.move_silo_token)
  local silo = event.rocket_silo
  if silo then silo.active = false end
end
Event.add(defines.events.on_rocket_launched, on_rocket_launched)

local function on_entity_mined(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end

  if entity.type == 'simple-entity' then
    Main.spawn_turret_outpost(entity.position)
  end
end
Event.add(defines.events.on_robot_mined_entity, on_entity_mined)
Event.add(defines.events.on_player_mined_entity, on_entity_mined)


-- == COMMANDS ================================================================

Command.add('ping-silo',
  {
    description = 'Pings the silo\'s position on map',
    allowed_by_server = true
  },
  function(_, player)
    local surface = RS.get_surface()
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

-- ============================================================================

return map
