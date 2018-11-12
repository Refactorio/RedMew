local Event = require 'utils.event'
local Game = require 'utils.game'
local player_colors = require 'resources.player_colors'

Event.add(
    defines.events.on_player_created,
    function(event)
        local player = Game.get_player_by_index(event.player_index)
        if not player or not player.valid then
            return
        end

        local color_data = player_colors[player.name]
        if not color_data then
            return
        end

        player.color = color_data.color
        player.chat_color = color_data.chat_color or color_data.color
    end
)