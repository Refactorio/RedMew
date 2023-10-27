local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'
local table = require 'utils.table'
local Random = require 'map_gen.shared.random'

local seed1 = 1410
local seed2 = 12900
local random = Random.new(seed1, seed2)

local weights = {
  ['ei_energy-crystal'] =  10,
  ['ei_gold-chunk']     =  10,
  ['ei_alien-resin']    = 150,
  ['ei_alien-seed']     =   4,
  ['ei_alien-beacon']   =   1,
}

local function draw_random(rng)
  local weighted_table = {}
  local total = 1
  for item, weight in pairs(weights) do
    for _=0, weight+1 do
      weighted_table[total] = item
      total = total + 1
    end
  end
  
  table.shuffle_table(weighted_table, rand)

  return weighted_table[random:next_int(1, total)]
end

local spill_items = Token.register(function(data)
    local surface = data.surface
    if not surface or not surface.valid then
        return
    end

    surface.spill_item_stack(data.position, data.stack, true)
end)

Event.add(defines.events.on_entity_died, function(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local entity_name = entity.name
    if not(entity_name == "biter-spawner" or entity_name == 'spitter-spawner') then
      return
    end

    local item = draw_random()
    if not item then
      return
    end

    local stack = {
      name = item,
      count = 1
    }

    Task.set_timeout_in_ticks(1, spill_items, {
        stack = stack,
        surface = entity.surface,
        position = entity.position
    })
end)
