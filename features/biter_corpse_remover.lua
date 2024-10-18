-- dependencies
local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Global = require 'utils.global'
local Queue = require 'utils.queue'

local queue_push = Queue.push
local queue_pop = Queue.pop
local queue_size = Queue.size

-- config table for the max queue size
-- Change at runtime with /sc storage.config.biter_corpse_remover.max_queue_size = 100
local biter_corpse_remover = storage.config.biter_corpse_remover

local corpse_queue = Queue.new()

Global.register(corpse_queue, function(tbl)
    corpse_queue = tbl
    biter_corpse_remover = storage.config.biter_corpse_remover
end)

local function process_corpses(corpses)
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

local combat_robot_corpse_map = {
    ['distractor'] = 'distractor-remnants',
    ['defender'] = 'defender-remnants',
    ['destroyer'] = 'destroyer-remnants',
}

local combat_robot_callback = Token.register(function(data)
    local position = data.position
    local surface = game.get_surface(data.surface_index)

    if not surface or not surface.valid then
        return
    end

    local corpse_name = combat_robot_corpse_map[data.prototype.name]
    if not corpse_name then
        return
    end

    local corpses = surface.find_entities_filtered{position = position, radius = 5, name = corpse_name}
    process_corpses(corpses)
end)

local function entity_died(event)
    local prototype_type = event.prototype.type
    if prototype_type == 'combat-robot' then
        Task.set_timeout_in_ticks(60, combat_robot_callback, event)
        return
    end

    if prototype_type == 'unit' or prototype_type == 'turret' then
        process_corpses(event.corpses)
    end
end

Event.add(defines.events.on_post_entity_died, entity_died)
