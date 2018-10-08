local Gui = require 'utils.gui'

local close_name = Gui.uid_name()

local function show_popup(player, message)
    local frame = player.gui.center.add {type = 'frame', direction = 'vertical', style = 'captionless_frame'}
    frame.style.minimal_width = 300

    local top_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local title_flow = top_flow.add {type = 'flow'}
    title_flow.style.align = 'center'
    title_flow.style.left_padding = 32
    title_flow.style.top_padding = 8
    title_flow.style.horizontally_stretchable = true

    local title = title_flow.add {type = 'label', caption = 'Attention!'}
    title.style.font = 'default-large-bold'

    local close_button_flow = top_flow.add {type = 'flow'}
    close_button_flow.style.align = 'right'

    local close_button = close_button_flow.add {type = 'button', name = close_name, caption = 'X'}
    Gui.set_data(close_button, frame)

    local content_flow = frame.add {type = 'flow', direction = 'horizontal'}
    content_flow.style.top_padding = 16
    content_flow.style.bottom_padding = 16
    content_flow.style.left_padding = 24
    content_flow.style.right_padding = 24
    content_flow.style.horizontally_stretchable = true

    local sprite_flow = content_flow.add {type = 'flow'}
    sprite_flow.style.vertical_align = 'center'
    sprite_flow.style.vertically_stretchable = true

    sprite_flow.add {type = 'sprite', sprite = 'utility/warning_icon'}

    local label_flow = content_flow.add {type = 'flow'}
    label_flow.style.align = 'left'
    label_flow.style.top_padding = 10
    label_flow.style.left_padding = 24

    label_flow.style.horizontally_stretchable = true
    local label = label_flow.add {type = 'label', caption = message}
    label.style.single_line = false
    label.style.font = 'default-large-bold'

    local ok_button_flow = frame.add {type = 'flow'}
    ok_button_flow.style.horizontally_stretchable = true
    ok_button_flow.style.align = 'center'

    local ok_button = ok_button_flow.add {type = 'button', name = close_name, caption = 'OK'}
    Gui.set_data(ok_button, frame)
end

Gui.on_click(
    close_name,
    function(event)
        local frame = Gui.get_data(event.element)

        Gui.remove_data_recursivly(frame)
        frame.destroy()
    end
)

local function popup(cmd)
    local player = game.player
    if player and not player.admin then
        cant_run(cmd.name)
        return
    end

    local message = cmd.parameter
    if not message then
        player_print('Usage: /popup <message>')
        return
    end

    message = message:gsub('\\n', '\n')

    for _, p in ipairs(game.connected_players) do
        show_popup(p, message)
    end
end

local function popup_update(cmd)
    local player = game.player
    if player and not player.admin then
        cant_run(cmd.name)
        return
    end

    local message = '\nServer updating to ' .. cmd.parameter .. ', back in one minute.'

    for _, p in ipairs(game.connected_players) do
        show_popup(p, message)
    end
end

local function popup_player(cmd)
    local player = game.player
    if player and not player.admin then
        cant_run(cmd.name)
        return
    end

    local message = cmd.parameter
    if not message then
        player_print('Usage: /popup <player> <message>')
        return
    end

    local start_index, end_index = message:find(' ')
    if not start_index then
        player_print('Usage: /popup <player> <message>')
        return
    end

    local target_name = message:sub(1, start_index - 1)
    local target = game.players[target_name]
    if not target then
        player_print('Player ' .. target_name .. ' not found.')
        return
    end

    message = message:sub(end_index, #message):gsub('\\n', '\n')

    show_popup(target, message)
end

commands.add_command('popup', '<message> - Shows a popup to all connected players (Admins only)', popup)

commands.add_command(
    'popup-update',
    '<version> - Shows an update popup to all connected players (Admins only)',
    popup_update
)

commands.add_command('popup-player', '<player> <message> - Shows a popup to the players (Admins only)', popup_player)

local Public = {}

--[[--
    Shows a popup dialog.

    @param player LuaPlayer
    @param message string
]]
function Public.player(player, message)
    show_popup(player, message)
end

--[[--
    Shows a popup dialog to all connected players.

    @param message string
]]
function Public.all_online(message)
    for _, p in ipairs(game.connected_players) do
        show_popup(p, message)
    end
end

--[[--
    Shows a popup dialog to all players.

    @param message string
]]
function Public.all(message)
    for _, p in pairs(game.players) do
        show_popup(p, message)
    end
end

return Public
