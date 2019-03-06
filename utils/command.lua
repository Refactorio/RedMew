-- luacheck: globals commands
local Event = require 'utils.event'
local Game = require 'utils.game'
local Utils = require 'utils.core'
local Timestamp = require 'utils.timestamp'
local ErrorLogging = require 'utils.error_logging'
local Rank = require 'features.rank_system'
local Donator = require 'features.donator'
local Server = require 'features.server'
local Ranks = require 'resources.ranks'

local insert = table.insert
local format = string.format
local next = next
local serialize = serpent.line
local gmatch = string.gmatch
local get_rank_name = Rank.get_rank_name

local Command = {}

local deprecated_command_alternatives = {
    ['silent-command'] = 'dc',
    ['sc'] = 'dc',
    ['tpplayer'] = 'tp <player>',
    ['tppos'] = 'tp',
    ['tpmode'] = 'tp mode',
    ['color-redmew'] = 'redmew-color'
}

local notify_on_commands = {
    ['version'] = 'RedMew has a version as well, accessible via /redmew-version',
    ['color'] = 'RedMew allows color saving and a color randomizer: check out /redmew-color',
    ['ban'] = 'In case your forgot: please remember to include a message on how to appeal a ban'
}

local option_names = {
    ['description'] = 'A description of the command',
    ['arguments'] = 'A table of arguments, example: {"foo", "bar"} would map the first 2 arguments to foo and bar',
    ['default_values'] = 'A default value for a given argument when omitted, example: {bar = false}',
    ['required_rank'] = 'Set this to determins what rank is required to execute a command',
    ['donator_only'] = 'Set this to true if only donators may execute this command',
    ['debug_only'] = 'Set this to true if it should be registered when _DEBUG is true',
    ['cheat_only'] = 'Set this to true if it should be registered when _CHEATS is true',
    ['allowed_by_server'] = 'Set to true if the server (host) may execute this command',
    ['allowed_by_player'] = 'Set to false to disable players from executing this command',
    ['log_command'] = 'Set to true to log commands. Always true when admin is required',
    ['capture_excess_arguments'] = 'Allows the last argument to be the remaining text in the command',
    ['custom_help_text'] = 'Sets a custom help text to override the auto-generated help'
}

---Validates if there aren't any wrong fields in the options.
---@param command_name string
---@param options table
local function assert_existing_options(command_name, options)
    local invalid = {}
    for name, _ in pairs(options) do
        if not option_names[name] then
            insert(invalid, name)
        end
    end

    if next(invalid) then
        error(format("The following options were given to the command '%s' but are invalid: %s", command_name, serialize(invalid))) -- command.error_bad_option when bug fixed
    end
end

---Adds a command to be executed.
---
---Options table accepts the following structure: {
---    description = 'A description of the command',
---    arguments = {'foo', 'bar'}, -- maps arguments to these names in the given sequence
---    default_values = {bar = false}, -- gives a default value to 'bar' when omitted
---    required_rank = Ranks.regular, -- defaults to Ranks.guest
---    donator_only = true, -- defaults to false
---    debug_only = true, -- registers the command if _DEBUG is set to true, defaults to false
---    cheat_only = true, -- registers the command if _CHEATS is set to true, defaults to false
---    allowed_by_server = true, -- lets the server execute this, defaults to false
---    allowed_by_player = false, -- lets players execute this, defaults to true
---    log_command = true, -- defaults to false unless admin only, then always true
---    capture_excess_arguments = true, -- defaults to false, captures excess arguments in the last argument, useful for sentences
---}
---
---The callback receives the following arguments:
--- - arguments (indexed by name, value is extracted from the parameters)
--- - the LuaPlayer or nil if it doesn't exist (such as the server player)
--- - the game tick in which the command was executed
---
---@param command_name string
---@param options table
---@param callback function
function Command.add(command_name, options, callback)
    local description = options.description or {'command.undocumented_command'}
    local arguments = options.arguments or {}
    local default_values = options.default_values or {}
    local required_rank = options.required_rank or Ranks.guest
    local donator_only = options.donator_only or false
    local debug_only = options.debug_only or false
    local cheat_only = options.cheat_only or false
    local capture_excess_arguments = options.capture_excess_arguments or false
    local custom_help_text = options.custom_help_text or false
    local allowed_by_server = options.allowed_by_server or false
    local allowed_by_player = options.allowed_by_player
    local log_command = options.log_command or (required_rank >= Ranks.admin) or false
    local argument_list_size = table_size(arguments)
    local argument_list = ''

    assert_existing_options(command_name, options)

    if nil == options.allowed_by_player then
        allowed_by_player = true
    end

    if (not _DEBUG and debug_only) and (not _CHEATS and cheat_only) then
        return
    end
    if not allowed_by_player and not allowed_by_server then
        error(format("The command %s is not allowed by the server nor player, please enable at least one of them.", command_name)) -- command.error_no_player_no_server when bug fixed
    end

    for index, argument_name in pairs(arguments) do
        local argument_display = argument_name
        for default_value_name, _ in pairs(default_values) do
            if default_value_name == argument_name then
                argument_display = argument_display .. ':optional'
                break
            end
        end

        if argument_list_size == index and capture_excess_arguments then
            argument_display = argument_display .. ':sentence'
        end

        argument_list = format('%s<%s> ', argument_list, argument_display)
    end

    local extra = {''}

    if allowed_by_server and not allowed_by_player then
        extra = {'command.server_only'}
    elseif allowed_by_player and (required_rank > Ranks.guest) then
        extra = {'command.required_rank', get_rank_name(required_rank)}
    elseif allowed_by_player and donator_only then
        extra = {'command.donator_only'}
    end

    local help_text = {'command.help_text_format', (custom_help_text or argument_list), description, extra}

    commands.add_command(
        command_name,
        help_text,
        function(command)
            local print  -- custom print reference in case no player is present
            local player = game.player
            local player_name = player and player.valid and player.name or '<server>'
            if not player or not player.valid then
                print = log

                if not allowed_by_server then
                    print({'command.not_allowed_by_server', command_name})
                    return
                end
            else
                print = player.print

                if not allowed_by_player then
                    print({'command.not_allowed_by_players', command_name})
                    return
                end

                if Rank.less_than(player_name, required_rank) then
                    print({'command.higher_rank_needed', command_name, get_rank_name(required_rank)})
                    return
                end

                if donator_only and not Donator.is_donator(player_name) then
                    print({'command.not_allowed_by_non_donators', command_name})
                    return
                end
            end

            local named_arguments = {}
            local from_command = {}
            local raw_parameter_index = 1
            for param in gmatch(command.parameter or '', '%S+') do
                if capture_excess_arguments and raw_parameter_index == argument_list_size then
                    if not from_command[raw_parameter_index] then
                        from_command[raw_parameter_index] = param
                    else
                        from_command[raw_parameter_index] = from_command[raw_parameter_index] .. ' ' .. param
                    end
                else
                    from_command[raw_parameter_index] = param
                    raw_parameter_index = raw_parameter_index + 1
                end
            end

            local errors = {}

            for index, argument in pairs(arguments) do
                local parameter = from_command[index]

                if not parameter then
                    for default_value_name, default_value in pairs(default_values) do
                        if default_value_name == argument then
                            parameter = default_value
                            break
                        end
                    end
                end

                if parameter == nil then
                    insert(errors, {'command.fail_missing_argument', argument, command_name})
                else
                    named_arguments[argument] = parameter
                end
            end

            local return_early = false

            for _, error in pairs(errors) do
                return_early = true
                print(error)
            end

            if return_early then
                return
            end

            if log_command then
                local tick = 'pre-game'
                if game then
                    tick = Utils.format_time(game.tick)
                end
                local server_time = Server.get_current_time()
                if server_time then
                    server_time = format('(Server time: %s)', Timestamp.to_string(server_time))
                else
                    server_time = ''
                end
                log({'command.log_entry', server_time, tick, (required_rank >= Ranks.admin) and 'Admin' or 'Player', player_name, command_name, serialize(named_arguments)})
            end

            local success, error =
                pcall(
                function()
                    callback(named_arguments, player, command.tick)
                end
            )

            if not success then
                local serialized_arguments = serialize(named_arguments)
                if _DEBUG then
                    print({'command.error_while_running_debug', player_name, command_name, serialized_arguments})
                    print(error)
                    ErrorLogging.generate_error_report(error)
                    return
                end

                print({'command.warn_player_of_error', command_name})
                local err = {'command.error_log', command_name, serialized_arguments, error}
                log(err)
                ErrorLogging.generate_error_report(err)
            end
        end
    )
end

--- Trigger messages on deprecated or defined commands, ignores the server
local function on_command(event)
    if not event.player_index then
        return
    end

    local alternative = deprecated_command_alternatives[event.command]
    if alternative then
        local player = Game.get_player_by_index(event.player_index)
        if player then
            player.print({'command.warn_deprecated_command', event.command, alternative})
        end
    end

    local notification = notify_on_commands[event.command]
    if notification and event.player_index then
        local player = Game.get_player_by_index(event.player_index)
        if player then
            player.print(notification)
        end
    end
end

--- Traps command errors if not in DEBUG.
if not _DEBUG then
    local old_add_command = commands.add_command
    commands.add_command =
        function(name, desc, func)
        old_add_command(
            name,
            desc,
            function(cmd)
                local success, error = pcall(func, cmd)
                if not success then
                    log(error)
                    Game.player_print({'command.failed_command', cmd.name})
                end
            end
        )
    end
end

Event.add(defines.events.on_console_command, on_command)

return Command
