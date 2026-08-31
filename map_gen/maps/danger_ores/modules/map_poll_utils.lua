local PollUtils = require 'utils.poll_utils'

local Public = {}

--- Returns an array of indices into maps for the maps to show in the poll.
-- A map is included if it has no tags, or if any of its tags matches any of the given
-- server tags (case-insensitive). server_tags being nil (no tags configured for the
-- server) means all maps are included.
-- May return an empty array when the server tags match no maps.
-- @param maps<table> array of maps, each entry with an optional tags array of strings.
-- @param server_tags<table?> array of tag strings, from the map_poll_tags data set.
function Public.get_map_indices(maps, server_tags)
    if server_tags == nil then
        local all_indices = {}
        for i = 1, #maps do
            all_indices[i] = i
        end
        return all_indices
    end

    local tag_set = {}
    if type(server_tags) == 'table' then
        for _, tag in pairs(server_tags) do
            if type(tag) == 'string' then
                tag_set[tag:lower()] = true
            end
        end
    end

    local indices = {}
    for index, map_data in ipairs(maps) do
        local map_tags = map_data.tags
        if map_tags == nil or next(map_tags) == nil then
            indices[#indices + 1] = index
        else
            for _, tag in ipairs(map_tags) do
                if tag_set[tag:lower()] then
                    indices[#indices + 1] = index
                    break
                end
            end
        end
    end

    return indices
end

--- Returns the map entry the poll answers resolved to, or nil if there is no winner.
-- map_indices is the array returned by get_map_indices for these poll answers and is
-- positionally aligned with them. map_indices being nil falls back to using the answer
-- position directly as index into maps (polls created by older scenario versions predate
-- map_indices).
-- @param maps<table> array of maps.
-- @param map_indices<table?> array of indices into maps, positionally aligned with answers.
-- @param answers<table> poll answers, each entry with a voted_count.
function Public.get_next_map(maps, map_indices, answers)
    local chosen_index = PollUtils.get_poll_winner(answers)
    if chosen_index == nil then
        return nil
    end

    if map_indices == nil then
        return maps[chosen_index]
    end

    return maps[map_indices[chosen_index]]
end

return Public
