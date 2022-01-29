local Poll = require 'features.gui.poll'
local Global = require 'utils.global'
local Event = require 'utils.event'
local Server = require 'features.server'

local data = {created = false}

Global.register(data, function(tbl)
    data = tbl
end)

Event.add(Server.events.on_server_started, function()
    if data.created then
        return
    end

    data.created = true

    Poll.poll({
        question = 'Next map? (Advisory only)',
        duration = 0,
        answers = {
            'terraforming (default)',
            'one direction (line)',
            '3-way (T shape)',
            'chessboard (random ratios)',
            'chessboard uniform (fixed ratios)',
            'circles (ore rings)',
            'gradient (smooth ore ratios)',
            'hub-spiral (with void)',
            'spiral (without void)',
            'landfill (all tiles)',
            'patches (ore islands in coal)',
            'xmas tree (triangle)'
        }
    })
end)
