local Event = require 'utils.event'

local biter_utils_conf = global.config.biter_corpse_util

local random = math.random

-- currently no on_corpse_spawned event, using on_entity_died instead

local function biter_died(event)
    local entity = event.entity
    if not entity.valid then
        return
    end

    -- ignore non-enemy entities
    if entity.force.name ~= 'enemy' then
        return
    end

    -- Only trigger on units
    if entity.type ~= 'unit' then
        return
    end

    -- Only a chance of cleanup
    if biter_utils_conf.cleanup_chance_percent < random(100) then
        return
    end

    local surface = entity.surface

    local filter = {
        position = entity.position,
        radius = biter_utils_conf.radius,
        type = 'corpse',
        force = 'neutral'
    }

    -- More than the desired number of corpses?
    if surface.count_entities_filtered(filter) <= biter_utils_conf.corpse_threshold then
        return
    end

    -- Get the actual entities
    local corpse_list = surface.find_entities_filtered (filter)

    local corpse_list_len = #corpse_list
    local num_to_remove = corpse_list_len - biter_utils_conf.corpse_threshold
    local random_offset = random(corpse_list_len)

    -- Starting at a random number, remove enough entities to be under the threshold
    for i = random_offset, num_to_remove + random_offset do
        --modulus + 1 to ensure we are not past the end of the table
        corpse_list[(i % corpse_list_len) + 1].destroy()
    end
end

Event.add(defines.events.on_entity_died, biter_died)
