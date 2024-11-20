local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'

local weights = {
  ['ei_energy-crystal'] = 10,
  ['ei_gold-chunk'] = 10,
  ['ei_alien-resin'] = 150,
  ['ei_alien-seed'] = 4,
  ['ei_alien-beacon'] = 1,
  ['ei_alien-stabilizer'] = 10,
}
local weighted_table = {}

for item, weight in pairs(weights) do
  for _ = 1, weight do
    weighted_table[#weighted_table + 1] = item
  end
end

local function draw_random()
  return weighted_table[math.random(#weighted_table)]
end

local spill_items = Token.register(function(data)
  local surface = data.surface
  if not surface or not surface.valid then
    return
  end

  surface.spill_item_stack { position = data.position, stack = data.stack, enable_looted = true }
end)

Event.add(defines.events.on_entity_died, function(event)
  local entity = event.entity
  if not entity or not entity.valid then
    return
  end

  local entity_name = entity.name
  if not (entity_name == 'biter-spawner' or entity_name == 'spitter-spawner') then
    return
  end

  local item = draw_random()
  if not item then
    return
  end

  local stack = { name = item, count = 1 }

  Task.set_timeout_in_ticks(1, spill_items, { stack = stack, surface = entity.surface, position = entity.position })
end)
