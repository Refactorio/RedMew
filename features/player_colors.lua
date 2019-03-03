local Event = require 'utils.event'
local Game = require 'utils.game'
local Command = require 'utils.command'
local Server = require 'features.server'
local Token = require 'utils.token'
local Utils = require 'utils.core'
local Ranks = require 'resources.ranks'

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

Command.add(
    'redmew-color',
    {
        description = {'command_description.redmew_color'},
        arguments = {'set-reset-random'},
        required_rank = Ranks.regular
    },
    function(args, player)
        local player_name = player.name
        local arg = args['set-reset-random']
        if arg == 'set' then
            local data = {
                color = player.color,
                chat_color = player.chat_color
            }
            Server.set_data('colors', player_name, data)
            player.print({'player_colors.color_saved'})
            Utils.print_except({'player_colors.color_saved_advert, player'})
        elseif arg == 'reset' then
            Server.set_data('colors', player_name, nil)
            player.print({'player_colors.color_reset'})
        elseif arg == 'random' then
            local color_data = Public.set_random_color(player)
            player.print({'player_colors.color_random', serialize(color_data)})
        else
            player.print({'player_colors.fail_wrong_argument'})
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
