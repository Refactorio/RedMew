local Command = require 'utils.command'
local Rank = require 'features.rank_system'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Server = require 'features.server'
local Popup = require 'features.gui.popup'
local Global = require 'utils.global'
local Ranks = require 'resources.ranks'
local Core = require 'utils.core'

local Public = {}

function Public.control(config)

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
            global_data.restarting = nil
            return
        elseif state == 1 then
            local time_string = Core.format_time(game.ticks_played)
            local discord_crashsite_role = '<@&762441731194748958>' -- @crash_site
            --local discord_crashsite_role = '<@&593534612051984431>' -- @test
            Server.to_discord_raw(discord_crashsite_role .. ' **Crash Site has just restarted! Previous map lasted: ' .. time_string .. '!**')

            local unix_time = Server.get_current_time()
            local game_time = game.ticks_played
            Server.set_data('crash_site_data', tostring(unix_time),  game_time) -- Store the server unix time as key and total game ticks in the Scenario Data

            Popup.all('\nServer restarting!\nInitiated by ' .. data.name .. '\n')
        end

        double_print(state)

        data.state = state - 1
        Task.set_timeout_in_ticks(60, callback, data)
    end
)

local static_entities_to_check = {
    'spitter-spawner','biter-spawner',
    'small-worm-turret', 'medium-worm-turret','big-worm-turret', 'behemoth-worm-turret',
    'gun-turret', 'laser-turret', 'artillery-turret', 'flamethrower-turret'
}

local biter_entities_to_check = {
    'small-spitter', 'medium-spitter', 'big-spitter', 'behemoth-spitter',
    'small-biter', 'medium-biter', 'big-biter', 'behemoth-biter'
}

local function map_cleared(player)
    player = player or server_player
    local get_entity_count = game.forces["enemy"].get_entity_count
    -- Check how many of each turrets, worms and spawners are left and return false if there are any of each left.
    for i = 1, #static_entities_to_check do
        local name = static_entities_to_check[i]
        if get_entity_count(name) > 0 then
            player.print('All enemy spawners, worms, buildings, biters and spitters must be cleared before crashsite can be restarted.')
            return false
        end
    end

    -- Count all the remaining biters and spitters
    local biter_total = 0;
    for i = 1, #biter_entities_to_check do
        local name = biter_entities_to_check[i]
        biter_total = biter_total + get_entity_count(name)
    end

    -- Return false if more than 20 left. Players have had problems finding the last few biters so set to a reasonable value.
    if biter_total > 20 then
       player.print('All enemy spawners, worms, buildings are dead. Crashsite can be restarted when all biters and spitters are killed.')
       return false
    end
    return true
end

local function restart(args, player)
    player = player or server_player
    local sanitised_scenario = args.scenario_name

    if global_data.restarting then
        player.print('Restart already in progress')
        return
    end

    if player ~= server_player and Rank.less_than(player.name, Ranks.admin) then
        -- Check enemy count
        if not map_cleared(player) then
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

local function spy(args, player)
    local player_name = player.name
    local coin_count = player.get_item_count("coin")

    -- Parse the values from the location string
    -- {location = "[gps=-110,-17,redmew]"}
    local location_string = args.location
    local coords = {}
    local coord_count = 0
    for m in string.gmatch( location_string, "%-?%d+" ) do
        table.insert(coords, tonumber(m))
        coord_count = coord_count + 1
    end

    -- Do some checks then reveal the pinged map and remove 1000 coins
    if coord_count ~= 2 then
        game.players[player_name].print("[color=red]You need to add a valid location to send a spy fish. e.g /spy [gps=-110,-17,redmew][/color]")
        return
    elseif coin_count < 1000 then
        game.players[player_name].print("[color=red]Training these spy fish ain't cheap! You need more coins![/color]")
        return
    else
        local xpos=coords[1]
        local ypos=coords[2]
        local rad=16
        game.player.force.chart(game.player.surface, {{xpos-rad, ypos-rad}, {xpos+rad, ypos+rad}})
        game.print("[color=red]Jayefuu used the /spy command and spent 1000 coins to train a fish to spy on the enemy [gps=" .. xpos .. "," .. ypos .. ",redmew][/color]")
        local inv = game.player.get_inventory(1)
        inv.remove("coin")
        player.insert({name="coin", count=coin_count-1000})
    end
end

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
    'abort',
    {
        description = {'command_description.crash_site_restart_abort'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    abort
)


local default_name = config.scenario_name or 'crashsite'
Command.add(
    'crash-site-restart',
    {
        description = {'command_description.crash_site_restart'},
        arguments = {'scenario_name'},
        default_values = {scenario_name = default_name},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    restart
)

Command.add(
    'restart',
    {
        description = {'command_description.crash_site_restart'},
        arguments = {'scenario_name'},
        default_values = {scenario_name = default_name},
        required_rank = Ranks.auto_trusted,
        allowed_by_server = true
    },
    restart
)

Command.add(
    'spy',
    {
        description = {'command_description.crash_site_spy'},
        arguments = {'location'},
        required_rank = Ranks.auto_trusted,
        allowed_by_server = false
    },
    spy
)
end

return Public
