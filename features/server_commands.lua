local Poll = require 'features.gui.poll'
local UserGroups = require 'features.user_groups'
local Token = require 'utils.token'
local Server = require 'features.server'

--- This module is for the web server to call functions and raise events.
-- Not intended to be called by scripts.
-- Needs to be in the _G table so it can be accessed by the web server.
ServerCommands = {}

ServerCommands.get_poll_result = Poll.send_poll_result_to_discord

ServerCommands.regular_sync = UserGroups.sync_regulars
ServerCommands.donator_sync = UserGroups.sync_donators

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
ServerCommands.query_online_players = Server.query_online_players

return ServerCommands
