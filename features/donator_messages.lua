local Game = require 'utils.game'
local Event = require 'utils.event'
local UserGroups = require 'features.user_groups'

local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    local message = UserGroups.get_donator_welcome_message(player.name)
    if not message then
        return
    end

    game.print(table.concat({'*** ', message, ' ***'}), player.chat_color)
end

Event.add(defines.events.on_player_joined_game, player_joined)
