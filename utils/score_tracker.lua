local Global = require 'utils.global'
local Event = require 'utils.event'
local error = error
local format = string.format
local raise_event = script.raise_event

local score_metadata = {}

local memory_players = {}
local memory_global = {}

Global.register({
    memory_players = memory_players,
    memory_global = memory_global
}, function (tbl)
    memory_players = tbl.memory_players
    memory_global = tbl.memory_global
end)

local Public = {}

Public.events = {
    -- Event {
    --     score_name = score_name
    --     player_index = player_index
    --  }
    on_player_score_changed = Event.generate_event_name('on_player_score_changed'),
    -- Event {
    --     score_name = score_name
    --  }
    on_global_score_changed = Event.generate_event_name('on_global_score_changed'),
}

local on_player_score_changed = Public.events.on_player_score_changed
local on_global_score_changed = Public.events.on_global_score_changed

---Register a specific score.
---
--- This function must be called in the control stage, i.e. not inside an event.
---
---@param name string
---@param locale_string table
---@param icon string
function Public.register(name, locale_string, icon)
    if _LIFECYCLE ~= _STAGE.control then
        error(format('You can only register score types in the control stage, i.e. not inside events. Tried setting "%s".', name), 2)
    end

    if score_metadata[name] then
        error(format('Trying to register score type for "%s" while it has already been registered.', name), 2)
    end

    local score = {
        name = name,
        icon = icon,
        locale_string = locale_string
    }

    score_metadata[name] = score

    return score
end

---Sets a setting to a specific value for a player.
---
---@param player_index number
---@param score_name string
---@param value number to subtract or add
function Public.change_for_player(player_index, score_name, value)
    if value == 0 then
        return
    end

    local setting = score_metadata[score_name]
    if not setting then
        if _DEBUG then
            error(format('Trying to change score "%s" while it has was never registered.', score_name), 2)
        end
        return
    end

    local player_score = memory_players[player_index]
    if not player_score then
        player_score = {}
        memory_players[player_index] = player_score
    end

    player_score[score_name] = (player_score[score_name] or 0) + value

    raise_event(on_player_score_changed, {
        score_name = score_name,
        player_index = player_index
    })
end

---Sets a setting to a specific value for a player.
---
---@param score_name string
---@param value number to subtract or add
function Public.change_for_global(score_name, value)
    if value == 0 then
        return
    end

    local setting = score_metadata[score_name]
    if not setting then
        if _DEBUG then
            error(format('Trying to change score "%s" while it has was never registered.', score_name), 2)
        end
        return
    end

    memory_global[score_name] = (memory_global[score_name] or 0) + value

    raise_event(on_global_score_changed, {
        score_name = score_name
    })
end

---Returns the value for this player of a specific score.
---
---@param player_index number
---@param score_name string
function Public.get_for_player(player_index, score_name)
    local setting = score_metadata[score_name]
    if not setting then
        return nil
    end

    local player_scores = memory_players[player_index]
    if not player_scores then
        return 0
    end

    return player_scores[score_name] or 0
end

---Returns the value of the game score.
---
---@param score_name string
function Public.get_for_global(score_name)
    local setting = score_metadata[score_name]
    if not setting then
        return 0
    end

    return memory_global[score_name] or 0
end

---Returns all metadata merged with the values for this player for the given score names.
---
---@param player_index number
---@param score_names table
function Public.get_player_scores_with_metadata(player_index, score_names)
    local scores = {}
    local size = 0
    for i = 1, #score_names do
        local score_name = score_names[i]
        local metadata = score_metadata[score_name]
        if metadata then
            local player_scores = memory_players[player_index]
            if player_scores then
                size = size + 1
                scores[size] = {
                    name = metadata.name,
                    locale_string = metadata.locale_string,
                    icon = metadata.icon,
                    value = player_scores[score_name] or 0
                }
            end
        end
    end

    return scores
end

---Returns all metadata merged with the values of the global scores for the given score names.
---
---@param score_names table
function Public.get_global_scores_with_metadata(score_names)
    local scores = {}
    local size = 0
    for i = 1, #score_names do
        local score_name = score_names[i]
        local metadata = score_metadata[score_name]
        if metadata then
            size = size + 1
            scores[size] = {
                name = metadata.name,
                locale_string = metadata.locale_string,
                icon = metadata.icon,
                value = memory_global[score_name] or 0
            }
        end
    end

    return scores
end

---Returns the full score metadata, note that this is a reference, do not modify
---this data unless you know what you're doing!
function Public.get_score_metadata()
    return score_metadata
end

return Public
