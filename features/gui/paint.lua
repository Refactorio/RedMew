local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Game = require 'utils.game'

local main_frame_name = Gui.uid_name()

local filter_button_name = Gui.uid_name()
local filter_clear_name = Gui.uid_name()

global.paint_brushes_by_player = {}

local function toggle(event)
    local left = event.player.gui.left
    local main_frame = left[main_frame_name]

    if main_frame and main_frame.valid then
        return
    else
        main_frame =
            left.add {
            type = 'frame',
            name = main_frame_name,
            direction = 'vertical',
            caption = 'Paint Brush'
        }
        local brush =
            main_frame.add({type = 'flow'}).add {
            type = 'sprite-button',
            name = filter_button_name,
        }
        local buttons_flow = main_frame.add {type = 'flow', direction = 'horizontal'}
        local clear_bursh = buttons_flow.add {type = 'button', name = filter_clear_name, caption = 'Clear Brush'}
        Gui.set_data(clear_bursh, brush)
    end
end

local function player_created(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end
    toggle({player = player, player_index = player.index})
end

Event.add(defines.events.on_player_created, player_created)
