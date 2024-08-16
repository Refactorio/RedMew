local b = require 'map_gen.shared.builders'
local Color = require 'resources.color_presets'
local Command = require 'utils.command'
local Event = require 'utils.event'
local EnemyTurret = require 'features.enemy_turret'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local math = require 'utils.math'
local MGSP = require 'resources.map_gen_settings'
local Noise = require 'map_gen.shared.simplex_noise'
local PriceRaffle = require 'features.price_raffle'
local Ranks = require 'resources.ranks'
local RS = require 'map_gen.shared.redmew_surface'
local ScenarioInfo = require 'features.gui.info'
local ScoreTracker = require 'utils.score_tracker'
local Sounds = require 'utils.sounds'
local Table = require 'utils.table'
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

local register_on_entity_destroyed = script.register_on_entity_destroyed

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

local this = {
  rounds = 0,
  -- Map gen
  silo_starting_x = 1700,

  height = 36,              -- in chunks, height of the ribbon world
  left_boundary = 8,        -- in chunks, distance to water body
  right_boundary = 11,      -- in chunks, distance to wall/biter presence
  wall_width = 5,           -- in tiles
  wall_vulnerability = true,
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
  loot_richness = 1,

  -- Rocket silo position management
  x = 0,
  y = 0,
  rocket_silo = nil,
  move_buffer = 0,
  rocket_step = 500,        -- rocket/tiles ratio
  min_step = 500,           -- minimum tiles to move
  max_distance = 100000,    -- maximum x distance of rocket silo

  -- Enemy data
  invincible = {},
  target_entities = {},
  unit_groups = {},

  -- Lobby
  lobby_enabled = false,

  -- Debug
  _DEBUG_AI = false,
  _DEBUG_SHOP = false,

  -- Spawn shop
  spawn_shop = nil,
  spawn_shop_funds = 0,
  spawn_shop_players_in_gui_view = {},
  spawn_shop_gui_refresh_scheduled = {},
  spawn_shop_upgrades = {},
}

Global.register(this, function(tbl) this = tbl end)

local noise_weights = {
  { modifier = 0.0042, weight = 1.000 },
  { modifier = 0.0310, weight = 0.080 },
  { modifier = 0.1000, weight = 0.025 },
}
local mixed_ores = { 'iron-ore', 'copper-ore', 'iron-ore', 'stone', 'copper-ore', 'iron-ore', 'copper-ore', 'iron-ore', 'coal', 'iron-ore', 'copper-ore', 'iron-ore', 'stone', 'copper-ore', 'coal'}
local ESCAPE_PLAYER = false
local VALUE_7_PACKS = 451
local PROD_PENALTY = 1.2 * 1.4^5

-- == MODULES =================================================================

local Main = {
  events = {
    on_game_started = Event.generate_event_name('on_game_started'),
    on_game_finished = Event.generate_event_name('on_game_finished'),
  },
  scores = {
    rocket_launches = { name = 'rockets-launches-frontier', tooltip = {'frontier.rockets_to_launch'}, sprite = '[img=item.rocket-silo]' },
    shop_funds      = { name = 'shop-funds-frontier',       tooltip = {'frontier.shop_funds'},        sprite = '[img=item.coin]' },
  },
}

local Debug = {}
local Enemy = {}
local Lobby = {}
local Market = {}
local SpawnShop = {}
local Terrain = {}

-- == DEBUG ===================================================================

function Debug.print_admins(msg, color)
  for _, p in pairs(game.connected_players) do
    if p.admin then
      p.print(msg, color)
    end
  end
end

function Debug.print(msg, color)
  for _, p in pairs(game.connected_players) do
    p.print(msg, color)
  end
end

function Debug.log(data)
  log(serpent.block(data))
end

-- == LOBBY ===================================================================

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
    SpawnShop.destroy_gui(player)
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
    for j = 0, w - 1 do
      local e = surface.create_entity {
        name = 'stone-wall',
        position = { x + j, y },
        force = 'player',
        move_stuck_players = true,
      }
      e.destructible = this.wall_vulnerability
    end
  end

  local tiles = {}
  for j = -4, w - 1 + 4 do
    for y = -this.height * 16, this.height * 16 do
      tiles[#tiles +1] = { name = 'hazard-concrete-left', position = { x = x + j, y = y }}
    end
  end
  for j = -1, w do
    for y = -this.height * 16, this.height * 16 do
      tiles[#tiles +1] = { name = 'concrete', position = { x = x + j, y = y }}
    end
  end
  surface.set_tiles(tiles, true)
end

-- == Enemy ===================================================================

Enemy.target_entity_types = {
  ['accumulator'] = true,
  ['assembling-machine'] = true,
  ['beacon'] = true,
  ['boiler'] = true,
  ['furnace'] = true,
  ['generator'] = true,
  ['heat-interface'] = true,
  ['lab'] = true,
  ['mining-drill'] = true,
  ['offshore-pump'] = true,
  ['reactor'] = true,
  ['roboport'] = true,
  ['solar-panel'] = true,
}

Enemy.commands = {
  move = function(unit_group, position)
    local data = Enemy.ai_take_control(unit_group)
    if not position then
      Enemy.ai_processor(unit_group)
      return
    end
    data.position = position
    data.stage = Enemy.stages.move
    unit_group.set_command {
      type = defines.command.go_to_location,
      destination = position,
      radius = 3,
      distraction = defines.distraction.by_enemy
    }
    unit_group.start_moving()
    if this._DEBUG_AI then
      Debug.print_admins(string.format('AI [id=%d] | cmd: MOVE [gps=%.2f,%.2f,%s]', unit_group.group_number, position.x, position.y, unit_group.surface.name), Color.dark_gray)
    end
  end,
  scout = function(unit_group, position)
    local data = Enemy.ai_take_control(unit_group)
    if not position then
      Enemy.ai_processor(unit_group)
      return
    end
    data.position = position
    data.stage = Enemy.stages.scout
    unit_group.set_command {
      type = defines.command.attack_area,
      destination = position,
      radius = 15,
      distraction = defines.distraction.by_enemy
    }
    unit_group.start_moving()
    if this._DEBUG_AI then
      Debug.print_admins(string.format('AI [id=%d] | cmd: SCOUT [gps=%.2f,%.2f,%s]', unit_group.group_number, position.x, position.y, unit_group.surface.name), Color.dark_gray)
    end
  end,
  attack = function(unit_group, target)
    local data = Enemy.ai_take_control(unit_group)
    if not (target and target.valid) then
      Enemy.ai_processor(unit_group)
      return
    end
    data.target = target
    data.stage = Enemy.stages.attack
    unit_group.set_command {
      type = defines.command.attack,
      target = target,
      distraction = defines.distraction.by_damage
    }
    if this._DEBUG_AI then
      Debug.print_admins(string.format('AI [id=%d] | cmd: ATTACK [gps=%.2f,%.2f,%s] (type = %s)', unit_group.group_number, target.position.x, target.position.y, unit_group.surface.name, target.type), Color.dark_gray)
    end
  end
}

Enemy.stages = {
  pending = 1,
  move = 2,
  scout = 3,
  attack = 4,
  fail = 5,
}

function Enemy.ai_take_control(unit_group)
  if not this.unit_groups[unit_group.group_number] then
    this.unit_groups[unit_group.group_number] = {
      unit_group = unit_group
    }
  end
  return this.unit_groups[unit_group.group_number]
end

function Enemy.ai_stage_by_distance(posA, posB)
  local x_axis = posA.x - posB.x
  local y_axis = posA.y - posB.y
  local distance = math_sqrt(x_axis * x_axis + y_axis * y_axis)
  if distance <= 15 then
    return Enemy.stages.attack
  elseif distance <= 32 then
    return Enemy.stages.scout
  else
    return Enemy.stages.move
  end
end

function Enemy.ai_processor(unit_group, result)
  if not (unit_group and unit_group.valid) then
    return
  end

  local data = this.unit_groups[unit_group.group_number]
  if not data then
    return
  end

  if data.failed_attempts and data.failed_attempts >= 3 then
    this.unit_groups[unit_group.group_number] = nil
    return
  end

  if not result or result == defines.behavior_result.fail or result == defines.behavior_result.deleted then
    data.stage = Enemy.stages.pending
  end
  if result == defines.behavior_result.success and (data.stage and data.stage == Enemy.stages.attack) then
    data.stage = Enemy.stages.pending
  end
  data.stage = data.stage or Enemy.stages.pending

  if data.stage == Enemy.stages.pending then
    local surface = unit_group.surface
    data.target = surface.find_nearest_enemy_entity_with_owner {
      position = unit_group.position,
      max_distance = this.rocket_step * 4,
      force = 'enemy',
    }
    if not (data.target and data.target.valid) then
      this.unit_groups[unit_group.group_number] = nil
      return
    end
    data.position = data.target.position
    data.stage = Enemy.ai_stage_by_distance(data.position, unit_group.position)
  else
    data.stage = data.stage + 1
  end

  if this._DEBUG_AI then
    Debug.print_admins(string.format('AI [id=%d] | status: %d', unit_group.group_number, data.stage), Color.dark_gray)
  end

  if data.stage == Enemy.stages.move then
    Enemy.commands.move(unit_group, data.target)
  elseif data.stage == Enemy.stages.scout then
    Enemy.commands.scout(unit_group, data.target)
  elseif data.stage == Enemy.stages.attack then
    Enemy.commands.attack(unit_group, data.target)
  else
    data.failed_attempts = (data.failed_attempts or 0) + 1
    if this._DEBUG_AI then
      Debug.print_admins(string.format('AI [id=%d] | FAIL | stage: %d | attempts: %d', unit_group.group_number, data.stage, data.failed_attempts), Color.dark_gray)
    end
    data.stage, data.position, data.target = nil, nil, nil
    Enemy.ai_processor(unit_group, nil)
  end
end

function Enemy.spawn_enemy_wave(position)
  local surface = RS.get_surface()
  local find_position = surface.find_non_colliding_position
  local spawn = surface.create_entity
  local current_tick = game.tick

  local unit_group = surface.create_unit_group { position = position, force = 'enemy' }

  local max_time = math_max(MINUTE, MINUTE * math_ceil(0.5 * (this.rockets_launched ^ 0.5)))

  local radius = 20
  for _ = 1, 12 do
    local name
    if this.rockets_launched < 3 then
      name = math_random(1, 6) == 1 and 'big-worm-turret' or 'medium-worm-turret'
    else
      name = math_random(1, 6) == 1 and 'behemoth-worm-turret' or 'big-worm-turret'
    end
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
    local name
    if this.rockets_launched < 3 then
      name = math_random(1, 3) == 1 and 'big-biter' or 'big-spitter'
    else
      name = math_random(1, 3) == 1 and 'behemoth-biter' or 'behemoth-spitter'
    end
    local about = find_position(name, { x = position.x + math_random(), y = position.y + math_random() }, radius, 0.6)
    if about then
      local unit = spawn { name = name, position = about, force = 'enemy', move_stuck_players = true }
      this.invincible[unit.unit_number] = {
        time_to_live = current_tick + math_random(MINUTE, max_time)
      }
      unit_group.add_member(unit)
    end
  end

  if unit_group.valid then
    Enemy.ai_take_control(unit_group)
    Enemy.ai_processor(unit_group)
  end
end
Enemy.spawn_enemy_wave_token = Token.register(Enemy.spawn_enemy_wave)

function Enemy.on_enemy_died(entity)
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
    if entity.unit_group then
      entity.unit_group.add_member(new_entity)
    end
  end
end

function Enemy.on_spawner_died(event)
  local entity = event.entity

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
  for i = 1, 4 do
    local item_stacks = PriceRaffle.roll(math_floor(budget / 3 ) + 1, i*i + math_random(3))
    for _, item_stack in pairs(item_stacks) do
      chest.insert(item_stack)
    end
  end
  if player then
    Toast.toast_player(player, nil, {'frontier.loot_chest'})
  end
end

function Enemy.spawn_turret_outpost(position)
  if position.x < this.right_boundary * 32 + this.wall_width then
    return
  end

  local max_chance = math_clamp(0.02 * math_sqrt(position.x), 0.01, 0.04)
  if math_random() > max_chance then
    return
  end

  local surface = RS.get_surface()

  if ESCAPE_PLAYER then
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

function Enemy.start_tracking(entity)
  if not Enemy.target_entity_types[entity.type] then
    return
  end

  if entity.force.name == 'enemy' or entity.force.name == 'neutral' then
    return
  end

  register_on_entity_destroyed(entity)
  this.target_entities[entity.unit_number] = entity
end

function Enemy.stop_tracking(entity)
  this.target_entities[entity.unit_number] = nil
end

function Enemy.get_target()
  return Table.get_random_dictionary_entry(this.target_entities, false)
end

function Enemy.nuclear_explosion(position)
  RS.get_surface().create_entity {
    name = 'atomic-rocket',
    position = position,
    force = 'enemy',
    source = position,
    target = position,
    max_range = 1,
    speed = 0.1
  }
end
Enemy.nuclear_explosion_token = Token.register(Enemy.nuclear_explosion)

function Enemy.artillery_explosion(data)
  local surface = game.get_surface(data.surface_name)
  local position = data.position
  local r = 20
  surface.create_entity {
    name = 'artillery-projectile',
    position = position,
    force = 'enemy',
    source = position,
    target = { x = position.x + math_random(-r, r) + math_random(), y = position.y + math_random(-r, r) + math_random() },
    max_range = 1,
    speed = 0.1
  }
end
Enemy.artillery_explosion_token = Token.register(Enemy.artillery_explosion)

-- == MARKET ==================================================================

Market.banned_items = { ['rocket-silo'] = true, ['space-science-pack'] = true, ['atomic-bomb'] = true, ['spidertron'] = true, ['tank'] = true }
Market.market_items = {}
Market.cheap_items = {}
Market.expensive_items = {}

do
  local market_items = PriceRaffle.get_items_worth()
  for k, _ in pairs(Market.banned_items) do
    market_items[k] = nil
  end
  market_items['car'] = 64
  market_items['tank-cannon'] = 2048
  market_items['tank-machine-gun'] = 1024
  market_items['light-armor'] = 16
  market_items['heavy-armor'] = 32
  market_items['modular-armor'] = 64
  for k, v in pairs(market_items) do
    if v > 127 then
      Market.expensive_items[k] = v
    else
      Market.cheap_items[k] = v
    end
  end
  Market.market_items = market_items
end

function Market.spawn_exchange_market(position)
  if position.x < this.left_boundary * 32 + this.wall_width then
    return
  end

  if position.y > this.height * 16 - 12 or position.y < -this.height * 16 + 12 then
    return
  end

  local surface = RS.get_surface()
  local market = surface.create_entity {
    name = 'market',
    position = position,
    force = 'neutral',
    create_build_effect_smoke = true,
    move_stuck_players = true,
  }
  market.minable = false
  market.destructible = false

  local offers_count = 10 + math_random(10)
  local max_attempts = 10

  local most_expensive_item = { value = 0 }
  local unlocked_items = PriceRaffle.get_unlocked_item_names()
  for _ = 1, offers_count do
    local inserted = false
    local expensive = Table.get_random_dictionary_entry(Market.expensive_items, true)
    for _ = 1, max_attempts do
      local cheap = unlocked_items[math_random(#unlocked_items)]
      if cheap and expensive then
        local cheap_value = Market.market_items[cheap]
        local expensive_value = Market.market_items[expensive]
        local price = expensive_value / cheap_value
        local nerf = PROD_PENALTY * math_clamp(math_sqrt(this.max_distance / (position.x * 10)), 1, 4.2) * (1 + math_random()) -- 1.4 = productivity, + some distance scaling. Further ) better offers
        price = math_min(math_ceil(price * nerf), 2^16-1)
        local stack_size = game.item_prototypes[cheap].stack_size
        if price / stack_size < 80 then
          market.add_market_item {
            offer = { type = 'give-item', item = expensive, count = 1 },
            price = {{ name = cheap, type = 'item', amount = price }},
          }
          if expensive_value > most_expensive_item.value then
            most_expensive_item.name = expensive
            most_expensive_item.value = expensive_value
          end
          inserted = true
          break
        end
      end
    end
    if not inserted then
      for _ = 1, max_attempts do
        local cheap = Table.get_random_dictionary_entry(Market.expensive_items, true)
        if cheap and expensive and cheap ~= expensive then
          local cheap_value = Market.market_items[cheap]
          local expensive_value = Market.market_items[expensive]
          local price = expensive_value / cheap_value
          local nerf = 1.4^5 * math_clamp(math_sqrt(this.max_distance / (position.x * 10)), 1.2, 10) * (1 + math_random()) -- 1.4 = productivity, + some distance scaling. Further ) better offers
          price = math_min(math_ceil(price * nerf), 2^16-1)
          local stack_size = game.item_prototypes[cheap].stack_size
          if price / stack_size < 50 then
            market.add_market_item {
              offer = { type = 'give-item', item = expensive, count = 1 },
              price = {{ name = cheap, type = 'item', amount = price }},
            }
            if expensive_value > most_expensive_item.value then
              most_expensive_item.name = expensive
              most_expensive_item.value = expensive_value
            end
            break
          end
        end
      end
    end
  end

  if most_expensive_item.name then
    local icon_offset = { 0, 0 }
    local icon_scale = 1
    rendering.draw_sprite {
      sprite = 'utility/entity_info_dark_background',
      surface = surface,
      target = market,
      target_offset = icon_offset,
      x_scale = icon_scale * 2,
      y_scale = icon_scale * 2,
      only_in_alt_mode = true
    }
    rendering.draw_sprite {
      sprite = 'item/' .. most_expensive_item.name,
      surface = surface,
      target = market,
      target_offset = icon_offset,
      x_scale = icon_scale,
      y_scale = icon_scale,
      only_in_alt_mode = true
    }
  end
end

-- == SPAWN SHOP ==============================================================

SpawnShop.main_frame_name = Gui.uid_name()
SpawnShop.close_button_name = Gui.uid_name()
SpawnShop.refresh_button_name = Gui.uid_name()
SpawnShop.upgrade_button_name = Gui.uid_name()

SpawnShop.upgrades = {
  { name = 'mining_productivity', packs =  100, sprite = 'technology/mining-productivity-1',                     caption = 'Mining productivity',        tooltip = {'frontier.tt_shop_mining_productivity'} },
  { name = 'energy_damage',       packs =  100, sprite = 'technology/energy-weapons-damage-1',                   caption = 'Energy weapons damage',      tooltip = {'frontier.tt_shop_energy_damage'} },
  { name = 'projectile_damage',   packs =  100, sprite = 'technology/physical-projectile-damage-1',              caption = 'Physical projectile damage', tooltip = {'frontier.tt_shop_projectile_damage'} },
  { name = 'explosive_damage',    packs =  100, sprite = 'technology/stronger-explosives-1',                     caption = 'Explosives damage',          tooltip = {'frontier.tt_shop_explosive_damage'} },
  { name = 'flammables_damage',   packs =  100, sprite = 'technology/refined-flammables-1',                      caption = 'Flammables damage',          tooltip = {'frontier.tt_shop_flammables_damage'} },
  { name = 'artillery_range',     packs =  100, sprite = 'technology/artillery-shell-range-1',                   caption = 'Artillery range',            tooltip = {'frontier.tt_shop_artillery_range'} },
  { name = 'artillery_speed',     packs =  100, sprite = 'technology/artillery-shell-speed-1',                   caption = 'Artillery speed',            tooltip = {'frontier.tt_shop_artillery_speed'} },
  { name = 'robot_cargo',         packs = 1000, sprite = 'technology/worker-robots-storage-1',                   caption = 'Worker robot cargo',         tooltip = {'frontier.tt_shop_robot_cargo'} },
  { name = 'robot_speed',         packs =  100, sprite = 'technology/worker-robots-speed-1',                     caption = 'Worker robot speed',         tooltip = {'frontier.tt_shop_robot_speed'} },
  { name = 'robot_battery',       packs =  100, sprite = 'technology/personal-roboport-mk2-equipment',           caption = 'Worker robot battery',       tooltip = {'frontier.tt_shop_robot_battery'} },
  { name = 'braking_force',       packs =  100, sprite = 'technology/braking-force-1',                           caption = 'Braking force',              tooltip = {'frontier.tt_shop_braking_force'} },
  { name = 'inserter_capacity',   packs =  200, sprite = 'technology/inserter-capacity-bonus-1',                 caption = 'Inserters capacity',         tooltip = {'frontier.tt_shop_inserter_capacity'} },
  { name = 'lab_productivity',    packs =  500, sprite = 'technology/research-speed-1',                          caption = 'Laboratory productivity',    tooltip = {'frontier.tt_shop_lab_productivity'} },
  { name = 'p_crafting_speed',    packs =  200, sprite = 'technology/automation-2',                              caption = 'Player crafting speed',      tooltip = {'frontier.tt_shop_p_crafting_speed'} },
  { name = 'p_health_bonus',      packs =  200, sprite = 'technology/energy-shield-mk2-equipment',               caption = 'Player health',              tooltip = {'frontier.tt_shop_p_health_bonus'} },
  { name = 'p_inventory_size',    packs =  500, sprite = 'technology/toolbelt',                                  caption = 'Player inventory size',      tooltip = {'frontier.tt_shop_p_inventory_size'} },
  { name = 'p_mining_speed',      packs =  200, sprite = 'technology/steel-axe',                                 caption = 'Player mining speed',        tooltip = {'frontier.tt_shop_p_mining_speed'} },
  { name = 'p_reach',             packs =  400, sprite = 'technology/power-armor',                               caption = 'Player reach',               tooltip = {'frontier.tt_shop_p_reach'} },
  { name = 'p_running_speed',     packs =  200, sprite = 'technology/exoskeleton-equipment',                     caption = 'Player running speed',       tooltip = {'frontier.tt_shop_p_running_speed'} },
  { name = 'p_trash_size',        packs =  200, sprite = 'utility/character_logistic_trash_slots_modifier_icon', caption = 'Player trash slots size',    tooltip = {'frontier.tt_shop_p_trash_size'} },
}

local bard_refresh_messages = {
  [[Ah, a gold coin! I bow to its allure! Here are fresh wares for your perusal!]],
  [[Splendid! Gold speaks, and I respond! Behold, new treasures await!]],
  [[With a coin of gold in hand, the fates realign! Check out my dazzling new offers!]],
  [[Gold flows like a river, and I shall bend to its will! Feast your eyes on these new delights!]],
  [[As you wish! The language of gold is my command! Here, new bargains for your quest!]],
  [[A glittering coin! I am at your service! New and wondrous offers are at your fingertips!]],
  [[Language of gold, you say? Very well! Behold, fresh offerings crafted by fate!]],
  [[A golden gift! I bend to its charm! Discover what new wonders sparkle before you!]],
  [[With your coin, I rejuvenate my stock! Here are shiny new wares for your journey!]],
  [[Gold calls, and I answer gladly! Fresh treasures for the wise adventurer await!]],
}

function SpawnShop.add_render()
  local e = this.spawn_shop
  rendering.draw_sprite {
    sprite = 'file/graphics/neon_lightning.png',
    x_scale = 0.8,
    y_scale = 0.8,
    target = e,
    target_offset = { 0.8, -4.5 },
    surface = e.surface,
  }
  game.forces.player.add_chart_tag(e.surface, {
    position = e.position,
    icon = { type = 'virtual', name = 'signal-info' },
    text = '[font=heading-1]   [color=#E9AF96]S[/color][color=#E9E096]P[/color][color=#BFE996]A[/color][color=#96E99E]W[/color][color=#96E9D0]N[/color]  [color=#96D0E9]S[/color][color=#969EE9]H[/color][color=#BF96E9]O[/color][color=#E996E0]P[/color][/font]'
  })
end
SpawnShop.add_render_token = Token.register(SpawnShop.add_render)

function SpawnShop.on_game_started()
  local surface = RS.get_surface()
  local position = surface.find_non_colliding_position('market', {0, 0}, 32, 0.5, true)
  local shop = surface.create_entity {
    name = 'market',
    position = position,
    force = 'player',
    create_build_effect_smoke = true,
    move_stuck_players = true,
    raise_built = false,
  }
  shop.minable = false
  this.spawn_shop = shop
  Task.set_timeout(1, SpawnShop.add_render_token)
  SpawnShop.refresh_all_prices(false)
end

function SpawnShop.draw_gui(player)
  local frame = player.gui.screen[SpawnShop.main_frame_name]
  if frame then
    player.opened = frame
    return
  end

  frame = player.gui.screen.add { type = 'frame', name = SpawnShop.main_frame_name, direction = 'vertical' }
  Gui.set_style(frame, {
    horizontally_stretchable = true,
    natural_width = 760,
    natural_height = 640,
    maximal_height = 900,
    top_padding = 8,
    bottom_padding = 8,
  })

  do -- title
    local flow = frame.add { type = 'flow', direction = 'horizontal' }
    Gui.set_style(flow, { horizontal_spacing = 8, vertical_align = 'center', bottom_padding = 4 })

    local label = flow.add { type = 'label', caption = 'Spawn shop', style = 'heading_1_label' }
    label.drag_target = frame

    local dragger = flow.add { type = 'empty-widget', style = 'draggable_space_header' }
    dragger.drag_target = frame
    Gui.set_style(dragger, { height = 24, horizontally_stretchable = true })

    flow.add {
      type = 'sprite-button',
      name = SpawnShop.close_button_name,
      sprite = 'utility/close_white',
      clicked_sprite = 'utility/close_black',
      style = 'close_button',
      tooltip = {'gui.close-instruction'}
    }
  end

  local idf = frame.add { type = 'frame', style = 'inside_deep_frame', direction = 'vertical' }
  local sp = idf.add { type = 'scroll-pane', style = 'text_holding_scroll_pane' }
  Gui.set_style(sp, {
    horizontally_stretchable = true,
    vertically_stretchable = true,
    vertically_squashable = false,
    maximal_height = 860,
  })
  sp.vertical_scroll_policy = 'always'

  local player_inventory = player.get_main_inventory()
  local pockets = player_inventory.get_contents()

  local function add_upgrade(parent, p)
    local data = this.spawn_shop_upgrades[p.name]
    if not data then
      return
    end

    local upgrade_frame = parent.add { type = 'frame', name = p.name, direction = 'vertical' }
    Gui.set_style(upgrade_frame, { horizontally_stretchable = true, bottom_padding = 4 })

    local row = upgrade_frame.add { type = 'flow', direction = 'horizontal' }
    Gui.set_style(row, { horizontal_spacing = 10, vertical_align = 'center' })

    local col_1 = row.add { type = 'sprite-button', sprite = p.sprite, style = 'transparent_slot' }
    Gui.set_style(col_1, { padding = -2, size = 48 })

    local col_2 = row.add { type = 'flow', direction = 'vertical' }
    Gui.set_style(col_2, { natural_width = 180 })
    col_2.add { type = 'label', style = 'caption_label', caption = p.caption }
    col_2.add { type = 'label', caption = 'Level: ' .. (data.level or 0) } --FIXME: number
    col_2.add { type = 'label', caption = p.tooltip }

    Gui.add_pusher(row)

    local col_3 = row.add { type = 'flow', direction = 'horizontal' }
    Gui.set_style(col_3, { natural_width = 360, vertical_align = 'center', horizontal_align = 'right' })
    local col_3_1 = col_3.add { type = 'flow', direction = 'vertical' }
    local table = col_3_1 .add { type = 'frame', style = 'inside_deep_frame' }.add { type = 'table', style = 'filter_slot_table', column_count = 5 }

    if data.price then
      for _, item_stack in pairs(data.price) do
        local satisfied = (item_stack.count <= (pockets[item_stack.name] or 0))
        table.add {
          type = 'sprite-button',
          sprite = 'item/'..item_stack.name,
          style = satisfied and 'recipe_slot_button' or 'yellow_slot_button',
          number = item_stack.count,
          tooltip = {'frontier.tt_shop_item_stack', {'?', {'item-name.'..item_stack.name}, {'entity-name.'..item_stack.name}, item_stack.name}, item_stack.count, (satisfied and 'green' or 'yellow') }
        }
      end
    end
    Gui.add_pusher(col_3)
    local col_3_2 = col_3.add { type = 'flow', direction = 'vertical' }
    local upgrade_button = col_3_2.add { type = 'button', name = SpawnShop.upgrade_button_name, style = 'confirm_button', caption = 'Upgrade', tags = { name = p.name } }
    upgrade_button.enabled = SpawnShop.can_purchase(player, p.name)
  end

  for _, params in pairs(SpawnShop.upgrades) do
    add_upgrade(sp, params)
  end

  local subfooter = idf.add { type = 'frame', style = 'subfooter_frame' }.add { type = 'flow', direction = 'horizontal' }
  Gui.set_style(subfooter, { horizontally_stretchable = true, horizontal_align = 'right', vertical_align = 'center', right_padding = 10 })

  subfooter.add { type = 'label', caption = 'Team funds ', style = 'caption_label' }
  local coin_button = subfooter.add {
    type = 'sprite-button',
    sprite = 'item/coin',
    style = 'transparent_slot',
    number = this.spawn_shop_funds,
    tooltip = {'frontier.tt_shop_funds_label'}
  }
  Gui.set_style(coin_button, { size = 28, right_margin = 8 })
  subfooter.add { type = 'label', caption = 'Refresh prices ', style = 'caption_label' }
  local refresh_button = subfooter.add {
    type = 'sprite-button',
    name = SpawnShop.refresh_button_name,
    sprite = 'utility/refresh',
    style = 'tool_button',
    tooltip = this.spawn_shop_funds > 0 and {'frontier.tt_shop_refresh_button'} or {'frontier.tt_shop_disabled_refresh_button'}
  }
  refresh_button.enabled = this.spawn_shop_funds > 0

  frame.force_auto_center()
  frame.auto_center = true
  player.opened = frame
end

function SpawnShop.destroy_gui(player)
  local frame = player.gui.screen[SpawnShop.main_frame_name]
  if frame then
    frame.destroy()
    this.spawn_shop_players_in_gui_view[player.index] = nil
  end
end

function SpawnShop.update_gui(player)
  local frame = player.gui.screen[SpawnShop.main_frame_name]
  if frame then
    frame.destroy()
    SpawnShop.draw_gui(player)
  end
end

function SpawnShop.update_all_guis()
  for _, player in pairs(game.players) do
    SpawnShop.update_gui(player)
  end
end

function SpawnShop.refresh_price(id)
  local upgrade = SpawnShop.get_upgrade_by_id(id)
  if not upgrade then
    return
  end

  local nominal_cost = math_floor(VALUE_7_PACKS * PROD_PENALTY * upgrade.packs)
  local item_stacks = PriceRaffle.roll(nominal_cost, 5, Market.banned_items)
  if this._DEBUG_SHOP then
    item_stacks = {{ name = 'iron-plate', count = 1 }}
  end

  do
    local cost_map = {}
    for _, is in pairs(item_stacks) do
      cost_map[is.name] = (cost_map[is.name] or 0) + is.count
    end
    item_stacks = {}
    for k, v in pairs(cost_map) do
      table.insert(item_stacks, { name = k, count = v })
    end
  end

  this.spawn_shop_upgrades[id] = this.spawn_shop_upgrades[id] or { level = 0 }
  this.spawn_shop_upgrades[id].price = item_stacks
end

function SpawnShop.refresh_all_prices(by_request)
  if by_request then
    ScoreTracker.change_for_global('coins-spent', 1)
  end
  for _, upgrade in pairs(SpawnShop.upgrades) do
    SpawnShop.refresh_price(upgrade.name)
  end
end

function SpawnShop.earn_coin()
  this.spawn_shop_funds = this.spawn_shop_funds + 1
  ScoreTracker.change_for_global(Main.scores.shop_funds.name, 1)
  Toast.toast_all_players(20, {'frontier.earn_coin'})
end

function SpawnShop.can_purchase(player, id)
  if not (player and player.valid) then
    return false
  end

  local data = this.spawn_shop_upgrades[id]
  if not (data and data.price) then
    return false
  end

  local inv = player.get_main_inventory()
  if inv.is_empty() then
    return false
  end

  local function can_purchase(request, available)
    for item, required in pairs(request) do
      if not available[item] or (available[item] < required) then
        return false
      end
    end
    return true
  end

  local available = inv.get_contents()
  local request = {}
  for _, item_stack in pairs(data.price) do
    request[item_stack.name] = item_stack.count
  end

  return can_purchase(request, available)
end

function SpawnShop.get_upgrade_by_id(id)
  for _, v in pairs(SpawnShop.upgrades) do
    if v.name == id then
      return v
    end
  end
end

function SpawnShop.on_player_purchase(player, id)
  if not (player and player.valid) then
    return
  end

  local data = this.spawn_shop_upgrades[id]
  if not (data and data.price) then
    return
  end

  if not SpawnShop.can_purchase(player, id) then
    player.print({'frontier.shop_purchase_fail'}, { sound_path = 'utility/cannot_build' })
    return
  end

  local inv = player.get_main_inventory()
  for _, item_stack in pairs(data.price) do
    inv.remove(item_stack)
  end

  data.level = data.level + 1
  SpawnShop.upgrade_perk(id)
  SpawnShop.refresh_price(id)
  SpawnShop.update_all_guis()
  game.print({'frontier.shop_purchase_success', player.name, SpawnShop.get_upgrade_by_id(id).caption, data.level}, { sound_path = 'utility/new_objective' })
end

function SpawnShop.on_player_refresh(player)
  this.spawn_shop_funds = this.spawn_shop_funds - 1
  ScoreTracker.change_for_global(Main.scores.shop_funds.name, -1)
  player.print('[color=orange][Bard][/color] ' .. bard_refresh_messages[math_random(#bard_refresh_messages)], { sound_path = 'utility/scenario_message', color = Color.dark_grey })
  SpawnShop.refresh_all_prices(true)
  SpawnShop.update_all_guis()
end

function SpawnShop.upgrade_perk(id)
  local players = game.forces.player

  local function apply_bonus(source, name, modifier)
    local types = {
      ammo   = { get = players.get_ammo_damage_modifier,   set = players.set_ammo_damage_modifier   },
      gun    = { get = players.get_gun_speed_modifier,     set = players.set_gun_speed_modifier     },
      turret = { get = players.get_turret_attack_modifier, set = players.set_turret_attack_modifier },
    }
    local force = types[source]
    force.set(name, force.get(name) + modifier)
  end

  local function scan_entities(source, target, modifier)
    for _, category in pairs({'entity_prototypes'}) do
      for name, p in pairs(game[category]) do
        if p.attack_parameters then
          local params = p.attack_parameters
          if params.ammo_type and params.ammo_type == target then
            apply_bonus(source, name, modifier)
          elseif params.ammo_type and params.ammo_type.category and params.ammo_type.category == target then
            apply_bonus(source, name, modifier)
          elseif params.ammo_categories and Table.contains(params.ammo_categories, target) then
            apply_bonus(source, name, modifier)
          end
        end
      end
    end
  end

  -- local target_types = { 'acid', 'electric', 'explosion', 'fire', 'impact', 'laser', 'physical', 'poison' }
  if id == 'mining_productivity' then
    players.mining_drill_productivity_bonus = players.mining_drill_productivity_bonus + 0.01
  elseif id == 'energy_damage' then
    apply_bonus('ammo', 'laser', 0.07)
    apply_bonus('ammo', 'electric', 0.07)
    apply_bonus('ammo', 'beam', 0.03)
  elseif id == 'projectile_damage' then
    apply_bonus('ammo', 'bullet', 0.04)
    apply_bonus('ammo', 'shotgun-shell', 0.04)
    apply_bonus('ammo', 'cannon-shell', 0.10)
    scan_entities('turret', 'bullet', 0.07)
  elseif id == 'explosive_damage' then
    apply_bonus('ammo', 'rocket', 0.05)
    apply_bonus('ammo', 'grenade', 0.02)
    apply_bonus('ammo', 'landmine', 0.02)
  elseif id == 'flammables_damage' then
    apply_bonus('ammo', 'flamethrower', 0.02)
    scan_entities('turret', 'flamethrower', 0.02)
  elseif id == 'artillery_range' then
    players.artillery_range_modifier = players.artillery_range_modifier + 0.03
  elseif id == 'artillery_speed' then
    apply_bonus('gun', 'artillery-shell', 0.1)
  elseif id == 'robot_cargo' then
    players.worker_robots_storage_bonus = players.worker_robots_storage_bonus + 1
  elseif id == 'robot_speed' then
    players.worker_robots_speed_modifier = players.worker_robots_speed_modifier + 0.065
  elseif id == 'robot_battery' then
    players.worker_robots_battery_modifier = players.worker_robots_battery_modifier + 0.05
  elseif id == 'braking_force' then
    players.train_braking_force_bonus = players.train_braking_force_bonus + 0.02
  elseif id == 'inserter_capacity' then
    players.inserter_stack_size_bonus = players.inserter_stack_size_bonus + 1
    players.stack_inserter_capacity_bonus = players.stack_inserter_capacity_bonus + 1
  elseif id == 'lab_productivity' then
    players.laboratory_productivity_bonus = players.laboratory_productivity_bonus + 0.005
  elseif id == 'p_crafting_speed' then
    players.manual_crafting_speed_modifier = players.manual_crafting_speed_modifier + 0.02
  elseif id == 'p_health_bonus' then
    players.character_health_bonus = players.character_health_bonus + 0.02
  elseif id == 'p_inventory_size' then
    players.character_inventory_slots_bonus = players.character_inventory_slots_bonus + 5
  elseif id == 'p_mining_speed' then
    players.manual_mining_speed_modifier = players.manual_mining_speed_modifier + 0.02
  elseif id == 'p_reach' then
    players.character_build_distance_bonus = players.character_build_distance_bonus + 0.02
    players.character_item_drop_distance_bonus = players.character_item_drop_distance_bonus + 0.02
    players.character_reach_distance_bonus = players.character_reach_distance_bonus + 0.02
    players.character_resource_reach_distance_bonus = players.character_resource_reach_distance_bonus + 0.02
    players.character_item_pickup_distance_bonus = players.character_item_pickup_distance_bonus + 0.02
  elseif id == 'p_running_speed' then
    players.character_running_speed_modifier = players.character_running_speed_modifier + 0.02
  elseif id == 'p_trash_size' then
    players.character_trash_slot_count = players.character_trash_slot_count + 5
  end
end

-- == MAIN ====================================================================

do
  local global_to_show = Config.score.global_to_show
  for k, v in pairs(Main.scores) do
    global_to_show[#global_to_show + 1] = v.name
    ScoreTracker.register(v.name, v.tooltip, v.sprite)
  end
end

local bard_messages_1 = {
  [1] = {
    [[The rocket has successfully launched! The Kraken has accepted your offering... for now.]],
    [[A distant rumble echoes through the air. The Kraken stirs in the depths.]],
    [[You can almost feel the waters shifting. What will the Kraken do with your gift?]],
    [[The sky darkens as the rocket ascends. Is the Kraken pleased or plotting revenge?]],
    [[You have awakened something ancient. Expect the unknown in the next moments.]],
    [[A whisper echoes in your mind: 'You dare disturb my slumber?']],
    [[The Kraken watches from below, its tendrils coiling in anticipation.]],
    [[A chilling wind sweeps across your factory—a sign the Kraken is not to be trifled with.]],
    [[The ground trembles as the rocket disappears into the sky... what price will you pay?]],
    [[An ominous shadow looms beneath the waves. The Kraken has taken notice.]],
  },
  [2] = {
    [[As the rocket pierces the sky, dark waters tremble in anticipation... something stirs.]],
    [[A whispering gale caresses the land; the Kraken's essence begins to awaken.]],
    [[Shadows flicker at the water's edge. The depths conceal secrets you cannot fathom.]],
    [[Eyes unblinking watch from the abyss; your offering has been noted with curiosity... or contempt.]],
    [[The air grows thick with foreboding. An ancient power rouses from its slumber.]],
    [[From the deep, a voice resonates: 'What price have you paid for your hubris?']],
    [[The ocean churns as if agitated. The Kraken's mood is as unpredictable as the tempest.]],
    [[Unseen tendrils drift closer to your shores. What has been awakened cannot be unmade.]],
    [[A shiver runs through the ground, as if the earth itself fears the Kraken's gaze.]],
    [[With each second that passes, the Kraken's presence suffocates the air around you.]],
  },
  [3] = {
    [[Hark! The rocket soars to the heavens, yet below, the Kraken stirs in its slumber deep, its ancient wrath looms ever near!]],
    [[Lo, the winds whisper secrets of the abyss; the Kraken watches, its tendrils twitching in delight or dread—can you tell which it shall be?]],
    [[By the light of the fading suns, shadows dance upon the waves. A gift offered, but at what terrible cost? Beware the storm that brews!]],
    [[Listen well, dear traveler! For the depths grow restless, and the Kraken, master of the abyss, awakens to claim its due!]],
    [[Oh, fear the echo of the deep! A creature of legend stirs, its gaze upon your fortress—wreathed in shadows, it feasts on your hubris!]],
    [[Beware the churning sea, where the ancient beast stirs; your paid price may be your eternal plight—what horrors shall it unleash?]],
    [[From depths unknown, an unsettling murmur rises, 'You dared disturb me, foolish one! Know now the depths of my disdain!']],
    [[As the rocket ascends, the sky darkens and trembles, for the Kraken's heart beats wildly—can you sense its lurking fury?]],
    [[Oremus, oh heed my words! For beneath the surface lies a horror awakened—a vengeful force hungering for the taste of calamity!]],
    [[An eternal shadow looms, beckoned by your ambition! What horrors have you invited to dance upon your very threshold?]],
  },
}
local bard_messages_2 = {
  [1] = {
    [[The surface of the water begins to churn ominously... something awakens.]],
    [[An unsettling roar reverberates through the land. The Kraken's wrath is near.]],
    [[A dark cloud forms above, casting a shadow over your factory. The Kraken is displeased.]],
    [[Tentacles rise from the deep, a harbinger of chaos approaching your base.]],
    [[The Kraken demands retribution! Prepare for the onslaught!]],
    [[A storm brews on the horizon; the Kraken lashes out in fury.]],
    [[The air grows thick with tension as a monstrous wave approaches your shores.]],
    [[All around you, the atmosphere shifts—something is very wrong.]],
    [[The Kraken's vengeance is upon you! Brace yourself for the inevitable.]],
    [[In its rage, the Kraken unleashes its fury! The biter swarm descends!]],
  },
  [2] = {
    [[The surface roils ominously, dark waters boiling as wrath takes form.]],
    [[A haunting cry echoes across the landscape—an ancient beast calls for retribution.]],
    [[Dark clouds gather like a shroud, heralding calamity born of the abyss.]],
    [[Tendrils of shadow writhe beneath the waves—a prelude to the storm of vengeance.]],
    [[The Kraken's disdain unfurls like a tempest, a dark promise of chaos and destruction.]],
    [[An unnatural stillness settles, broken only by the distant crash of furious waves.]],
    [[The deep stirs with malice. Can you hear the heartbeat of your impending doom?]],
    [[In the twilight, the Kraken's fury eclipses all hope, a symphony of despair draws near.]],
    [[As specters rise from the depths, their intent is clear: retribution is swift and merciless.]],
    [[Your fate is entwined with the Kraken's ire—prepare for the inexorable tide of darkness.]],
  },
  [3] = {
    [[Attend! A tempest brews upon darkened waters, rage unfurling like a ravenous beast—your time is nigh!]],
    [[The Kraken's call resounds, echoing through the night; from the abyss it comes, cloaked in shadows and dread!]],
    [[A shudder passes through the land, and ominous clouds converge—gaze now upon the darkening sky, for doom draws near!]],
    [[Dread whisperings of the deep herald the coming tempest; the Kraken rises, eager to reclaim what is owed with swift malice!]],
    [[Foul winds carry the scent of vengeance. The Kraken's ire is unbound, and soon your fortress shall feel its dark embrace!]],
    [[In the twilight haze, a cacophony of doom stirs—behold, the tide of destruction approaches with unholy intent!]],
    [[Tremble now, for the Kraken awakens! A chorus of despair sings forth, heralding the swarm that comes, hungry and relentless!]],
    [[The ancient beast unleashes fury upon your path—a storm of chaos born from the depths, bringing forth a wretched tide!]],
    [[Beware! The Kraken's wrath is a specter unshackled, and every heartbeat draws nearer to the end of your peace!]],
    [[Thus, from beneath the waves, chaos and slaughter arise—oh, brave souls, face the horrors your hubris has conjured!]],
  },
}

Main.play_sound_token = Token.register(Sounds.notify_all)

Main.restart_message_token = Token.register(function(seconds)
  game.print({'frontier.restart', seconds}, Color.success)
end)

function Main.bard_message(list)
  game.print('[color=orange][Bard][/color] ' .. list[math_random(#list)], { sound_path = 'utility/axe_fighting', color = Color.brown })
end
Main.bard_message_token = Token.register(Main.bard_message)

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
    Enemy.nuclear_explosion(chest.position)

    for _ = 1, 3 do
      local spawn_target = Enemy.get_target()
      if spawn_target and spawn_target.valid then
        for _ = 1, 12 do
          Task.set_timeout_in_ticks(math_random(30, 4 * 60), Enemy.artillery_explosion_token, { surface_name = surface.name, position = spawn_target.position })
        end
        for t = 1, math_clamp(math_floor((#game.connected_players) / 2 + 0.5), 1, 5) do
          Task.set_timeout(15 * t, Enemy.spawn_enemy_wave_token, spawn_target.position)
        end
        break
      end
    end

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
        Main.set_game_state(true)
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

function Main.set_game_state(player_won)
  this.scenario_finished = true
  game.set_game_state {
    game_finished = true,
    player_won = player_won or false,
    can_continue = true,
    victorious_force = player_won and 'player' or 'enemy'
  }

  Task.set_timeout( 1, Main.restart_message_token, 90)
  Task.set_timeout(31, Main.restart_message_token, 60)
  Task.set_timeout(61, Main.restart_message_token, 30)
  Task.set_timeout(81, Main.restart_message_token, 10)
  Task.set_timeout(86, Main.restart_message_token,  5)
  Task.set_timeout(91, Main.end_game_token)
  Task.set_timeout(92, Main.restart_game_token)
end
Main.set_game_state_token = Token.register(Main.set_game_state)

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
  this.rockets_to_win = 12 + math_random(12) + this.rounds
  this.rockets_launched = 0
  this.scenario_finished = false
  this.x = 0
  this.y = 0
  this.rocket_silo = nil
  this.move_buffer = 0
  this.invincible = {}
  this.target_entities = {}
  this.unit_groups = {}
  this.spawn_shop_funds = 1
  this.spawn_shop_upgrades = {}

  if _DEBUG then
    this.silo_starting_x = 30
    this.rockets_to_win = 2
    this.spawn_shop_funds = 3
  end

  for _, force in pairs(game.forces) do
    force.reset()
    force.reset_evolution()
  end

  game.speed = 1
  game.reset_game_state()
  game.reset_time_played()

  ScoreTracker.reset()
  ScoreTracker.set_for_global(Main.scores.rocket_launches.name, this.rockets_to_win)
  ScoreTracker.set_for_global(Main.scores.shop_funds.name, this.spawn_shop_funds)
end

Main.restart_game_token = Token.register(function()
  script.raise_event(Main.events.on_game_started, {})
end)

function Main.on_game_finished()
  this.lobby_enabled = true
  Lobby.teleport_all_to()

  local surface = RS.get_surface()
  surface.clear(true)
  local mgs = table.deepcopy(surface.map_gen_settings)
  mgs.seed = mgs.seed + 1e4
  surface.map_gen_settings = mgs
end

Main.end_game_token = Token.register(function()
  script.raise_event(Main.events.on_game_finished, {})
end)

-- == EVENTS ==================================================================

local function on_init()
  Lobby.on_init()
  Main.on_game_started()
  Main.reveal_spawn_area()
  SpawnShop.on_game_started()

  this.lobby_enabled = false
  Lobby.teleport_all_from()
end
Event.on_init(on_init)

local function on_game_started()
  Main.on_game_started()
  Main.reveal_spawn_area()
  SpawnShop.on_game_started()

  this.lobby_enabled = false
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
    Task.set_timeout(3, Main.set_game_state_token, false)
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
  ScoreTracker.set_for_global(Main.scores.rocket_launches.name, this.rockets_to_win - this.rockets_launched)

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
  ScoreTracker.set_for_global(Main.scores.rocket_launches.name, this.rockets_to_win - this.rockets_launched)
  if this.rockets_launched >= this.rockets_to_win then
    Main.set_game_state(true)
    return
  end

  game.print({'frontier.rocket_launched', this.rockets_launched, (this.rockets_to_win - this.rockets_launched) })
  Main.compute_silo_coordinates(this.rocket_step + math_random(200))

  local ticks = 60
  for _, delay in pairs{60, 40, 20} do
    for i = 1, 30 do
      ticks = ticks + math_random(math_ceil(delay/5), delay)
      Task.set_timeout_in_ticks(ticks, Main.play_sound_token, 'utility/alert_destroyed')
    end
  end
  Task.set_timeout( 5, Main.bard_message_token, bard_messages_1[3])
  Task.set_timeout(25, Main.bard_message_token, bard_messages_2[3])
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

return map
