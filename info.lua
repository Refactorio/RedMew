local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Event = require 'utils.event'
local UserGroups = require 'user_groups'

local normal_color = {r = 1, g = 1, b = 1}
local focus_color = {r = 1, g = 0.55, b = 0.1}
local rank_colors = {
    {r = 1, g = 1, b = 1}, -- Guest
    {r = 0.155, g = 0.540, b = 0.898}, -- Regular
    {r = 0.093, g = 0.768, b = 0.172} -- Admin
}

local welcomed_players = {}

Global.register(
    {welcomed_players = welcomed_players},
    function(tbl)
        welcomed_players = tbl.welcomed_players
    end
)

local function prepare_title()
    local welcome_title =
        [[
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

local function line_bar(parent)
    local bar = parent.add {type = 'progressbar', value = 1}
    local style = bar.style
    style.color = normal_color
    style.horizontally_stretchable = true
end

local pages = {
    {
        header = function(parent, player)
            local button = parent.add {type = 'button', name = tab_button_name, caption = 'Welcome'}
            return button
        end,
        content = function(parent, player)
            local top_flow = parent.add {type = 'flow'}
            local top_flow_style = top_flow.style
            top_flow_style.align = 'center'
            top_flow_style.horizontally_stretchable = true

            local top_label = top_flow.add {type = 'label', caption = 'Welcome to the Redmew Server!'}
            local top_label_style = top_label.style
            top_label_style.font = 'default-frame'

            local label1 =
                parent.add {
                type = 'label',
                caption = [[
				Redmew is community for players of all skill levels committed to pushing the limits of Factorio Multiplayer through custom scripts and crazy map designs.
				
				Our Objective is to have as much fun as possible.

				Check out our discord for new map info and to suggest new maps / ideas]]
            }
            local label1_style = label1.style
            label1_style.single_line = false
            label1_style.align = 'center'

            local discord_textbox_flow = parent.add {type = 'flow'}
            local discord_textbox_flow_style = discord_textbox_flow.style
            discord_textbox_flow_style.align = 'center'
            discord_textbox_flow_style.horizontally_stretchable = true

            local discord_textbox = discord_textbox_flow.add {type = 'text-box', text = 'redmew.com/discord '}
            discord_textbox.read_only = true

            local label2_flow = parent.add {type = 'flow'}
            local label2_flow_style = label2_flow.style
            label2_flow_style.align = 'center'
            label2_flow_style.horizontally_stretchable = true
            local label2 = label2_flow.add {type = 'label', caption = 'Contribute to our servers at'}

            local contribute2_flow = parent.add {type = 'flow', direction = 'horizontal'}
            local contribute2_flow_style = contribute2_flow.style
            contribute2_flow_style.align = 'center'
            contribute2_flow_style.horizontally_stretchable = true

            local contribute2_label = contribute2_flow.add {type = 'label', caption = 'Patreon:'}
            local contribute2_textbox = contribute2_flow.add {type = 'text-box', text = 'patreon.com/redmew '}
            contribute2_textbox.read_only = true

            local contribute2_flow = parent.add {type = 'flow', direction = 'horizontal'}
            local contribute2_flow_style = contribute2_flow.style
            contribute2_flow_style.align = 'center'
            contribute2_flow_style.horizontally_stretchable = true

            local contribute2_label = contribute2_flow.add {type = 'label', caption = 'Paypal:'}
            local contribute2_textbox = contribute2_flow.add {type = 'text-box', text = 'paypal.me/jsuesse '}
            contribute2_textbox.read_only = true
        end
    },
    {
        header = function(parent, player)
            local button = parent.add {type = 'button', name = tab_button_name, caption = 'Rules'}
            return button
        end,
        content = function(parent, player)
            local top_flow = parent.add {type = 'flow'}
            local top_flow_style = top_flow.style
            top_flow_style.align = 'center'
            top_flow_style.horizontally_stretchable = true

            local top_label = top_flow.add {type = 'label', caption = 'Rules'}
            local top_label_style = top_label.style
            top_label_style.font = 'default-frame'

            local label1_flow = parent.add {type = 'flow'}
            local label1_flow_style = label1_flow.style
            label1_flow_style.align = 'center'
            label1_flow_style.horizontally_stretchable = true

            local label1 =
                label1_flow.add {
                type = 'label',
                caption = [[

				Have fun and play nice.

				Don't talk about Fight club.

				Don't talk about rule 2.

				If this is your first night, then  you have to fight.
			]]
            }

            local label1_style = label1.style
            label1_style.single_line = false
            label1_style.align = 'center'
        end
    },
    {
        header = function(parent, player)
            local button = parent.add {type = 'button', name = tab_button_name, caption = 'Scenario Mods'}
            return button
        end,
        content = function(parent, player)
            parent =
                parent.add {
                type = 'scroll-pane',
                vertical_scroll_policy = 'auto-and-reserve-space',
                horizontal_scroll_policy = 'never'
            }
            local parent_style = parent.style
            parent_style.vertically_stretchable = true

            local top_flow = parent.add {type = 'flow'}
            local top_flow_style = top_flow.style
            top_flow_style.align = 'center'
            top_flow_style.horizontally_stretchable = true

            local top_label = top_flow.add {type = 'label', caption = 'Soft Mods and Server Plugins'}
            local top_label_style = top_label.style
            top_label_style.font = 'default-frame'

            local ranks_flow = parent.add {type = 'flow', direction = 'horizontal'}
            local ranks = ranks_flow.add {type = 'label', caption = '  Ranks'}
            ranks.style.font = 'default-listbox'
            local ranks_label =
                ranks_flow.add {
                type = 'label',
                caption = [[
				We have a basic rank system to prevent griefing. You can't use nukes or the deconstruction planner if you are a guest. If you play for a couple of hours an admin will promote you to regular.	]]
            }
            local ranks_label_style = ranks_label.style
            ranks_label_style.single_line = false

            local player_rank_flow = parent.add {type = 'flow', direction = 'horizontal'}
            player_rank_flow.add {type = 'label', caption = '                     Your rank is:'}

            if player.admin then
                local label = player_rank_flow.add {type = 'label', caption = 'Admin'}
                label.style.font_color = rank_colors[3]
            elseif UserGroups.is_regular(player.name) then
                local label = player_rank_flow.add {type = 'label', caption = 'Regular'}
                label.style.font_color = rank_colors[2]
            else
                local label = player_rank_flow.add {type = 'label', caption = 'Guest'}
                label.style.font_color = rank_colors[1]
            end

            local player_list_flow = parent.add {type = 'flow', direction = 'horizontal'}
            player_list_flow.add {type = 'sprite', sprite = 'entity/player'}

            local player_list = player_list_flow.add {type = 'label', caption = ' Player list'}
            player_list.style.font = 'default-listbox'

            local player_list_label =
                player_list_flow.add {
                type = 'label',
                caption = [[
				This lists all players on the server and shows some stats. You can sort the list by clicking on the column header.
			]]
            }
            player_list_label.style.single_line = false

            local poll_flow = parent.add {type = 'flow', direction = 'horizontal'}
            poll_flow.add {type = 'sprite', sprite = 'item/programmable-speaker'}

            local poll = poll_flow.add {type = 'label', caption = ' Polls'}
            poll.style.font = 'default-listbox'

            local poll_label =
                poll_flow.add {
                type = 'label',
                caption = [[
					Polls help players communicate. Want to improve someone’s build, make a poll to check everyone is ok with that. Not sure what our next objective should be, why not make a poll. You need to be a regular to make new polls.
			]]
            }
            poll_label.style.single_line = false

            local tag_flow = parent.add {type = 'flow', direction = 'horizontal'}
            local tag_button = tag_flow.add {type = 'label', caption = 'tag'}
            local tag_button_style = tag_button.style
            tag_button_style.font = 'default-listbox'
            tag_button_style.font_color = {r = 0, g = 0, b = 0}

            local tag = tag_flow.add {type = 'label', caption = ' Tags'}
            tag.style.font = 'default-listbox'

            local tag_label =
                tag_flow.add {
                type = 'label',
                caption = [[
					You can assign yourself a role with tags to let other players know what you are doing. Or just use the tag as decoration. Regulars can create new custom tags, be sure to show off your creatively. 
			]]
            }
            tag_label.style.single_line = false

            local task_flow = parent.add {type = 'flow', direction = 'horizontal'}
            task_flow.add {type = 'sprite', sprite = 'item/discharge-defense-remote'}

            local task = task_flow.add {type = 'label', caption = ' Tasks'}
            task.style.font = 'default-listbox'

            local task_label =
                task_flow.add {
                type = 'label',
                caption = [[
					Not sure what you should be working on, why not look at the tasks and see what needs doing. Regulars can add new tasks.
			]]
            }
            task_label.style.single_line = false
        end
    },
    {
        header = function(parent, player)
            local button = parent.add {type = 'button', name = tab_button_name, caption = 'Map Info'}
            return button
        end,
        content = function(parent, player)
            local label = parent.add {type = 'label', caption = 'This map is sick'}
        end
    },
    {
        header = function(parent, player)
            local button = parent.add {type = 'button', name = tab_button_name, caption = 'Other Servers'}
            return button
        end,
        content = function(parent, player)
            local label = parent.add {type = 'label', caption = 'There is a modded server'}
        end
    }
}

local function draw_main_frame(center, player)
    local frame = center.add {type = 'frame', name = main_frame_name, direction = 'vertical'}
    local frame_style = frame.style
    frame_style.height = 600
    frame_style.width = 600
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
        local button = page.header(button_flow, player)
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

    local close_button = bottom_flow.add {type = 'button', name = main_button_name, caption = 'Close'}

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
    local player = game.players[event.player_index]

    if not player or not player.valid then
        return
    end

    local gui = player.gui

    local button = gui.top.add {type = 'sprite-button', name = main_button_name, sprite = 'utility/questionmark'}

    if player.admin or UserGroups.is_regular(player.name) or welcomed_players[player.index] then
        return
    end

    welcomed_players[player.index] = true
    draw_main_frame(gui.center, player)
end

Event.add(defines.events.on_player_created, player_created)

Gui.on_click(main_button_name, toggle)

Gui.on_click(
    tab_button_name,
    function(event)
        local button = event.element
        local player = event.player

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

        pages[index].content(content, player)
    end
)

Gui.on_custom_close(
    main_frame_name,
    function(event)
        Gui.destroy(event.element)
    end
)
