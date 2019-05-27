local Global = require 'utils.global'
local Event = require 'utils.event'
local Token = require 'utils.token'
local Schedule = require 'utils.task'
local Server = require 'features.server'
local Settings = require 'utils.redmew_settings'
local set_timeout_in_ticks = Schedule.set_timeout_in_ticks
local pairs = pairs
local raise_event = script.raise_event

local Public = {}

Public.events = {
    --- Triggered when the settings are synced back to the server
    -- Event {
    --     player = player
    -- }
    on_synced_to_server = Event.generate_event_name('on_synced_to_server'),

    --- Triggered when the settings are synced back from the server
    --- keeps track of whether or not it's cancelled
    -- Event {
    --     player = player
    --     cancelled = cancelled
    -- }
    on_synced_from_server = Event.generate_event_name('on_synced_from_server'),
}


local memory = {
    -- when already scheduled, no new schedules have to be added
    sync_scheduled = false,

    -- when locked it won't schedule anything to prevent recursion syncing back to server
    locked = false,
}

local do_sync_settings_to_server -- token

Global.register(memory, function (tbl) memory = tbl end)

local function schedule_sync_to_server(player_index)
    set_timeout_in_ticks(1, do_sync_settings_to_server, {
        player_index = player_index
    })
    memory.sync_scheduled = true
end

do_sync_settings_to_server = Token.register(function(params)
    local player_index = params.player_index;
    local player = game.get_player(player_index)
    if not player or not player.valid then
        return
    end

    -- do update
    Server.set_data('player_settings', player.name, Settings.all(player_index))

    -- mark it as updated
    memory.sync_scheduled = false

    raise_event(Public.events.on_synced_to_server, {
        player = player
    })
end)

local function setting_set(event)
    if memory.locked or memory.sync_scheduled then
        return
    end

    local setting = event.setting
    if not setting.value_changed then
        return
    end

    schedule_sync_to_server(setting.player_index)
end

local on_player_settings_get = Token.register(function (data)
    local player = game.get_player(data.key)
    if not player or not player.valid then
        return
    end

    if data.cancelled then
        raise_event(Public.events.on_synced_from_server, {
            player = player,
            cancelled = true
        })
        return
    end

    local settings = data.value

    if settings ~= nil then
        -- temporarily lock the sync so it won't sync from server to client to server
        -- as this would cause recursion
        memory.locked = true
        local player_index = player.index
        for key, value in pairs(settings) do
            Settings.set(player_index, key, value)
        end
        memory.locked = false
    end

    raise_event(Public.events.on_synced_from_server, {
        player = player,
        cancelled = false
    })
end)

local function player_joined(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    Server.try_get_data_timeout('player_settings', player.name, on_player_settings_get, 30)
end

Event.add(Settings.events.on_setting_set, setting_set);
Event.add(defines.events.on_player_joined_game, player_joined)

return Public
