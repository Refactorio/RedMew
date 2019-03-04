local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Event = require 'utils.event'
local Donator = require 'features.donator'
local Rank = require 'features.rank_system'
local Game = require 'utils.game'
local PlayerRewards = require 'utils.player_rewards'
local Server = require 'features.server'
local Token = require 'utils.token'
local Color = require 'resources.color_presets'

local format = string.format

local config = global.config
local config_mapinfo = config.map_info
local config_prewards = config.player_rewards

local normal_color = Color.white
local focus_color = Color.dark_orange
local unfocus_color = Color.black

local reward_amount = 2
local reward_token = PlayerRewards.get_reward()
local info_tab_flags = {
    0x1, -- welcome
    0x2, -- rules
    0x4, -- map_info
    0x8, -- scenario_mods
    0x10 -- whats_new
}
local flags_sum = 0
for _, v in pairs(info_tab_flags) do
    flags_sum = flags_sum + v
end

local map_name_key = 1
local map_description_key = 2
local map_extra_info_key = 3
local new_info_key = 4

local rewarded_players = {}
local primitives = {
    map_extra_info_lock = nil,
    info_edited = nil
}

local editable_info = {
    [map_name_key] = config_mapinfo.map_name_key,
    [map_description_key] = config_mapinfo.map_description_key,
    [map_extra_info_key] = config_mapinfo.map_extra_info_key,
    [new_info_key] = config_mapinfo.new_info_key
}

Global.register(
    {
        rewarded_players = rewarded_players,
        editable_info = editable_info,
        primitives = primitives
    },
    function(tbl)
        rewarded_players = tbl.rewarded_players
        editable_info = tbl.editable_info
        primitives = tbl.primitives
    end
)

--- Sets the "new info" according to the changelog located on the server
local function process_changelog(data)
    local key = data.key
    if key ~= 'changelog' then
        return
    end

    local value = data.value -- will be nil if no data
    if value then
        editable_info[new_info_key] = value
    end
end

local changelog_callback = Token.register(process_changelog)

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
    flow_style.horizontal_align = 'center'
    flow_style.horizontally_stretchable = true

    local label = flow.add {type = 'label', caption = string}
    local label_style = label.style
    label_style.horizontal_align = 'center'
    label_style.single_line = false

    return label
end

local function header_label(parent, string)
    local flow = parent.add {type = 'flow'}
    local flow_style = flow.style
    flow_style.horizontal_align = 'center'
    flow_style.horizontally_stretchable = true

    local label = flow.add {type = 'label', caption = string}
    local label_style = label.style
    label_style.horizontal_align = 'center'
    label_style.single_line = false
    label_style.font = 'default-dialog-button'

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
            parent_style.right_padding = 0
            parent_style.left_padding = 0
            parent_style.top_padding = 1

            parent =
                parent.add {
                type = 'scroll-pane',
                vertical_scroll_policy = 'auto-and-reserve-space',
                horizontal_scroll_policy = 'never'
            }
            parent_style = parent.style
            parent_style.vertically_stretchable = false

            header_label(parent, {'info.welcome_header'})
            centered_label(parent, {'info.welcome_text'})

            header_label(parent, {'info.chatting_header'})
            centered_label(parent, {'info.chatting_text', {'gui-menu.settings'}, {'gui-menu.controls'}, {'controls.toggle-console'}})

            if config_prewards.enabled and config_prewards.info_player_reward then
                header_label(parent, {'info.free_coin_header'})
                centered_label(parent, {'info.free_coin_text', reward_amount, reward_token, reward_amount, reward_token})
            end

            header_label(parent, {'info.links_header'})
            centered_label(parent, {'info.links_discord'})
            local discord_textbox_flow = parent.add {type = 'flow'}
            local discord_textbox_flow_style = discord_textbox_flow.style
            discord_textbox_flow_style.horizontal_align = 'center'
            discord_textbox_flow_style.horizontally_stretchable = true
            discord_textbox_flow.add({type = 'label', caption = 'Discord: '}).style.font = 'default-bold'
            local discord_textbox = discord_textbox_flow.add {type = 'text-box', text = 'https://www.redmew.com/discord '}
            discord_textbox.read_only = true
            discord_textbox.style.width = 235
            discord_textbox.style.height = 28
            centered_label(parent, {'info.links_patreon'})
            local patreon_flow = parent.add {type = 'flow', direction = 'horizontal'}
            local patreon_flow_style = patreon_flow.style
            patreon_flow_style.horizontal_align = 'center'
            patreon_flow_style.horizontally_stretchable = true
            patreon_flow.add({type = 'label', caption = 'Patreon:'}).style.font = 'default-bold'
            local patreon_textbox = patreon_flow.add {type = 'text-box', text = 'https://www.patreon.com/redmew '}
            patreon_textbox.read_only = true
            patreon_textbox.style.width = 235
            patreon_textbox.style.height = 28
            centered_label(parent, {'info.links_saves'})
            local save_textbox_flow = parent.add {type = 'flow'}
            local save_textbox_flow_style = save_textbox_flow.style
            save_textbox_flow_style.horizontal_align = 'center'
            save_textbox_flow_style.horizontally_stretchable = true
            save_textbox_flow.add({type = 'label', caption = 'Saves: '}).style.font = 'default-bold'
            local save_textbox = save_textbox_flow.add {type = 'text-box', text = 'http://www.redmew.com/saves/ '}
            save_textbox.read_only = true
            save_textbox.style.width = 235
            save_textbox.style.height = 28
            centered_label(parent, {'info.links_factoriomaps'})
            local maps_textbox_flow = parent.add {type = 'flow'}
            local maps_textbox_flow_style = maps_textbox_flow.style
            maps_textbox_flow_style.horizontal_align = 'center'
            maps_textbox_flow_style.horizontally_stretchable = true
            maps_textbox_flow.add({type = 'label', caption = 'Maps: '}).style.font = 'default-bold'
            local maps_textbox = maps_textbox_flow.add {type = 'text-box', text = 'https://factoriomaps.com/browse/redmew.html '}
            maps_textbox.read_only = true
            maps_textbox.style.width = 315
            maps_textbox.style.height = 28

            parent.add({type = 'flow'}).style.height = 24
        end
    },
    {
        tab_button = function(parent)
            local button = parent.add {type = 'button', name = tab_button_name, caption = 'Rules'}
            return button
        end,
        content = function(parent)
            local parent_style = parent.style
            parent_style.right_padding = 0
            parent_style.left_padding = 0
            parent_style.top_padding = 1

            parent =
                parent.add {
                type = 'flow',
                direction = 'vertical'
            }
            parent_style = parent.style
            parent_style.vertically_stretchable = false
            parent_style.width = 600

            header_label(parent, {'info.rules_header'})

            centered_label(parent, {'info.rules_text'})
        end
    },
    {
        tab_button = function(parent)
            local button = parent.add {type = 'button', name = tab_button_name, caption = {'info.map_info_button'}}
            return button
        end,
        content = function(parent, player)
            local read_only = not player.admin
            local text_width = 490

            local top_flow = parent.add {type = 'flow'}
            local top_flow_style = top_flow.style
            top_flow_style.horizontal_align = 'center'
            top_flow_style.horizontally_stretchable = true

            local top_label = top_flow.add {type = 'label', caption = {'info.map_info_header'}}
            local top_label_style = top_label.style
            top_label_style.font = 'default-dialog-button'

            local grid = parent.add {type = 'table', column_count = 2}
            local grid_style = grid.style
            grid_style.horizontally_stretchable = true

            grid.add {type = 'label', caption = {'info.map_name_label'}}
            local map_name_textbox =
                grid.add({type = 'flow'}).add {
                type = 'text-box',
                name = editable_textbox_name,
                text = editable_info[map_name_key]
            }
            map_name_textbox.read_only = read_only
            --map_name_textbox.word_wrap = true

            local map_name_textbox_style = map_name_textbox.style
            map_name_textbox_style.width = text_width
            map_name_textbox_style.maximal_height = 30

            Gui.set_data(map_name_textbox, map_name_key)

            grid.add {type = 'label', caption = {'info.map_desc_label'}}
            local map_description_textbox =
                grid.add({type = 'flow'}).add {
                type = 'text-box',
                name = editable_textbox_name,
                text = editable_info[map_description_key]
            }
            map_description_textbox.read_only = read_only
            --map_description_textbox.word_wrap = true

            local map_description_textbox_style = map_description_textbox.style
            map_description_textbox_style.width = text_width
            map_description_textbox_style.minimal_height = 80
            map_description_textbox_style.vertically_stretchable = true
            map_description_textbox_style.maximal_height = 100

            Gui.set_data(map_description_textbox, map_description_key)

            grid.add {type = 'label', caption = {'info.map_extra_info_label'}}
            local map_extra_info_textbox =
                grid.add({type = 'flow'}).add {
                type = 'text-box',
                name = editable_textbox_name,
                text = editable_info[map_extra_info_key]
            }
            map_extra_info_textbox.read_only = read_only
            --map_extra_info_textbox.word_wrap = true

            local map_extra_info_textbox_style = map_extra_info_textbox.style
            map_extra_info_textbox_style.width = text_width
            map_extra_info_textbox_style.height = 210

            Gui.set_data(map_extra_info_textbox, map_extra_info_key)
        end
    },
    {
        tab_button = function(parent)
            local button = parent.add {type = 'button', name = tab_button_name, caption = {'info.softmods_button'}}
            return button
        end,
        content = function(parent, player)
            local parent_style = parent.style
            parent_style.right_padding = 0
            parent_style.left_padding = 0
            parent_style.top_padding = 1

            parent =
                parent.add {
                type = 'scroll-pane',
                vertical_scroll_policy = 'auto-and-reserve-space',
                horizontal_scroll_policy = 'never'
            }
            parent_style = parent.style
            parent_style.vertically_stretchable = true

            header_label(parent, {'info.softmods_header'})

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
                caption = {'info.softmods_rank_text'}
            }
            local ranks_label_style = ranks_label.style
            ranks_label_style.single_line = false
            local player_rank_flow = ranks_flow.add {type = 'flow', direction = 'horizontal'}
            player_rank_flow.add {type = 'label', caption = {'info.softmods_rank_is'}}
            local player_name = player.name

            local rank_label = player_rank_flow.add {type = 'label', caption = Rank.get_player_rank_name(player_name)}
            rank_label.style.font_color = Rank.get_player_rank_color(player_name)

            if Donator.is_donator(player_name) then
                local donator_label = player_rank_flow.add {type = 'label', caption = {'ranks.donator'}}
                donator_label.style.font_color = Color.donator
            end

            grid.add {type = 'sprite', sprite = 'entity/market'}
            local market = grid.add {type = 'label', caption = {'info.softmods_market_label'}}
            market.style.font = 'default-listbox'
            local market_label =
                grid.add {
                type = 'label',
                caption = {'info.softmods_market_text'}
            }
            market_label.style.single_line = false

            grid.add {type = 'sprite', sprite = 'item/small-plane'}
            local train_savior = grid.add {type = 'label', caption = {'info.softmods_saviour_label'}}
            local train_savior_style = train_savior.style
            train_savior_style.font = 'default-listbox'
            train_savior_style.single_line = false
            local train_savior_label =
                grid.add {
                type = 'label',
                caption = {'info.softmods_saviour_text'}
            }
            train_savior_label.style.single_line = false

            if config.player_list.enabled then
                grid.add {type = 'sprite', sprite = 'entity/player'}
                local player_list = grid.add {type = 'label', caption = {'info.softmods_plist_label'}}
                player_list.style.font = 'default-listbox'
                player_list.style.single_line = false
                local player_list_label =
                    grid.add {
                    type = 'label',
                    caption = {'info.softmods_plist_text'}
                }
                player_list_label.style.single_line = false
            end
            if config.poll.enabled then
                grid.add {type = 'sprite', sprite = 'item/programmable-speaker'}
                local poll = grid.add {type = 'label', caption = {'info.softmods_polls_label'}}
                poll.style.font = 'default-listbox'
                local poll_label =
                    grid.add {
                    type = 'label',
                    caption = {'info.softmods_polls_text'}
                }
                poll_label.style.single_line = false
            end

            if config.tag_group.enabled then
                local tag_button = grid.add {type = 'label', caption = 'tag'}
                local tag_button_style = tag_button.style
                tag_button_style.font = 'default-listbox'
                tag_button_style.font_color = Color.black
                local tag = grid.add {type = 'label', caption = {'info.softmods_tags_label'}}
                tag.style.font = 'default-listbox'
                local tag_label =
                    grid.add {
                    type = 'label',
                    caption = {'info.softmods_tags_text'}
                }
                tag_label.style.single_line = false
            end

            if config.tasklist.enabled then
                grid.add {type = 'sprite', sprite = 'item/repair-pack'}
                local task = grid.add {type = 'label', caption = {'info.softmods_tasks_label'}}
                task.style.font = 'default-listbox'
                local task_label =
                    grid.add {
                    type = 'label',
                    caption = {'info.softmods_tasks_text'}
                }
                task_label.style.single_line = false
            end

            if config.blueprint_helper.enabled then
                grid.add {type = 'sprite', sprite = 'item/blueprint'}
                local blueprint = grid.add {type = 'label', caption = {'info.softmods_bp_label'}}
                local blueprint_style = blueprint.style
                blueprint_style.font = 'default-listbox'
                blueprint_style.single_line = false
                blueprint_style.width = 55
                local blueprint_label =
                    grid.add {
                    type = 'label',
                    caption = {'info.softmods_bp_text'}
                }
                blueprint_label.style.single_line = false
            end

            if config.score.enabled then
                grid.add {type = 'sprite', sprite = 'item/rocket-silo'}
                local score = grid.add {type = 'label', caption = {'info.softmods_score_label'}}
                score.style.font = 'default-listbox'
                local score_label =
                    grid.add {
                    type = 'label',
                    caption = {'info.softmods_score_text'}
                }
                score_label.style.single_line = false
            end
        end
    },
    {
        tab_button = function(parent)
            local button = parent.add {type = 'button', name = tab_button_name, caption = {'info.whats_new_button'}}
            return button
        end,
        content = function(parent, player)
            local read_only = not player.admin

            header_label(parent, 'New Features')

            local new_info_flow = parent.add {name = 'whatsNew_new_info_flow', type = 'flow'}
            new_info_flow.style.horizontal_align = 'center'

            local new_info_textbox =
                new_info_flow.add {
                type = 'text-box',
                name = editable_textbox_name,
                text = editable_info[new_info_key]
            }
            new_info_textbox.read_only = read_only

            local new_info_textbox_style = new_info_textbox.style
            new_info_textbox_style.width = 600
            new_info_textbox_style.height = 360
            new_info_textbox_style.left_margin = 2

            Gui.set_data(new_info_textbox, new_info_key)
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
    top_flow_style.horizontal_align = 'center'
    top_flow_style.top_padding = 8
    top_flow_style.horizontally_stretchable = true

    local title_grid = top_flow.add {type = 'table', column_count = title_max}
    for _, row in ipairs(title) do
        for _, char in ipairs(row) do
            local ele
            if char then
                ele = title_grid.add {type = 'sprite', sprite = 'virtual-signal/signal-red'}
                ele.style.stretch_image_to_widget_size = true
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
    tab_flow_style.horizontal_align = 'center'
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
    bottom_flow_style.horizontal_align = 'center'
    bottom_flow_style.top_padding = 8
    bottom_flow_style.horizontally_stretchable = true

    bottom_flow.add {type = 'button', name = main_button_name, caption = {'common.close_button'}}

    player.opened = frame
end

local function reward_player(player, index, message)
    if not config_prewards.enabled or not config_prewards.info_player_reward then
        return
    end

    local player_index = player.index
    if not rewarded_players[player_index] then
        error('Player with no entry in rewarded_players table')
        return false
    end
    local tab_flag = info_tab_flags[index]

    if bit32.band(rewarded_players[player_index], tab_flag) == tab_flag then
        return
    else
        PlayerRewards.give_reward(player, reward_amount, message)
        rewarded_players[player_index] = rewarded_players[player_index] + tab_flag
        if rewarded_players[player_index] == flags_sum then
            rewarded_players[player_index] = nil
        end
    end
end

--- Uploads the contents of new info tab to the server.
-- Is triggered on closing the info window by clicking the close button or by pressing escape.
local function upload_changelog(event)
    local player = event.player
    if not player or not player.valid or not player.admin then
        return
    end

    if editable_info[new_info_key] ~= config_mapinfo.new_info_key and primitives.info_edited then
        Server.set_data('misc', 'changelog', editable_info[new_info_key])
        primitives.info_edited = nil
    end
end

--- Tries to download the latest changelog
local function download_changelog()
    Server.try_get_data('misc', 'changelog', changelog_callback)
end

local function toggle(event)
    local player = event.player
    local center = player.gui.center
    local main_frame = center[main_frame_name]

    if main_frame then
        upload_changelog(event)
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
    gui.top.add {type = 'sprite-button', name = main_button_name, sprite = 'virtual-signal/signal-info'}

    rewarded_players[player.index] = 0
    reward_player(player, info_tab_flags[1])
end

--- Sets editable_info[map_extra_info_key] outright or adds info to it.
-- Forbids map_extra_info being explicitly set twice
local function create_map_extra_info(value, set)
    if primitives.map_extra_info_lock and set then
        error('Cannot set extra info twice, use add instead')
        return
    elseif primitives.map_extra_info_lock then
        return
    elseif set then
        editable_info[map_extra_info_key] = value
        primitives.map_extra_info_lock = true
    elseif editable_info[map_extra_info_key] == config_mapinfo.map_extra_info_key then
        editable_info[map_extra_info_key] = value
    else
        editable_info[map_extra_info_key] = format('%s\n%s', editable_info[map_extra_info_key], value)
    end
end

Event.add(defines.events.on_player_created, player_created)

Event.add(Server.events.on_server_started, download_changelog)

Server.on_data_set_changed('misc', process_changelog)

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

        old_button.style.font_color = unfocus_color
        button.style.font_color = focus_color

        data.active_tab = index

        local content = data.content
        Gui.clear(content)

        pages[index].content(content, player)
        if rewarded_players[player.index] then
            reward_player(player, index, {'info.free_coin_print', reward_amount, reward_token})
        end
    end
)

Gui.on_text_changed(
    editable_textbox_name,
    function(event)
        local textbox = event.element
        local key = Gui.get_data(textbox)

        editable_info[key] = textbox.text
        primitives.info_edited = true
    end
)

Gui.on_custom_close(
    main_frame_name,
    function(event)
        upload_changelog(event)
        Gui.destroy(event.element)
    end
)

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

local Public = {}

function Public.show_info(player)
    toggle({player = player})
end

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

--- Adds to existing map_extra_info. Removes default text if it is the only text in place.
function Public.add_map_extra_info(value)
    create_map_extra_info(value, false)
end

--- Overrides all info added via add_map_extra_info.
-- This should only be used in maps, never in features/modules.
-- Use case: for maps that know exactly what features they're using and
-- want full control over the info presented.
function Public.set_map_extra_info(value)
    create_map_extra_info(value, true)
end

function Public.get_new_info()
    return editable_info[new_info_key]
end

function Public.set_new_info(value)
    editable_info[new_info_key] = value
end

return Public
