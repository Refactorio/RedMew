local GameGui = require 'features.snake.gui'
local Game = require 'features.snake.game'

local Public = {}

function Public.start_game(surface, top_left_position, size, update_rate, max_food)
    Game.start_game(surface, top_left_position, size, update_rate, max_food)
    GameGui.show()
end

function Public.end_game()
    Game.end_game()
    GameGui.destroy()
end

remote.add_interface('snake', Public)

return Public
