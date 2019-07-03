local Game = require 'features.snake.game'
local Gui = require 'utils.gui'
local Event = require 'utils.event'

local Public = {}

local main_button_name = Gui.uid_name()

local function show_gui_for_player(player)
    if not player or not player.valid then
        return
    end

    local top = player.gui.top
    if not top[main_button_name] then
        top.add {type = 'button', name = main_button_name, caption = {'snake.name'}}
    end
end

local function player_created(event)
    if Game.is_running() then
        local player = game.get_player(event.player_index)
        show_gui_for_player(player)
    end
end

Event.add(defines.events.on_player_created, player_created)

function Public.show()
    for _, player in pairs(game.players) do
        show_gui_for_player(player)
    end
end

function Public.destroy()
    for _, player in pairs(game.players) do
        local button = player.gui.top[main_button_name]
        if button and button.valid then
            button.destroy()
        end
    end
end

Gui.on_click(
    main_button_name,
    function(event)
        Game.new_snake(event.player)
    end
)

return Public
