local insert = table.insert
local format = string.format

local Command = {}

---Adds a command to be executed.
---
---Options table accepts the following structure: {
---    description = 'A description of the command',
---    arguments = {'foo', 'bar'}, -- maps arguments to these names in the given sequence
---    default_values = {'bar' = nil}, -- gives a default value to 'bar' when omitted
---    admin_only = true, -- defaults to false
---    debug_only = false, -- only registers it if _DEBUG is set to true when false
---    allowed_by_server = false -- lets the server execute this, defaults to false
---    allowed_by_player = true -- lets players execute this, defaults to true
---    log_command = true, -- defaults to false unless admin only, then always true
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
    local admin_only = options.admin_only or false
    local debug_only = options.debug_only or false
    local allowed_by_server = options.allowed_by_server or false
    local allowed_by_player = options.allowed_by_player
    local log_command = options.log_command or options.admin_only or false
    local argument_list = ''

    if nil == options.allowed_by_player then
        allowed_by_player = true
    end

    if not _DEBUG and debug_only then
        return
    end

    if not allowed_by_player and not allowed_by_server then
        error(format("The command '%s' is not allowed by the server nor player, please enable at least one of them.", command_name))
    end

    for _, argument_name in ipairs(arguments) do
        local argument_display = argument_name
        for default_value_name, _ in pairs(default_values) do
            if default_value_name == argument_name then
                argument_display = argument_display .. ':optional'
                break
            end
        end

        argument_list = format('%s<%s> ', argument_list, argument_display)
    end

    local extra = ''

    if allowed_by_server and not allowed_by_player then
        extra = ' (Server Only)'
    elseif allowed_by_player and admin_only then
        extra = ' (Admin Only)'
    end

    commands.add_command(command_name, argument_list .. description .. extra, function (command)
        local print -- custom print reference in case no player is present
        local player_index = command.player_index
        local player = game.player
        if not player or not player.valid then
            print = function (message)
                log(format('Trying to print message to player #%d, but not such player found: %s', player_index, message))
            end

            if not allowed_by_server then
                log(format("The command '%s' is not allowed to be executed by the server.", command_name))
                return
            end
        else
            print = player.print

            if not allowed_by_player then
                print(format("The command '%s' is not allowed to be executed by players.", command_name))
                return
            end

            if admin_only and not player.admin then
                print(format("The command '%s' requires an admin to be be executed", command_name))
                return
            end
        end

        local named_arguments = {}
        local from_command = {}
        for param in string.gmatch(command.parameter or '', '%S+') do
            insert(from_command, param)
        end

        local errors = {}

        for index, argument in ipairs(arguments) do
            local parameter = from_command[index]

            if not parameter then
                for default_value_name, default_value in pairs(default_values) do
                    if default_value_name == argument then
                        parameter = default_value
                        break
                    end
                end
            end

            if not parameter then
                insert(errors, format('Argument %s from command %s is missing.', argument, command_name))
            else
                named_arguments[argument] = parameter
            end
        end

        local return_early = false

        for _, error in ipairs(errors) do
            return_early = true
            print(error)
        end

        if return_early then
            return
        end

        if log_command then
            log(format(
                '[%s Command] %s, used: %s %s',
                admin_only and 'Admin' or 'Player',
                player and player.valid and player.name or '<server>',
                command_name,
                serpent.line(named_arguments)
            ))
        end

        if _DEBUG then
            -- in debug mode it will crash and report errors directly
            callback(named_arguments, player, command.tick)
            return
        end

        -- safety check for the command
        local success, error = pcall(function ()
            callback(named_arguments, player, command.tick)
        end)

        if not success then
            log(format('Error while running %s: %s', command_name, error))
            print(format('There was an error running %s, it has been logged.', command_name))
        end
    end)
end

return Command
