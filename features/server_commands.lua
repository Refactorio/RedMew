local Poll = {send_poll_result_to_discord = function() end}
local Rank = require 'features.rank_system'
local Token = require 'utils.token'
local Server = require 'features.server'
local Donator = require 'features.donator'

if storage.config.poll.enabled then
    local Event = require 'utils.event'

    local function set_poll()
        -- Hack to prevent poll being required before control.lua finishes.
        -- This is so that the top gui buttons are in the order they are
        -- required in control.lua.
        Poll = _G.package.loaded['features.gui.poll'] or Poll
    end

    Event.on_init(set_poll)
    Event.on_load(set_poll)
end

--- This module is for the web server to call functions and raise events.
-- Not intended to be called by scripts.
-- Needs to be in the _G table so it can be accessed by the web server.
ServerCommands = {}

ServerCommands.get_poll_result = Poll.send_poll_result_to_discord

ServerCommands.regular_sync = Rank.sync_ranks
ServerCommands.donator_sync = Donator.sync_donators

function ServerCommands.raise_callback(func_token, data)
    local func = Token.get(func_token)
    func(data)
end

ServerCommands.raise_data_set = Server.raise_data_set
ServerCommands.get_tracked_data_sets = Server.get_tracked_data_sets

function ServerCommands.server_started()
    script.raise_event(Server.events.on_server_started, {})
end

ServerCommands.set_time = Server.set_time
ServerCommands.set_start_data = Server.set_start_data
ServerCommands.query_online_players = Server.query_online_players

return ServerCommands
