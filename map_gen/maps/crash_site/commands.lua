local Command = require 'utils.command'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Server = require 'features.server'
local Popup = require 'features.gui.popup'
local Global = require 'utils.global'
local Ranks = require 'resources.ranks'

local server_player = {name = '<server>', print = print}

local global_data = {restarting = nil}

Global.register(
    global_data,
    function(tbl)
        global_data = tbl
    end
)

local function double_print(str)
    game.print(str)
    print(str)
end

local callback
callback =
    Token.register(
    function(data)
        if not global_data.restarting then
            return
        end

        local state = data.state
        if state == 0 then
            Server.start_scenario(data.scenario_name)
            double_print('restarting')
            return
        elseif state == 1 then
            Popup.all('\nServer restarting!\nInitiated by ' .. data.name .. '\n')
        end

        double_print(state)

        data.state = state - 1
        Task.set_timeout_in_ticks(60, callback, data)
    end
)

local function restart(args, player)
    player = player or server_player

    if global_data.restarting then
        player.print('Restart already in progress')
        return
    end

    global_data.restarting = true

    double_print('#################-Attention-#################')
    double_print('Server restart initiated by ' .. player.name)
    double_print('###########################################')

    for k, v in pairs(game.players) do
        if v.admin then
            game.print('Abort restart with /abort')
        end
    end
    print('Abort restart with /abort')

    Task.set_timeout_in_ticks(60, callback, {name = player.name, scenario_name = args.scenario_name, state = 10})
end

local function abort(_, player)
    player = player or server_player

    if global_data.restarting then
        global_data.restarting = nil
        double_print('Restart aborted by ' .. player.name)
    else
        player.print('Cannot abort a restart that is not in progress.')
    end
end

Command.add(
    'crash-site-restart',
    {
        description = {'command_description.crash_site_restart'},
        arguments = {'scenario_name'},
        default_values = {scenario_name = 'crashsite'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    restart
)

Command.add(
    'crash-site-restart-abort',
    {
        description = {'command_description.crash_site_restart_abort'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    abort
)

Command.add(
    'restart',
    {
        description = {'command_description.crash_site_restart'},
        arguments = {'scenario_name'},
        default_values = {scenario_name = 'crashsite'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    restart
)

Command.add(
    'abort',
    {
        description = {'command_description.crash_site_restart_abort'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    abort
)
