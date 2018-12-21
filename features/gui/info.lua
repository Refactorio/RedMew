local Gui = require 'utils.gui'
local Event = require 'utils.event'
local Game = require 'utils.game'

local normal_color = {r = 1, g = 1, b = 1}
local focus_color = {r = 1, g = 0.55, b = 0.1}

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local tab_button_name = Gui.uid_name()

local function line_bar(parent)
    local bar = parent.add {type = 'progressbar', value = 1}
    local style = bar.style
    style.color = normal_color
    style.horizontally_stretchable = true
end

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
    local frame_style = frame.style
    frame_style.height = 600
    frame_style.width = 650
    frame_style.left_padding = 16
    frame_style.right_padding = 16
    frame_style.top_padding = 16

    local top_flow = frame.add {type = 'flow'}
    local top_flow_style = top_flow.style
    top_flow_style.align = 'center'
    top_flow_style.top_padding = 8
    top_flow_style.horizontally_stretchable = true

    line_bar(frame)

    local tab_buttons = {}
    local active_tab = 1
    local data = {
        tab_buttons = tab_buttons,
        active_tab = active_tab
    }

    local tab_flow = frame.add {type = 'flow', direction = 'horizontal'}
    local tab_flow_style = tab_flow.style
    tab_flow_style.align = 'center'
    tab_flow_style.horizontally_stretchable = true

    for index, page in ipairs(pages) do
        local button_flow = tab_flow.add {type = 'flow'}
        local button = page.tab_button(button_flow, player)

        local button_style = button.style
        button_style.left_padding = 3
        button_style.right_padding = 3

        Gui.set_data(button, {index = index, data = data})

        tab_buttons[index] = button
    end

    tab_buttons[active_tab].style.font_color = focus_color

    line_bar(frame)

    local content = frame.add {type = 'frame', direction = 'vertical', style = 'image_frame'}
    local content_style = content.style
    content_style.horizontally_stretchable = true
    content_style.vertically_stretchable = true
    content_style.left_padding = 8
    content_style.right_padding = 8
    content_style.top_padding = 4

    pages[active_tab].content(content, player)

    data.content = content

    local bottom_flow = frame.add {type = 'flow'}
    local bottom_flow_style = bottom_flow.style
    bottom_flow_style.align = 'center'
    bottom_flow_style.top_padding = 8
    bottom_flow_style.horizontally_stretchable = true

    bottom_flow.add {type = 'button', name = main_button_name, caption = 'Close'}

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

Gui.on_click(
    tab_button_name,
    function(event)
        local button = event.element

        local button_data = Gui.get_data(button)
        local index = button_data.index
        local data = button_data.data
        local active_tab = data.active_tab

        if active_tab == index then
            return
        end

        local tab_buttons = data.tab_buttons
        local old_button = tab_buttons[active_tab]

        old_button.style.font_color = normal_color
        button.style.font_color = focus_color

        data.active_tab = index

        local content = data.content
        Gui.clear(content)
    end
)

Gui.on_custom_close(
    main_frame_name,
    function(event)
        Gui.destroy(event.element)
    end
)
