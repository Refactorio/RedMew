require 'utils.table'
local UserGroups = require 'features.user_groups'
local Event = require 'utils.event'
local Game = require 'utils.game'

local insert = table.insert
local format = string.format
local next = next
local serialize = serpent.line
local match = string.match

local Command = {}

local deprecated_command_alternatives = {
    ['silent-command'] = 'sc',
    ['tpplayer'] = 'tp',
    ['tppos'] = 'tp',
    ['tpmode'] = 'tp',
}

local option_names = {
    ['description'] = 'A description of the command',
    ['arguments'] = 'A table of arguments, example: {"foo", "bar"} would map the first 2 arguments to foo and bar',
    ['default_values'] = 'A default value for a given argument when omitted, example: {bar = false}',
    ['regular_only'] = 'Set this to true if only regulars may execute this command',
    ['admin_only'] = 'Set this to true if only admins may execute this command',
    ['debug_only'] = 'Set this to true if it should be registered when _DEBUG is true',
    ['cheat_only'] = 'Set this to true if it should be registered when _CHEATS is true',
    ['allowed_by_server'] = 'Set to true if the server (host) may execute this command',
    ['allowed_by_player'] = 'Set to false to disable players from executing this command',
    ['log_command'] = 'Set to true to log commands. Always true when admin_only is enabled',
    ['capture_excess_arguments'] = 'Allows the last argument to be the remaining text in the command',
    ['custom_help_text'] = 'Sets a custom help text to override the auto-generated help',
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
        error(format("The following options were given to the command '%s' but are invalid: %s", command_name, serialize(invalid)))
    end
end

---Adds a command to be executed.
---
---Options table accepts the following structure: {
---    description = 'A description of the command',
---    arguments = {'foo', 'bar'}, -- maps arguments to these names in the given sequence
---    default_values = {bar = false}, -- gives a default value to 'bar' when omitted
---    regular_only = true, -- defaults to false
---    admin_only = false, -- defaults to false
---    debug_only = false, -- registers the command if _DEBUG is set to true, defaults to false
---    cheat_only = false, -- registers the command if _CHEATS is set to true, defaults to false
---    allowed_by_server = false, -- lets the server execute this, defaults to false
---    allowed_by_player = true, -- lets players execute this, defaults to true
---    log_command = true, -- defaults to false unless admin only, then always true
---    capture_excess_arguments = true, defaults to false, captures excess arguments in the last argument, useful for sentences
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
    local description = options.description or '[Undocumented command]'
    local arguments = options.arguments or {}
    local default_values = options.default_values or {}
    local regular_only = options.regular_only or false
    local admin_only = options.admin_only or false
    local debug_only = options.debug_only or false
    local cheat_only = options.cheat_only or false
    local capture_excess_arguments = options.capture_excess_arguments or false
    local custom_help_text = options.custom_help_text or false
    local allowed_by_server = options.allowed_by_server or false
    local allowed_by_player = options.allowed_by_player
    local log_command = options.log_command or options.admin_only or false
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
        error(format("The command '%s' is not allowed by the server nor player, please enable at least one of them.", command_name))
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

    local extra = ''

    if allowed_by_server and not allowed_by_player then
        extra = ' (Server Only)'
    elseif allowed_by_player and admin_only then
        extra = ' (Admin Only)'
    elseif allowed_by_player and regular_only then
        extra = ' (Regulars Only)'
    end

    local help_text = custom_help_text or argument_list .. description .. extra

    commands.add_command(command_name, help_text, function (command)
        local print -- custom print reference in case no player is present
        local player = game.player
        local player_name = player and player.valid and player.name or '<server>'
        if not player or not player.valid then
            print = _G.print

            if not allowed_by_server then
                print(format("The command '%s' is not allowed to be executed by the server.", command_name))
                return
            end
        else
            print = player.print

            if not allowed_by_player then
                print(format("The command '%s' is not allowed to be executed by players.", command_name))
                return
            end

            if admin_only and not player.admin then
                print(format("The command '%s' requires admin status to be be executed.", command_name))
                return
            end

            if regular_only and not UserGroups.is_regular(player_name) then
                print(format("The command '%s' is not available to guests.", command_name))
                return
            end
        end

        local named_arguments = {}
        local from_command = {}
        local raw_parameter_index = 1
        for param in string.gmatch(command.parameter or '', '%S+') do
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
                insert(errors, format('Argument "%s" from command %s is missing.', argument, command_name))
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
            log(format('[%s Command] %s, used: %s %s', admin_only and 'Admin' or 'Player', player_name, command_name, serialize(named_arguments)))
        end

        local success, error = pcall(function ()
            callback(named_arguments, player, command.tick)
        end)

        if not success then
            local serialized_arguments = serialize(named_arguments)
            if _DEBUG then
                print(format("%s triggered an error running a command and has been logged: '%s' with arguments %s", player_name, command_name, serialized_arguments))
                print(error)
                return
            end

            print(format('There was an error running %s, it has been logged.', command_name))
            log(format("Error while running '%s' with arguments %s: %s", command_name, serialized_arguments, error))
        end
    end)
end

function Command.search(keyword)
    local matches = {}
    local count = 0
    keyword = keyword:lower()
    for name, description in pairs(commands.commands) do
        local command = format('%s %s', name, description)
        if match(command:lower(), keyword) then
            count = count + 1
            matches[count] = command
        end
    end

    -- built-in commands use LocalisedString, which cannot be translated until player.print is called
    for name in pairs(commands.game_commands) do
        name = name
        if match(name:lower(), keyword) then
            count = count + 1
            matches[count] = name
        end
    end

    return matches
end

--- Warns users of deprecated commands
local function notify_deprecated(event)
    local alternative = deprecated_command_alternatives[event.command]
    if alternative then
        local print = log
        if event.player_index then
            print = Game.get_player_by_index(event.player_index).print
        end
        print(string.format('Warning! Usage of the command "/%s" is deprecated. Please use "/%s" instead.', event.command, alternative))
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
                    Game.player_print('Sorry there was an error running ' .. cmd.name)
                end
            end
        )
    end
end

Event.add(defines.events.on_console_command, notify_deprecated)

return Command
