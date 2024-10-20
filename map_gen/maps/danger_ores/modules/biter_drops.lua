local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'

local entity_drop_amount = {
    ['biter-spawner'] = {
        name = 'raw-fish',
        count = 5
    },
    ['spitter-spawner'] = {
        name = 'raw-fish',
        count = 5
    }
}

local spill_items = Token.register(function(data)
    local surface = data.surface
    if not surface or not surface.valid then
        return
    end

    surface.spill_item_stack{ position = data.position, stack = data.stack, enable_looted = true }
end)

Event.add(defines.events.on_entity_died, function(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local entity_name = entity.name
    local stack = entity_drop_amount[entity_name]
    if not stack then
        return
    end

    Task.set_timeout_in_ticks(1, spill_items, {
        stack = stack,
        surface = entity.surface,
        position = entity.position
    })
end)
