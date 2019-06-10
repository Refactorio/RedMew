-- dependencies
local Event = require 'utils.event'
local Global = require 'utils.global'
local table = require 'utils.table'

local biter_utils_conf = global.config.biter_corpse_util

local corpse_chunks = {}

-- Factorio removes corpses that hit 15 minutes anyway
local max_corpse_age = 15 * 60 * 60

Global.register(
    {
        corpse_chunks = corpse_chunks
    },
    function(tbl)
        corpse_chunks = tbl.corpse_chunks
    end
)

-- cleans up the stored list of corpses and chunks
local function remove_outdated_corpses()
    local now = game.tick
    -- loop each stored chunk
    for cci, corpse_chunk in pairs(corpse_chunks) do
        local count = corpse_chunk.count

        -- loop stored corpses
        local corpses = corpse_chunk.corpses
        local i = 1
        local corpse = corpses[i]
        while corpse ~= nil do
            if corpse.tick < now then
                table.fast_remove(corpses, i)
                count = count - 1
            else
                i = i + 1
            end
            corpse = corpses[i]
        end

        corpse_chunk.count = count

        -- remove tracked chunk if no corpses
        if count < 1 then
            corpse_chunks[cci] = nil
        end
    end
end

--Remove extra corpses that are in this area
local function corpse_cleanup(hash_position)

    local corpse_chunk = corpse_chunks[hash_position]
    local count = corpse_chunk.count
    local corpses = corpse_chunk.corpses
    local num_to_remove = count - biter_utils_conf.corpse_threshold

    -- remove enough entities to be under the threshold
    for i = 1, num_to_remove do
        local corpse = corpses[i]
        if corpse.entity.valid then
            corpse.entity.destroy()
        end

        table.fast_remove(corpses, i)
        count = count -1
    end

    corpse_chunk.count = count

end

local function biter_died(event)
    local prot = event.prototype

    -- Only trigger on dead units
    if prot.type ~= 'unit' then
        return
    end

    local entity = event.corpses[1]
    -- Ensure there is actually a corpse
    if entity == nil then
        return
    end

    -- Chance to clean up old corpses and chunks
    if game.tick % 60 == 0 then
        remove_outdated_corpses()
    end

    --Calculate the hash position
    local x = entity.position.x - (entity.position.x % biter_utils_conf.chunk_size)
    local y = entity.position.y - (entity.position.y % biter_utils_conf.chunk_size)
    local hash_position = x .. "_" .. y

    -- check global table has this position, add if not
    if corpse_chunks[hash_position] == nil then
        corpse_chunks[hash_position] = {
            count = 0,
            corpses = {}
        }
    end

    -- get and increment this chunk, add this entity
    local corpse_chunk = corpse_chunks[hash_position];
    local count = corpse_chunk.count + 1
    corpse_chunk.count = count
    corpse_chunk.corpses[count] = {
        entity = entity,
        tick = game.tick + max_corpse_age
    }

    -- Call cleanup if above threshold
    if corpse_chunk.count > biter_utils_conf.corpse_threshold then
        corpse_cleanup(hash_position)
    end
end

Event.add(defines.events.on_post_entity_died, biter_died)
