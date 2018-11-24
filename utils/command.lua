local insert = table.insert

local Command = {}

---Adds a command to be executed.
---
---Options table accepts the following structure: {
---    description = 'Teleports you to the player',
---    arguments = {'foo', 'bar'},
---    admin_only = true, -- defaults to false
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
    local admin_only = options.admin_only or false
    local log_command = options.log_command or options.admin_only or false
    local argument_list = ''

    for _, argument in ipairs(arguments) do
        argument_list = string.format('%s<%s> ', argument_list, argument)
    end

    commands.add_command(command_name, argument_list .. description .. (admin_only and ' (Admin Only)' or ''), function (command)
        local print -- custom print reference in case no player is present
        local player_index = command.player_index
        local player = game.player
        if not player or not player.valid then
            print = function (message)
                log(string.format('Trying to print message to player #%d, but not such player found: %s', player_index, message))
            end
        else
            print = player.print
        end

        local named_arguments = {}
        local from_command = {}
        for param in string.gmatch(command.parameter or '', '%S+') do
            insert(from_command, param)
        end

        for index, argument in ipairs(arguments) do
            local parameter = from_command[index]
            if not parameter then
                print(string.format('Argument %s from command %s is missing.', argument, command_name))
                return
            end

            named_arguments[argument] = parameter
        end

        if log_command then
            log(string.format(
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
            log(string.format('Error while running %s: %s', command_name, error))
            print(string.format('There was an error running %s, it has been logged.', command_name))
        end
    end)
end

return Command
