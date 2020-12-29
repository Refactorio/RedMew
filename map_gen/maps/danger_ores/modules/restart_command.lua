local Command = require 'utils.command'
local Rank = require 'features.rank_system'
local Ranks = require 'resources.ranks'
local Global = require 'utils.global'
local Discord = require 'resources.discord'
local Server = require 'features.server'
local Popup = require 'features.gui.popup'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Core = require 'utils.core'
local ShareGlobals = require 'map_gen.maps.danger_ores.modules.shared_globals'

return function(config)
    local default_name = config.scenario_name or 'terraforming-danger-ore'

    local map_promotion_channel = Discord.channel_names.map_promotion
    local danger_ore_role_mention = Discord.role_mentions.danger_ore

    local server_player = {name = '<server>', print = print}
    local global_data = {restarting = nil}

    Global.register(global_data, function(tbl)
        global_data = tbl
    end)

    local function double_print(str)
        game.print(str)
        print(str)
    end

    local callback
    callback = Token.register(function(data)
        if not global_data.restarting then
            return
        end

        local state = data.state
        if state == 0 then
            Server.start_scenario(data.scenario_name)
            double_print('restarting')
            global_data.restarting = nil
            return
        elseif state == 1 then
            Popup.all('\nServer restarting!\nInitiated by ' .. data.name .. '\n')

            local time_string = Core.format_time(game.ticks_played)
            Server.to_discord_named_raw(map_promotion_channel, danger_ore_role_mention
                .. ' **Danger Ore has just restarted! Previous map lasted: ' .. time_string .. '!**')
        end

        double_print(state)

        data.state = state - 1
        Task.set_timeout_in_ticks(60, callback, data)
    end)

    local function restart(args, player)
        player = player or server_player
        local sanitised_scenario = args.scenario_name

        if global_data.restarting then
            player.print('Restart already in progress')
            return
        end

        if player ~= server_player and Rank.less_than(player.name, Ranks.admin) then
            if not ShareGlobals.data.map_won then
                player.print({'command_description.danger_ore_restart_condition_not_met'})
                return
            end

            -- Limit the ability of non-admins to call the restart function with arguments to change the scenario
            -- If not an admin, restart the same scenario always
            sanitised_scenario = config.scenario_name
        end

        global_data.restarting = true

        double_print('#################-Attention-#################')
        double_print('Server restart initiated by ' .. player.name)
        double_print('###########################################')

        for _, p in pairs(game.players) do
            if p.admin then
                p.print('Abort restart with /abort')
            end
        end
        print('Abort restart with /abort')
        Task.set_timeout_in_ticks(60, callback, {name = player.name, scenario_name = sanitised_scenario, state = 10})
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

    Command.add('abort',
        {description = {'command_description.abort'}, required_rank = Ranks.admin, allowed_by_server = true}, abort)

    Command.add('restart', {
        description = {'command_description.restart'},
        arguments = {'scenario_name'},
        default_values = {scenario_name = default_name},
        required_rank = Ranks.guest,
        allowed_by_server = true
    }, restart)
end
