local Gui = require 'utils.gui'

local close_name = Gui.uid_name()

local function show_popup(player, message)
    local frame = player.gui.center.add {type = 'frame', direction = 'vertical'}

    local close_button_flow = frame.add {type = 'flow'}
    close_button_flow.style.horizontally_stretchable = true
    close_button_flow.style.align = 'right'

    local close_button = close_button_flow.add {type = 'button', name = close_name, caption = 'X'}
    Gui.set_data(close_button, frame)

    local title_flow = frame.add {type = 'flow'}
    title_flow.style.align = 'center'
    title_flow.style.horizontally_stretchable = true

    local title = title_flow.add {type = 'label', caption = 'Attention!'}
    title.style.font = 'default-large-bold'

    local label_flow = frame.add {type = 'flow'}
    label_flow.style.top_padding = 32
    label_flow.style.bottom_padding = 32
    label_flow.style.left_padding = 32
    label_flow.style.right_padding = 32

    local label = label_flow.add {type = 'label', caption = message}
    label.style.single_line = false
    label.style.font = 'default-large-bold'

    local ok_button_flow = frame.add {type = 'flow'}
    ok_button_flow.style.horizontally_stretchable = true
    ok_button_flow.style.align = 'center'

    local ok_button = ok_button_flow.add {type = 'button', name = close_name, caption = 'OK'}
    Gui.set_data(ok_button, frame)

    player.opened = frame
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
    local player = game.players[cmd.player_index]
    if player and not player.admin then
        player.print("You don't have permission to run this command")
        return
    end

    local message = cmd.parameter:gsub('\\n', '\n')

    for _, p in ipairs(game.connected_players) do
        show_popup(p, message)
    end
end

local function popup_update(cmd)
    local player = game.players[cmd.player_index]
    if player and not player.admin then
        player.print("You don't have permission to run this command")
        return
    end

    local message = 'Server updating to ' .. cmd.parameter .. ', back in one minute.'

    for _, p in ipairs(game.connected_players) do
        show_popup(p, message)
    end
end

commands.add_command('popup', '<message> - Shows a popup to all connected players (Admins only)', popup)
commands.add_command(
    'popup-update',
    '<version> - Shows an update popup to all connected players (Admins only)',
    popup_update
)
