local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Rank = require 'features.rank_system'
local Game = require 'utils.game'
local Command = require 'utils.command'
local Ranks = require 'resources.ranks'
local tag_groups = require 'resources.tag_groups'
local Settings = require 'utils.redmew_settings'
local LocaleBuilder = require 'utils.locale_builder'
local table = require 'utils.table'
local concat = table.concat

local notify_name = 'notify_tag_group'
Settings.register(notify_name, Settings.types.boolean, true, 'tag_group.notify_caption_short')

local default_join_message = '{tag} has expanded with {player}'
local default_leave_message = '{player} has left the {tag} squad'
local player_tags = {}
local no_notify_players = {}

Global.register(
    {tag_groups = tag_groups, player_tags = player_tags, no_notify_players = no_notify_players},
    function(tbl)
        tag_groups = tbl.tag_groups
        player_tags = tbl.player_tags
        no_notify_players = tbl.no_notify_players
    end
)

local function notify_players(message)
    local players = game.connected_players
    for i = 1, #players do
        local p = players[i]
        if p.valid and not no_notify_players[p.index] then
            p.print(message)
        end
    end
end

local function change_player_tag(player, tag_name, silent)
    local old_tag = player.tag
    if tag_name == '' and old_tag == '' then
        return false
    end

    local tag = '[' .. tag_name .. ']'
    if old_tag == tag then
        return false
    end

    if old_tag ~= '' then
        local players = player_tags[old_tag]
        if players then
            players[player.index] = nil
        end
    end

    if tag_name == '' then
        player.tag = ''
        if not silent then
            local old_tag_name = old_tag:sub(2, -2)
            local old_tag_data = tag_groups[old_tag_name]
            if old_tag_data then
                local leave_message = old_tag_data.leave_message or default_leave_message
                leave_message = leave_message:gsub('{tag}', old_tag):gsub('{player}', player.name)
                notify_players(leave_message)
            end
        end
        return true
    end

    local tag_data = tag_groups[tag_name]
    if not tag_data then
        return false
    end

    local players = player_tags[tag]
    if not players then
        players = {}
        player_tags[tag] = players
    end

    players[player.index] = true

    player.tag = tag

    local join_message = tag_data.join_message or default_join_message
    join_message = join_message:gsub('{tag}', tag):gsub('{player}', player.name)

    if not silent then
        notify_players(join_message)
    end
    return true
end

local function get_size(players, show_offline)
    local size = 0

    if not players then
        return ''
    end

    if show_offline then
        size = table.size(players)
    else
        for pi, _ in pairs(players) do
            local player = game.get_player(pi)
            if player and player.valid and player.connected then
                size = size + 1
            end
        end
    end

    if size == 0 then
        return ''
    else
        return ' (' .. size .. ')'
    end
end

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local main_frame_content_name = Gui.uid_name()
local tag_button_name = Gui.uid_name()
local tag_label_name = Gui.uid_name()
local clear_button_name = Gui.uid_name()
local create_tag_button_name = Gui.uid_name()
local edit_tag_button_name = Gui.uid_name()
local notify_checkbox_name = Gui.uid_name()

local create_tag_frame_name = Gui.uid_name()
local create_tag_choose_icon_name = Gui.uid_name()
local create_tag_icon_type_name = Gui.uid_name()
local confirm_create_tag_name = Gui.uid_name()
local delete_tag_name = Gui.uid_name()
local close_create_tag_name = Gui.uid_name()

local function player_joined(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    if player.gui.top[main_button_name] ~= nil then
        return
    end

    player.gui.top.add(
        {
            name = main_button_name,
            type = 'sprite-button',
            caption = 'tag',
            tooltip = {'tag_group.tooltip'}
        }
    )
end

local function draw_main_frame_content(parent)
    local player = parent.gui.player
    local grid = parent.add {type = 'table', column_count = 1}
    grid.style.vertical_spacing = 0

    local can_edit = Rank.equal_or_greater_than(player.name, Ranks.regular)

    for tag_name, tag_data in pairs(tag_groups) do
        local tag = '[' .. tag_name .. ']'
        local players = player_tags[tag]

        local size = get_size(players)
        local path = tag_data.path

        local row = grid.add {type = 'table', column_count = 4}
        row.style.horizontal_spacing = 0

        if can_edit then
            local edit_button =
                row.add {
                type = 'sprite-button',
                name = edit_tag_button_name,
                sprite = 'utility/rename_icon_normal',
                tooltip = {'tag_group.edit_group'}
            }
            edit_button.style.top_padding = 0
            edit_button.style.bottom_padding = 0
            edit_button.style.maximal_height = 32
            Gui.set_data(edit_button, tag_name)
        end

        local tag_button =
            row.add {
            type = 'sprite-button',
            name = tag_button_name,
            sprite = path,
            tooltip = tag_name
        }

        tag_button.style.maximal_height = 32
        Gui.set_data(tag_button, tag_name)

        local tag_label = row.add {type = 'label', name = tag_label_name, caption = tag_name .. size}
        tag_label.style.left_padding = 4
        tag_label.style.minimal_width = 120
        Gui.set_data(tag_label, {tag_name = tag_name, path = path})

        local list = row.add {type = 'flow', direction = 'horizontal'}

        if players then
            for k, _ in pairs(players) do
                local p = game.get_player(k)
                if p and p.valid and p.connected then
                    local color = {r = 0.4 + 0.6 * p.color.r, g = 0.4 + 0.6 * p.color.g, b = 0.4 + 0.6 * p.color.b}

                    local label = list.add {type = 'label', caption = game.get_player(k).name}
                    label.style.top_padding = 8
                    label.style.font_color = color
                end
            end
        end

        list.style.minimal_width = 100
    end
end

local function draw_main_frame(player)
    local left = player.gui.left
    local main_frame =
        left.add {
        type = 'frame',
        name = main_frame_name,
        caption = {'tag_group.choose_your_tag'},
        direction = 'vertical'
    }

    main_frame.style.maximal_height = 500
    main_frame.style.maximal_width = 500
    main_frame.style.minimal_width = 320

    local scroll_pane =
        main_frame.add {
        type = 'scroll-pane',
        name = main_frame_content_name,
        vertical_scroll_policy = 'always'
    }

    scroll_pane.style.horizontally_stretchable = true
    scroll_pane.style.right_padding = 0

    draw_main_frame_content(scroll_pane)

    local state = Settings.get(player.index, notify_name)
    local notify_checkbox =
        main_frame.add {
        type = 'checkbox',
        name = notify_checkbox_name,
        state = state,
        caption = {'tag_group.notify_caption'},
        tooltip = {'tag_group.notify_tooltip'}
    }

    local bottom_flow = main_frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow = bottom_flow.add {type = 'flow', direction = 'horizontal'}
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    left_flow.add {type = 'button', name = main_button_name, caption = {'common.close_button'}}

    local right_flow = bottom_flow.add {type = 'flow', direction = 'horizontal'}
    right_flow.style.horizontal_align = 'right'

    right_flow.add {type = 'button', name = clear_button_name, caption = {'tag_group.clear_tag'}}

    if Rank.equal_or_greater_than(player.name, Ranks.regular) then
        right_flow.add {type = 'button', name = create_tag_button_name, caption = {'tag_group.create_tag'}}
    end

    Gui.set_data(main_frame, notify_checkbox)
end

local function redraw_main_frame()
    for _, p in pairs(game.players) do
        local main_frame = p.gui.left[main_frame_name]
        if main_frame and main_frame.valid then
            local content = main_frame[main_frame_content_name]

            Gui.remove_data_recursively(content)
            content.clear()

            if p.connected then
                draw_main_frame_content(content)
            end
        end
    end
end

local function redraw_main_button(player, path)
    local main_button = player.gui.top[main_button_name]

    if path == '' or path == nil then
        main_button.sprite = 'utility/pump_cannot_connect_icon'
        main_button.caption = 'tag'
    else
        main_button.caption = ''
        main_button.sprite = path
    end
end

local function toggle(event)
    local player = event.player
    local gui = player.gui
    local left = gui.left
    local main_frame = left[main_frame_name]
    local main_button = gui.top[main_button_name]

    if main_frame then
        Gui.destroy(main_frame)
        main_button.style = 'icon_button'
    else
        draw_main_frame(event.player)

        main_button.style = 'selected_slot_button'
        local style = main_button.style
        style.width = 38
        style.height = 38
    end
end

local choices = {
    'tile',
    'item',
    'entity',
    'fluid',
    'signal',
    'recipe'
}

local function draw_create_tag_frame(event, tag_data)
    local name
    local join_message
    local leave_message
    local path
    local spirte_type
    local frame_caption
    local confirm_caption
    if tag_data then
        name = tag_data.name
        join_message = tag_data.join_message
        leave_message = tag_data.leave_message
        path = tag_data.path

        if path and path ~= '' then
            spirte_type, path = path:match('([^/]+)/([^/]+)')
            if spirte_type == 'virtual-signal' then
                spirte_type = 'signal'
                path = {type = 'virtual', name = path}
            end
        else
            spirte_type = choices[1]
            path = nil
        end

        frame_caption = {'tag_group.edit_tag_title'}
        confirm_caption = {'common.edit'}
    else
        name = ''
        join_message = default_join_message
        leave_message = default_leave_message
        spirte_type = choices[1]
        frame_caption = {'tag_group.create_tag_title'}
        confirm_caption = {'common.create'}
    end

    local player = event.player
    local center = player.gui.center

    local frame = center[create_tag_frame_name]
    if frame then
        Gui.remove_data_recursively(frame)
        frame.destroy()
    end

    frame = center.add({type = 'frame', name = create_tag_frame_name, caption = frame_caption, direction = 'vertical'})

    if tag_data then
        local text = LocaleBuilder.new({'common.created_by', tag_data.created_by or '<Server>'})

        local edited_by = tag_data.edited_by
        if edited_by then
            text = text:add(', '):add({'common.edited_by', concat(edited_by, ', ')})
        end

        frame.add({type = 'label', caption = text})
    end

    local main_table = frame.add {type = 'table', column_count = 2}

    main_table.add {type = 'label', caption = {'common.name'}}
    local name_field = main_table.add {type = 'textfield', text = name}
    Gui.set_data(name_field, frame)

    main_table.add {type = 'label', caption = {'common.icon'}}
    local icons_flow = main_table.add {type = 'flow', direction = 'horizontal'}
    local selection_flow = icons_flow.add {type = 'flow'}

    local focus
    for _, value in ipairs(choices) do
        local radio =
            selection_flow.add({type = 'flow'}).add {
            type = 'radiobutton',
            name = create_tag_icon_type_name,
            caption = value,
            state = value == spirte_type
        }

        if value == spirte_type then
            focus = radio
        end

        Gui.set_data(radio, frame)
    end

    local choose =
        icons_flow.add {
        type = 'choose-elem-button',
        name = create_tag_choose_icon_name,
        elem_type = spirte_type
    }

    if path then
        choose.elem_value = path
    end

    Gui.set_data(choose, frame)

    main_table.add {type = 'label', caption = {'tag_group.join_message'}}
    local join_message_field = main_table.add {type = 'textfield', text = join_message}
    join_message_field.style.minimal_width = 353
    Gui.set_data(join_message_field, frame)

    main_table.add {type = 'label', caption = {'tag_group.leave_message'}}
    local leave_message_field = main_table.add {type = 'textfield', text = leave_message}
    leave_message_field.style.minimal_width = 353
    Gui.set_data(leave_message_field, frame)

    local bottom_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow = bottom_flow.add {type = 'flow', direction = 'horizontal'}
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button =
        left_flow.add {type = 'button', name = close_create_tag_name, caption = {'common.close_button'}}
    Gui.set_data(close_button, frame)

    local right_flow = bottom_flow.add {type = 'flow', direction = 'horizontal'}
    right_flow.style.horizontal_align = 'right'

    if tag_data then
        local delete_button = right_flow.add {type = 'button', name = delete_tag_name, caption = {'common.delete'}}
        Gui.set_data(delete_button, frame)
    end

    local confirm_button = right_flow.add {type = 'button', name = confirm_create_tag_name, caption = confirm_caption}
    Gui.set_data(confirm_button, frame)

    local data = {
        focus = focus,
        choose = choose,
        icons_flow = icons_flow,
        name = name_field,
        join_message = join_message_field,
        leave_message = leave_message_field,
        tag_data = tag_data
    }
    Gui.set_data(frame, data)

    player.opened = frame
end

Gui.on_click(main_button_name, toggle)

Gui.on_click(
    tag_button_name,
    function(event)
        local tag_name = Gui.get_data(event.element)
        local path = event.element.sprite

        if change_player_tag(event.player, tag_name) then
            redraw_main_frame()
            redraw_main_button(event.player, path)
        end
    end
)

Gui.on_click(
    tag_label_name,
    function(event)
        local data = Gui.get_data(event.element)
        local tag_name = data.tag_name
        local path = data.path

        if change_player_tag(event.player, tag_name) then
            redraw_main_frame()
            redraw_main_button(event.player, path)
        end
    end
)

Gui.on_click(
    delete_tag_name,
    function(event)
        local frame = Gui.get_data(event.element)
        local data = Gui.get_data(frame)
        local tag_data = data.tag_data
        local tag_name = tag_data.name

        Gui.remove_data_recursively(frame)
        frame.destroy()

        if not tag_groups[tag_name] then
            event.player.print({'tag_group.tag_not_found', tag_name})
            return
        end

        local tag = '[' .. tag_name .. ']'

        for _, player in pairs(game.players) do
            if player.valid and player.tag == tag then
                change_player_tag(player, '')

                if player.connected then
                    redraw_main_button(player, '')
                end
            end
        end

        tag_groups[tag_name] = nil

        redraw_main_frame()

        notify_players({'tag_group.player_delete_tag_group', event.player.name, tag_name})
    end
)

Gui.on_click(
    edit_tag_button_name,
    function(event)
        local tag_name = Gui.get_data(event.element)

        local tag_data = tag_groups[tag_name]
        if not tag_data then
            event.player.print({'tag_group.tag_not_found', tag_name})
            return
        end

        tag_data.name = tag_name

        draw_create_tag_frame(event, tag_data)
    end
)

Gui.on_checked_state_changed(
    notify_checkbox_name,
    function(event)
        local player_index = event.player_index
        local checkbox = event.element
        local state = checkbox.state

        local no_notify
        if state then
            no_notify = nil
        else
            no_notify = true
        end

        no_notify_players[player_index] = no_notify
        Settings.set(player_index, notify_name, state)
    end
)

Gui.on_click(
    clear_button_name,
    function(event)
        if change_player_tag(event.player, '') then
            redraw_main_frame()
            redraw_main_button(event.player, '')
        end
    end
)

Gui.on_click(create_tag_button_name, draw_create_tag_frame)

Gui.on_click(
    create_tag_icon_type_name,
    function(event)
        local radio = event.element
        local frame = Gui.get_data(radio)
        local frame_data = Gui.get_data(frame)

        frame_data.focus.state = false
        radio.state = true
        frame_data.focus = radio

        local choose = frame_data.choose
        Gui.remove_data_recursively(choose)
        choose.destroy()

        choose =
            frame_data.icons_flow.add {
            type = 'choose-elem-button',
            name = create_tag_choose_icon_name,
            elem_type = radio.caption
        }

        frame_data.choose = choose
    end
)

Gui.on_click(
    confirm_create_tag_name,
    function(event)
        local player = event.player
        local frame = Gui.get_data(event.element)
        local data = Gui.get_data(frame)
        local old_tag_data = data.tag_data

        local tag_name = data.name.text

        if tag_name == '' then
            player.print({'tag_group.tag_needs_name'})
            return
        end

        if not old_tag_data and tag_groups[tag_name] then
            player.print({'tag_group.tag_name_already_in_use', tag_name})
            return
        end

        local type = data.focus.caption
        local sprite = data.choose.elem_value

        local path
        if not sprite or sprite == '' then
            path = nil
        elseif type == 'signal' then
            path = 'virtual-signal/' .. data.choose.elem_value.name
        else
            path = type .. '/' .. data.choose.elem_value
        end

        if path and not frame.gui.is_valid_sprite_path(path) then
            player.print({'tag_group.sprite_not_valid', path})
            return
        end

        local join_message = data.join_message.text
        if join_message == '' then
            join_message = default_join_message
        end

        local leave_message = data.leave_message.text
        if leave_message == '' then
            leave_message = default_leave_message
        end

        Gui.destroy(frame)

        local tag_data = {
            path = path,
            join_message = join_message,
            leave_message = leave_message,
            created_by = nil,
            edited_by = nil
        }

        if old_tag_data then
            tag_data.created_by = old_tag_data.created_by

            local edited_by = tag_data.edited_by
            if not edited_by then
                edited_by = {}
                tag_data.edited_by = edited_by
            end

            local name = player.name
            if not table.array_contains(edited_by, name) then
                edited_by[#edited_by + 1] = name
            end
        else
            tag_data.created_by = player.name
        end

        tag_groups[tag_name] = tag_data

        local print_message
        if old_tag_data then
            local old_name = old_tag_data.name
            if
                old_name == tag_name and old_tag_data.path == path and old_tag_data.join_message == join_message and
                    old_tag_data.leave_message == leave_message
             then
                return
            end

            if old_name ~= tag_name then
                print_message = {'tag_group.player_edit_tag_group_name_change', player.name, tag_name, old_name}

                local old_tag = '[' .. old_name .. ']'

                for _, p in pairs(game.players) do
                    if p.valid and p.tag == old_tag then
                        change_player_tag(p, tag_name, true)

                        if p.connected then
                            redraw_main_button(player, '')
                        end
                    end
                end

                tag_groups[old_name] = nil
            else
                print_message = {'tag_group.player_edit_tag_group', player.name, tag_name}
            end
        else
            print_message = {'tag_group.player_create_tag_group', player.name, tag_name}
        end

        redraw_main_frame()

        notify_players(print_message)
    end
)

Gui.on_click(
    close_create_tag_name,
    function(event)
        local frame = Gui.get_data(event.element)

        Gui.remove_data_recursively(frame)
        frame.destroy()
    end
)

Gui.on_custom_close(
    create_tag_frame_name,
    function(event)
        local element = event.element
        Gui.remove_data_recursively(element)
        element.destroy()
    end
)

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Event.add(
    Settings.events.on_setting_set,
    function(event)
        if event.setting_name ~= notify_name then
            return
        end

        local player_index = event.player_index
        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end

        local state = event.new_value
        local no_notify
        if state then
            no_notify = nil
        else
            no_notify = true
        end

        no_notify_players[player_index] = no_notify

        local frame = player.gui.left[main_frame_name]
        if not frame then
            return
        end

        local checkbox = Gui.get_data(frame)
        checkbox.state = state
    end
)

Event.add(defines.events.on_player_joined_game, player_joined)

local function tag_command(args)
    local target_player = game.players[args.player]

    if not target_player then
        Game.player_print({'common.fail_no_target', target_player})
        return
    end

    local tag_name = args.tag
    local tag = tag_groups[tag_name]

    if tag == nil then
        Game.player_print({'tag_group.tag_does_not_exist', tag_name})
        return
    end

    if change_player_tag(target_player, tag_name) then
        redraw_main_frame()
    else
        Game.player_print({'tag_group.player_already_has_tag', target_player.name, tag_name})
    end
end

Command.add(
    'tag',
    {
        description = {'command_description.tag'},
        arguments = {'player', 'tag'},
        required_rank = Ranks.admin,
        capture_excess_arguments = true,
        allowed_by_server = true
    },
    tag_command
)
