-- dependencies
local Event = require 'utils.event'
local Global = require 'utils.global'
local Queue = require 'utils.queue'

local queue_push = Queue.push
local queue_pop = Queue.pop
local queue_size = Queue.size

-- config table for the max queue size
-- Change at runtime with /sc global.config.biter_corpse_remover.max_queue_size = 100
local biter_corpse_remover = global.config.biter_corpse_remover

local corpse_queue = Queue.new()

Global.register(corpse_queue, function(tbl)
    corpse_queue = tbl
end)

local function entity_died(event)
    local prototype_type = event.prototype.type
    if prototype_type ~= 'unit' and prototype_type ~= 'turret' then
        return
    end

    local corpses = event.corpses
    for i = 1, #corpses do
        local corpse = corpses[i]
        if corpse.valid then
            queue_push(corpse_queue, corpse)
        end
    end

    local to_remove = queue_size(corpse_queue) - biter_corpse_remover.max_queue_size
    for _ = 1, to_remove do
        local corpse = queue_pop(corpse_queue)
        if corpse.valid then
            corpse.destroy()
        end
    end
end

Event.add(defines.events.on_post_entity_died, entity_died)
