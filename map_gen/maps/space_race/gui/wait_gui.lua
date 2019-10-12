local Gui = require 'utils.gui'
local snake_game = require 'features.snake.game'

local config = require 'map_gen.maps.space_race.config'
local players_needed = config.players_needed_to_start_game

local Public = {}

-- <Waiting GUI start>

local waiting_close_name = Gui.uid_name()

function Public.show_gui(event)
    local frame
    local player = game.get_player(event.player_index)
    local center = player.gui.center
    local gui = center['Space-Race-Lobby']
    if (gui) then
        Gui.destroy(gui)
    end

    local snake_button_text

    if snake_game.is_running() then
        snake_button_text = 'Play Snake'
    else
        snake_button_text = '... Loading Snake ...'
    end
    frame = player.gui.center.add {name = 'Space-Race-Lobby', type = 'frame', direction = 'vertical', style = 'captionless_frame'}

    frame.style.minimal_width = 300

    --Header
    local top_flow = frame.add {type = 'flow', direction = 'horizontal'}
    top_flow.style.horizontal_align = 'center'
    top_flow.style.horizontally_stretchable = true

    local title_flow = top_flow.add {type = 'flow'}
    title_flow.style.horizontal_align = 'center'
    title_flow.style.top_padding = 8
    title_flow.style.horizontally_stretchable = false

    local title = title_flow.add {type = 'label', caption = 'Welcome to Space Race'}
    title.style.font = 'default-large-bold'

    --Body

    local content_flow = frame.add {type = 'flow', direction = 'horizontal'}
    content_flow.style.top_padding = 8
    content_flow.style.bottom_padding = 16
    content_flow.style.left_padding = 24
    content_flow.style.right_padding = 24
    content_flow.style.horizontal_align = 'center'
    content_flow.style.horizontally_stretchable = true

    local label_flow = content_flow.add {type = 'flow'}
    label_flow.style.horizontal_align = 'center'

    label_flow.style.horizontally_stretchable = true
    local label = label_flow.add {type = 'label', caption = #game.connected_players .. ' out of ' .. players_needed .. ' players needed to begin!'}
    label.style.horizontal_align = 'center'
    label.style.single_line = false
    label.style.font = 'default'

    --Footer
    local ok_button_flow = frame.add {type = 'flow'}
    ok_button_flow.style.horizontally_stretchable = true
    ok_button_flow.style.horizontal_align = 'center'

    local ok_button = ok_button_flow.add {type = 'button', name = waiting_close_name, caption = snake_button_text}
    Gui.set_data(ok_button, frame)
end

Gui.on_click(
    waiting_close_name,
    function(event)
        if snake_game.is_running() then
            local frame = Gui.get_data(event.element)
            local player = event.player

            game.permissions.get_group('lobby').remove_player(player)
            snake_game.new_snake(player)

            Gui.remove_data_recursively(frame)
            frame.destroy()
        end
    end
)

-- <Waiting GUI end>

return Public
