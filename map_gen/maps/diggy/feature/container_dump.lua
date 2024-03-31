--[[
  When a chest with items is (intentionally) destroyed by players/enemies,
  the chest 'spills' its content to the floor generating an ore patch
  proportional to the content destroyed (for DangerOres)
]]
local Event = require 'utils.event'
local Global = require 'utils.global'
local math = require 'utils.math'
local table = require 'utils.table'

local floor = math.floor
local max = math.max

local chest = defines.inventory.chest

local died_entities = {}
local default_resources = {
  {'iron-ore',    35},
  {'copper-ore',  30},
  {'coal',        20},
  {'stone',       10},
  {'uranium-ore',  5},
}

Global.register(died_entities, function(tbl)
  died_entities = tbl
end)

local ContainerDump = {}

function ContainerDump.register(config)
  local resources = config.resources or default_resources

  Event.add(defines.events.on_entity_died, function(event)
    local entity = event.entity

    if not entity.valid then
      return
    end

    local type = entity.type
    if type ~= 'container' and type ~= 'logistic-container' then
      return
    end

    local inventory = entity.get_inventory(chest)
    if not inventory or not inventory.valid then
      return
    end

    local count = 0
    local deadlock_stack_size = (settings.startup['deadlock-stack-size'] or {}).value or 1
    local contents = inventory.get_contents()
    for name, c in pairs(contents) do
      local real_count
      if name:sub(1, #'deadlock-stack') == 'deadlock-stack' then
        real_count = c * deadlock_stack_size
      else
        real_count = c
      end

      count = count + real_count
    end

    if count == 0 then
      return
    end

    local area = entity.bounding_box
    local left_top, right_bottom = area.left_top, area.right_bottom
    local x1, y1 = floor(left_top.x), floor(left_top.y)
    local x2, y2 = floor(right_bottom.x), floor(right_bottom.y)

    local size_x = x2 - x1 + 1
    local size_y = y2 - y1 + 1
    local amount = floor(count / (size_x * size_y))
    amount = max(amount, 1)

    local create_entity = entity.surface.create_entity
    local resource_to_drop = table.get_random_weighted(resources)

    for x = x1, x2 do
      for y = y1, y2 do
        create_entity({ name = resource_to_drop, position = { x, y }, amount = amount })
      end
    end

    died_entities[entity.unit_number] = true
  end)

  Event.add(defines.events.on_post_entity_died, function(event)
    local unit_number = event.unit_number
    if not unit_number then
      return
    end

    if not died_entities[unit_number] then
      return
    end

    died_entities[unit_number] = nil

    local ghost = event.ghost
    if not ghost or not ghost.valid then
      return
    end

    ghost.destroy()
  end)
end

return ContainerDump
