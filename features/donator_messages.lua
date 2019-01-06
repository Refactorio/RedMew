local Game = require 'utils.game'
local Event = require 'utils.event'
local UserGroups = require 'features.user_groups'
local Task = require 'utils.task'
local Token = require 'utils.token'

local print_after_timeout =
    Token.register(
    function(data)
        local player = data.player
        if not player.valid then
            return
        end
        game.print(data.message, player.chat_color)
    end
)

local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    local message = UserGroups.get_donator_welcome_message(player.name)
    if not message then
        return
    end

    message = table.concat({'*** ', message, ' ***'})
    Task.set_timeout_in_ticks(60, print_after_timeout, {player = player, message = message})
end

Event.add(defines.events.on_player_joined_game, player_joined)
