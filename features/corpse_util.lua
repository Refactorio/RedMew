local Event = require 'utils.event'
local Global = require 'utils.global'
local Task = require 'utils.task'
local Token = require 'utils.token'
local table = require 'utils.table'
local Utils = require 'utils.core'

local Public = {}

local player_corpses = {}

Global.register(player_corpses, function(tbl)
    player_corpses = tbl
end)

local function get_index(player_index, tick)
    return player_index * 0x100000000 + tick
end

local function get_data(player_index, tick)
    local index = get_index(player_index, tick)
    return player_corpses[index]
end

local function remove_tag(player_index, tick)
    local index = get_index(player_index, tick)

    local data = player_corpses[index]
    if not data then
        return
    end

    local tag = data.tag
    player_corpses[index] = nil

    if not tag or not tag.valid then
        return
    end

    tag.destroy()
end

local function remove_corpse_tag(corpse)
    if corpse and corpse.valid then
        remove_tag(corpse.character_corpse_player_index, corpse.character_corpse_tick_of_death)
    end
end

local function corpse_expired(event)
    remove_corpse_tag(event.corpse)
end

local corpse_util_mined_entity = Token.register(function(data)
    if not data.entity.valid then
        remove_tag(data.player_index, data.tick)
    end
end)

local function mined_entity(event)
    local entity = event.entity

    if not entity or not entity.valid or entity.name ~= 'character-corpse' then
        return
    end

    local corpse_owner_index = entity.character_corpse_player_index
    local death_tick = entity.character_corpse_tick_of_death

    -- The corpse may be mined but not removed (if player doesn't have inventory space)
    -- so we wait one tick to see if the corpse is gone.
    Task.set_timeout_in_ticks(1, corpse_util_mined_entity, {
        entity = entity,
        player_index = corpse_owner_index,
        tick = death_tick
    })

    local player_index = event.player_index
    if player_index == corpse_owner_index then
        return
    end

    local data = get_data(corpse_owner_index, death_tick)
    if not data or not data.alert_looting then
        return
    end

    local player = game.get_player(player_index)
    local corpse_owner = game.get_player(corpse_owner_index)

    if player and corpse_owner then
        local position = entity.position
        local message = table.concat {
            player.name,
            ' has looted ',
            corpse_owner.name,
            "'s corpse.",
            ' [gps=',
            string.format('%.1f', position.x),
            ',',
            string.format('%.1f', position.y),
            ',',
            entity.surface.name,
            ']'
        }
        Utils.action_warning('[Corpse]', message)
    end
end

local function on_gui_opened(event)
    local entity = event.entity
    if not entity or not entity.valid or entity.name ~= 'character-corpse' then
        return
    end

    local player_index = event.player_index
    local corpse_owner_index = entity.character_corpse_player_index

    if player_index == corpse_owner_index then
        return
    end

    local death_tick = entity.character_corpse_tick_of_death
    local data = get_data(corpse_owner_index, death_tick)
    if not data or not data.alert_looting then
        return
    end

    local player = game.get_player(player_index)
    local corpse_owner = game.get_player(corpse_owner_index)

    if player and corpse_owner then
        local position = entity.position
        local message = table.concat {
            player.name,
            ' is looting ',
            corpse_owner.name,
            "'s corpse.",
            ' [gps=',
            string.format('%.1f', position.x),
            ',',
            string.format('%.1f', position.y),
            ',',
            entity.surface.name,
            ']'
        }
        Utils.action_warning('[Corpse]', message)
    end
end

local function on_gui_closed(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local entity = event.entity
    if not entity or not entity.valid or entity.name ~= 'character-corpse' then
        return
    end

    local inv_corpse = entity.get_inventory(defines.inventory.character_corpse)
    if not inv_corpse or not inv_corpse.valid then
        return
    end

    if inv_corpse.is_empty() then
        remove_corpse_tag(entity)
        entity.destroy()
    end
end

Event.add(defines.events.on_character_corpse_expired, corpse_expired)
Event.add(defines.events.on_pre_player_mined_item, mined_entity)
Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_gui_closed, on_gui_closed)

function Public.clear()
    table.clear_table(player_corpses)
end

function Public.add_tag(tag, player_index, death_tick, alert_looting)
    local index = get_index(player_index, death_tick)
    player_corpses[index] = { tag = tag, alert_looting = alert_looting }
end

return Public
