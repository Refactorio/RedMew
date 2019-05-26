local Global = require 'utils.global'
local Event = require 'utils.event'
local Token = require 'utils.token'
local Schedule = require 'utils.task'
local Server = require 'features.server'
local Settings = require 'utils.redmew_settings'
local set_timeout_in_ticks = Schedule.set_timeout_in_ticks

local Public = {}

local memory = {
    sync_scheduled = false,
}

local do_sync_settings_to_server -- token

Global.register(memory, function (tbl) memory = tbl end)

local function schedule_sync_to_server(player_index)
    if memory.sync_scheduled then
        return
    end

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
end)

local function setting_set(event)
    if memory.sync_scheduled then
        -- no need to determine if something should be set, already scheduled
        return
    end

    local setting = event.setting
    if setting.old_value == setting.new_value then
        -- setting value has not been changed, ignore
        return
    end

    schedule_sync_to_server(setting.player_index)
end

Event.add(Settings.events.on_setting_set, setting_set);

return Public
