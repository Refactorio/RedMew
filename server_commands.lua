local Poll = require 'poll'
local UserGroups = require 'user_groups'

local Public = {}

function Public.get_poll_result(id)
    Poll.send_poll_result_to_discord(id)
end

function Public.regular_sync(names)
    global.regulars = names
end

function Public.regular_promote(name)
    global.regulars[name] = true
end

function Public.regular.demote(name)
    global.regulars[name] = nil
end

return Public
