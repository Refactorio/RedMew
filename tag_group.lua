local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Global = require 'utils.global'
local UserGroups = require 'user_groups'

local deafult_verb = 'expanded'

local tag_groups = require 'resources.tag_groups'
local player_tags = {}

Global.register(
    {tag_groups = tag_groups, player_tags = player_tags},
    function(data)
        tag_groups = data.tag_groups
        player_tags = data.player_tags
    end
)

local function change_player_tag(player, tag_name)
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
        return true
    end

    local band = tag_groups[tag_name]
    if not band then
        return false
    end

    local players = player_tags[tag]
    if not players then
        players = {}
        player_tags[tag] = players
    end

    players[player.index] = true

    player.tag = tag

    local verb = band.verb or deafult_verb

    game.print(tag .. ' squad has `' .. verb .. '` with ' .. player.name)

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
            local player = game.players[pi]
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
local band_button_name = Gui.uid_name()
local band_label_name = Gui.uid_name()
local clear_button_name = Gui.uid_name()
local create_tag_button_name = Gui.uid_name()
local edit_tag_button_name = Gui.uid_name()

local create_tag_frame_name = Gui.uid_name()
local create_tag_choose_icon_name = Gui.uid_name()
local create_tag_icon_type_name = Gui.uid_name()
local confirm_create_tag_name = Gui.uid_name()
local delete_tag_name = Gui.uid_name()
local close_create_tag_name = Gui.uid_name()

local function player_joined(event)
    local player = game.players[event.player_index]
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

    for tag_name, band_data in pairs(tag_groups) do
        local tag = '[' .. tag_name .. ']'
        local players = player_tags[tag]

        local size = get_size(players)
        local path = band_data.path
        local tooltip = tag_name

        local row = parent.add {type = 'flow', direction = 'horizontal'}
        row.style.top_padding = 0
        row.style.bottom_padding = 0

        if player.admin then
            local delete_button =
                row.add {type = 'sprite-button', name = edit_tag_button_name, sprite = 'utility/rename_icon_normal'}
            delete_button.tooltip = 'Edit tag group'
            delete_button.style.top_padding = 0
            delete_button.style.bottom_padding = 0
            delete_button.style.maximal_height = 32
            Gui.set_data(delete_button, tag_name)
        end

        local button = row.add {type = 'sprite-button', name = band_button_name, sprite = path}
        button.tooltip = tooltip
        button.style.top_padding = 0
        button.style.bottom_padding = 0
        button.style.maximal_height = 32
        Gui.set_data(button, tag_name)

        local role_label = row.add {type = 'label', name = band_label_name, caption = tag_name .. size}
        role_label.style.top_padding = 4
        role_label.style.minimal_width = 120
        Gui.set_data(role_label, {tag_name = tag_name, path = path})

        local list = row.add {type = 'flow', direction = 'horizontal'}

        if players then
            for k, _ in pairs(players) do
                local p = game.players[k]
                if p and p.valid and p.connected then
                    local color = {r = 0.4 + 0.6 * p.color.r, g = 0.4 + 0.6 * p.color.g, b = 0.4 + 0.6 * p.color.b}

                    local label = list.add {type = 'label', caption = game.players[k].name}
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

    local scroll_pane =
        main_frame.add {
        type = 'scroll-pane',
        name = main_frame_content_name,
        direction = 'vertical',
        vertical_scroll_policy = 'always'
    }

    scroll_pane.style.right_padding = 0

    draw_main_frame_content(scroll_pane)

    local flow = main_frame.add {type = 'flow'}
    flow.add {type = 'button', name = main_button_name, caption = 'Close'}
    flow.add {type = 'button', name = clear_button_name, caption = 'Clear Tag'}

    if player.admin or UserGroups.is_regular(player.name) then
        flow.add {type = 'button', name = create_tag_button_name, caption = 'Create Tag'}
    end
end

local function redraw_main_frame()
    for _, p in ipairs(game.connected_players) do
        local main_frame = p.gui.left[main_frame_name]
        if main_frame and main_frame.valid then
            local content = main_frame[main_frame_content_name]

            Gui.remove_data_recursivly(content)
            content.clear()

            draw_main_frame_content(content)
        end
    end
end

local function redraw_main_button(player, path)
    local main_button = player.gui.top[main_button_name]

    if path == '' then
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
        Gui.remove_data_recursivly(main_frame)
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

    local center = event.player.gui.center

    local frame = center[create_tag_frame_name]
    if frame then
        Gui.remove_data_recursivly(frame)
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

    local left_flow = bottom_flow.add{type = 'flow', direction = 'horizontal'}
    left_flow.style.align = 'left'

    local right_flow = bottom_flow.add{type = 'flow', direction = 'horizontal'}
    right_flow.style.horizontally_stretchable  = true
    right_flow.style.align = 'right'

    local confirm_button = left_flow.add {type = 'button', name = confirm_create_tag_name, caption = confirm_caption}
    Gui.set_data(confirm_button, frame)

    Gui.set_data(
        frame,
        {
            focus = focus,
            choose = choose,
            icons_flow = icons_flow,
            name = name_field,
            verb = verb_field,
            tag_data = tag_data
        }
    )

    if tag_data then
        left_flow.add {type = 'button', name = delete_tag_name, caption = 'Delete'}
    end

    local close_button = right_flow.add {type = 'button', name = close_create_tag_name, caption = 'Close'}
    Gui.set_data(close_button, frame)

    event.player.opened = frame
end

Gui.on_click(main_button_name, toggle)

Gui.on_click(
    band_button_name,
    function(event)
        local tag = Gui.get_data(event.element)
        local path = event.element.sprite

        if change_player_tag(event.player, tag) then
            redraw_main_frame()
            redraw_main_button(event.player, path)
        end
    end
)

Gui.on_click(
    band_label_name,
    function(event)
        local data = Gui.get_data(event.element)
        local tag = data.band_name
        local path = data.path

        if change_player_tag(event.player, tag) then
            redraw_main_frame()
            redraw_main_button(event.player, path)
        end
    end
)

--[[ Gui.on_click(
    edit_tag_button_name,
    function(event)
        local tag_name = Gui.get_data(event.element)

        if not tag_groups[tag_name] then
            event.player.print("Sorry, Tag name '" .. tag_name .. "' not found.")
            return
        end

        local tag = '[' .. tag_name .. ']'

        for _, player in pairs(game.players) do
            if player.tag == tag then
                change_player_tag(player, '')

                if player.connected then
                    redraw_main_button(player, '')
                end
            end
        end

        tag_groups[tag_name] = nil

        redraw_main_frame()

        game.print(event.player.name .. ' has deleted the ' .. tag_name .. ' tag group')
    end
) ]]
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
        Gui.remove_data_recursivly(choose)
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

        local name = data.name.text

        if name == '' then
            player.print('Sorry, the tag needs a name')
            return
        end

        if tag_groups[name] then
            player.print('Sorry, tag ' .. data.name .. ' is already in use.')
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
            verb = deafult_verb
        end

        local band_role = {
            path = path,
            verb = verb,
            tooltip = name
        }

        tag_groups[name] = band_role

        redraw_main_frame()

        Gui.remove_data_recursivly(frame)
        frame.destroy()

        game.print(player.name .. ' has made a new tag group called ' .. name)
    end
)

Gui.on_click(
    close_create_tag_name,
    function(event)
        local frame = Gui.get_data(event.element)

        Gui.remove_data_recursivly(frame)
        frame.destroy()
    end
)

Gui.on_custom_close(
    create_tag_frame_name,
    function(event)
        local element = event.element
        Gui.remove_data_recursivly(element)
        element.destroy()
    end
)

Event.add(defines.events.on_player_joined_game, player_joined)

local function tag_command(cmd)
    local player = game.player
    if player and not player.admin then
        cant_run(cmd.name)
        return
    end

    if cmd.parameter == nil then
        player_print('Usage: /tag <player> <tag> Sets a players tag.')
        return
    end

    local params = {}
    for param in string.gmatch(cmd.parameter, '%S+') do
        table.insert(params, param)
    end

    if #params < 2 then
        player_print('Usage: <player> <tag> Sets a players tag.')
        return
    end

    local target_player = game.players[params[1]]

    if target_player == nil or not target_player.valid then
        player_print('Player does not exist.')
        return
    end

    local tag_name = string.sub(cmd.parameter, params[1]:len() + 2)
    local tag = tag_groups[tag_name]

    if tag == nil then
        player_print("Tag '" .. tag_name .. "' does not exist. Create the tag first by clicking Tag -> Create Tag.")
        return
    end

    if change_player_tag(target_player, tag_name) then
        redraw_main_frame()
    else
        player_print(target_player.name .. ' already has ' .. tag_name .. ' tag')
    end
end

commands.add_command('tag', '<player> <tag> Sets a players tag. (Admins only)', tag_command)
