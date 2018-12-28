local Event = require 'utils.event'
local Game = require 'utils.game'
local Command = require 'utils.command'
local Server = require 'features.server'
local Token = require 'utils.token'
local Utils = require 'utils.core'

local serialize = serpent.line

local Public = {}

local color_callback =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value
        if not value then
            return
        end
        local player = game.players[key]
        if not player then
            return
        end
        player.chat_color = value.chat_color
        player.color = value.color
    end
)

--- Attempts to retrieve and get the saved color of a LuaPlayer
function Public.recall_player_color(player)
    Server.try_get_data('colors', player.name, color_callback)
end

--- Assigns LuaPlayer random RGB values for color and player_color and returns the RGB table.
function Public.set_random_color(player)
    return {
        chat_color = Utils.set_and_return(player, 'chat_color', Utils.random_RGB()),
        color = Utils.set_and_return(player, 'color', Utils.random_RGB())
    }
end

--- Saves the player's color to the server
local function save_color(player_name, value)
    Server.set_data('colors', player_name, value)
end

Command.add(
    'color-redmew',
    {
        description = 'Set will save your current color for future maps. Reset will erase your saved color. Random will give you a random color.',
        arguments = {'set-reset-random'},
        admin_only = false,
        regular_only = true,
        allowed_by_server = false,
        allowed_by_player = true
    },
    function(args, player)
        local player_name = player.name
        if args['set-reset-random'] == 'set' then
            local data = {
                color = player.color,
                chat_color = player.chat_color,
            }
            save_color(player_name, data)
            player.print('Your color has been saved. Any time you join a redmew server your color will automatically be set.')
        elseif args['set-reset-random'] == 'reset' then
            save_color(player_name, nil)
            player.print('Your saved color (if you had one) has been removed.')
        elseif args['set-reset-random'] == 'random' then
            local color_data = Public.set_random_color(player)
            player.print('Your color has been changed to: ' .. serialize(color_data))
        else
            player.print('Only set, reset, and random are accepted arguments')
        end
    end
)

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = Game.get_player_by_index(event.player_index)
        if not player or not player.valid then
            return
        end

        Public.recall_player_color(player)
    end
)

return Public
