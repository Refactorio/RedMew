local Gui = require 'utils.gui'
local Event = require 'utils.event'
local Game = require 'utils.game'

local focus_color = {r = 1, g = 0.55, b = 0.1}

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local tab_button_name = Gui.uid_name()

local function centered_label(parent, string)
    local flow = parent.add {type = 'flow'}
    local flow_style = flow.style
    flow_style.align = 'center'
    flow_style.horizontally_stretchable = true

    local label = flow.add {type = 'label', caption = string}
    local label_style = label.style
    label_style.align = 'center'
    label_style.single_line = false

    return label
end

local function header_label(parent, string)
    local flow = parent.add {type = 'flow'}
    local flow_style = flow.style
    flow_style.align = 'center'
    flow_style.horizontally_stretchable = true

    local label = flow.add {type = 'label', caption = string}
    local label_style = label.style
    label_style.align = 'center'
    label_style.single_line = false
    label_style.font = 'default-frame'

    return label
end

local pages = {
    {
        tab_button = function(parent)
            local button = parent.add {type = 'button', name = tab_button_name, caption = 'Rules'}
            return button
        end,
        content = function(parent)
            header_label(parent, 'Rules')

            centered_label(parent, 'hello')
        end
    }
}

local function draw_main_frame(center, player)
    local frame = center.add {type = 'frame', name = main_frame_name, direction = 'vertical'}

    frame.add {type = 'flow'}

    local tab_buttons = {}
    local active_tab = 1
    local data = {
        tab_buttons = tab_buttons,
        active_tab = active_tab
    }

    local tab_flow = frame.add {type = 'flow', direction = 'horizontal'}

    for index, page in ipairs(pages) do
        local button_flow = tab_flow.add {type = 'flow'}
        local button = page.tab_button(button_flow, player)

        Gui.set_data(button, {index = index, data = data})

        tab_buttons[index] = button
    end

    tab_buttons[active_tab].style.font_color = focus_color

    local content = frame.add {type = 'frame', direction = 'vertical', style = 'image_frame'}

    pages[active_tab].content(content, player)

    data.content = content

    player.opened = frame
end

local function player_created(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    local gui = player.gui
    gui.top.add {type = 'sprite-button', name = main_button_name, sprite = 'utility/questionmark'}
    draw_main_frame(gui.center, player)
end

Event.add(defines.events.on_player_created, player_created)

Gui.on_custom_close(
    main_frame_name,
    function(event)
        Gui.destroy(event.element)
    end
)
