local Poll = require 'features.gui.poll'
local UserGroups = require 'features.user_groups'
local Token = require 'utils.global_token'
local Server = require 'server'

local Public = {}

Public.get_poll_result = Poll.send_poll_result_to_discord

Public.regular_sync = UserGroups.sync_regulars

Public.regular_promote = UserGroups.server_add_regular

Public.regular_demote = UserGroups.server_remove_regular

function Public.raise_callback(func_token, data)
    local func = Token.get(func_token)
    func(data)
end

Public.raise_data_set = Server.raise_data_set
Public.get_tracked_data_sets = Server.get_tracked_data_sets

function Public.server_started()
    script.raise_event(Server.events.on_server_started, {})
end

return Public
