local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Token = require 'utils.global_token'
local UserGroups = require 'user_groups'

local band_roles = require 'resources.band_roles'
local band_roles_token = Token.register_global(band_roles)

local player_tags = {}
local player_tags_token = Token.register_global(player_tags)

Event.on_load(
    function()
        band_roles = Token.get_global(band_roles_token)
        player_tags = Token.get_global(player_tags_token)
    end
)

local function change_player_tag(player, band_name)
    local old_tag = player.tag
    if band_name == '' and old_tag == '' then
        return false
    end

    local tag_name = '[' .. band_name .. ']'
    if old_tag == tag_name then
        return false
    end

    if old_tag ~= '' then
        local players = player_tags[old_tag]
        if players then
            players[player.index] = nil
        end
    end

    if band_name == '' then
        player.tag = ''
        return true
    end

    local band = band_roles[band_name]
    if not band then
        return false
    end

    local players = player_tags[tag_name]
    if not players then
        players = {}
        player_tags[tag_name] = players
    end

    players[player.index] = true

    player.tag = tag_name

    local verbs = band.verbs
    local verb
    if verbs then
        verb = verbs[math.random(#verbs)]
    else
        verb = 'expanded'
    end

    game.print(tag_name .. ' squad has `' .. verb .. '` with ' .. player.name)

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
local band_button_name = Gui.uid_name()
local band_label_name = Gui.uid_name()
local clear_button_name = Gui.uid_name()
local create_tag_button_name = Gui.uid_name()
local delete_tag_button_name = Gui.uid_name()

local create_tag_frame_name = Gui.uid_name()
local create_tag_choose_icon_name = Gui.uid_name()
local create_tag_icon_type_name = Gui.uid_name()
local close_create_tag_name = Gui.uid_name()
local confirm_create_tag_name = Gui.uid_name()

local main_frame_content_name = Gui.uid_name()

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

    for band_name, band_data in pairs(band_roles) do
        local tag_name = '[' .. band_name .. ']'
        local players = player_tags[tag_name]

        local size = get_size(players)
        local path = band_data.paths[math.random(#band_data.paths)]
        local tooltip = band_data.tooltips[math.random(#band_data.tooltips)]

        local row = parent.add {type = 'flow', direction = 'horizontal'}
        row.style.top_padding = 0
        row.style.bottom_padding = 0

        if player.admin then
            local delete_button =
                row.add {type = 'sprite-button', name = delete_tag_button_name, sprite = 'utility/remove'}
            delete_button.tooltip = 'Delete tag group'
            delete_button.style.top_padding = 0
            delete_button.style.bottom_padding = 0
            delete_button.style.maximal_height = 32
            Gui.set_data(delete_button, band_name)
        end

        local button = row.add {type = 'sprite-button', name = band_button_name, sprite = path}
        button.tooltip = tooltip
        button.style.top_padding = 0
        button.style.bottom_padding = 0
        button.style.maximal_height = 32
        Gui.set_data(button, band_name)

        local role_label = row.add {type = 'label', name = band_label_name, caption = band_name .. size}
        role_label.style.top_padding = 4
        role_label.style.minimal_width = 120
        Gui.set_data(role_label, {band_name = band_name, path = path})

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

local function draw_create_tag_frame(event)
    local center = event.player.gui.center

    if center[create_tag_frame_name] then
        return
    end

    local frame =
        center.add {type = 'frame', name = create_tag_frame_name, caption = 'Create A New Tag', direction = 'vertical'}

    local main_table = frame.add {type = 'table', column_count = 2}

    main_table.add {type = 'label', caption = 'Name'}
    local name_field = main_table.add {type = 'textfield'}
    Gui.set_data(name_field, frame)

    main_table.add {type = 'label', caption = 'Icon'}
    local icons_flow = main_table.add {type = 'flow', direction = 'horizontal'}
    local selection_flow = icons_flow.add {type = 'flow'}

    local focus
    for i, value in ipairs(choices) do
        local radio =
            selection_flow.add({type = 'flow'}).add {
            type = 'radiobutton',
            name = create_tag_icon_type_name,
            caption = value,
            state = i == 1
        }

        if i == 1 then
            focus = radio
        end

        Gui.set_data(radio, frame)
    end

    local choose =
        icons_flow.add {
        type = 'choose-elem-button',
        name = create_tag_choose_icon_name,
        elem_type = choices[1]
    }
    Gui.set_data(choose, frame)

    main_table.add {type = 'label', caption = 'Verb'}
    local verb_field = main_table.add {type = 'textfield', text = 'expanded'}
    Gui.set_data(verb_field, frame)

    local flow = frame.add {type = 'flow', direction = 'horizontal'}

    local close_button = flow.add {type = 'button', name = close_create_tag_name, caption = 'Close'}
    Gui.set_data(close_button, frame)

    local confirm_button = flow.add {type = 'button', name = confirm_create_tag_name, caption = 'Confirm'}
    Gui.set_data(confirm_button, frame)

    Gui.set_data(
        frame,
        {
            focus = focus,
            choose = choose,
            icons_flow = icons_flow,
            name = name_field,
            verb = verb_field
        }
    )

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

Gui.on_click(
    delete_tag_button_name,
    function(event)
        local tag_name = Gui.get_data(event.element)

        if not band_roles[tag_name] then
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

        band_roles[tag_name] = nil

        redraw_main_frame()

        game.print(event.player.name .. ' has deleted the ' .. tag_name .. ' tag group')
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

        if band_roles[name] then
            player.print('Sorry, tag ' .. data.name .. ' is already in use.')
            return
        end

        local type = data.focus.caption
        local sprite = data.choose.elem_value

        local path
        if not sprite or sprite == '' then
            path = 'utility/pump_cannot_connect_icon'
        elseif type == 'signal' then
            path = 'virtual-signal/' .. data.choose.elem_value.name
        else
            path = type .. '/' .. data.choose.elem_value
        end

        if not frame.gui.is_valid_sprite_path(path) then
            player.print('Sorry, ' .. path .. ' is not a valid sprite')
            return
        end

        local verb = data.verb.text
        if verb == '' then
            verb = 'expanded'
        end

        local band_role = {
            paths = {path},
            verbs = {verb},
            tooltips = {name}
        }

        band_roles[name] = band_role

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
    local tag = band_roles[tag_name]

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
