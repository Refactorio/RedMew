local b = require 'map_gen.shared.builders'
local Command = require 'utils.command'
local Event = require 'utils.event'
local Global = require 'utils.global'
local math = require 'utils.math'
local MGSP = require 'resources.map_gen_settings'
local Noise = require 'map_gen.shared.simplex_noise'
local PriceRaffle = require 'features.price_raffle'
local RS = require 'map_gen.shared.redmew_surface'
local ScenarioInfo = require 'features.gui.info'
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
local simplex = Noise.d2

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

local _g = {
  -- Map gen
  silo_starting_x = 1700,

  height = 36,              -- in chunks, height of the ribbon world
  left_boundary = 8,        -- in chunks, distance to water body
  right_boundary = 11,      -- in chunks, distance to wall/biter presence
  wall_width = 5,

  ore_base_quantity = 61,   -- base ore quantity, everything is scaled up from this
  ore_chunk_scale = 32,     -- sets how fast the ore will increase from spawn, lower = faster

  -- Kraken handling
  kraken_distance = 25,     -- where the kraken lives past the left boundary
  kraken_contributors = {}, -- list of players eaten by kraken
  death_contributions = {}, -- list of all players deaths

  -- Satellites to win
  rockets_to_win = 1,
  rockets_launched = 0,
  rockets_per_death = 1,    -- how many extra launch needed for each death
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
}

if _DEBUG then
  _g.silo_starting_x = 30
  _g.rockets_to_win = 3
end

Global.register(_g, function(tbl) _g = tbl end)

local noise_weights = {
  { modifier = 0.0042, weight = 1.000 },
  { modifier = 0.0310, weight = 0.080 },
  { modifier = 0.1000, weight = 0.025 },
}
local mixed_ores = { 'iron-ore', 'copper-ore', 'iron-ore', 'stone', 'copper-ore', 'iron-ore', 'copper-ore', 'iron-ore', 'coal', 'iron-ore', 'copper-ore', 'iron-ore', 'stone', 'copper-ore', 'coal'}

-- == MAP GEN =================================================================

local map, water, green_water

RS.set_map_gen_settings({
  {
    autoplace_controls = {
      coal = { frequency = 3, richness = 1, size = 0.75 },
      ['copper-ore'] = { frequency = 3, richness = 1, size = 0.75 },
      ['crude-oil'] = { frequency = 1, richness = 1, size = 0.75 },
      ['enemy-base'] = { frequency = 6, richness = 1, size = 4 },
      ['iron-ore'] = { frequency = 3, richness = 1, size = 0.75 },
      stone = { frequency = 3, richness = 1, size = 0.75 },
      trees = { frequency = 1, richness = 1, size = 1 },
      ['uranium-ore'] = { frequency = 0.5, richness = 1, size = 0.5 },
    },
    cliff_settings = { name = 'cliff', cliff_elevation_0 = 20, cliff_elevation_interval = 40, richness = 1 / 3 },
    height = _g.height * 32,
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
  return x > (-_g.left_boundary * 32 - 320) and not ((y < -_g.height * 16) or (y > _g.height * 16))
end

water = b.change_tile(bounds, true, 'water')
water = b.fish(water, 0.075)

green_water = b.change_tile(bounds, true, 'deepwater-green')

map = b.choose(function(x) return x < -_g.left_boundary * 32 end, water, bounds)
map = b.choose(function(x) return math_floor(x) == -(_g.kraken_distance + _g.left_boundary * 32 + 1) end, green_water, map)

-- == EVENTS ==================================================================

local function noise_pattern(position, seed)
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

local function mixed_resources(surface, area)
  local left_top = { x = math_max(area.left_top.x, _g.right_boundary * 32), y = area.left_top.y }
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
    }) do resource.destroy() end
  end

  local chunks = math_clamp(math_abs((left_top.x - _g.right_boundary * 32) / _g.ore_chunk_scale), 1, 100)
  chunks = math_random(chunks, chunks + 4)
  for x = 0, 31 do
    for y = 0, 31 do
      local position = { x = left_top.x + x, y = left_top.y + y }
      if can_place_entity({ name = 'iron-ore', position = position }) then
        local noise = noise_pattern(position, seed)
        if math_abs(noise) > 0.67 then
          local idx = math_floor(noise * 25 + math_abs(position.x) * 0.05) % #mixed_ores + 1
          local amount = _g.ore_base_quantity * chunks * 3
          clear_ore(position)
          create_entity({ name = mixed_ores[idx], position = position, amount = amount })
        end
      end
    end
  end
end

local function clear_enemies_inside_wall(surface, area)
  if area.right_bottom.x < (_g.right_boundary * 32 + 96) then
    for _, entity in pairs(surface.find_entities_filtered { area = area, force = 'enemy' }) do
      entity.destroy()
    end
  end
end

local function scale_resource_richness(surface, area)
  for _, resource in pairs(surface.find_entities_filtered { area = area, type = 'resource' }) do
    if resource.position.x > _g.right_boundary * 32 then
      local chunks = math.clamp(math_abs((resource.position.x - _g.right_boundary * 32) / _g.ore_chunk_scale), 1, 100)
      chunks = math_random(chunks, chunks + 4)
      if resource.prototype.resource_category == 'basic-fluid' then
        resource.amount = 3000 * 3 * chunks
      elseif resource.prototype.resource_category == 'basic-solid' then
        resource.amount = _g.ore_base_quantity * chunks
      end
    end
  end
end

local function set_silo_tiles(entity)
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

local function nuclear_explosion(entity)
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

local function init_wall(x, w)
  local surface = RS.get_surface()
  local area = { { x, -_g.height * 16 }, { x + w, _g.height * 16 } }
  for _, entity in pairs(surface.find_entities_filtered { area = area, collision_mask = 'player-layer' }) do
    entity.destroy()
  end

  for y = -_g.height * 16, _g.height * 16 do
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

local function win()
  _g.scenario_finished = true
  game.set_game_state { game_finished = true, player_won = true, can_continue = true, victorious_force = 'player' }
end

local play_sound_token = Token.register(Sounds.notify_all)

local function move_silo(position)
  local surface = RS.get_surface()
  local old_silo = _g.rocket_silo
  local old_position = old_silo and old_silo.position or { x = 0, y = 0 }
  local new_silo
  local new_position = position or { x = _g.x, y = _g.y }

  if old_silo and math_abs(new_position.x - old_position.x) < _g.min_step then
    _g.move_buffer = _g.move_buffer + new_position.x - old_position.x
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
    else
      local spill_item_stack = surface.spill_item_stack
      for x = -15, 15 do
        for y = -15, 15 do
          for _ = 1, 4 do
            spill_item_stack({ x = old_position.x + x + math_random(), y = old_position.y + y + math_random()}, { name = 'raw-fish', count = 1 }, false, nil, true)
          end
        end
      end
      game.print({'frontier.empty_rocket'})
    end
    nuclear_explosion(chest)
  else
    new_silo = surface.create_entity { name = 'rocket-silo', position = new_position, force = 'player', move_stuck_players = true }
  end

  if new_silo and new_silo.valid then
    new_silo.destructible = false
    new_silo.minable = false
    new_silo.active = true
    new_silo.get_output_inventory().clear()
    _g.rocket_silo = new_silo
    _g.x = new_silo.position.x
    _g.y = new_silo.position.y
    _g.move_buffer = 0
    set_silo_tiles(new_silo)

    local x_diff = math.round(new_position.x - old_position.x)
    if x_diff > 0 then
      game.print({'frontier.silo_forward', x_diff})
    else
      game.print({'frontier.silo_backward', x_diff})
    end
  end
end
local move_silo_token = Token.register(move_silo)

local function compute_silo_coordinates(step)
  _g.move_buffer = _g.move_buffer + (step or 0)

  if _g.x + _g.move_buffer > _g.max_distance then
    -- Exceeding max right direction, move to max (if not already) and add rockets to win
    local remainder = _g.x + _g.move_buffer - _g.max_distance
    local add_rockets = math_floor(remainder / _g.rocket_step)
    if add_rockets > 0 then
      _g.rockets_to_win = _g.rockets_to_win + add_rockets
      game.print({'frontier.warning_max_distance', _g.rocket_step})
    end
    _g.x = math_min(_g.max_distance, _g.x + _g.move_buffer)
    _g.move_buffer = remainder % _g.rocket_step
  elseif _g.x + _g.move_buffer < -(_g.left_boundary * 32) + 12 then
    -- Exceeding min left direction, move to min (if not already) and remove rockets to win
    local min_distance = -(_g.left_boundary * 32) + 12
    local remainder = _g.x + _g.move_buffer - min_distance -- this is negative
    local remove_rockets = math_floor(-remainder / _g.rocket_step)
    if remove_rockets > 0 then
      _g.rockets_to_win = _g.rockets_to_win - remove_rockets
      if _g.rockets_to_win < 1 then _g.rockets_to_win = 1 end
      if _g.rockets_launched >= _g.rockets_to_win then
        win()
        return
      else
        game.print({'frontier.warning_min_distance', _g.rocket_step})
      end
    end
    _g.x = math_max(min_distance, _g.x + _g.move_buffer)
    _g.move_buffer = remainder % _g.rocket_step
  else
    _g.x = _g.x + _g.move_buffer
    _g.move_buffer = 0
  end

  local max_height = (_g.height * 16) - 16
  _g.y = math_random(-max_height, max_height)
end

Event.on_init(function()
  local ms = game.map_settings
  ms.enemy_expansion.friendly_base_influence_radius = 0
  ms.enemy_expansion.min_expansion_cooldown = 60 * 30 -- 30 seconds
  ms.enemy_expansion.max_expansion_cooldown = 60 * 60 * 4 -- 4 minutes
  ms.enemy_expansion.max_expansion_distance = 5
  ms.enemy_evolution.destroy_factor = 0.0001

  local surface = RS.get_surface()
  local far_left, far_right = _g.kraken_distance + _g.left_boundary * 32 + 1, _g.right_boundary * 32 + _g.wall_width
  surface.request_to_generate_chunks({ x = 0, y = 0 }, math.ceil(math_max(far_left, far_right, _g.height * 32) / 32))
  surface.force_generate_chunk_requests()

  compute_silo_coordinates(_g.silo_starting_x + math_random(100))
  move_silo()
  init_wall(_g.right_boundary * 32, _g.wall_width)

  game.forces.player.chart(surface, { { -far_left - 32, -_g.height * 16 }, { far_right + 32, _g.height * 16 } })
end)

local function on_chunk_generated(event)
  local area = event.area
  local surface = event.surface
  if surface.name ~= RS.get_surface_name() then
    return
  end

  -- kill off biters inside the wall
  clear_enemies_inside_wall(surface, area)

  -- scale freshly generated ore by a scale factor
  scale_resource_richness(surface, area)

  -- add mixed patches
  mixed_resources(surface, area)
end
Event.add(defines.events.on_chunk_generated, on_chunk_generated)

local function on_entity_died(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end

  if entity.type ~= 'unit-spawner' then
    return
  end

  local chance = math_random()
  if chance > _g.loot_chance then
    return
  end

  local budget = _g.loot_budget + entity.position.x * 2.75
  budget = budget * math_random(25, 175) * 0.01

  local player = event.cause and event.cause.player
  if player and player.valid then
    budget = budget + (_g.death_contributions[player.name] or 0) * 80
  end

  if math_random(1, 128) == 1 then budget = budget * 4 end
  if math_random(1, 256) == 1 then budget = budget * 4 end
  budget = budget * _g.loot_richness

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

  if _g.rockets_per_death <= 0 then
    return
  end

  local player_name = 'a player'
  if player then
    player_name = player.name
    _g.death_contributions[player_name] = (_g.death_contributions[player_name] or 0) + 1
  end

  _g.rockets_to_win = _g.rockets_to_win + _g.rockets_per_death
  if _g.rockets_to_win < 1 then
    _g.rockets_to_win = 1
  end

  game.print({'frontier.add_rocket', _g.rockets_per_death, player_name, (_g.rockets_to_win - _g.rockets_launched)})
end
Event.add(defines.events.on_player_died, on_player_died)

local function on_player_changed_position(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  if player.position.x < (-_g.left_boundary * 32 - _g.kraken_distance) then
    local player_name = 'a player'
    if player.character ~= nil then
      player_name = player.name
    end
    game.print({'frontier.kraken_eat', player_name}, { sound_path = 'utility/game_lost' })
    if player.character ~= nil then
      player.character.die()
      _g.kraken_contributors[player_name] = true
    end
  end
end
Event.add(defines.events.on_player_changed_position, on_player_changed_position)

local function on_rocket_launched(event)
  local rocket = event.rocket
  if not (rocket and rocket.valid) then
    return
  end

  if _g.scenario_finished then
    return
  end

  _g.rockets_launched = _g.rockets_launched + 1
  if _g.rockets_launched >= _g.rockets_to_win then
    win()
    return
  end

  game.print({'frontier.rocket_launched', _g.rockets_launched, (_g.rockets_to_win - _g.rockets_launched) })
  compute_silo_coordinates(500)

  local ticks = 60
  for _, delay in pairs{60, 40, 20} do
    for i = 1, 30 do
      ticks = ticks + math_random(math_ceil(delay/5), delay)
      Task.set_timeout_in_ticks(ticks, play_sound_token, 'utility/alert_destroyed')
    end
  end
  Task.set_timeout_in_ticks(ticks + 30, move_silo_token)
  local silo = event.rocket_silo
  if silo then silo.active = false end
end
Event.add(defines.events.on_rocket_launched, on_rocket_launched)

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
