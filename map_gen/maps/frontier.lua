local b = require 'map_gen.shared.builders'
local degrees = math.degrees
local Event = require 'utils.event'
local math = require 'utils.math'
local MGSP = require 'resources.map_gen_settings'
local RS = require 'map_gen.shared.redmew_surface'
local ScenarioInfo = require 'features.gui.info'
local Command = require 'utils.command'

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

local ScenarioInfo = require 'features.gui.info'
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

local silo_center = 1700 -- center point the silo will be to the right of spawn
local silo_radius = 450 -- radius around center point the silo will be

local height = 36 -- in chunks
local left_boundary = 8 -- in chunks
local left_water_boundary = left_boundary * 32 -- after this distance just generate water to a barrier
local death_world_boundary = 11 * 32 -- point where the ores start getting richer and biters begin
local wall_width = 5

local ore_base_quantity = 61 -- base ore quantity, everything is scaled up from this
local ore_chunk_scale = 32 -- sets how fast the ore will increase from spawn, lower = faster

-- == MAP GEN =================================================================

local b = require 'map_gen.shared.builders'
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

map = b.choose(function(x, y, world) return x < -left_water_boundary end, water, bounds)
map = b.choose(function(x, y, world) return math_floor(x) == -(global.kraken_distance + left_water_boundary + 1) end, green_water, map)

-- == EVENTS ==================================================================

-- passed the x distance from spawn and returns a number scaled up depending on how high it is
local ore_multiplier = function(distance)
  local a = math_max(1, math_abs(distance / ore_chunk_scale))
  a = math_min(a, 100)
  local multiplier = math_random(a, 4 + a)
  return multiplier
end

local seed_global_xy = function()
  if global.x == nil or global.y == nil then
    -- math_random is fine for the jitter around x, but for y, we use the game tick... more random
    global.x = silo_center + (game.tick + 12787132) % silo_radius - silo_radius / 2 -- math_random(silo_center, (silo_center+silo_radius))
    global.y = game.tick % silo_radius - silo_radius / 2 --  math_random(-silo_radius, silo_radius)
  end
end

local signstr = function(amount)
  if amount > 0 then
    return '+' .. tostring(amount)
  end
  return tostring(amount)
end

local set_silo_tiles = function(surface)
  -- put tiles around silo
  local tiles = {}
  local i = 1
  for dx = -6, 6 do
    for dy = -6, 6 do
      tiles[i] = { name = 'concrete', position = { global.x + dx + 14, global.y + dy + 14 } }
      i = i + 1
    end
  end
  for df = -6, 6 do
    tiles[i] = { name = 'hazard-concrete-left', position = { global.x + df + 14, global.y - 7 + 14 } }
    tiles[i + 1] = { name = 'hazard-concrete-left', position = { global.x + df + 14, global.y + 7 + 14 } }
    tiles[i + 2] = { name = 'hazard-concrete-left', position = { global.x - 7 + 14, global.y + df + 14 } }
    tiles[i + 3] = { name = 'hazard-concrete-left', position = { global.x + 7 + 14, global.y + df + 14 } }
    i = i + 4
  end
  surface.set_tiles(tiles, true)
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

-- Delete all silos, recreate 1 new one at the coordinate (preserve inventory)
local refresh_silo = function(on_launch, old_silos)
  seed_global_xy()

  -- Remove all silos blindly, we count the output inventory so we don't lose science
  local surface = RS.get_surface()

  -- If we were not given a list of old silos, we work on all of them
  if old_silos == nil then
    old_silos = surface.find_entities_filtered { name = 'rocket-silo' }
  end

  local output_inventory = {}
  local rocket_inventory = {}
  local module_inventory = {}
  local rocket_parts = 0

  for _, entity in pairs(old_silos) do
    local i = nil
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
      chest = surface.create_entity { name = 'steel-chest', position = p, force = 'player', move_stuck_players = true }
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
    area = { { global.x + 10, global.y + 11 }, { global.x + 18, global.y + 19 } },
  }) do
    if entity.type ~= 'character' then
      entity.destroy()
    end -- Don't go destroying players
  end

  -- Remove enemy bases
  for _, entity in pairs(game.surfaces[1].find_entities_filtered {
    area = { { global.x + 7, global.y + 7 }, { global.x + 21, global.y + 21 } },
    force = 'enemy',
  }) do
    if entity.type ~= 'character' then
      entity.destroy()
    end -- Don't go destroying (enemy) players
  end

  -- Create the silo first to create the chunk (otherwise tiles won't be settable)
  local silo = surface.create_entity {
    name = 'rocket-silo',
    position = { global.x + 14, global.y + 14 },
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

  set_silo_tiles(surface)
end

-- Delete all kraken limit times, and recreate the boundary tiles at the new position
local refresh_kraken = function(old_kraken)
  seed_global_xy()

  local surface = RS.get_surface()

  -- If we were not given the tile array of the previous kraken, we grab all the water tiles
  local tiles = {}
  if old_kraken == nil then
    old_tiles = surface.find_tiles_filtered { name = 'deepwater-green' }
    local i = 1
    for _, t in pairs(old_tiles) do
      tiles[i] = { name = 'water', position = t.position }
      i = i + 1
    end
  else
    -- else we fix the old tiles
    local i = 1
    for dx = -1, 0 do
      for dy = -silo_radius - 150, silo_radius + 150 do
        tiles[i] = { name = 'water', position = { -old_kraken - left_water_boundary + dx, dy } }
        i = i + 1
      end
    end
  end

  surface.set_tiles(tiles, true)

  -- put tiles for the new kraken limit
  local tiles = {}
  local i = 1
  for dx = -1, 0 do
    for dy = -silo_radius - 150, silo_radius + 150 do
      tiles[i] = { name = 'deepwater-green', position = { -global.kraken_distance - left_water_boundary + dx, dy } }
      i = i + 1
    end
  end
  surface.set_tiles(tiles, true)
end

local move_silo = function(amount, contributor, on_launch)
  seed_global_xy() -- We need to make sure that X/Y are seesed (in case someone moves the silo before moving)
  local surface = RS.get_surface()

  -- We limit ourselves to the last good position of the silo, to avoid 130ms worth of work
  local old_silos = surface.find_entities_filtered {
    area = { { global.x + 7, global.y + 7 }, { global.x + 21, global.y + 21 } },
    name = 'rocket-silo',
  }

  -- Make sure that all the silos can be destroyed (we shouldn't have more than one, but just in case)
  local silo_empty = true
  if not on_launch then -- When we do not launch (external request)
    for _, entity in pairs(old_silos) do
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
  end

  if global.x < global.max_distance then
    local new_amount = math.floor((amount / global.move_cost_ratio) + 0.5)
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
  global.move_buffer = global.move_buffer + amount

  -- Remember the caller
  if amount ~= 0 and contributor ~= '' and contributor ~= nil then
    if amount > 0 then
      insert(global.plus_contributors, contributor .. '(+' .. amount .. ')')
    else
      insert(global.minus_contributors, contributor .. '(' .. amount .. ')')
    end
  end

  -- If it's enough to trigger a move and the silo is empty (or it was a launch in case we move "forcefully")
  local move_silo = ((math_abs(global.move_buffer) >= global.move_step or global.x + global.move_buffer >=
                        global.max_distance) and silo_empty)
  if move_silo then
    local new_x = global.x
    if global.x + global.move_buffer >= global.max_distance then -- We reach the "end"
      global.move_buffer = global.x + global.move_buffer - global.max_distance
      new_x = global.max_distance
    else
      if global.x + global.move_buffer < -left_water_boundary + 30 then -- We are getting too close to water
        global.move_buffer = global.x + global.move_buffer - (-left_water_boundary + 30)
        new_x = -left_water_boundary + 30
      else -- We moved "enough"
        new_x = global.x + global.move_buffer
        global.move_buffer = 0
      end
    end

    if new_x ~= global.x then -- If there is actually a move (if we call refresh_silo without moving X, Y will randomly jump anyway)
      local str = ''
      if new_x > global.x then
        str = 'Moved the silo forward by ' .. (new_x - global.x) .. ' tiles thanks to the meanness of ' ..
                  concat(global.plus_contributors, ', ')
        if #global.minus_contributors > 0 then
          str = str .. ' and despite the kindness of ' .. concat(global.minus_contributors, ', ')
        end
      else
        str = 'Moved the silo backward by ' .. (new_x - global.x) .. ' tiles thanks to the kindness of ' ..
                  concat(global.minus_contributors, ', ')
        if #global.plus_contributors > 0 then
          str = str .. ' and despite the meanness of ' .. concat(global.plus_contributors, ', ')
        end
      end
      game.print(str)

      global.plus_contributors = {}
      global.minus_contributors = {}
      global.x = new_x
      global.y = math_random(-silo_radius, silo_radius)
      refresh_silo(on_launch, old_silos) -- Effect the silo move

      if new_x >= global.max_distance then
        game.print('We have reached the MAXIMUM DISTANCE! Every ' .. global.rocket_step ..
                       ' tiles will now add one more launch to win.')
        if global.move_buffer > 0 then
          insert(global.plus_contributors, 'everyone(' .. global.move_buffer .. ')')
          contributor = 'everyone'
          amount = global.move_buffer
        end
      end
    else
      move_silo = false -- We didn't actually move the silo
    end
  end

  -- We reached the end, we now use the buffer to add rockets
  if global.x >= global.max_distance then
    local add_rocket = math.floor(global.move_buffer / global.rocket_step)
    if add_rocket > 0 then
      global.rockets_to_win = global.rockets_to_win + add_rocket
      global.move_buffer = global.move_buffer % global.rocket_step

      -- Build contributor lines
      local str_launch = tostring(add_rocket) .. ' extra launches'
      if add_rocket == 1 then
        str_launch = 'one extra launch'
      end

      local str = 'Adding ' .. str_launch .. ' thanks to the meanness of ' .. concat(global.plus_contributors, ', ')
      if #global.minus_contributors > 0 then
        str = str .. ' and despite the kindness of ' .. concat(global.minus_contributors, ', ')
      end
      game.print(str)

      global.plus_contributors = {}
      global.minus_contributors = {}

      str = (global.rockets_to_win - global.rockets_launched) .. ' launches to go!'
      if global.move_buffer > 0 then
        str = str .. ' And already ' .. global.move_buffer .. ' tiles out of ' .. global.rocket_step ..
                  ' towards an extra launch.'
      end
      game.print(str)
    else
      if amount > 0 then
        game.print('Thanks to ' .. contributor .. ', we are now ' .. global.move_buffer .. ' (' .. amount ..
                       ') tiles out of ' .. global.rocket_step .. ' towards the next launch.')
      end
    end
  else -- We haven't reach the maximum distance, check if we should ack the contribution
    if amount ~= 0 and not move_silo then
      local str1 = 'Thanks to ' .. contributor .. ', the silo will move by ' .. global.move_buffer .. ' (' ..
                       signstr(amount) .. ') tiles'
      if math.abs(global.move_buffer) < global.move_step then -- Below move threshold
        game.print(str1 .. ' when we reach a total of ' .. global.move_step .. ' tiles.')
      else
        game.print(str1 .. ' after the next launch.')
      end
    end
  end

  -- Keep track of the move forward for the purpose of multiplying cost
  if amount ~= 0 and global.move_cost_step > 0 then
    if global.x < global.max_distance then
      global.move_buffer_ratio = global.move_buffer_ratio + amount
      while global.move_buffer_ratio >= global.move_cost_step do
        global.move_cost_ratio = global.move_cost_ratio * global.move_cost_ratio_mult
        global.move_buffer_ratio = global.move_buffer_ratio - global.move_cost_step
        local next_increment = global.move_cost_step - global.move_buffer_ratio
        if next_increment < 0 then
          next_increment = 0
        end
        game.print('You must now request ' .. global.move_cost_ratio .. ' tiles to actually move by one tile. In ' ..
                       next_increment .. ' tiles, we\'ll multiply that cost by ' .. global.move_cost_ratio_mult ..
                       ' again.')
      end
    else
      global.move_cost_ratio = global.move_cost_ratio_mult ^ math_floor(global.max_distance / global.move_cost_step)
      -- game.print("You must now request "..tostring(global.move_cost_ratio).." tiles to actually move by one tile. In "..tostring(next_increment).." tiles, we'll multiply that cost by "..tostring(global.move_cost_ratio_mult).." again.")
    end
  end
end

local move_kraken = function(amount, contributor)
  seed_global_xy() -- We need to make sure that X/Y are seeded (in case someone moves the silo before moving)
  local surface = RS.get_surface()

  amount = math_max(1, math_floor((amount / global.kraken_move_cost_ratio) + 0.5))
  global.kraken_move_buffer = global.kraken_move_buffer + amount

  -- Remember the caller
  if amount ~= 0 and contributor ~= '' and contributor ~= nil then
    insert(global.kraken_contributors, contributor .. '(+' .. amount .. ')')
  end

  -- If it's enough to trigger a move and the silo is empty (or it was a launch in case we move "forcefully")
  local move_kraken = math_abs(global.kraken_move_buffer) >= global.kraken_move_step
  if move_kraken then
    local new_x = global.kraken_distance
    local old_x = global.kraken_distance
    -- We moved "enough"
    new_x = global.kraken_distance + global.kraken_move_buffer
    global.kraken_move_buffer = 0

    local str = ''
    str = 'The kraken was pushed back by ' .. (new_x - global.kraken_distance) .. ' tiles thanks to the kindness of ' ..
              concat(global.kraken_contributors, ', ')
    game.print(str)

    global.kraken_contributors = {}
    global.kraken_distance = new_x

    refresh_kraken(old_x) -- Effect the silo move
  else
    if amount ~= 0 then
      local str1 =
          'Thanks to ' .. contributor .. ', the kraken will retreat by ' .. global.kraken_move_buffer .. ' (' ..
              signstr(amount) .. ') tiles'
      game.print(str1 .. ' when we reach a total of ' .. global.kraken_move_step .. ' tiles.')
    end
  end

  -- Keep track of the move forward for the purpose of multiplying cost
  if amount ~= 0 and global.kraken_move_cost_step > 0 then
    global.kraken_move_buffer_ratio = global.kraken_move_buffer_ratio + amount
    while global.kraken_move_buffer_ratio >= global.kraken_move_cost_step do
      global.kraken_move_cost_ratio = global.kraken_move_cost_ratio * global.kraken_move_cost_ratio_mult
      global.kraken_move_buffer_ratio = global.kraken_move_buffer_ratio - global.kraken_move_cost_step
      local next_increment = global.kraken_move_cost_step - global.kraken_move_buffer_ratio
      if next_increment < 0 then
        next_increment = 0
      end
      game.print(
          'You must now request ' .. global.kraken_move_cost_ratio .. ' tiles to actually move by one tile. In ' ..
              next_increment .. ' tiles, we\'ll multiply that cost by ' .. global.move_cost_ratio_mult .. ' again.')
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

  -- Disable default victory and replace our own rocket launch screen (don't think it matters since we are replacing the silo-script entirely)
  global.no_victory = true

  -- Kraken handling
  global.kraken_distance = 25 -- Where the kraken lives past the water boundary

  global.kraken_move_cost_ratio = 10 -- If the multipler is 2, you need to buy 2x the tiles to actually move 1x
  global.kraken_move_step = 5 -- By default, we only move 500 tiles at a time

  global.kraken_move_cost_ratio_mult = 4 -- Be default, we increase the "cost" of a tile by 2
  global.kraken_move_cost_step = 10 -- Every 50k tiles move

  global.kraken_move_buffer_ratio = 0 -- How many tiles we have moved since the last ratio multiplier
  global.kraken_move_buffer = 0 -- How many tiles we haven't currently reflected (between +move_step and -move_step)
  global.kraken_contributors = {} -- List of contributors so far (so that we can print when we actually move the silo)

  -- Rockets/silo location management
  global.rockets_to_win = 1
  global.rockets_launched = 0
  global.scenario_finished = false

  global.move_cost_ratio = 1 -- If the multipler is 2, you need to buy 2x the tiles to actually move 1x
  global.move_step = 500 -- By default, we only move 500 tiles at a time

  global.rocket_step = 500 -- How many "tiles" past the max distance adds a launch

  global.rockets_per_death = 1 -- How many extra launch needed for each death

  global.max_distance = 100000 -- By default, 100k tiles max to the right

  global.move_cost_ratio_mult = 2 -- Be default, we increase the "cost" of a tile by 2
  global.move_cost_step = 50000 -- Every 50k tiles move

  global.move_buffer_ratio = 0 -- How many tiles we have moved since the last ratio multiplier
  global.move_buffer = 0 -- How many tiles we haven't currently reflected (between +move_step and -move_step)
  global.plus_contributors = {} -- List of contributors so far (so that we can print when we actually move the silo)
  global.minus_contributors = {} -- List of contributors so far (so that we can print when we actually move the silo)

  local surface = RS.get_surface()
  local far_left, far_right = global.kraken_distance + left_water_boundary + 1, death_world_boundary + wall_width
  surface.request_to_generate_chunks({ x = 0, y = 0 }, math.ceil(math_max(far_left, far_right, height * 32) / 32))
  surface.force_generate_chunk_requests()

  seed_global_xy()
  init_wall(death_world_boundary, wall_width)  
  refresh_silo(false, nil)

  game.forces.player.chart(surface, { { -far_left - 32, -height * 16 }, { far_right + 32, height * 16 } })
end)

-- When a new chunk is created, we make sure it's the right type based on the various region of the map (water, clear space, wall and the rest)
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

  -- based off Frontier scenario, it scales freshly generated ore by a scale factor
  for _, resource in pairs(event.surface.find_entities_filtered { area = event.area, type = 'resource' }) do
    local a
    if resource.position.x > death_world_boundary then
      a = ore_multiplier(resource.position.x - death_world_boundary)
      -- else a = ore_multiplier(ore_base_quantity) end  
      if resource.prototype.resource_category == 'basic-fluid' then
        resource.amount = 3000 * 3 * a
      elseif resource.prototype.resource_category == 'basic-solid' then
        resource.amount = ore_base_quantity * a
      end
    end
  end
end
Event.add(defines.events.on_chunk_generated, on_chunk_generated)

-- Make sure rocket-silo research is never enabled
local on_research_finished = function(event)
  local recipes = event.research.force.recipes
  if recipes['rocket-silo'] then
    recipes['rocket-silo'].enabled = false
  end
end
Event.add(defines.events.on_research_finished, on_research_finished)

-- Make sure we catch players going off-bound and ... KRAKEN
-- Also use the first time a player moves as our "randomness" for initial silo position
local on_player_died = function(event)
  local player = game.get_player(event.player_index)
  local cause = event.cause
  if not cause or not cause.valid then
    return
  end
  if cause.force == player.force then
    return
  end

  if global.rockets_per_death <= 0 then
    return
  end

  local player_name = 'a player'
  if player then
    player_name = player.name
  end

  -- Build player death lines
  local add_rocket = global.rockets_per_death

  global.rockets_to_win = global.rockets_to_win + add_rocket
  if global.rockets_to_win < 1 then
    global.rockets_to_win = 1
  end

  -- game.print("Rocket launches to win: " .. tostring(global.rockets_to_win).." with "..tostring(global.rockets_launched).." launches so far.")

  local str_launch = add_rocket .. ' extra launches'
  if add_rocket == 1 then
    str_launch = 'one extra launch'
  end

  game.print('Adding ' .. str_launch .. ' thanks to the death of ' .. player_name)
  game.print((global.rockets_to_win - global.rockets_launched) .. ' launches to go!')
end
Event.add(defines.events.on_player_died, on_player_died)

-- Make sure we catch players going off-bound and ... KRAKEN
-- Also use the first time a player moves as our "randomness" for initial silo position
local on_player_changed_position = function(event)
  local player = game.players[event.player_index]
  if player.position.x < (-left_water_boundary - global.kraken_distance) then
    local player_name = 'A player'
    if player.character ~= nil then
      player_name = player.name
    end
    game.print(player_name .. ' was eaten by a Kraken!!!', { sound_path = 'utility/game_lost' })
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

  global.scenario_finished = global.scenario_finished or false
  if global.scenario_finished then
    return
  end

  global.rockets_launched = global.rockets_launched + 1

  if global.rockets_launched >= global.rockets_to_win then
    global.scenario_finished = true

    game.set_game_state { game_finished = true, player_won = true, can_continue = true, victorious_force = force }

    -- No more silo moves, we are done!
    return
  end

  game.print('Rocket launches so far: ' .. global.rockets_launched .. ', ' .. (global.rockets_to_win - global.rockets_launched) .. ' to go!.', { sound_path = 'utility/scenario_message'})

  -- A rocket was launched, we should check if there are deferred moves to do (and we do them no matter the inventory)
  move_silo(0, '', true)
end
Event.add(defines.events.on_rocket_launched, on_rocket_launched)

-- == COMMANDS ================================================================

Command.add('ping-silo',
  { 
    description = 'Pings the silo\'s position on map',
    allowed_by_server = true
  },
  function(args, player)
    local surface = RS.get_surface()
    local msg = '[color=blue][mapkeeper][/color] Here you\'ll find a silo:'
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
