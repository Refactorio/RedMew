local b = require 'map_gen.shared.builders'
local Command = require 'utils.command'
local Event = require 'utils.event'
local Global = require 'utils.global'
local math = require 'utils.math'
local MGSP = require 'resources.map_gen_settings'
local RS = require 'map_gen.shared.redmew_surface'
local ScenarioInfo = require 'features.gui.info'

local concat = table.concat
local insert = table.insert
local math_random = math.random
local math_max = math.max
local math_min = math.min
local math_abs = math.abs
local math_floor = math.floor

--[[
  Scenario info: Frontier
  From 'Frontier Extended' mod: https://mods.factorio.com/mod/Frontier-Extended
]]

ScenarioInfo.set_map_name('Frontier')
ScenarioInfo.set_map_description([[
  [font=default-bold]Welcome to Frontier![/font]

  You are stranded between an ocean and a land infested with exceptionally aggressive biters and your only defense is a mysterious wall which up until now has kept the biters from completely overrunning the land.
  Somewhere behind the wall is a rocket silo where you can escape the nightmare of biters.

  Good luck, have fun.
  The [color=red]RedMew[/color] team
]])
ScenarioInfo.set_map_extra_info('Watch out for the Kraken!')

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

local silo_starting_x = 1700 -- center point the silo will be to the right of spawn
--local silo_radius = 450 -- radius around center point the silo will be

local height = 36 -- in chunks
local left_boundary = 8 -- in chunks
local left_water_boundary = left_boundary * 32 -- after this distance just generate water to a barrier
local death_world_boundary = 11 * 32 -- point where the ores start getting richer and biters begin
local wall_width = 5

local ore_base_quantity = 61 -- base ore quantity, everything is scaled up from this
local ore_chunk_scale = 32   -- sets how fast the ore will increase from spawn, lower = faster

local _global = {
  rocket_silo = nil,

  -- Kraken handling
  kraken_distance = 25, -- Where the kraken lives past the water boundary

  kraken_contributors = {}, -- List of contributors so far (so that we can print when we actually move the silo)

  -- Rockets/silo location management
  rockets_to_win = 1,
  rockets_launched = 0,
  scenario_finished = false,

  move_cost_ratio = 1,-- If the multipler is 2, you need to buy 2x the tiles to actually move 1x
  move_step = 500, -- By default, we only move 500 tiles at a time

  rocket_step = 500, -- How many "tiles" past the max distance adds a launch

  rockets_per_death = 1, -- How many extra launch needed for each death

  max_distance = 100000, -- By default, 100k tiles max to the right

  move_cost_ratio_mult = 2, -- Be default, we increase the "cost" of a tile by 2
  move_cost_step = 50000, -- Every 50k tiles move

  move_buffer_ratio = 0, -- How many tiles we have moved since the last ratio multiplier
  move_buffer = 0, -- How many tiles we haven't currently reflected (between +move_step and -move_step)
  plus_contributors = {}, -- List of contributors so far (so that we can print when we actually move the silo)
  minus_contributors = {}, -- List of contributors so far (so that we can print when we actually move the silo)
}

Global.register(_global, function(tbl) _global = tbl end)

-- == MAP GEN =================================================================

local map, water, green_water

RS.set_map_gen_settings({
  {
    autoplace_controls = {
      coal = { frequency = 3, richness = 1, size = 0.75 },
      ['copper-ore'] = { frequency = 3, richness = 1, size = 0.75 },
      ['crude-oil'] = { frequency = 1, richness = 0.5, size = 0.5 },
      ['enemy-base'] = { frequency = 6, richness = 1, size = 4 },
      ['iron-ore'] = { frequency = 3, richness = 1, size = 0.75 },
      stone = { frequency = 3, richness = 1, size = 0.75 },
      trees = { frequency = 1, richness = 1, size = 1 },
      ['uranium-ore'] = { frequency = 0.5, richness = 1, size = 0.5 },
    },
    cliff_settings = { name = 'cliff', cliff_elevation_0 = 20, cliff_elevation_interval = 40, richness = 1 / 3 },
    height = height * 32,
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
  return x > (-left_water_boundary * 32 - 320) and not ((y < -height * 16) or (y > height * 16))
end

water = b.change_tile(bounds, true, 'water')
water = b.fish(water, 0.075)

green_water = b.change_tile(bounds, true, 'deepwater-green')

map = b.choose(function(x) return x < -left_water_boundary end, water, bounds)
map = b.choose(function(x) return math_floor(x) == -(_global.kraken_distance + left_water_boundary + 1) end, green_water, map)

-- == EVENTS ==================================================================

local function signstr(amount)
  if amount > 0 then
    return '+' .. tostring(amount)
  end
  return tostring(amount)
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

local function init_wall(x, w)
  local surface = RS.get_surface()
  local area = { { x, -height * 16 }, { x + w, height * 16 } }
  for _, entity in pairs(surface.find_entities_filtered { area = area, collision_mask = 'player-layer' }) do
    entity.destroy()
  end

  for y = -height * 16, height * 16 do
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

local function refresh_silo(on_launch)
  local surface = RS.get_surface()
  local old_silo = _global.rocket_silo
  local new_position = { _global.x, _global.y }
  local new_silo

  for _, e in pairs(surface.find_entities_filtered{ position = new_position, radius = 20 }) do
    if e.type == 'character' then
      local find = surface.find_non_colliding_position
      local pos = surface.find_non_colliding_position('character', { _global.x + 12, _global.y }, 5, 0.5),
      if pos then
        e.teleport(pos)
      else
        e.destroy()
      end
    else
      e.destroy()
    end
  end

  if old_silo then
    entity = old_silo.clone { position = new_position, force = old_silo.force, create_build_effect_smoke = true }
    old_silo.destroy()
  else
    entity = surface.create_entity { name = 'rocket-silo', position = new_position, force = 'player', move_stuck_players = true }
  end
  entity.destructible = false
  entity.minable = false
  set_silo_tiles(entity)

  if true then return end

  local surface = RS.get_surface()
  local entity = _global.rocket_silo

  local output_inventory = {}
  local rocket_inventory = {}
  local module_inventory = {}
  local rocket_parts = 0

  if entity and entity.valid do
    local i
    local input_inventory = {} -- We do not keep the input inventory when it jumps, otherwise it looks like we managed to get something in it after it moved
    local has_inventory = false -- Because #input_inventory is broken in lua ?!

    -- What module the entity has
    i = entity.get_module_inventory()
    if i ~= nil then
      for n, c in pairs(i.get_contents()) do
        if module_inventory[n] == nil then
          module_inventory[n] = 0
        end
        module_inventory[n] = module_inventory[n] + c
      end
    end

    -- What is in the input
    i = entity.get_inventory(defines.inventory.assembling_machine_input)
    if i ~= nil then
      for n, c in pairs(i.get_contents()) do
        if input_inventory[n] == nil then
          input_inventory[n] = 0
        end
        input_inventory[n] = input_inventory[n] + c
        has_inventory = true
      end
    end

    -- What is in the output slot
    i = entity.get_output_inventory()
    if i ~= nil then
      for n, c in pairs(i.get_contents()) do
        if output_inventory[n] == nil then
          output_inventory[n] = 0
        end
        output_inventory[n] = output_inventory[n] + c
      end
    end

    -- What is in the rocket (if there is one)
    i = entity.get_inventory(defines.inventory.rocket_silo_rocket)
    if i ~= nil then
      for n, c in pairs(i.get_contents()) do
        if rocket_inventory[n] == nil then
          rocket_inventory[n] = 0
        end
        rocket_inventory[n] = rocket_inventory[n] + c
        if c > 0 then
          rocket_parts = 100
        end -- There is something in a rocket, so it's ready to go
      end
    end

    -- When called from on_rocket_launch, the status is still launching_rocket, so we can't use this
    -- We must just ignore the status
    if not on_launch and (entity.status == defines.entity_status.preparing_rocket_for_launch or entity.status ==
        defines.entity_status.waiting_to_launch_rocket or entity.status == defines.entity_status.launching_rocket) then
      rocket_parts = 100
    end -- so that we put the new silo in Preparing for launch

    if entity.rocket_parts ~= nil and entity.rocket_parts > 0 then
      rocket_parts = rocket_parts + entity.rocket_parts
    end

    local p = entity.position

    entity.destroy()

    -- We put a chest with the inputs so they are not lost
    if has_inventory then
      local chest = surface.create_entity { name = 'steel-chest', position = p, force = 'player', move_stuck_players = true }
      for n, c in pairs(input_inventory) do
        chest.insert({ name = n, count = c })
      end
    end
  end

  if rocket_parts > 100 then
    rocket_parts = 100
  end -- Make sure we don't insert more than the max

  -- Clean the destination area so we can actually create the silo there, hope you didn't have anything there
  for _, entity in pairs(surface.find_entities_filtered {
    area = { { _global.x + 10, _global.y + 11 }, { _global.x + 18, _global.y + 19 } },
  }) do
    if entity.type ~= 'character' then
      entity.destroy()
    end -- Don't go destroying players
  end

  -- Remove enemy bases
  for _, entity in pairs(game.surfaces[1].find_entities_filtered {
    area = { { _global.x + 7, _global.y + 7 }, { _global.x + 21, _global.y + 21 } },
    force = 'enemy',
  }) do
    if entity.type ~= 'character' then
      entity.destroy()
    end -- Don't go destroying (enemy) players
  end

  -- Create the silo first to create the chunk (otherwise tiles won't be settable)
  local silo = surface.create_entity {
    name = 'rocket-silo',
    position = { _global.x + 14, _global.y + 14 },
    force = 'player',
    move_stuck_players = true,
  }
  silo.destructible = false
  silo.minable = false

  -- Restore silo content and status (we re-create from scratch to avoid cheese and inconsistent states)
  for n, c in pairs(module_inventory) do
    silo.get_module_inventory().insert({ name = n, count = c })
  end

  for n, c in pairs(output_inventory) do
    silo.get_output_inventory().insert({ name = n, count = c })
  end

  for n, c in pairs(rocket_inventory) do
    silo.get_inventory(defines.inventory.rocket_silo_rocket).insert({ name = n, count = c })
  end

  silo.rocket_parts = rocket_parts

  set_silo_tiles(silo)
end

local move_silo = function(amount, contributor, on_launch)
  local surface = RS.get_surface()

  local entity = _global.rocket_silo
  local silo_empty = true

  -- Make sure that all the silos can be destroyed (we shouldn't have more than one, but just in case)
  if not on_launch then -- When we do not launch (external request)
      local i1 = entity.get_inventory(defines.inventory.rocket_silo_rocket)
      local i2 = entity.get_inventory(defines.inventory.assembling_machine_input)
      if (i1 ~= nil and i1.get_item_count() > 0) or -- Are there inputs (we don't move once someone puts something in it)
      (i2 ~= nil and i2.get_item_count() > 0) or -- Is there something in the rocket
      entity.status == defines.entity_status.preparing_rocket_for_launch or -- Is it in launch stage
      entity.status == defines.entity_status.waiting_to_launch_rocket or entity.status ==
          defines.entity_status.launching_rocket or (entity.rocket_parts or 0) > 0 then -- There are rocket parts made
        silo_empty = false
      end
  end

  if _global.x < _global.max_distance then
    local new_amount = math.floor((amount / _global.move_cost_ratio) + 0.5)
    if new_amount == 0 then -- We make sure that we don't move by zero (if the donation is too small and the ratio too large)
      if amount > 0 then
        new_amount = 1
      end
      if amount < 0 then
        new_amount = -1
      end
    end
    amount = new_amount
  end -- We do not use the ratio once we are in add-rocket territory
  _global.move_buffer = _global.move_buffer + amount


  -- If it's enough to trigger a move and the silo is empty (or it was a launch in case we move "forcefully")
  local move_silo = ((math_abs(_global.move_buffer) >= _global.move_step or _global.x + _global.move_buffer >= _global.max_distance) and silo_empty)
  if move_silo then
    local new_x
    if _global.x + _global.move_buffer >= _global.max_distance then -- We reach the "end"
      _global.move_buffer = _global.x + _global.move_buffer - _global.max_distance
      new_x = _global.max_distance
    else
      if _global.x + _global.move_buffer < -left_water_boundary + 30 then -- We are getting too close to water
        _global.move_buffer = _global.x + _global.move_buffer - (-left_water_boundary + 30)
        new_x = -left_water_boundary + 30
      else -- We moved "enough"
        new_x = _global.x + _global.move_buffer
        _global.move_buffer = 0
      end
    end

    if new_x ~= _global.x then -- If there is actually a move (if we call refresh-silo without moving X, Y will randomly jump anyway)
      if new_x > _global.x then
        game.print({'frontier.silo_forward', (new_x - _global.x)})
      else
        game.print({'frontier.silo_backward', (new_x - _global.x)})
      end

      _global.x = new_x
      _global.y = math_random(-silo_radius, silo_radius)
      refresh_silo(on_launch)

      if new_x >= _global.max_distance then
        game.print({'frontier.warning_max_distance', _global.rocket_step})
        --[[
        if _global.move_buffer > 0 then
          insert(_global.plus_contributors, 'everyone(' .. _global.move_buffer .. ')')
          contributor = 'everyone'
          amount = _global.move_buffer
        end
        ]]
      end
    else
      move_silo = false
    end
  end

  -- We reached the end, we now use the buffer to add rockets
  if _global.x >= _global.max_distance then
    local add_rocket = math.floor(_global.move_buffer / _global.rocket_step)
    if add_rocket > 0 then
      _global.rockets_to_win = _global.rockets_to_win + add_rocket
      _global.move_buffer = _global.move_buffer % _global.rocket_step

      -- Build contributor lines
      local str_launch = tostring(add_rocket) .. ' extra launches'
      if add_rocket == 1 then
        str_launch = 'one extra launch'
      end

      local str = 'Adding ' .. str_launch .. ' thanks to the meanness of ' .. concat(_global.plus_contributors, ', ')
      if #_global.minus_contributors > 0 then
        str = str .. ' and despite the kindness of ' .. concat(_global.minus_contributors, ', ')
      end
      game.print(str)

      _global.plus_contributors = {}
      _global.minus_contributors = {}

      str = (_global.rockets_to_win - _global.rockets_launched) .. ' launches to go!'
      if _global.move_buffer > 0 then
        str = str .. ' And already ' .. _global.move_buffer .. ' tiles out of ' .. _global.rocket_step ..
                  ' towards an extra launch.'
      end
      game.print(str)
    else
      if amount > 0 then
        game.print('Thanks to ' .. contributor .. ', we are now ' .. _global.move_buffer .. ' (' .. amount .. ') tiles out of ' .. _global.rocket_step .. ' towards the next launch.')
      end
    end
  else -- We haven't reach the maximum distance, check if we should ack the contribution
    if amount ~= 0 and not move_silo then
      local str1 = 'Thanks to ' .. contributor .. ', the silo will move by ' .. _global.move_buffer .. ' (' .. signstr(amount) .. ') tiles'
      if math.abs(_global.move_buffer) < _global.move_step then -- Below move threshold
        game.print(str1 .. ' when we reach a total of ' .. _global.move_step .. ' tiles.')
      else
        game.print(str1 .. ' after the next launch.')
      end
    end
  end

  -- Keep track of the move forward for the purpose of multiplying cost
  if amount ~= 0 and _global.move_cost_step > 0 then
    if _global.x < _global.max_distance then
      _global.move_buffer_ratio = _global.move_buffer_ratio + amount
      while _global.move_buffer_ratio >= _global.move_cost_step do
        _global.move_cost_ratio = _global.move_cost_ratio * _global.move_cost_ratio_mult
        _global.move_buffer_ratio = _global.move_buffer_ratio - _global.move_cost_step
        local next_increment = _global.move_cost_step - _global.move_buffer_ratio
        if next_increment < 0 then
          next_increment = 0
        end
        game.print('You must now request ' .. _global.move_cost_ratio .. ' tiles to actually move by one tile. In ' ..
                       next_increment .. ' tiles, we\'ll multiply that cost by ' .. _global.move_cost_ratio_mult ..
                       ' again.')
      end
    else
      _global.move_cost_ratio = _global.move_cost_ratio_mult ^ math_floor(_global.max_distance / _global.move_cost_step)
    end
  end
end

Event.on_init(function()
  local ms = game.map_settings
  ms.enemy_expansion.friendly_base_influence_radius = 0
  ms.enemy_expansion.min_expansion_cooldown = 60 * 30 -- 30 seconds
  ms.enemy_expansion.max_expansion_cooldown = 60 * 60 * 4 -- 4 minutes
  ms.enemy_expansion.max_expansion_distance = 5
  ms.enemy_evolution.destroy_factor = 0.0001

  local surface = RS.get_surface()
  local far_left, far_right = _global.kraken_distance + left_water_boundary + 1, death_world_boundary + wall_width
  surface.request_to_generate_chunks({ x = 0, y = 0 }, math.ceil(math_max(far_left, far_right, height * 32) / 32))
  surface.force_generate_chunk_requests()

  local max_height = (height * 32) - 16
  _global.x = silo_starting_x + math.random(100)
  _global.y = math.random(-max_height, max_height)
  refresh_silo()
  init_wall(death_world_boundary, wall_width)

  game.forces.player.chart(surface, { { -far_left - 32, -height * 16 }, { far_right + 32, height * 16 } })
end)

local on_chunk_generated = function(event)
  if event.surface.name ~= RS.get_surface().name then
    return
  end

  -- kill off biters inside the wall
  if event.area.right_bottom.x < (death_world_boundary + 96) then
    for _, entity in pairs(event.surface.find_entities_filtered { area = event.area, force = 'enemy' }) do
      entity.destroy()
    end
  end

  -- scale freshly generated ore by a scale factor
  for _, resource in pairs(event.surface.find_entities_filtered { area = event.area, type = 'resource' }) do
    if resource.position.x > death_world_boundary then
      local chunks = math.clamp(math_abs((resource.position.x - death_world_boundary) / ore_chunk_scale), 1, 100)
      chunks = math_random(chunks, chunks + 4)
      if resource.prototype.resource_category == 'basic-fluid' then
        resource.amount = 3000 * 3 * chunks
      elseif resource.prototype.resource_category == 'basic-solid' then
        resource.amount = ore_base_quantity * chunks
      end
    end
  end
end
Event.add(defines.events.on_chunk_generated, on_chunk_generated)

local on_research_finished = function(event)
  local recipes = event.research.force.recipes
  if recipes['rocket-silo'] then
    recipes['rocket-silo'].enabled = false
  end
end
Event.add(defines.events.on_research_finished, on_research_finished)

local on_player_died = function(event)
  local player = game.get_player(event.player_index)
  local cause = event.cause
  if not cause or not cause.valid then
    return
  end
  if cause.force == player.force then
    return
  end

  if _global.rockets_per_death <= 0 then
    return
  end

  local player_name = 'a player'
  if player then
    player_name = player.name
  end

  _global.rockets_to_win = _global.rockets_to_win + _global.rockets_per_death
  if _global.rockets_to_win < 1 then
    _global.rockets_to_win = 1
  end

  game.print({'frontier.add_rocket', _global.rockets_per_death, player_name, (_global.rockets_to_win - _global.rockets_launched)})
end
Event.add(defines.events.on_player_died, on_player_died)

local on_player_changed_position = function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  if player.position.x < (-left_water_boundary - _global.kraken_distance) then
    local player_name = 'a player'
    if player.character ~= nil then
      player_name = player.name
    end
    game.print({'frontier.kraken_eat', player_name}, { sound_path = 'utility/game_lost' })
    if player.character ~= nil then
      player.character.die()
    end
  end
end
Event.add(defines.events.on_player_changed_position, on_player_changed_position)

local on_rocket_launched = function(event)
  local rocket = event.rocket
  if not (rocket and rocket.valid) then
    return
  end

  local force = rocket.force

  _global.scenario_finished = _global.scenario_finished or false
  if _global.scenario_finished then
    return
  end

  _global.rockets_launched = _global.rockets_launched + 1

  if _global.rockets_launched >= _global.rockets_to_win then
    _global.scenario_finished = true

    game.set_game_state { game_finished = true, player_won = true, can_continue = true, victorious_force = force }
    return
  end

  game.print({'frontier.rocket_launched', _global.rockets_launched, (_global.rockets_to_win - _global.rockets_launched) })
  move_silo(0, '', true)
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
