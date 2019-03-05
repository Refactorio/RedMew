--[[
    This module aims to gradually teach players about redmew-specific features.
]]
-- Dependencies
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'
local Rank = require 'features.rank_system'
local Task = require 'utils.task'
local Toast = require 'features.gui.toast'
local Token = require 'utils.token'
local Ranks = require 'resources.ranks'

-- Constants
local time_to_toast = 600 -- 60s * 10 mins
local time_to_chat = 1200 -- 60s * 20 mins

-- Local vars
local Public = {}

-- Global-registered locals
local player_chatted = {}
Global.register(
    {
        player_chatted = player_chatted
    },
    function(tbl)
        player_chatted = tbl.player_chatted
    end
)

-- Local functions
local toast_token =
    Token.register(
    function(data)
        local player_index = data.player_index

        if data.chat_teaching and player_chatted[player_index] then
            return
        end

        local player = Game.get_player_by_index(player_index)
        if not player or not player.valid or not player.connected then
            return
        end

        Toast.toast_player(player, 60, data.msg)
    end
)

local function on_player_created(event)
    local player_index = event.player_index
    local player = Game.get_player_by_index(player_index)
    if not player or not player.valid then
        return
    end

    local player_name = player.name
    if Rank.equal(player_name, Ranks.guest) then
        Task.set_timeout(
            time_to_toast,
            toast_token,
            {
                player_index = player_index,
                msg = {'player_onboarding.teach_toast'}
            }
        )
        Task.set_timeout(
            time_to_chat,
            toast_token,
            {
                player_index = player_index,
                chat_teaching = true,
                msg = {
                    'player_onboarding.teach_chat',
                    {'gui-menu.settings'},
                    {'gui-menu.controls'},
                    {'controls.toggle-console'}
                }
            }
        )
    end
end

--- Log all players who have chatted or used commands this map.
-- This will also gives us a measure of how many players engage in chat in a map.
local function on_player_chat(event)
    local player_index = event.player_index
    if not player_index then
        return
    end

    local player = Game.get_player_by_index(player_index)
    if not player or not player.valid then
        return
    end

    player_chatted[player_index] = true
end

-- Public functions

--- Returns the number of players who have chatted or used a command this map.
function Public.get_num_players_chatted()
    return table_size(player_chatted)
end

-- Event registers
Event.add(defines.events.on_player_created, on_player_created)
Event.add(defines.events.on_console_chat, on_player_chat)
Event.add(defines.events.on_console_command, on_player_chat)

return Public
