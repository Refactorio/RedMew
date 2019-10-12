local Gui = require 'utils.gui'

local Public = {}

-- <Join GUI start>

local join_USA = Gui.uid_name()
local join_USSR = Gui.uid_name()

function Public.show_gui(event)
    local frame
    local player = game.get_player(event.player_index)
    local center = player.gui.center
    local gui = center['Space-Race-Lobby']
    if (gui) then
        Gui.destroy(gui)
    end

    frame = player.gui.center.add {name = 'Space-Race-Lobby', type = 'frame', direction = 'vertical', style = 'captionless_frame'}

    frame.style.minimal_width = 300

    --Header
    local top_flow = frame.add {type = 'flow', direction = 'horizontal'}
    top_flow.style.horizontal_align = 'center'
    top_flow.style.horizontally_stretchable = true

    local title_flow = top_flow.add {type = 'flow'}
    title_flow.style.horizontal_align = 'center'
    title_flow.style.top_padding = 8
    title_flow.style.horizontally_stretchable = false

    local title = title_flow.add {type = 'label', caption = 'Welcome to Space Race'}
    title.style.font = 'default-large-bold'

    --Body

    local content_flow = frame.add {type = 'flow', direction = 'horizontal'}
    content_flow.style.top_padding = 8
    content_flow.style.bottom_padding = 16
    content_flow.style.left_padding = 24
    content_flow.style.right_padding = 24
    content_flow.style.horizontal_align = 'center'
    content_flow.style.horizontally_stretchable = true

    local label_flow = content_flow.add {type = 'flow'}
    label_flow.style.horizontal_align = 'center'
    label_flow.style.horizontally_stretchable = true

    local label = label_flow.add {type = 'label', caption = 'Feel free to pick a side!'}
    label.style.horizontal_align = 'center'
    label.style.single_line = false
    label.style.font = 'default'

    --Footer
    local button_flow = frame.add {type = 'flow'}
    button_flow.style.horizontal_align = 'center'
    button_flow.style.horizontally_stretchable = true

    local usa_button_flow = button_flow.add {type = 'flow', direction = 'vertical'}
    usa_button_flow.style.horizontally_stretchable = true
    usa_button_flow.style.horizontal_align = 'center'

    local ussr_button_flow = button_flow.add {type = 'flow', direction = 'vertical'}
    ussr_button_flow.style.horizontally_stretchable = true
    ussr_button_flow.style.horizontal_align = 'center'

    local teams = remote.call('space-race', 'get_teams')

    local force_USSR = teams[2]
    local force_USA = teams[1]

    local usa_players = #force_USA.players
    local ussr_players = #force_USSR.players

    local usa_connected = #force_USA.connected_players
    local ussr_connected = #force_USSR.connected_players

    label = usa_button_flow.add {type = 'label', caption = usa_connected .. ' online / ' .. usa_players .. ' total'}
    label.style.horizontal_align = 'center'
    label.style.single_line = false
    label.style.font = 'default'

    local join_usa_button = usa_button_flow.add {type = 'button', name = join_USA, caption = 'Join United Factory Workers'}

    label = ussr_button_flow.add {type = 'label', caption = ussr_connected .. ' online / ' .. ussr_players .. ' total'}
    label.style.horizontal_align = 'center'
    label.style.single_line = false
    label.style.font = 'default'
    local join_ussr_button = ussr_button_flow.add {type = 'button', name = join_USSR, caption = 'Join Union of Factory Employees'}

    Gui.set_data(join_usa_button, frame)
    Gui.set_data(join_ussr_button, frame)
end

Gui.on_click(
    join_USA,
    function(event)
        local frame = Gui.get_data(event.element)
        local player = event.player

        if remote.call('space-race', 'join_usa', nil, player) then
            Gui.remove_data_recursively(frame)
            frame.destroy()
            remote.call('space-race-lobby' ,'update_gui')
        end
    end
)

Gui.on_click(
    join_USSR,
    function(event)
        local frame = Gui.get_data(event.element)
        local player = event.player

        if remote.call('space-race', 'join_ussr', nil, player) then
            Gui.remove_data_recursively(frame)
            frame.destroy()
            remote.call('space-race-lobby' ,'update_gui')
        end
    end
)

-- <Join GUI end>

return Public
