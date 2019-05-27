local DebugView = require 'features.gui.debug.main_view'
local Model = require 'features.gui.debug.model'
local Command = require 'utils.command'

local loadstring = loadstring
local pcall = pcall
local dump = Model.dump
local log = log

Command.add(
    'debug',
    {
        description = {'command_descriptiondebuger'},
        debug_only = true
    },
    function(_, player)
        DebugView.open_dubug(player)
    end
)

Command.add(
    'dump',
    {
        arguments = {'str'},
        capture_excess_arguments = true,
        allowed_by_server = true,
        debug_only = true,
        description = 'dumps value to player.print'
    },
    function(args, player)
        local p
        if player then
            p = player.print
        else
            p = print
        end

        local func, err = loadstring('return ' .. args.str)

        if not func then
            p(err)
            return
        end

        local suc, value = pcall(func)

        if not suc then
            if value then
                local i = value:find('\n')
                if i then
                    p(value:sub(1, i))
                    return
                end

                i = value:find('%s')
                if i then
                    p(value:sub(i + 1))
                end
            end

            return
        end

        p(dump(value))
    end
)

Command.add(
    'dump-log',
    {
        arguments = {'str'},
        capture_excess_arguments = true,
        allowed_by_server = true,
        debug_only = true,
        description = 'dumps value to log'
    },
    function(args, player)
        local p
        if player then
            p = player.print
        else
            p = print
        end

        local func, err = loadstring('return ' .. args.str)

        if not func then
            p(err)
            return
        end

        local suc, value = pcall(func)

        if not suc then
            p(value)
            return
        end

        log(dump(value))
    end
)

Command.add(
    'dump-file',
    {
        arguments = {'str'},
        capture_excess_arguments = true,
        allowed_by_server = true,
        debug_only = true,
        description = 'dumps value to dump.lua'
    },
    function(args, player)
        local p
        local player_index
        if player then
            p = player.print
            player_index = player.index
        else
            p = print
            player_index = 0
        end

        local func, err = loadstring('return ' .. args.str)

        if not func then
            p(err)
            return
        end

        local suc, value = pcall(func)

        if not suc then
            p(value)
            return
        end

        value = dump(value)
        game.write_file('dump.lua', value, false, player_index)
    end
)
