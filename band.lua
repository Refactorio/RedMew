local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Token = require 'utils.global_token'

local player_tags = {}
local player_tags_token = Token.register_global(player_tags)

Event.on_load(
    function()
        player_tags = Token.get_global(player_tags_token)
    end
)

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local clear_button_name = Gui.uid_name()

local function player_joined(event)
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    if player.gui.top[main_button_name] ~= nil then
        return
    end

    player.gui.top.add {name = main_button_name, type = 'button', caption = 'tag'}
end

local function toggle(event)
    local left = event.player.gui.left
    local main_frame = left[main_frame_name]

    if main_frame then
        Gui.remove_data_recursivly(main_frame)
        main_frame.destroy()
    else
        main_frame =
            left.add {type = 'frame', name = main_frame_name, caption = 'Choose your tag', direction = 'vertical'}

        main_frame.style.maximal_height = 500

        local scroll_pane =
            main_frame.add {type = 'scroll-pane', direction = 'vertical', vertical_scroll_policy = 'always'}

        scroll_pane.style.right_padding = 0

        for _ = 1, 100 do
            local row = scroll_pane.add {type = 'flow', direction = 'horizontal'}

            local button = row.add {type = 'button', caption = 'role'}
            local list = row.add {type = 'label'}

            list.style.minimal_width = 100
        end

        local flow = main_frame.add {type = 'flow'}
        flow.add {type = 'button', name = main_button_name, caption = 'close'}
        flow.add {type = 'button', name = clear_button_name, caption = 'clear tag'}
    end
end

Gui.on_click(main_button_name, toggle)

Event.add(defines.events.on_player_joined_game, player_joined)
