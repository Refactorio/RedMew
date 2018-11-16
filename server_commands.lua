local Poll = require 'features.gui.poll'
local UserGroups = require 'features.user_groups'

local Public = {}

Public.get_poll_result = Poll.send_poll_result_to_discord

Public.regular_sync = UserGroups.sync_regulars

Public.regular_promote = UserGroups.server_add_regular

Public.regular_demote = UserGroups.server_remove_regular

return Public
