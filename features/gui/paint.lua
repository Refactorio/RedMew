local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Game = require 'utils.game'

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()

local filter_button_name = Gui.uid_name()
local filter_clear_name = Gui.uid_name()
local filter_table_close_button_name = Gui.uid_name()

global.paint_brushes_by_player = {}

local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    if player.gui.top[main_button_name] ~= nil then
        return
    end

    player.gui.top.add {name = main_button_name, type = 'sprite-button', sprite = 'utility/spray_icon'}
end

local function toggle(event)
    local left = event.player.gui.left
    local main_frame = left[main_frame_name]

    if main_frame and main_frame.valid then
        Gui.remove_data_recursively(main_frame)
        main_frame.destroy()
    else
        main_frame =
            left.add {
            type = 'frame',
            name = main_frame_name,
            direction = 'vertical',
            caption = 'Paint Brush'
        }
        main_frame.add {
            type = 'label',
            caption = 'Choose a replacement tile for Refined hazard concrete'
        }

        local tooltip = global.paint_brushes_by_player[event.player_index] or ''

        local brush =
            main_frame.add({type = 'flow'}).add {
            type = 'sprite-button',
            name = filter_button_name,
            tooltip = tooltip,
            sprite = tooltip ~= '' and 'tile/' .. tooltip or nil
        }
        brush.style = 'slot_button'

        local buttons_flow = main_frame.add {type = 'flow', direction = 'horizontal'}

        buttons_flow.add {type = 'button', name = main_button_name, caption = 'Close'}

        local clear_bursh = buttons_flow.add {type = 'button', name = filter_clear_name, caption = 'Clear Brush'}
        Gui.set_data(clear_bursh, brush)
    end
end

Gui.on_click(main_button_name, toggle)

Gui.on_click(
    filter_table_close_button_name,
    function(event)
        local frame = Gui.get_data(event.element)
        Gui.remove_data_recursively(frame)
        frame.destroy()
    end
)

Event.add(defines.events.on_player_joined_game, player_joined)

local function player_created(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end
    toggle({player = player, player_index = player.index})
end

Event.add(defines.events.on_player_created, player_created)
