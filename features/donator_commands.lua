-- Dependencies
local Game = require 'utils.game'
local Command = require 'utils.command'
local Donator = require 'features.donator'
local Color = require 'resources.color_presets'

-- Local functions

--- Saves the player's message to the server
local function set_donator_message(args, player)
    Donator.change_donator_data(player.name, {welcome_messages = args.message})
    Game.player_print('Welcome message updated.', Color.green)
end

-- Commands

Command.add(
    'donator-join-message',
    {
        description = 'Changes your on-join message',
        arguments = {'message'},
        capture_excess_arguments = true,
        donator_only = true
    },
    set_donator_message
)
