-- This adds a button that stashes/sorts your inventory into nearby chests in some kind of intelligent way
-- made by mewmew
-- modified by gerkiz & RedRafe
-- source: https://github.com/ComfyFactory/ComfyFactorio/blob/develop/modules/autostash.lua
-- ======================================================= --

local Color = require 'resources.color_presets'
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'
local LP = require 'utils.logistic_point'

local floor = math.floor

local this = {
  floating_text_y_offsets = {},
  whitelist = {},
  insert_to_neutral_chests = false,
  insert_into_furnace = false,
  insert_into_wagon = false,
  bottom_button = false,
  small_radius = 2,
  limit_containers = 50,
  init_whitelist = false,
}

local Public = {}

Global.register(this, function(tbl) this = tbl end)

local bps_blacklist = { ['blueprint-book'] = true, ['blueprint'] = true }

local function container_has_requests(chest)
  local requests = 0
  if chest.type == 'logistic-container' then
    local lp = chest.get_logistic_point(defines.logistic_member_index.logistic_container)
    local filters = LP.get_filters(lp)
    requests = #filters
  end
  return requests > 0
end

local function create_floaty_text(surface, position, name, count)
  if this.floating_text_y_offsets[position.x .. '_' .. position.y] then
    this.floating_text_y_offsets[position.x .. '_' .. position.y] =
        this.floating_text_y_offsets[position.x .. '_' .. position.y] - 0.5
  else
    this.floating_text_y_offsets[position.x .. '_' .. position.y] = 0
  end
  Game.create_local_flying_text({
    surface = surface,
    position = { position.x, position.y + this.floating_text_y_offsets[position.x .. '_' .. position.y] },
    text = { '', '-', count, ' ', prototypes.item[name].localised_name },
    color = { r = 255, g = 255, b = 255 },
  })
end

local function prepare_floaty_text(list, surface, position, name, count)
  local str = surface.index .. ',' .. position.x .. ',' .. position.y
  if not list[str] then
    list[str] = {}
  end
  if not list[str][name] then
    list[str][name] = { surface = surface, position = position, count = 0 }
  end
  list[str][name].count = list[str][name].count + count
end

local function chest_is_valid(chest)
  for _, e in pairs(chest.surface.find_entities_filtered({
    type = { 'inserter', 'loader' },
    area = { { chest.position.x - 1, chest.position.y - 1 }, { chest.position.x + 1, chest.position.y + 1 } },
  })) do
    if e.name ~= 'long-handed-inserter' then
      if e.position.x == chest.position.x then
        if e.direction == 0 or e.direction == 4 then
          return false
        end
      end
      if e.position.y == chest.position.y then
        if e.direction == 2 or e.direction == 6 then
          return false
        end
      end
    end
  end

  local i1 = chest.surface.find_entity('long-handed-inserter', { chest.position.x - 2, chest.position.y })
  if i1 then
    if i1.direction == 2 or i1.direction == 6 then
      return false
    end
  end
  local i2 = chest.surface.find_entity('long-handed-inserter', { chest.position.x + 2, chest.position.y })
  if i2 then
    if i2.direction == 2 or i2.direction == 6 then
      return false
    end
  end

  local i3 = chest.surface.find_entity('long-handed-inserter', { chest.position.x, chest.position.y - 2 })
  if i3 then
    if i3.direction == 0 or i3.direction == 4 then
      return false
    end
  end
  local i4 = chest.surface.find_entity('long-handed-inserter', { chest.position.x, chest.position.y + 2 })
  if i4 then
    if i4.direction == 0 or i4.direction == 4 then
      return false
    end
  end

  return true
end

local function sort_entities_by_distance(position, entities)
  local t = {}
  local distance
  local index
  local size_of_entities = #entities
  if size_of_entities < 2 then
    return entities
  end

  for _, entity in pairs(entities) do
    distance = (entity.position.x - position.x) ^ 2 + (entity.position.y - position.y) ^ 2
    index = floor(distance) + 1
    if not t[index] then
      t[index] = {}
    end
    table.insert(t[index], entity)
  end

  local i = 0
  local containers = {}
  for _, range in pairs(t) do
    for _, entity in pairs(range) do
      i = i + 1
      if i >= (this.limit_containers or 50) then
        return containers
      end
      containers[i] = entity
    end
  end

  return containers
end

local function get_nearby_chests(player, a, furnace, wagon)
  local r = player.force.character_reach_distance_bonus + 10
  local r_square = r * r
  local chests, inventories = {}, {}
  local size_of_chests = 0
  local area = { { player.physical_position.x - r, player.physical_position.y - r }, { player.physical_position.x + r, player.physical_position.y + r } }

  area = a or area

  local container_type = { 'container', 'logistic-container', 'linked-container' }
  local inventory_type = defines.inventory.chest
  local containers = {}
  local i = 0

  if furnace then
    container_type = { 'furnace' }
    inventory_type = defines.inventory.furnace_source
  end
  if wagon then
    container_type = { 'cargo-wagon', 'logistic-container' }
    inventory_type = defines.inventory.cargo_wagon
  end

  local forces = player.force
  if this.insert_to_neutral_chests then
    forces = { player.force, 'neutral' }
  end

  for _, e in pairs(player.physical_surface.find_entities_filtered({ type = container_type, area = area, force = forces })) do
    if ((player.physical_position.x - e.position.x) ^ 2 + (player.physical_position.y - e.position.y) ^ 2) <= r_square then
      i = i + 1
      containers[i] = e
    end
  end

  containers = sort_entities_by_distance(player.physical_position, containers)
  for _, entity in pairs(containers) do
    size_of_chests = size_of_chests + 1
    chests[size_of_chests] = entity
    inventories[size_of_chests] = entity.get_inventory(inventory_type)
  end
  return { chest = chests, inventory = inventories }
end

local function insert_to_furnace(player_inventory, chests, name, count, floaty_text_list)
  local try = 0

  local to_insert = floor(count / #chests.chest)
  if to_insert <= 0 then
    if count > 0 then
      to_insert = count
    else
      return
    end
  end

  local variate = count % #chests.chest
  local chests_available = #chests.chest
  local tries = #chests.chest

  ::retry::

  -- Attempt to store into furnaces.
  for chestnr, chest in pairs(chests.chest) do
    local chest_inventory = chests.inventory[chestnr]
    local amount = to_insert
    if variate > 0 then
      amount = amount + 1
      variate = variate - 1
    end
    if amount <= 0 then
      return
    end

    if chest_inventory then
      if (chest.type == 'furnace' or chest.type == 'assembling-machine') then
        if name == 'stone' then
          local valid_to_insert = (amount % 2 == 0)
          if valid_to_insert then
            if chest_inventory.can_insert({ name = name, count = amount }) then
              local inserted_count = chest_inventory.insert({ name = name, count = amount })
              if inserted_count < 0 then
                return
              end
              player_inventory.remove({ name = name, count = inserted_count })
              prepare_floaty_text(floaty_text_list, chest.surface, chest.position, name, inserted_count)
              count = count - inserted_count
              if count <= 0 then
                return
              end
            end
          else
            try = try + 1
            if try <= tries then
              chests_available = chests_available - 1
              to_insert = floor(count / chests_available)
              variate = count % chests_available
              goto retry
            end
          end
        else
          if chest_inventory.can_insert({ name = name, count = amount }) then
            local inserted_count = chest_inventory.insert({ name = name, count = amount })
            if inserted_count < 0 then
              return
            end
            player_inventory.remove({ name = name, count = inserted_count })
            prepare_floaty_text(floaty_text_list, chest.surface, chest.position, name, inserted_count)
            count = count - inserted_count
            if count <= 0 then
              return
            end
          end
        end
      end
    end
  end

  to_insert = floor(count / #chests.chest)
  variate = count % #chests.chest

  for _, chest in pairs(chests.chest) do -- fuel
    if chest.type == 'furnace' or chest.type == 'assembling-machine' then
      local amount = to_insert
      if variate > 0 then
        amount = amount + 1
        variate = variate - 1
      end
      if amount <= 0 then
        return
      end
      local chest_inventory = chest.get_inventory(defines.inventory.chest)
      if chest_inventory and chest_inventory.can_insert({ name = name, count = amount }) then
        local inserted_count = chest_inventory.insert({ name = name, count = amount })
        if inserted_count < 0 then
          return
        end
        player_inventory.remove({ name = name, count = inserted_count })
        prepare_floaty_text(floaty_text_list, chest.surface, chest.position, name, inserted_count)
        count = count - inserted_count
        if count <= 0 then
          return
        end
      end
    end
  end
end

local function insert_into_wagon(stack, chests, name, floaty_text_list)
  -- Attempt to load filtered cargo wagon
  for chestnr, chest in pairs(chests.chest) do
    if chest.type == 'cargo-wagon' then
      local chest_inventory = chests.inventory[chestnr]
      if chest_inventory.can_insert(stack) then
        local inserted_count = chest_inventory.insert(stack)
        stack.count = stack.count - inserted_count
        prepare_floaty_text(floaty_text_list, chest.surface, chest.position, name, inserted_count)
        if stack.count <= 0 then
          return chestnr
        end
      end
    end
  end
end

local function insert_into_wagon_filtered(stack, chests, name, floaty_text_list)
  -- Attempt to load filtered cargo wagon
  for chestnr, chest in pairs(chests.chest) do
    if chest.type == 'cargo-wagon' then
      local chest_inventory = chests.inventory[chestnr]
      for index = 1, 40 do
        if chest_inventory.can_insert(stack) then
          if chest_inventory.get_filter(index) ~= nil then
            local n = chest_inventory.get_filter(index)
            if n == name then
              local inserted_count = chest_inventory.insert(stack)
              stack.count = stack.count - inserted_count
              prepare_floaty_text(floaty_text_list, chest.surface, chest.position, name, inserted_count)
              if stack.count <= 0 then
                return chestnr
              end
            end
          end
        end
      end
    end
  end

  -- Attempt to load filtered slots
  for chestnr, chest in pairs(chests.chest) do
    if chest.type == 'logistic-container' then
      local chest_inventory = chests.inventory[chestnr]
      local lp = chest.get_logistic_point(defines.logistic_member_index.logistic_container)
      local filters = LP.get_filters(lp)
      for _, filter in pairs(filters) do
        if filter.value.name == name then
          local inserted_count = chest_inventory.insert(stack)
          stack.count = stack.count - inserted_count
          prepare_floaty_text(floaty_text_list, chest.surface, chest.position, name, inserted_count)
          if stack.count <= 0 then
            return chestnr
          end
        end
      end
    end
  end
end

local function insert_item_into_chest(stack, chests, filtered_chests, name, floaty_text_list, previous_insert)
  local container = { ['container'] = true, ['logistic-container'] = true, ['linked-container'] = true }
  -- Attemp to store in chest that stored last same item
  if previous_insert.name == name and previous_insert.full ~= nil then
    local chest_inventory = chests.inventory[previous_insert.full]
    if chest_inventory and chest_inventory.can_insert(stack) then
      local inserted_count = chest_inventory.insert(stack)
      stack.count = stack.count - inserted_count
      prepare_floaty_text(floaty_text_list, chests.chest[previous_insert.full].surface,
                          chests.chest[previous_insert.full].position, name, inserted_count)
      if stack.count <= 0 then
        return previous_insert.full
      end
    end
  end

  --- Attempt to store in req slots that are filtered
  for chestnr, chest in pairs(chests.chest) do
    if chest.type == 'logistic-container' then
      local chest_inventory = chests.inventory[chestnr]
      local lp = chest.get_logistic_point(defines.logistic_member_index.logistic_container)
      local filters = LP.get_filters(lp)
      for _, filter in pairs(filters) do
        if filter.value.name == name then
          local inserted_count = chest_inventory.insert(stack)
          stack.count = stack.count - inserted_count
          prepare_floaty_text(floaty_text_list, chest.surface, chest.position, name, inserted_count)
          if stack.count <= 0 then
            return chestnr
          end
        end
      end
    end
  end

  -- Attempt to store in chests that already have the same item.
  for chestnr, chest in pairs(chests.chest) do
    if container[chest.type] then
      if container_has_requests(chest) then
        goto continue
      end
      local chest_inventory = chests.inventory[chestnr]
      if chest_inventory and chest_inventory.find_item_stack(stack.name) then
        if chest_inventory.can_insert(stack) then
          local inserted_count = chest_inventory.insert(stack)
          stack.count = stack.count - inserted_count
          prepare_floaty_text(floaty_text_list, chest.surface, chest.position, name, inserted_count)
          if stack.count <= 0 then
            return chestnr
          end
        end
      end
      ::continue::
    end
  end

  -- Attempt to store in empty chests.
  for chestnr, chest in pairs(filtered_chests.chest) do
    if container[chest.type] then
      if container_has_requests(chest) then
        goto continue
      end
      local chest_inventory = filtered_chests.inventory[chestnr]
      if not chest_inventory then
        break
      end
      local count = chest_inventory.get_item_count() == 0
      if count then
        local inserted_count = chest_inventory.insert(stack)
        stack.count = stack.count - inserted_count
        prepare_floaty_text(floaty_text_list, chest.surface, chest.position, name, inserted_count)
        if stack.count <= 0 then
          return chestnr
        end
      end
      ::continue::
    end
  end

  local item_prototypes = prototypes.item

  -- Attempt to store in chests with same item subgroup.
  local item_subgroup = prototypes.item[name].subgroup.name
  if item_subgroup then
    for chestnr, chest in pairs(filtered_chests.chest) do
      if container_has_requests(chest) then
        goto continue
      end
      if container[chest.type] then
        local chest_inventory = filtered_chests.inventory[chestnr]
        if not chest_inventory then
          break
        end
        local content = chest_inventory.get_contents()
        if chest_inventory.can_insert(stack) then
          for item_stack, _ in pairs(content) do
            local t = item_prototypes[item_stack.name]
            if t and t.subgroup.name == item_subgroup then
              local inserted_count = chest_inventory.insert(stack)
              stack.count = stack.count - inserted_count
              prepare_floaty_text(floaty_text_list, chest.surface, chest.position, name, inserted_count)
              if stack.count <= 0 then
                return chestnr
              end
            end
          end
        end
      end
      ::continue::
    end
  end

  -- Attempt to store in mixed chests.
  for chestnr, chest in pairs(filtered_chests.chest) do
    if container[chest.type] then
      if container_has_requests(chest) then
        goto continue
      end
      local chest_inventory = filtered_chests.inventory[chestnr]
      if not chest_inventory then
        break
      end
      if chest_inventory.can_insert(stack) then
        local inserted_count = chest_inventory.insert(stack)
        stack.count = stack.count - inserted_count
        prepare_floaty_text(floaty_text_list, chest.surface, chest.position, name, inserted_count)
        if stack.count <= 0 then
          return chestnr
        end
      end
      ::continue::
    end
  end
end

local function whitelist()
  local resources = prototypes.entity
  local items = prototypes.item
  this.whitelist = {}
  for k, _ in pairs(resources) do
    if resources[k] and resources[k].type == 'resource' and resources[k].mineable_properties then
      if resources[k].mineable_properties.products and resources[k].mineable_properties.products[1] then
        local r = resources[k].mineable_properties.products[1].name
        this.whitelist[r] = true
      elseif resources[k].mineable_properties.products and resources[k].mineable_properties.products[2] then
        local r = resources[k].mineable_properties.products[2].name
        this.whitelist[r] = true
      end
    end
  end

  for k, _ in pairs(items) do
    if items[k] and items[k].group.name == 'resource-refining' then
      local r = items[k].name
      this.whitelist[r] = true
    end
  end

  this.init_whitelist = true
end

function Public.auto_stash(player, event)
  if not this.init_whitelist then
    whitelist()
  end

  local button = event.button
  local ctrl = event.control
  local shift = event.shift
  if not (player and player.valid) then
    return
  end
  if not (player.character and player.character.valid) then
    player.print({'auto_stash.err_no_character'}, {color = Color.warning})
    return
  end
  local inventory = player.get_main_inventory()
  if inventory.is_empty() then
    player.print({'auto_stash.err_no_inventory'}, {color = Color.warning})
    return
  end

  local floaty_text_list = {}
  local chests = { chest = {}, inventory = {} }
  local r = this.small_radius
  local area = { { player.physical_position.x - r, player.physical_position.y - r }, { player.physical_position.x + r, player.physical_position.y + r } }
  if ctrl then
    if button == defines.mouse_button_type.right and this.insert_into_furnace then
      chests = get_nearby_chests(player, nil, true, false)
    end
  elseif shift then
    if button == defines.mouse_button_type.right and this.insert_into_wagon or button == defines.mouse_button_type.left and
        this.insert_into_wagon then
      chests = get_nearby_chests(player, area, false, true)
    end
  else
    chests = get_nearby_chests(player)
  end

  if not chests.chest or not chests.chest[1] then
    player.print({'auto_stash.err_no_container'}, {color = Color.warning})
    return
  end

  local filtered_chests = { chest = {}, inventory = {} }
  for index, e in pairs(chests.chest) do
    if chest_is_valid(e) then
      filtered_chests.chest[index] = e
      filtered_chests.inventory[index] = chests.inventory[index]
    end
  end

  this.floating_text_y_offsets = {}

  local hotbar_items = {}
  for i = 1, 100, 1 do
    local prototype = player.get_quick_bar_slot(i)
    if prototype then
      hotbar_items[prototype.name] = true
    end
  end

  local furnaceList = { ['coal'] = 0, ['iron-ore'] = 0, ['copper-ore'] = 0, ['stone'] = 0 }

  local full_insert = { full = nil, name = nil }
  for i = #inventory, 1, -1 do
    if not inventory[i].valid_for_read then
      goto continue
    end
    local name = inventory[i].name
    local is_resource = this.whitelist[name]
    if not hotbar_items[name] and not bps_blacklist[name] then
      if ctrl and this.insert_into_furnace then
        if button == defines.mouse_button_type.right then
          if is_resource then
            furnaceList[name] = (furnaceList[name] or 0) + inventory[i].count
          end
        end
      elseif shift and this.insert_into_wagon then -- insert into wagon
        if button == defines.mouse_button_type.right then -- insert all ores into wagon
          if is_resource then
            full_insert = { full = insert_into_wagon(inventory[i], chests, name, floaty_text_list), name = name }
          end
        end
        if button == defines.mouse_button_type.left then -- insert all filtered into wagon
          full_insert = { full = insert_into_wagon_filtered(inventory[i], chests, name, floaty_text_list), name = name }
        end
      elseif button == defines.mouse_button_type.right then -- only ores to nearby chests
        if is_resource then
          full_insert = {
            full = insert_item_into_chest(inventory[i], chests, filtered_chests, name, floaty_text_list, full_insert),
            name = name,
          }
        end
      elseif button == defines.mouse_button_type.left then -- all items to nearby chests
        full_insert = {
          full = insert_item_into_chest(inventory[i], chests, filtered_chests, name, floaty_text_list, full_insert),
          name = name,
        }
      end
      if not full_insert.success then
        hotbar_items[#hotbar_items + 1] = name
      end
    end
    ::continue::
  end
  for furnaceName, furnaceCount in pairs(furnaceList) do
    insert_to_furnace(inventory, chests, furnaceName, furnaceCount, floaty_text_list)
  end

  for _, texts in pairs(floaty_text_list) do
    for name, text in pairs(texts) do
      create_floaty_text(text.surface, text.position, name, text.count)
    end
  end

  local c = this.floating_text_y_offsets
  for k, _ in pairs(c) do
    this.floating_text_y_offsets[k] = nil
  end
end

function Public.insert_into_furnace(value)
  this.insert_into_furnace = value or false
end

function Public.insert_into_wagon(value)
  this.insert_into_wagon = value or false
end

function Public.limit_containers(value)
  this.limit_containers = value or 50
end

function Public.insert_to_neutral_chests(value)
  this.insert_to_neutral_chests = value or false
end

Event.on_configuration_changed(whitelist)
Event.on_init(whitelist)

return Public
