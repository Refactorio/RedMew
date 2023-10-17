local Poll = require 'features.gui.poll'
local Global = require 'utils.global'
local Event = require 'utils.event'
local PollUtils = require 'utils.poll_utils'
local Restart = require 'features.restart_command'
local Server = require 'features.server'
local Ranks = require 'resources.ranks'

local data = {
    created = false,
    id = nil
}

Global.register(data, function(tbl)
    data = tbl
end)

local maps = {
    {
        name = 'crashsite',
        display_name = 'Normal'
    },
    {
        name = 'crashsite-UK',
        display_name = 'UK'
    },
    {
        name = 'crashsite-arrakis',
        display_name = 'Arrakis'
    },
    {
        name = 'crashsite-desert',
        display_name = 'Desert'
    },
    {
        name = 'crashsite-manhattan',
        display_name = 'Manhattan'
    },
    {
        name = 'crashsite-venice',
        display_name = 'Venice'
    },
    {
        name = 'crashsite-world',
        display_name = 'World'
    },
}

Event.add(Server.events.on_server_started, function()
    if data.created then
        return
    end

    data.created = true

    local answers = {}
    for i, map_data in pairs(maps) do
        answers[i] = map_data.display_name
    end

    local success, id = Poll.poll({
        question = 'Next map? (Advisory only)',
        duration = 0,
        edit_rank = Ranks.admin,
        answers = answers
    })

    if success then
        data.id = id
    end

    Restart.set_use_map_poll_result_option(true)
end)

local Public = {}

function Public.get_map_poll_id()
    return data.id
end

function Public.get_next_map()
    local poll_data = Poll.get_poll_data(data.id)
    if poll_data == nil then
        return nil
    end

    local answers = poll_data.answers
    local chosen_index = PollUtils.get_poll_winner(answers)
    if chosen_index == nil then
        return nil
    end

    return maps[chosen_index]
end

return Public
