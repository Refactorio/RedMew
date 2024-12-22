local b = require 'map_gen.shared.builders'
local Event = require 'utils.event'
local Generate = require 'map_gen.shared.generate'
local Global = require 'utils.global'
local LP = require 'utils.logistic_point'
local PriceRaffle = require 'features.price_raffle'
local RS = require 'map_gen.shared.redmew_surface'
local table = require 'utils.table'
local Task = require 'utils.task'
local Token = require 'utils.token'

local rendering = rendering
local math_abs = math.abs

local RADIUS = 3
local ROCK_RESOURCES = {
  'iron-ore', 'iron-ore', 'iron-ore', 'iron-ore', 'iron-ore',
  'copper-ore', 'copper-ore', 'copper-ore',
  'coal'
}
local PRICE_MODIFIERS = {
  ['cliff'] = -128,
  ['deepwater-green'] = -5,
  ['deepwater'] = -5,
  ['simple-entity'] = 2,
  ['tree'] = -8,
  ['turret'] = -128,
  ['unit-spawner'] = -256,
  ['unit'] = -16,
  ['water-green'] = -5,
  ['water-mud'] = -6,
  ['water-shallow'] = -6,
  ['water'] = -5,
}

---@param config
---@field start_size              number, the width/height of the starting area. Will be ceiled to a multiple of a chunk
---@field chance_to_receive_token number, probability of coin rewards [0, 1]
---@field max_ore_price_modifier  number, max value for the ore_modifier after cmputing it with the distance_modifier
---@field price_distance_modifier number, how distance from {0,0} influence the request price
return function(config)
  Generate.enable_register_events = false

  local cell_size = 32
  local start_size = config.start_size
  local chance_to_receive_token = config.chance_to_receive_token or 0.20
  local max_ore_price_modifier  = config.max_ore_price_modifier  or 0.20
  local price_distance_modifier = config.price_distance_modifier or 0.006

  -- pad start_size to closest multiple of 32 for chunk alignment
  if start_size % cell_size ~= 0 then
    start_size = start_size + cell_size - start_size % cell_size
  end

  local surface
  local primitives = { index = nil }
  local chest_data = {}
  local grid = {}

  local bounds = b.rectangle(start_size, start_size)

  local function on_chunk_generated(event)
    if surface ~= event.surface then
      return
    end

    local left_top = event.area.left_top
    local x, y = left_top.x, left_top.y

    if bounds(x + 0.5, y + 0.5) then
      -- Starting area
      Generate.do_chunk(event)
    else
      -- Outside starting area
      local tiles = {}
      for x1 = x, x + 31 do
        for y1 = y, y + 31 do
          tiles[#tiles + 1] = { name = 'out-of-map', position = { x1, y1 } }
        end
      end
      surface.set_tiles(tiles, true)
    end
  end

  local function get_left_top(position)
    return {
      x = position.x - position.x % cell_size,
      y = position.y - position.y % cell_size,
    }
  end

  local function get_empty_neighbour_left_top(entity_position)
    local vectors = { { -RADIUS, 0 }, { RADIUS, 0 }, { 0, RADIUS }, { 0, -RADIUS } }
    --table.shuffle_table(vectors) --left, right, down, up

    for _, v in pairs(vectors) do
      local tile = surface.get_tile({ entity_position.x + v[1], entity_position.y + v[2] })

      if tile.name == 'out-of-map' then
        return get_left_top(tile.position)
      end
    end
    return
  end

  local function is_container_position_valid(position)
    if game.tick == 0 then
      return position.x == -start_size/2 or position.y == -start_size/2 or
        position.x == start_size/2-1 or position.y == start_size/2-1
    end

    return get_empty_neighbour_left_top(position) ~= nil
  end

  local function destroy_and_spill_content(entity)
    chest_data[entity.unit_number] = nil
    local inventory = entity.get_inventory(defines.inventory.chest)
    if not inventory.is_empty() then
      for _, item_stack in pairs(inventory.get_contents()) do
        entity.surface.spill_item_stack{ position = entity.position, stack = item_stack, enable_looted = true, allow_belts = false }
      end
    end
    inventory.clear()
    entity.destructible = true
    entity.die()
  end

  local function remove_one_render(chest, key)
    if chest.price[key].render[1].valid then
      chest.price[key].render[1].destroy()
    end
    if chest.price[key].render[2].valid then
      chest.price[key].render[2].destroy()
    end
  end

  local function remove_old_renders(chest)
    for key, _ in pairs(chest.price) do
      remove_one_render(chest, key)
    end
  end

  local function get_remaining_budget(chest)
    local budget = 0
    for _, item_stack in pairs(chest.price) do
      budget = budget + (item_stack.count * PriceRaffle.get_item_worth(item_stack.name))
    end
    return budget
  end

  local function get_cell_budget(left_top, src_entity)
    local value = 8 * (cell_size ^ 2)
    local area = { { left_top.x, left_top.y }, { left_top.x + cell_size - 1, left_top.y + cell_size - 1} }
    local entities = surface.find_entities(area)
    local tiles = surface.find_tiles_filtered({ area = area })

    for _, tile in pairs(tiles) do
      if PRICE_MODIFIERS[tile.name] then
        value = value + PRICE_MODIFIERS[tile.name]
      end
    end
    for _, entity in pairs(entities) do
      if PRICE_MODIFIERS[entity.type] then
        value = value + PRICE_MODIFIERS[entity.type]
      end
    end

    local distance = math.sqrt(left_top.x ^ 2 + left_top.y ^ 2)
    value = value * ((distance ^ 1.1) * price_distance_modifier)
    local ore_modifier = distance * (price_distance_modifier / 20)
    if ore_modifier > max_ore_price_modifier then
      ore_modifier = max_ore_price_modifier
    end

    for _, entity in pairs(entities) do
      if entity.type == 'resource' then
        if entity.prototype.resource_category == 'basic-fluid' then
          value = value + (entity.amount * ore_modifier * 0.01)
        else
          value = value + (entity.amount * ore_modifier)
        end
      end
    end

    value = math.floor(value)
    if value < 16 then
      value = 16
    end

    if _DEBUG and src_entity then
      local gps_chest = '('..src_entity.position.x..','..src_entity.position.y..')'
      local gps_area = '{('..area[1][1]..','..area[1][2]..'), ('..area[2][1]..','..area[2][2]..')}'
      log('Chest: '..gps_chest..' | Area: '..gps_area..' | Value:'..value)
    end
    return value
  end

  local function create_costs_render(entity, name, offset)
    local obj1 = rendering.draw_sprite {
      sprite = 'virtual-signal/signal-white',
      surface = entity.surface,
      target = entity,
      x_scale = 1.1,
      y_scale = 1.1,
      render_layer = '190',
      target_offset = { offset, -1.5 },
      only_in_alt_mode = true,
    }
    local obj2 = rendering.draw_sprite {
      sprite = 'item/' .. name,
      surface = entity.surface,
      target = entity,
      x_scale = 0.75,
      y_scale = 0.75,
      render_layer = '191',
      target_offset = { offset, -1.5 },
      only_in_alt_mode = true,
    }
    return { obj1, obj2 }
  end

  local function init_chest(entity, budget)
    local left_top = get_left_top(entity.position)
    if not left_top then
      return
    end

    local cell_value = budget or get_cell_budget(left_top, entity)
    local item_stacks = {}
    if _DEBUG then
      item_stacks = {
        ['iron-plate'] = 1,
      }
    else
      local roll_count = 3
      for _ = 1, roll_count do
        local value = math.floor(cell_value / roll_count)
        local max_item_value = math.max(4, cell_value / (roll_count * 6))
        for _, stack in pairs(PriceRaffle.roll(value, 3, nil, max_item_value)) do
          if not item_stacks[stack.name] then
            item_stacks[stack.name] = stack.count
          else
            item_stacks[stack.name] = item_stacks[stack.name] + stack.count
          end
        end
      end
    end

    local price = {}
    local offset = -table_size(item_stacks) / 2 + 0.5
    for k, v in pairs(item_stacks) do
      table.insert(price, { name = k, count = v, render = create_costs_render(entity, k, offset) })
      offset = offset + 1
    end

    chest_data[entity.unit_number] = { entity = entity, left_top = left_top, price = price }
  end

  local function process_chest(entity, budget)
    if entity.name ~= 'requester-chest' then
      return
    end
    if not chest_data[entity.unit_number] then
      init_chest(entity, budget)
    end

    local container = chest_data[entity.unit_number]
    if not container or not container.entity or not container.entity.valid then
      chest_data[entity.unit_number] = nil
      return
    end
    if game.tick > 0 and not is_container_position_valid(entity.position) then
      destroy_and_spill_content(entity)
      return
    end

    local inventory = container.entity.get_inventory(defines.inventory.chest)

    if not inventory.is_empty() then
      local contents = table.array_to_dict(inventory.get_contents(), 'name')
      if contents['coin'] then
        local count_removed = inventory.remove({ name = 'coin', count = 1 })
        if count_removed > 0 then
          remove_old_renders(container)
          init_chest(entity, get_remaining_budget(container))
          container = chest_data[entity.unit_number]
          game.print({ 'danger_ores.chest_reset', { 'danger_ores.gps', math.floor(entity.position.x), math.floor(entity.position.y), entity.surface.name } })
        end
      end
      if contents['infinity-chest'] then
        remove_old_renders(container)
        container.price = {}
      end
    end

    for key, item_stack in pairs(container.price) do
      local name = item_stack.name
      local count_removed = inventory.remove({ name = name, count = item_stack.count })
      container.price[key].count = container.price[key].count - count_removed
      if container.price[key].count <= 0 then
        remove_one_render(container, key)
        table.remove(container.price, key)
      end
    end

    if #container.price == 0 then
      -- compute new chunk to unlock
      local new_area
      local vectors = { { -RADIUS, 0 }, { RADIUS, 0 }, { 0, RADIUS }, { 0, -RADIUS } }
      table.shuffle_table(vectors) --left, right, down, up

      for _, v in pairs(vectors) do
        local tile = surface.get_tile({ entity.position.x + v[1], entity.position.y + v[2] })

        if tile.name == 'out-of-map' then
          local p = tile.position
          new_area = {
            left_top = {
              x = p.x - p.x % cell_size,
              y = p.y - p.y % cell_size,
            },
            right_bottom = {
              x = p.x - p.x % cell_size + cell_size - 1,
              y = p.y - p.y % cell_size + cell_size - 1,
            }
          }
        end
      end

      if math.random() < chance_to_receive_token then
        entity.surface.spill_item_stack{ position = entity.position, stack = { name = 'coin', count = 1 }, enable_looted = true, allow_belts = false }
      end
      destroy_and_spill_content(entity)

      return new_area
    end

    local lp = container.entity.get_logistic_point(defines.logistic_member_index.logistic_container)
    LP.clear_sections(lp)
    LP.add_filters(lp, container.price)

    return false
  end

  local function expand(left_top)
    grid[tostring(left_top.x .. '_' .. left_top.y)] = true

    if not surface then
      return
    end
    surface.request_to_generate_chunks(left_top, 0)
    surface.force_generate_chunk_requests()

    local max_side = cell_size - 1 - RADIUS
    local min_side = RADIUS
    local positions = {
      { x = left_top.x + math.random(min_side, max_side), y = left_top.y }, -- north
      { x = left_top.x, y = left_top.y + math.random(min_side, max_side) }, -- west
      { x = left_top.x + math.random(min_side, max_side), y = left_top.y + (cell_size - 1) }, -- south
      { x = left_top.x + (cell_size - 1), y = left_top.y + math.random(min_side, max_side) }, -- east
    }

    local chests = {}
    for _, position in pairs(positions) do
      if is_container_position_valid(position) then
        local e = surface.create_entity({ name = 'requester-chest', position = position, force = 'neutral' })
        e.destructible = false
        e.minable_flag = false
        table.insert(chests, e)
      end
    end

    return chests
  end

  local function on_chunk_unlocked(event)
    local left_top = event.area and event.area.left_top
    local right_bottom = event.area and event.area.right_bottom
    if not (left_top and right_bottom) then
      return
    end

    -- first, remove all adjacent chests & destroy those
    local old_chests = surface.find_entities_filtered{name = 'requester-chest', force = 'neutral', area = {
      left_top = {
        x = left_top.x-1,
        y = left_top.y-1,
      },
      right_bottom = {
        x = right_bottom.x+1,
        y = right_bottom.y+1,
      }
    }}
    for _, entity in pairs(old_chests) do
      destroy_and_spill_content(entity)
    end

    -- then generate new expansion chests
    local cell_budget = get_cell_budget(left_top)
    for _, new_chest in pairs(expand(left_top)) do
      process_chest(new_chest, cell_budget)
    end
  end

  local function on_tick()
    if primitives.index ~= nil and chest_data[primitives.index] == nil then
      primitives.index = nil
      return
    end

    local idx, chest = next(chest_data, primitives.index)
    if not (chest and chest.entity) then
      primitives.index = nil
      return
    end

    local position = chest.entity.position
    local new_area = process_chest(chest.entity)
    if new_area then
      Generate.do_chunk({
        area = new_area,
        surface = surface,
        position = { x = position.x, y = position.y}
      })
    end
    primitives.index = idx
  end

  local function infinite_resource(event)
    local entity = event.entity
    if not (entity and entity.valid) then
      return
    end

    if not (math_abs(entity.position.x) < 10 and math_abs(entity.position.y) < 10) then
      return
    end

    if entity.type == 'tree' then
      for _, corpse in pairs(surface.find_entities_filtered{
        position = entity.position,
        radius = 1,
        type = 'corpse'}
      ) do corpse.destroy() end
      local tree = surface.create_entity{name = 'tree-0'..math.random(9), position = entity.position}
      tree.destructible = false
    elseif entity.type == 'simple-entity' then
      local rock = surface.create_entity{name = 'huge-rock', position = entity.position, move_stuck_players = true}
      rock.graphics_variation = math.random(16)
      rock.destructible = false
      surface.spill_item_stack{ position = entity.position, stack = { name = ROCK_RESOURCES[math.random(#ROCK_RESOURCES)], count = math.random(80, 160) }, enable_looted = true, allow_belts = true }
      surface.spill_item_stack{ position = entity.position, stack = { name = 'stone', count = math.random(5, 15) }, enable_looted = true, allow_belts = true }
    end
  end

  local delay_cost = Token.register(function()
    local rs = RS.get_surface()
    local chests = rs.find_entities_filtered{name = 'requester-chest', force = 'neutral'}
    for _, chest in pairs(chests) do
      if chest_data[chest.unit_number] then
        remove_old_renders(chest_data[chest.unit_number])
      end
      init_chest(chest)
    end
  end)

  Global.register_init({ chest_data = chest_data, primitives = primitives, grid = grid },
  function(tbl)
    local rs = RS.get_surface()
    --[[
      Always need to request starting map size + 1 chunk border to per-unlock adjacent chunks
    ]]
    rs.request_to_generate_chunks({0, 0}, start_size / 32 + 1)
    rs.force_generate_chunk_requests()

    local e = rs.create_entity{name = 'tree-01', position = {0, -8}}
    e.destructible = false
    e = rs.create_entity{name = 'huge-rock', position = {0, 8}}
    e.destructible = false
    local oil = rs.create_entity{name = 'crude-oil', position = {-8, 0}}
    oil.amount, oil.initial_amount = 3e5, 3e7

    Task.set_timeout_in_ticks(30, delay_cost)
    tbl.surface = rs
  end, function(tbl)
    surface = tbl.surface
    chest_data = tbl.chest_data
    primitives = tbl.primitives
    grid = tbl.grid
  end)

  Event.on_nth_tick(1, on_tick)
  Event.add(defines.events.on_chunk_generated, on_chunk_generated)
  Event.add(Generate.events.on_chunk_generated, on_chunk_unlocked)
  Event.add(defines.events.on_pre_player_mined_item, infinite_resource)
  Event.add(defines.events.on_robot_pre_mined, infinite_resource)
end
