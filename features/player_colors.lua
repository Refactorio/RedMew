local Event = require 'utils.event'
local Server = require 'features.server'
local Token = require 'utils.token'
local Settings = require 'utils.redmew_settings'
local Color = require 'resources.color_presets'

local player_color_name = 'player-color'
local player_chat_color_name = 'player-chat-color'
Settings.register(player_color_name, Settings.types.color, nil, 'player_colors.player_color_setting_label')
Settings.register(player_chat_color_name, Settings.types.chat_color, nil, 'player_colors.player_chat_color_setting_label')

local Public = {}

-- left in for migration purposes, remove at a later point
local color_callback = Token.register(function(data)
    local key = data.key
    local value = data.value

    if not value then
        return
    end

    local player = game.players[key]
    if not player then
        return
    end

    Settings.set(player.index, player_color_name, value.color)
    Settings.set(player.index, player_chat_color_name, value.chat_color)

end)

local function setting_set(event)
    local value = event.new_value
    if not value then
        return
    end

    local setting_name = event.setting_name
    if setting_name ~= player_color_name and setting_name ~= player_chat_color_name then
        return
    end

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    if setting_name == player_color_name then
        player.color = value
    end

    if setting_name == player_chat_color_name then
        player.chat_color = value
    end
end

local function player_joined_game(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player or not player.valid then
        return
    end

    -- already migrated
    if Settings.get(player_index, player_color_name) then
        return
    end

    Server.try_get_data('colors', player.name, color_callback)
end

local function on_command(event)
    local player_index = event.player_index
    if not player_index or event.command ~= 'color' then
        return
    end

    local player = game.get_player(player_index)
    if not player or not player.valid then
        return
    end

    player.print({'player_colors.gui_setting_reference_message'}, Color.success)
    Settings.set(player_index, player_color_name, player.color)

    local error = Settings.validate(player_chat_color_name, player.chat_color)
    if not error then
        Settings.set(player_index, player_chat_color_name, player.chat_color)
    end
end

Event.add(defines.events.on_player_joined_game, player_joined_game)
Event.add(Settings.events.on_setting_set, setting_set)
Event.add(defines.events.on_console_command, on_command)

return Public
