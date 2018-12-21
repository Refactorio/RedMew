local Game = require 'utils.game'
local Event = require 'utils.event'
local Info = require 'features.gui.info'

local function player_created(event)
    local player = Game.get_player_by_index(event.player_index)
    if Info ~= nil then
        Info.show_info({player = player})
    end
end

Event.add(defines.events.on_player_created, player_created)
