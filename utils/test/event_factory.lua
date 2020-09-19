local EventCore = require 'utils.event_core'

local Public = {}

Public.raise = EventCore.on_event

function Public.on_gui_click(element, player_index)
    return {
        name = defines.events.on_gui_click,
        tick = game.tick,
        element = element,
        player_index = player_index,
        button = defines.mouse_button_type.left,
        alt = false,
        control = false,
        shift = false
    }
end

return Public
