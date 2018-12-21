local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Event = require 'utils.event'
local Game = require 'utils.game'

local normal_color = {r = 1, g = 1, b = 1}
local focus_color = {r = 1, g = 0.55, b = 0.1}
local rank_colors = {
    {r = 1, g = 1, b = 1}, -- Guest
    {r = 0.155, g = 0.540, b = 0.898}, -- Regular
    {r = 172.6, g = 70.2, b = 215.8}, -- Donator
    {r = 0.093, g = 0.768, b = 0.172} -- Admin
}

local map_name_key = 1
local map_description_key = 2
local map_extra_info_key = 3
local new_info_key = 4

local editable_info = {
    [map_name_key] = global.config.map_info.map_name_key,
    [map_description_key] = global.config.map_info.map_description_key,
    [map_extra_info_key] = global.config.map_info.map_extra_info_key,
    [new_info_key] = global.config.map_info.new_info_key
}

Global.register(
    {
        editable_info = editable_info
    },
    function(tbl)
        editable_info = tbl.editable_info
    end
)

local function prepare_title()
    local welcome_title = [[
111111  1111111 111111  111    111 1111111 11     11
11   11 11      11   11 1111  1111 11      11     11
111111  11111   11   11 11 1111 11 11111   11  1  11
11   11 11      11   11 11  11  11 11      11 111 11
11   11 1111111 111111  11      11 1111111  111 111
]]

    local row = {}
    local welcome_title2 = {row}
    local row_index = 1
    local column_index = 1

    local max = 0
    for i = 1, #welcome_title do
        local char = welcome_title:sub(i, i)
        if char == '\n' then
            row_index = row_index + 1
            row = {}
            welcome_title2[row_index] = row

            max = math.max(max, column_index - 1)

            column_index = 1
        elseif char == '1' then
            row[column_index] = true
            column_index = column_index + 1
        elseif char == ' ' then
            row[column_index] = false
            column_index = column_index + 1
        end
    end

    return welcome_title2, max
end

local title, title_max = prepare_title()

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local tab_button_name = Gui.uid_name()
local editable_textbox_name = Gui.uid_name()

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
            local button = parent.add {type = 'button', name = tab_button_name, caption = 'Welcome'}
            return button
        end,
        content = function(parent)
            local parent_style = parent.style
            parent_style.right_padding = 2

            parent =
                parent.add {
                type = 'scroll-pane',
                vertical_scroll_policy = 'auto-and-reserve-space',
                horizontal_scroll_policy = 'never'
            }
            parent_style = parent.style
            parent_style.vertically_stretchable = true

            header_label(parent, 'Welcome to the Redmew Server!')
            centered_label(
                parent,
                [[
Redmew is a community for players of all skill levels committed to pushing the limits of Factorio Multiplayer through custom scripts and crazy map designs.

We are a friendly bunch, our objective is to have as much fun as possible and we hope you will too.
                ]]
            )

            header_label(parent, 'How To Chat')
            centered_label(parent, [[
To chat with other players, press the "grave" key on your keyboard.
It is below the ESC key on English keyboards and looks like ~ or `
This can be changed in options -> controls -> "toggle lua console".
                ]])

            header_label(parent, 'Useful Links')
            centered_label(parent, [[Check out our discord for new map info and to suggest new maps / ideas.]])
            local discord_textbox_flow = parent.add {type = 'flow'}
            local discord_textbox_flow_style = discord_textbox_flow.style
            discord_textbox_flow_style.align = 'center'
            discord_textbox_flow_style.horizontally_stretchable = true
            discord_textbox_flow.add({type = 'label', caption = 'Discord: '}).style.font = 'default-bold'
            local discord_textbox = discord_textbox_flow.add {type = 'text-box', text = 'redmew.com/discord '}
            discord_textbox.read_only = true
            centered_label(parent, 'Contribute to our Patreon to receive special perks and help maintain our servers.')
            local patreon_flow = parent.add {type = 'flow', direction = 'horizontal'}
            local patreon_flow_style = patreon_flow.style
            patreon_flow_style.align = 'center'
            patreon_flow_style.horizontally_stretchable = true
            patreon_flow.add({type = 'label', caption = 'Patreon:'}).style.font = 'default-bold'
            local patreon_textbox = patreon_flow.add {type = 'text-box', text = 'patreon.com/redmew '}
            patreon_textbox.read_only = true
            centered_label(parent, 'Download our maps, start and finish state, from our website.')
            local save_textbox_flow = parent.add {type = 'flow'}
            local save_textbox_flow_style = save_textbox_flow.style
            save_textbox_flow_style.align = 'center'
            save_textbox_flow_style.horizontally_stretchable = true
            save_textbox_flow.add({type = 'label', caption = 'Saves: '}).style.font = 'default-bold'
            local save_textbox = save_textbox_flow.add {type = 'text-box', text = 'http://www.redmew.com/saves/ '}
            save_textbox.read_only = true

            centered_label(parent, 'View our past maps as a Google Map.')
            local maps_textbox_flow = parent.add {type = 'flow'}
            local maps_textbox_flow_style = maps_textbox_flow.style
            maps_textbox_flow_style.align = 'center'
            maps_textbox_flow_style.horizontally_stretchable = true
            maps_textbox_flow.add({type = 'label', caption = 'Maps: '}).style.font = 'default-bold'
            local maps_textbox = maps_textbox_flow.add {type = 'text-box', text = 'https://factoriomaps.com/browse/redmew.html '}
            maps_textbox.read_only = true

            parent.add({type = 'flow'}).style.height = 24
        end
    },
    {
        tab_button = function(parent)
            local button = parent.add {type = 'button', name = tab_button_name, caption = 'Rules'}
            return button
        end,
        content = function(parent)
            header_label(parent, 'Rules')

            centered_label(
                parent,
                [[
Have fun and play nice. Remember we are all just here to have fun so let’s keep it that way.

No hateful content or personal attacks.

If you suspect someone is griefing, notify the admin team by using /report or by clicking the report button next to the player in the player list.
                ]]
            )
        end
    },
    {
        tab_button = function(parent)
            local button = parent.add {type = 'button', name = tab_button_name, caption = 'Map Info'}
            return button
        end,
        content = function(parent, player)
            local read_only = not player.admin
            local text_width = 480

            local top_flow = parent.add {type = 'flow'}
            local top_flow_style = top_flow.style
            top_flow_style.align = 'center'
            top_flow_style.horizontally_stretchable = true

            local top_label = top_flow.add {type = 'label', caption = 'Map Infomation'}
            local top_label_style = top_label.style
            top_label_style.font = 'default-frame'

            local grid = parent.add {type = 'table', column_count = 2}
            local grid_style = grid.style
            grid_style.horizontally_stretchable = true

            grid.add {type = 'label', caption = 'Map name: '}
            local map_name_textbox =
                grid.add({type = 'flow'}).add {
                type = 'text-box',
                name = editable_textbox_name,
                text = editable_info[map_name_key]
            }
            map_name_textbox.read_only = read_only
            map_name_textbox.word_wrap = true

            local map_name_textbox_style = map_name_textbox.style
            map_name_textbox_style.width = text_width
            map_name_textbox_style.maximal_height = 27

            Gui.set_data(map_name_textbox, map_name_key)

            grid.add {type = 'label', caption = 'Map description: '}
            local map_description_textbox =
                grid.add({type = 'flow'}).add {
                type = 'text-box',
                name = editable_textbox_name,
                text = editable_info[map_description_key]
            }
            map_description_textbox.read_only = read_only
            map_description_textbox.word_wrap = true

            local map_description_textbox_style = map_description_textbox.style
            map_description_textbox_style.width = text_width
            map_description_textbox_style.maximal_height = 72

            Gui.set_data(map_description_textbox, map_description_key)

            grid.add {type = 'label', caption = 'Extra Info: '}
            local map_extra_info_textbox =
                grid.add({type = 'flow'}).add {
                type = 'text-box',
                name = editable_textbox_name,
                text = editable_info[map_extra_info_key]
            }
            map_extra_info_textbox.read_only = read_only
            map_extra_info_textbox.word_wrap = true

            local map_extra_info_textbox_style = map_extra_info_textbox.style
            map_extra_info_textbox_style.width = text_width
            map_extra_info_textbox_style.height = 210

            Gui.set_data(map_extra_info_textbox, map_extra_info_key)
        end
    },
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

    local title_grid = top_flow.add {type = 'table', column_count = title_max}
    for _, row in ipairs(title) do
        for _, char in ipairs(row) do
            local ele
            if char then
                ele = title_grid.add {type = 'sprite', sprite = 'virtual-signal/signal-red'}
            else
                ele = title_grid.add {type = 'label', caption = ' '}
            end

            local ele_style = ele.style
            ele_style.height = 10
            ele_style.width = 10
        end
    end

    local title_grid_style = title_grid.style
    title_grid_style.vertical_spacing = 0
    title_grid_style.horizontal_spacing = 0
    title_grid_style.bottom_padding = 8

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

local function toggle(event)
    local player = event.player
    local center = player.gui.center
    local main_frame = center[main_frame_name]

    if main_frame then
        Gui.destroy(main_frame)
    else
        draw_main_frame(center, player)
    end
end

local function player_created(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    local gui = player.gui
    gui.top.add {type = 'sprite-button', name = main_button_name, sprite = 'utility/questionmark'}
end

Event.add(defines.events.on_player_created, player_created)

Gui.on_click(main_button_name, toggle)

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

Gui.on_text_changed(
    editable_textbox_name,
    function(event)
        local textbox = event.element
        local key = Gui.get_data(textbox)

        editable_info[key] = textbox.text
    end
)

Gui.on_custom_close(
    main_frame_name,
    function(event)
        Gui.destroy(event.element)
    end
)

local Public = {}

function Public.show_info(player)
    toggle(player)
end

return Public
