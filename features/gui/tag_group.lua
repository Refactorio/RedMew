local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Rank = require 'features.rank_system'
local Game = require 'utils.game'
local Command = require 'utils.command'
local Ranks = require 'resources.ranks'
local tag_groups = require 'resources.tag_groups'

local default_verb = 'expanded'
local player_tags = {}
local no_notify_players = {}

Global.register(
    {tag_groups = tag_groups, player_tags = player_tags, no_notify_players = no_notify_players},
    function(data)
        tag_groups = data.tag_groups
        player_tags = data.player_tags
        no_notify_players = data.no_notify_players
    end
)

local function notify_players(message)
    local players = game.connected_players
    for i=1, #players do
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
            notify_players(player.name .. ' has left the ' .. old_tag .. ' squad')
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

    local verb = tag_data.verb or default_verb

    if not silent then
        notify_players(tag .. ' squad has `' .. verb .. '` with ' .. player.name)
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
            local player = Game.get_player_by_index(pi)
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
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    if player.gui.top[main_button_name] ~= nil then
        return
    end

    player.gui.top.add {name = main_button_name, type = 'sprite-button', caption = 'tag'}
end

local function draw_main_frame_content(parent)
    local player = parent.gui.player
    local grid = parent.add {type = 'table', column_count = 1}
    grid.style.vertical_spacing = 0

    for tag_name, tag_data in pairs(tag_groups) do
        local tag = '[' .. tag_name .. ']'
        local players = player_tags[tag]

        local size = get_size(players)
        local path = tag_data.path

        local row = grid.add {type = 'table', column_count = 4}
        row.style.horizontal_spacing = 0

        if Rank.equal_or_greater_than(player.name, Ranks.regular) then
            local edit_button =
                row.add {
                type = 'sprite-button',
                name = edit_tag_button_name,
                sprite = 'utility/rename_icon_normal',
                tooltip = 'Edit tag group'
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
                local p = Game.get_player_by_index(k)
                if p and p.valid and p.connected then
                    local color = {r = 0.4 + 0.6 * p.color.r, g = 0.4 + 0.6 * p.color.g, b = 0.4 + 0.6 * p.color.b}

                    local label = list.add {type = 'label', caption = Game.get_player_by_index(k).name}
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
        left.add {type = 'frame', name = main_frame_name, caption = 'Choose your tag', direction = 'vertical'}

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

    main_frame.add {
        type = 'checkbox',
        name = notify_checkbox_name,
        caption = 'Notify me when tag groups change.',
        state = not no_notify_players[player.index],
        tooltip = 'Receive a message when a player enters or leaves a tag group or when a tag group is created, edited or deleted.'
    }

    local bottom_flow = main_frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow = bottom_flow.add {type = 'flow', direction = 'horizontal'}
    left_flow.style.horizontal_align  = 'left'
    left_flow.style.horizontally_stretchable = true

    left_flow.add {type = 'button', name = main_button_name, caption = 'Close'}

    local right_flow = bottom_flow.add {type = 'flow', direction = 'horizontal'}
    right_flow.style.horizontal_align  = 'right'

    right_flow.add {type = 'button', name = clear_button_name, caption = 'Clear Tag'}

    if Rank.equal_or_greater_than(player.name, Ranks.regular) then
        right_flow.add {type = 'button', name = create_tag_button_name, caption = 'Create Tag'}
    end
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
    local left = event.player.gui.left
    local main_frame = left[main_frame_name]

    if main_frame then
        Gui.remove_data_recursively(main_frame)
        main_frame.destroy()
    else
        draw_main_frame(event.player)
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
    local verb
    local path
    local spirte_type
    local frame_caption
    local confirm_caption
    if tag_data then
        name = tag_data.name
        verb = tag_data.verb
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

        frame_caption = 'Edit Tag'
        confirm_caption = 'Edit'
    else
        name = ''
        verb = 'expanded'
        spirte_type = choices[1]
        frame_caption = 'Create A New Tag'
        confirm_caption = 'Create'
    end

    local player = event.player
    local center = player.gui.center

    local frame = center[create_tag_frame_name]
    if frame then
        Gui.remove_data_recursively(frame)
        frame.destroy()
    end

    frame = center.add {type = 'frame', name = create_tag_frame_name, caption = frame_caption, direction = 'vertical'}

    local main_table = frame.add {type = 'table', column_count = 2}

    main_table.add {type = 'label', caption = 'Name'}
    local name_field = main_table.add {type = 'textfield', text = name}
    Gui.set_data(name_field, frame)

    main_table.add {type = 'label', caption = 'Icon'}
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

    main_table.add {type = 'label', caption = 'Verb'}
    local verb_field = main_table.add {type = 'textfield', text = verb}
    Gui.set_data(verb_field, frame)

    local bottom_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow = bottom_flow.add {type = 'flow', direction = 'horizontal'}
    left_flow.style.horizontal_align  = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add {type = 'button', name = close_create_tag_name, caption = 'Close'}
    Gui.set_data(close_button, frame)

    local right_flow = bottom_flow.add {type = 'flow', direction = 'horizontal'}
    right_flow.style.horizontal_align  = 'right'

    if tag_data then
        local delete_button = right_flow.add {type = 'button', name = delete_tag_name, caption = 'Delete'}
        Gui.set_data(delete_button, frame)
    end

    local confirm_button = right_flow.add {type = 'button', name = confirm_create_tag_name, caption = confirm_caption}
    Gui.set_data(confirm_button, frame)

    local data = {
        focus = focus,
        choose = choose,
        icons_flow = icons_flow,
        name = name_field,
        verb = verb_field,
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
            event.player.print("Sorry, Tag name '" .. tag_name .. "' not found.")
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

        notify_players(event.player.name .. ' has deleted the ' .. tag_name .. ' tag group')
    end
)

Gui.on_click(
    edit_tag_button_name,
    function(event)
        local tag_name = Gui.get_data(event.element)

        local tag_data = tag_groups[tag_name]
        if not tag_data then
            event.player.print("Sorry, Tag name '" .. tag_name .. "' not found.")
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

        local new_state
        if checkbox.state then
            new_state = nil
        else
            new_state = true
        end

        no_notify_players[player_index] = new_state
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
            player.print('Sorry, the tag needs a name')
            return
        end

        if not old_tag_data and tag_groups[tag_name] then
            player.print('Sorry, tag ' .. tag_name .. ' is already in use.')
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
            player.print('Sorry, ' .. path .. ' is not a valid sprite')
            return
        end

        local verb = data.verb.text
        if verb == '' then
            verb = default_verb
        end

        Gui.remove_data_recursively(frame)
        frame.destroy()

        local tag_data = {
            path = path,
            verb = verb
        }
        tag_groups[tag_name] = tag_data

        local message
        if old_tag_data then
            local old_name = old_tag_data.name
            if old_name == tag_name and old_tag_data.path == path and old_tag_data.verb == verb then
                return
            end

            if old_name ~= tag_name then
                message = player.name .. ' has edited the ' .. tag_name .. ' (formerly ' .. old_name .. ') tag group'

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
                message = player.name .. ' has edited the ' .. tag_name .. ' tag group'
            end
        else
            message = player.name .. ' has made a new tag group called ' .. tag_name
        end

        redraw_main_frame()

        notify_players(message)
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

Event.add(defines.events.on_player_joined_game, player_joined)

local function tag_command(args)
    local target_player = game.players[args.player]

    if not target_player then
        Game.player_print('Player does not exist.')
        return
    end

    local tag_name = args.tag
    local tag = tag_groups[tag_name]

    if tag == nil then
        Game.player_print("Tag '" .. tag_name .. "' does not exist. Create the tag first by clicking Tag -> Create Tag.")
        return
    end

    if change_player_tag(target_player, tag_name) then
        redraw_main_frame()
    else
        Game.player_print(target_player.name .. ' already has ' .. tag_name .. ' tag')
    end
end

Command.add(
    'tag',
    {
        description = {"command_description.tag"},
        arguments = {'player', 'tag'},
        required_rank = Ranks.admin,
        capture_excess_arguments = true,
        allowed_by_server = true
    },
    tag_command
)
