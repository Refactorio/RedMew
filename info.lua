local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Event = require 'utils.event'
local UserGroups = require 'user_groups'
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

local welcomed_players = {}
local editable_info = {
    [map_name_key] = 'This Map has no name',
    [map_description_key] = "By default this section is blank as it's supposed to be filled out on a per map basis. (If you're seeing this message, ping the admin team to get a description added for this map)",
    [map_extra_info_key] = 'This map has no extra infomation',
    [new_info_key] = 'Nothing is new. The world is at peace'
}

Global.register(
    {
        welcomed_players = welcomed_players,
        editable_info = editable_info
    },
    function(tbl)
        welcomed_players = tbl.welcomed_players
        editable_info = tbl.editable_info
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
        tab_button = function(parent, player)
            local button = parent.add {type = 'button', name = tab_button_name, caption = 'Welcome'}
            return button
        end,
        content = function(parent, player)
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
Redmew is community for players of all skill levels committed to pushing the limits of Factorio
Multiplayer through custom scripts and crazy map designs.

We are a friendly bunch, our objective is to have as much fun as possible and we hope you
will too.
]]
            )

            header_label(parent, 'Useful Links')
            centered_label(parent, [[
Check out our discord for new map info and to suggest new maps / ideas.]])
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
            local maps_textbox =
                maps_textbox_flow.add {type = 'text-box', text = 'https://factoriomaps.com/browse/redmew.html '}
            maps_textbox.read_only = true

            parent.add({type = 'flow'}).style.height = 24

            header_label(parent, 'How To Chat')
            centered_label(
                parent,
                [[
To chat with other players, press the "grave" key on your keyboard. It is below the ESC key on
English keyboards and looks like ~ or `
This can be changed in options -> controls -> "toggle lua console".
]]
            )
        end
    },
    {
        tab_button = function(parent, player)
            local button = parent.add {type = 'button', name = tab_button_name, caption = 'Rules'}
            return button
        end,
        content = function(parent, player)
            header_label(parent, 'Rules')

            centered_label(
                parent,
                [[
Have fun and play nice. Remember we are all just here to have fun so let’s keep it that way.

No hateful content or personal attacks.

If you suspect someone is griefing, notify the admin team by using /report or by clicking the report
button next to the player in the player list.]]
            )
        end
    },
    {
        tab_button = function(parent, player)
            local button = parent.add {type = 'button', name = tab_button_name, caption = 'Scenario Mods'}
            return button
        end,
        content = function(parent, player)
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

            header_label(parent, 'Soft Mods and Server Plugins')

            local grid = parent.add {type = 'table', column_count = 3}
            local grid_style = grid.style
            grid_style.vertical_spacing = 24
            grid_style.horizontal_spacing = 8
            grid_style.top_padding = 8
            grid_style.bottom_padding = 16

            grid.add {type = 'label'}
            local ranks = grid.add {type = 'label', caption = 'Ranks'}
            ranks.style.font = 'default-listbox'
            local ranks_flow = grid.add {type = 'flow', direction = 'vertical'}
            local ranks_label =
                ranks_flow.add {
                type = 'label',
                caption = [[
We have a basic rank system to prevent griefing. You can't use nukes or the
deconstruction planner if you are a guest. If you play for a couple of hours an
admin will promote you to regular. You may also ask an admin for a promotion if
you're working on a project which requires it.]]
            }
            local ranks_label_style = ranks_label.style
            ranks_label_style.single_line = false
            local player_rank_flow = ranks_flow.add {type = 'flow', direction = 'horizontal'}
            player_rank_flow.add {type = 'label', caption = 'Your rank is:'}
            if player.admin then
                local label = player_rank_flow.add {type = 'label', caption = 'Admin'}
                label.style.font_color = rank_colors[4]
            elseif UserGroups.is_donator(player.name) then
                local label = player_rank_flow.add {type = 'label', caption = 'Donator'}
                label.style.font_color = rank_colors[3]
            elseif UserGroups.is_regular(player.name) then
                local label = player_rank_flow.add {type = 'label', caption = 'Regular'}
                label.style.font_color = rank_colors[2]
            else
                local label = player_rank_flow.add {type = 'label', caption = 'Guest'}
                label.style.font_color = rank_colors[1]
            end

            grid.add {type = 'sprite', sprite = 'entity/market'}
            local market = grid.add {type = 'label', caption = 'Market'}
            market.style.font = 'default-listbox'
            local market_label =
                grid.add {
                type = 'label',
                caption = [[
On most maps you will find a market near spawn where you can use coins to
make purchases. Coins are acquired by chopping trees, hand crafting items and
destroying biter nests. Most items in the market are constant but some are
map-specific (usually landfill) and will rotate in and out from time to time.]]
            }
            market_label.style.single_line = false

            grid.add {type = 'sprite', sprite = 'entity/player'}
            local player_list = grid.add {type = 'label', caption = 'Player list'}
            player_list.style.font = 'default-listbox'
            local player_list_label =
                grid.add {
                type = 'label',
                caption = [[
Lists all players on the server and shows some stats. You can sort the list by
clicking on the column headers. You can also poke people, which throws a random
noun in the chat.]]
            }
            player_list_label.style.single_line = false

            grid.add {type = 'sprite', sprite = 'item/programmable-speaker'}
            local poll = grid.add {type = 'label', caption = 'Polls'}
            poll.style.font = 'default-listbox'
            local poll_label =
                grid.add {
                type = 'label',
                caption = [[
Polls help players get consensus for major actions. Want to improve an important
build? Make a poll to check everyone is ok with that. You need to be a regular
to make new polls.]]
            }
            poll_label.style.single_line = false

            local tag_button = grid.add {type = 'label', caption = 'tag'}
            local tag_button_style = tag_button.style
            tag_button_style.font = 'default-listbox'
            tag_button_style.font_color = {r = 0, g = 0, b = 0}
            local tag = grid.add {type = 'label', caption = 'Tags'}
            tag.style.font = 'default-listbox'
            local tag_label =
                grid.add {
                type = 'label',
                caption = [[
You can assign yourself a role with tags to let other players know what you are
doing. Or just use the tag as decoration. Regulars can create new custom tags,
be sure to show off your creatively.]]
            }
            tag_label.style.single_line = false

            grid.add {type = 'sprite', sprite = 'item/repair-pack'}
            local task = grid.add {type = 'label', caption = 'Tasks'}
            task.style.font = 'default-listbox'
            local task_label =
                grid.add {
                type = 'label',
                caption = [[
Not sure what you should be working on, why not look at the tasks and see what
needs doing. Regulars can add new tasks.]]
            }
            task_label.style.single_line = false

            grid.add {type = 'sprite', sprite = 'item/blueprint'}
            local blueprint = grid.add {type = 'label', caption = 'Blueprint\nhelper'}
            local blueprint_style = blueprint.style
            blueprint_style.font = 'default-listbox'
            blueprint_style.single_line = false
            blueprint_style.width = 64
            local blueprint_label =
                grid.add {
                type = 'label',
                caption = [[
The Blueprint helper™ lets you flip blueprints horizontally or vertically and lets you
converter the entities used in the blueprint e.g. turn yellow belts into red belts.]]
            }
            blueprint_label.style.single_line = false

            grid.add {type = 'sprite', sprite = 'item/rocket-silo'}
            local score = grid.add {type = 'label', caption = 'Score'}
            score.style.font = 'default-listbox'
            local score_label =
                grid.add {
                type = 'label',
                caption = [[
Shows number of rockets launched and biters liberated.]]
            }
            score_label.style.single_line = false
        end
    },
    {
        tab_button = function(parent, player)
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
    {
        tab_button = function(parent, player)
            local button = parent.add {type = 'button', name = tab_button_name, caption = "What's New"}
            return button
        end,
        content = function(parent, player)
            local read_only = not player.admin

            header_label(parent, 'New Scenario Features')

            local new_info_flow = parent.add {type = 'flow'}
            new_info_flow.style.align = 'center'

            local new_info_textbox =
                new_info_flow.add {
                type = 'text-box',
                name = editable_textbox_name,
                text = editable_info[new_info_key]
            }
            new_info_textbox.read_only = read_only

            local new_info_textbox_style = new_info_textbox.style
            new_info_textbox_style.width = 590
            new_info_textbox_style.height = 150

            Gui.set_data(new_info_textbox, new_info_key)

            centered_label(
                parent,
                [[
Help us maintain the servers and develop new features by contributing to our Patreon.
Our donators will receive special perks.]]
            )

            local patreon_flow = parent.add {type = 'flow', direction = 'horizontal'}
            local patreon_flow_style = patreon_flow.style
            patreon_flow_style.align = 'center'
            patreon_flow_style.horizontally_stretchable = true

            patreon_flow.add({type = 'label', caption = 'Patreon:'}).style.font = 'default-bold'
            local patreon_textbox = patreon_flow.add {type = 'text-box', text = 'patreon.com/redmew '}
            patreon_textbox.read_only = true

            centered_label(
                parent,
                [[
Suggest new maps / features and see what we are working on by joining our discord.]]
            )

            local discord_flow = parent.add {type = 'flow', direction = 'horizontal'}
            local discord_flow_style = discord_flow.style
            discord_flow_style.align = 'center'
            discord_flow_style.horizontally_stretchable = true

            discord_flow.add({type = 'label', caption = 'Discord:'}).style.font = 'default-bold'
            local discord_textbox = discord_flow.add {type = 'text-box', text = 'redmew.com/discord '}
            discord_textbox.read_only = true
        end
    },
    {
        tab_button = function(parent, player)
            local button = parent.add {type = 'button', name = tab_button_name, caption = 'Other Servers'}
            return button
        end,
        content = function(parent, player)
            header_label(parent, 'Other Servers')

            centered_label(
                parent,
                [[

We also host a modded server.

Check out the modded channel on our discord for details.]]
            )

            local discord_flow = parent.add {type = 'flow', direction = 'horizontal'}
            local discord_flow_style = discord_flow.style
            discord_flow_style.align = 'center'
            discord_flow_style.horizontally_stretchable = true

            discord_flow.add({type = 'label', caption = 'Discord:'}).style.font = 'default-bold'
            local discord_textbox = discord_flow.add {type = 'text-box', text = 'redmew.com/discord '}
            discord_textbox.read_only = true
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

function Public.get_map_name()
    return editable_info[map_name_key]
end

function Public.set_map_name(value)
    editable_info[map_name_key] = value
end

function Public.get_map_description()
    return editable_info[map_description_key]
end

function Public.set_map_description(value)
    editable_info[map_description_key] = value
end

function Public.get_map_extra_info()
    return editable_info[map_extra_info_key]
end

function Public.set_map_extra_info(value)
    editable_info[map_extra_info_key] = value
end

function Public.get_new_info()
    return editable_info[new_info_key]
end

function Public.set_new_info(value)
    editable_info[new_info_key] = value
end

return Public
