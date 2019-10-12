local Gui = require 'utils.gui'
local Color = require 'resources.color_presets'

local Public = {}

-- <Load GUI start>

function Public.show_gui(event)
    local frame
    local player = game.get_player(event.player_index)
    local center = player.gui.center
    local gui = center['Space-Race-Waiting']
    if (gui) then
        Gui.destroy(gui)
    end

    frame = player.gui.center.add {name = 'Space-Race-Waiting', type = 'frame', direction = 'vertical', style = 'captionless_frame'}

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

    local content_flow = frame.add {type = 'flow'}
    content_flow.style.top_padding = 8
    content_flow.style.horizontal_align = 'center'
    content_flow.style.horizontally_stretchable = true

    local label_flow = content_flow.add {type = 'flow', direction = 'vertical'}
    label_flow.style.horizontal_align = 'center'

    label_flow.style.horizontally_stretchable = true
    local label = label_flow.add {type = 'label', caption = 'Waiting for map to generate\nPlease wait\n'}
    label.style.horizontal_align = 'center'
    label.style.single_line = false
    label.style.font = 'default'
    label.style.font_color = Color.yellow

    local started_tick = remote.call('space-race', 'get_started_tick')
    local time = game.tick - started_tick

    if time > 60 then
        local minutes = (time / 3600)
        minutes = minutes - minutes % 1
        time = time - (minutes * 3600)
        local seconds = (time / 60)
        seconds = seconds - seconds % 1
        time = minutes .. ' minutes and ' .. seconds .. ' seconds'
    else
        local seconds = (time - (time % 60)) / 60
        time = seconds .. ' seconds'
    end

    label = label_flow.add {type = 'label', caption = '[color=blue]Time elapsed: ' .. time .. ' [/color]'}
    label.style.horizontal_align = 'center'
    label.style.single_line = false
    label.style.font = 'default'
end

-- <Load GUI end>

function Public.show_gui_to_all()
    for _, player in pairs(game.connected_players) do
        Public.show_gui({player_index = player.index})
    end
end

function Public.remove_gui()
    for _, player in pairs(game.connected_players) do
        local center = player.gui.center
        local gui = center['Space-Race-Waiting']
        if (gui) then
            Gui.destroy(gui)
        end
    end
end

return Public
