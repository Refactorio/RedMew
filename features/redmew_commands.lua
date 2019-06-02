local Game = require 'utils.game'
local Timestamp = require 'utils.timestamp'
local Command = require 'utils.command'
local Utils = require 'utils.core'
local Server = require 'features.server'
local Rank = require 'features.rank_system'
local Donator = require 'features.donator'
local Color = require 'resources.color_presets'
local ScoreTracker = require 'utils.score_tracker'
local format_number = require 'util'.format_number
local player_data_to_show = global.config.redmew_commands.whois.player_data_to_show
local print_to_player = Game.player_print
local concat = table.concat
local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local floor = math.floor

--- Informs the actor that there is no target. Acts as a central place where this message can be changed.
local function print_no_target(target_name)
    print_to_player({'common.fail_no_target', target_name}, Color.fail)
end

--- Kill a player with fish as the cause of death.
local function do_fish_kill(player, suicide)
    local c = player.character
    if not c then
        return false
    end

    local e = player.surface.create_entity {name = 'fish', position = player.position}
    c.die(player.force, e)

    -- Don't want people killing themselves for free fish.
    if suicide then
        e.destroy()
    end

    return true
end

--- Kill a player: admins and the server can kill others, non-admins can only kill themselves
local function kill(args, player)
    local target_ident = args.player
    local target, target_name = Utils.validate_player(target_ident)
    if target_ident and not target then
        if not target then
            print_no_target(target_ident)
            return
        end
    end

    if player then
        if not target or target == player then -- player suicide
            if not do_fish_kill(player, true) then
                print_to_player({'redmew_commands.kill_fail_suicide_no_character'})
            end
        elseif target and player.admin then -- admin killing target
            if not do_fish_kill(target) then
                print_to_player({'redmew_commands.kill_fail_target_no_character'}, target_name)
            end
        else -- player failing to kill target
            print_to_player({'redmew_commands.kill_fail_no_perm'})
        end
    elseif target then -- server killing target
        if not do_fish_kill(target) then
            print_to_player({'redmew_commands.kill_fail_target_no_character'}, target_name)
        end
    end
end

--- Check players' afk times
local function afk()
    local count = 0
    for _, v in pairs(game.players) do
        local afk_time = v.afk_time
        if afk_time > 300 then
            count = count + 1
            local time = ' '
            if afk_time > 21600 then
                time = time .. floor(afk_time / 216000) .. ' hours '
            end
            if afk_time > 3600 then
                time = time .. floor(afk_time / 3600) % 60 .. ' minutes and '
            end
            time = time .. floor(v.afk_time / 60) % 60 .. ' seconds.'
            print_to_player(v.name .. ' has been afk for' .. time)
        end
    end
    if count == 0 then
        print_to_player({'redmew_commands.afk_no_afk'})
    end
end

--- Lets a player set their zoom level
local function zoom(args, player)
    local zoom_val = tonumber(args.zoom)
    if zoom_val then
        player.zoom = zoom_val
    else
        print_to_player({'redmew_commands.zoom_fail'})
    end
end

--- Creates an alert for the player at the location of their target
local function find_player(args, player)
    local target_ident = args.player
    local target, target_name = Utils.validate_player(target_ident)

    if not target then
        print_no_target(target_ident)
        return
    end

    target = target.character
    if not target or not target.valid then
        print_to_player({'redmew_commands.find_player_fail_no_character', target_name})
        return
    end

    player.add_custom_alert(target, {type = 'virtual', name = 'signal-F'}, target_name, true)
end

--- Turns on rail block visualization for player
local function show_rail_block(_, player)
    local vs = player.game_view_settings
    local show = not vs.show_rail_block_visualisation
    vs.show_rail_block_visualisation = show

    print_to_player({'redmew_commands.show_rail_block_success', tostring(show)})
end

--- Provides the time on the server
local function server_time(_, player)
    local p
    if not player then
        p = print
    elseif player.valid then
        p = player.print
    else
        return
    end

    local secs = Server.get_current_time()
    if secs == nil then
        p({'redmew_commands.server_time_fail'})
    else
        p(Timestamp.to_string(secs))
    end
end

local function list_seeds()
    local seeds = {}
    local count_of_seeds = 0
    for _, surface in pairs(game.surfaces) do
        seeds[count_of_seeds + 1] = surface.name
        seeds[count_of_seeds + 2] = ': '
        seeds[count_of_seeds + 3] = tostring(surface.map_gen_settings.seed)
        count_of_seeds = count_of_seeds + 4
        seeds[count_of_seeds] = ', '
    end

    seeds[#seeds] = nil
    seeds = concat(seeds)
    print_to_player(seeds)
end

local function print_version()
    local version_str
    if global.redmew_version then
        version_str = global.redmew_version
    else
        version_str = {'redmew_commands.print_version_from_source'}
    end
    print_to_player(version_str)
end

--- Prints information about the target player
local function print_player_info(args, player)
    local target_ident = args.player
    local target, target_name, player_index = Utils.validate_player(target_ident)

    if not target then
        print_no_target(target_ident)
        return
    end

    local sep = ': '
    print_to_player({'', {'common.player_name'}, sep, target_name})
    print_to_player({'', {'common.connection_status'}, sep, {target.connected and 'common.online' or 'common.offline'}})
    print_to_player({'', {'common.player_index'}, sep, target.index})
    print_to_player({'', {'common.player_rank'}, sep, Rank.get_player_rank_name(target_name)})
    print_to_player({'', {'ranks.donator'}, sep, {Donator.is_donator(target.name) and 'common.yes' or 'common.no'}})
    print_to_player({'', {'common.time_played'}, sep, Utils.format_time(target.online_time)})
    print_to_player({'', {'common.afk_time'}, sep, Utils.format_time(target.afk_time or 0)})
    print_to_player({'', {'common.current_force'}, sep, target.force.name})
    print_to_player({'', {'common.current_surface'}, sep, target.surface.name})
    print_to_player({'', {'common.player_tag'}, sep, target.tag})

    local scores = ScoreTracker.get_player_scores_with_metadata(player_index, player_data_to_show)

    for i = 1, #scores do
        local score_data = scores[i]
        print_to_player({'', score_data.locale_string, sep, format_number(score_data.value, true)})
    end

    if (not player or player.admin) and args.inventory then
        local m_inventory = target.get_inventory(defines.inventory.character_main)
        m_inventory = m_inventory.get_contents()
        print_to_player('Main and hotbar inventories: ')
        print_to_player(serpent.line(m_inventory))
    end
end

-- Command registrations

Command.add(
    'kill',
    {
        description = {'command_description.kill'},
        arguments = {'player'},
        default_values = {player = false},
        allowed_by_server = true
    },
    kill
)

Command.add(
    'afk',
    {
        description = {'command_description.afk'},
        allowed_by_server = true
    },
    afk
)

Command.add(
    'zoom',
    {
        description = {'command_description.zoom'},
        arguments = {'zoom'}
    },
    zoom
)

Command.add(
    'find',
    {
        description = {'command_description.find'},
        arguments = {'player'}
    },
    find_player
)

Command.add(
    'show-rail-block',
    {
        description = {'command_description.show_rail_block'}
    },
    show_rail_block
)

Command.add(
    'server-time',
    {
        description = {'command_description.server_time'},
        allowed_by_server = true
    },
    server_time
)

Command.add(
    'seeds',
    {
        description = {'command_description.seeds'},
        allowed_by_server = true
    },
    list_seeds
)

Command.add(
    'redmew-version',
    {
        description = {'command_description.redmew_version'},
        allowed_by_server = true
    },
    print_version
)

Command.add(
    'whois',
    {
        description = {'command_description.whois'},
        arguments = {'player', 'inventory'},
        default_values = {inventory = false},
        allowed_by_server = true
    },
    print_player_info
)
