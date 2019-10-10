local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local b = require 'map_gen.shared.builders'
local RS = require 'map_gen.shared.redmew_surface'
local floor = math.floor
local Snake = require 'features.snake.game'


local config = global.config
local size = 45

config.market.enabled = false

local snake_generate = Token.register(function()
    local position = {x = -floor(size), y = 5}
    local max_food = 8
    local speed = 30
    Snake.start_game(RS.get_surface(), position, size, speed, max_food)
    -- An alternative is to use: remote.call('snake', 'start_game', RS.get_surface(), position, size, speed, max_food)
end)

Event.on_init(function()
    Task.set_timeout_in_ticks(60, snake_generate)
end)

local function on_snake_player_died(event)
    local player = event.player
    player.set_controller{type = defines.controllers.spectator}
end

Event.add(Snake.events.on_snake_player_died, on_snake_player_died)

return b.change_tile(b.rectangle(4, 4), true, 'concrete')
