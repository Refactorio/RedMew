local GameGui = require 'features.snake.gui'
local Game = require 'features.snake.game'

local Public = {}

--- Starts snake game.
-- Note when players join the game they will lose thier character.
-- @param surface <LuaSurface> Surface that the board is placed on.
-- @param top_left_position <Position> Position where board is placed. Defaults to {x = 1, y = 1}.
-- @param size <int> size of board in board tiles. Note that the actual size of the board will be (2 * size) + 1 in
-- factorio tiles. Defaults to 15.
-- @param update_rate <int> number of ticks between updates. Defaults to 30.
-- @param <int> maximun food on the board. Defaults to 6.
function Public.start_game(surface, top_left_position, size, update_rate, max_food)
    Game.start_game(surface, top_left_position, size, update_rate, max_food)
    GameGui.show()
end

--- Ends the snake game. This will clean up any snake and food entities but will not restore the tiles nor
-- give players thier character back.
function Public.end_game()
    Game.end_game()
    GameGui.destroy()
end

remote.add_interface('snake', Public)

return Public
