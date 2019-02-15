-- Dependencies
local Game = require 'utils.game'
local Command = require 'utils.command'
local Donator = require 'features.donator'
local Color = require 'resources.color_presets'

local format = string.format

-- Local functions

--- Saves the player's message
local function add_join_message(args, player)
    local str = tostring(args.value)
    if not str or str == 'false' then
        Game.player_print({'donator_commands.add_join_message_fail_not_string'}, Color.fail)
        return
    end
    Donator.add_donator_message(player.name, str)
    Game.player_print({'donator_commands.add_join_message_success'}, Color.success)
end

--- Deletes one of the player's message
local function delete_join_message(args, player)
    local num = tonumber(args.value)
    if not num then
        Game.player_print({'donator_commands.delete_join_message_fail_not_number'}, Color.fail)
        return
    end

    local message = Donator.delete_donator_message(player.name, num)
    if message then
        Game.player_print({'donator_commands.delete_join_message_success', message}, Color.success)
    else
        Game.player_print({'donator_commands.delete_join_message_fail_no_message'}, Color.fail)
    end
end

--- Lists the player's messages
local function list_join_messages(player)
    local messages = Donator.get_donator_messages(player.name)
    if messages then
        for k, v in pairs(messages) do
            Game.player_print(format('[%s] %s', k, v))
        end
    else
        Game.player_print({'donator_commands.list_join_message_fail_no_messages'}, Color.warning)
    end
end

--- Decides which function to call depending on the first arg to the command
local function donator_join_message_command(args, player)
    local multi = args['add|delete|list']
    if multi == 'add' then
        add_join_message(args, player)
    elseif multi == 'delete' then
        delete_join_message(args, player)
    elseif multi == 'list' then
        list_join_messages(player)
    else
        Game.player_print({'donator_commands.donator_join_message_wrong_arg1'}, Color.white)
    end
end

-- Commands

Command.add(
    'donator-join-message',
    {
        description = 'Adds, deletes, or lists donator on-join messages.', -- (LOCALE) Localize once command can handle localized strings
        arguments = {'add|delete|list', 'value'},
        default_values = {value = false},
        capture_excess_arguments = true,
        donator_only = true
    },
    donator_join_message_command
)
