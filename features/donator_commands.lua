-- Dependencies
local Game = require 'utils.game'
local Command = require 'utils.command'
local Donator = require 'features.donator'
local Color = require 'resources.color_presets'
local Global = require 'utils.global'

local format = string.format
local config = storage.config.donator.donator_perks


Global.register(
    {
        config = config
    },
    function()
        config = storage.config.donator.donator_perks
    end
)

-- Local functions

--- Saves the player's message
local function add_message(args, player, table_name)
    local str = args.value
    if not str then
        Game.player_print({'donator_commands.add_message_fail_not_string'}, Color.fail)
        return
    end

    Donator.add_donator_message(player.name, table_name, str)
    Game.player_print({'donator_commands.add_message_success', str}, Color.success)
end

--- Deletes one of the player's message
local function delete_message(args, player, table_name)
    local num = tonumber(args.value)
    if not num then
        Game.player_print({'donator_commands.delete_message_fail_not_number'}, Color.fail)
        return
    end

    local message = Donator.delete_donator_message(player.name, table_name, num)
    if message then
        Game.player_print({'donator_commands.delete_message_success', message}, Color.success)
    else
        Game.player_print({'donator_commands.delete_message_fail_no_message'}, Color.fail)
    end
end

--- Lists the player's messages
local function list_messages(player, table_name)
    local messages = Donator.get_donator_messages(player.name, table_name)
    if messages and #messages > 0 then
        for k, v in pairs(messages) do
            Game.player_print(format('[%s] %s', k, v))
        end
    else
        Game.player_print({'donator_commands.list_message_no_messages'}, Color.info)
    end
end

local function command_path_decider(args, player, table_name)
    local multi = args['add|delete|list']
    if multi == 'add' then
        add_message(args, player, table_name)
    elseif multi == 'delete' then
        delete_message(args, player, table_name)
    elseif multi == 'list' then
        list_messages(player, table_name)
    else
        Game.player_print({'donator_commands.donator_message_wrong_arg1'}, Color.white)
    end
end

--- Decides which function to call depending on the first arg to the command
local function donator_welcome_message_command(args, player)
    local table_name = 'welcome_messages'
    command_path_decider(args, player, table_name)
end

--- Decides which function to call depending on the first arg to the command
local function donator_death_message_command(args, player)
    local table_name = 'death_messages'
    command_path_decider(args, player, table_name)
end

-- Prints a list of currently active perks to the player
local function print_perks(_, player)
    local print = print
    if player and player.valid then -- allows us to call print_perks from the server console OR in-game
        print = player.print
    end

    if not config.enabled then
        print("Donator perks have been disabled for this map.")
        return
    end

    local donator_tiers = Donator.get_donator_perks_table()

    print("Currently active team perks: +"..(donator_tiers[2].count*10).."% hand mining speed (max +"..(donator_tiers[2].max*10).."%), +"
        ..(donator_tiers[3].count*10).."% hand crafting speed (max +"..(donator_tiers[3].max*10).."%), +"
        ..(donator_tiers[4].count*10).."% run speed  (max +"..(donator_tiers[4].max*10).."%) and +"
        ..(donator_tiers[5].count*5).." inventory slots  (max +"..(donator_tiers[5].max*5).."%).")
end

-- Commands

Command.add(
    'donator-welcome-message',
    {
        description = {'command_description.donator_welcome_message'},
        arguments = {'add|delete|list', 'value'},
        default_values = {value = false},
        capture_excess_arguments = true,
        donator_only = true
    },
    donator_welcome_message_command
)

Command.add(
    'donator-death-message',
    {
        description = {'command_description.donator_death_message'},
        arguments = {'add|delete|list', 'value'},
        default_values = {value = false},
        capture_excess_arguments = true,
        donator_only = true
    },
    donator_death_message_command
)

Command.add(
    'perks',
    {
        description = {'command_description.perks'},
    },
    print_perks
)