local Game = require 'utils.game'
local Event = require 'utils.event'
local Donators = require 'resources.donators'

local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    local message = Donators.welcome_messages[player.name]
    if not message then
        return
    end

    game.print(table.concat({'*** ', message, ' ***'}), player.chat_color)
end

Event.add(defines.events.on_player_joined_game, player_joined)
