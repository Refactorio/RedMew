local Event = require 'utils.event'

local player_colors = {
    ['grilledham'] = {
        color = {r = 0.9290000202716064, g = 0.3860000739097595, b = 0.51399999856948853, a = 0.5},
        chat_color = {r = 1, g = 0.51999998092651367, b = 0.63300001621246338, a = 0.5}
    },
    ['plague006'] = {
        color = {r = 64, g = 224, b = 208, a = 0.5},
        chat_color = {r = 175, g = 238, b = 238, a = 0.5}
    },
    ['Linaori'] = {
        color = {r = 0.485, g = 0.111, b = 0.659, a = 0.5},
        chat_color = {r = 0.821, g = 0.444, b = 0.998, a = 0.5}
    },
    ['Jayefuu'] = {
        color = {r = 0.559, g = 0.761, b = 0.157, a = 0.5},
        chat_color = {r = 0.708, g = 0.996, b = 0.134, a = 0.5}
    }
}

Event.add(
    defines.events.on_player_created,
    function(event)
        local player = game.players[event.player_index]
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
