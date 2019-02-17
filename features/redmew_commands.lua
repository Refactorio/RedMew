local Game = require 'utils.game'
local Timestamp = require 'utils.timestamp'
local Command = require 'utils.command'
local Settings = require 'utils.redmew_settings'
local Utils = require 'utils.core'
local Server = require 'features.server'
local Walkabout = require 'features.walkabout'
local PlayerStats = require 'features.player_stats'
local Rank = require 'features.rank_system'
local Donator = require 'features.donator'

local format = string.format
-- local ceil = math.ceil
local concat = table.concat
local pcall = pcall
local tostring = tostring
local tonumber = tonumber
local pairs = pairs

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
    local target_name = args.player
    local target
    if target_name then
        target = game.players[target_name]
        if not target then
            Game.player_print(format('Player %s was not found.', target_name))
            return
        end
    end

    if (player and Walkabout.is_on_walkabout(player.index)) or (target and Walkabout.is_on_walkabout(target.index)) then
        Game.player_print("A player on walkabout cannot be killed by a mere fish, don't waste your efforts.")
        return
    end

    if not target and player then
        if not do_fish_kill(player, true) then
            Game.player_print("Sorry, you don't have a character to kill.")
        end
    elseif player then
        if target == player then
            if not do_fish_kill(player, true) then
                Game.player_print("Sorry, you don't have a character to kill.")
            end
        elseif target and player.admin then
            if not do_fish_kill(target) then
                Game.player_print(table.concat {"'Sorry, '", target.name, "' doesn't have a character to kill."})
            end
        else
            Game.player_print("Sorry you don't have permission to use the kill command on other players.")
        end
    elseif target then
        if not do_fish_kill(target) then
            Game.player_print(table.concat {"'Sorry, '", target.name, "' doesn't have a character to kill."})
        end
    end
end

--- Check players' afk times
local function afk()
    local count = 0
    for _, v in pairs(game.players) do
        if v.afk_time > 300 then
            count = count + 1
            local time = ' '
            if v.afk_time > 21600 then
                time = time .. math.floor(v.afk_time / 216000) .. ' hours '
            end
            if v.afk_time > 3600 then
                time = time .. math.floor(v.afk_time / 3600) % 60 .. ' minutes and '
            end
            time = time .. math.floor(v.afk_time / 60) % 60 .. ' seconds.'
            Game.player_print(v.name .. ' has been afk for' .. time)
        end
    end
    if count == 0 then
        Game.player_print('No players afk.')
    end
end

--- Lets a player set their zoom level
local function zoom(args, player)
    if tonumber(args.zoom) then
        player.zoom = tonumber(args.zoom)
    else
        Game.player_print('You must give zoom a number.')
    end
end

--- Creates an alert for the player at the location of their target
local function find_player(args, player)
    local name = args.player

    local target = game.players[name]
    if not target then
        Game.player_print('player ' .. name .. ' not found')
        return
    end

    target = target.character
    if not target or not target.valid then
        Game.player_print('player ' .. name .. ' does not have a character')
        return
    end

    player.add_custom_alert(target, {type = 'virtual', name = 'signal-F'}, name, true)
end

--- Turns on rail block visualization for player
local function show_rail_block(_, player)
    local vs = player.game_view_settings
    local show = not vs.show_rail_block_visualisation
    vs.show_rail_block_visualisation = show

    Game.player_print('show_rail_block_visualisation set to ' .. tostring(show))
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
        p('Server time is not available, is this game running on a Redmew server?')
    else
        p(Timestamp.to_string(secs))
    end
end

local function search_command(arguments) -- TODO: Re-enable this when (locale) has been properly integrated
    Game.player_print('Sorry, search is temporarily out of order')
    return arguments -- return args so that we avoid a lint warning

    --[[
    local keyword = arguments.keyword
    local p = Game.player_print
    if #keyword < 2 then
        p('Keyword should be 2 characters or more')
        return
    end

    local per_page = 7
    local matches = Command.search(keyword)
    local count = #matches

    if count == 0 then
        p('---- 0 Search Results ----')
        p(format('No commands found matching "%s"', keyword))
        p('-------------------------')
        return
    end

    local page = tonumber(arguments.page)
    local pages = ceil(count / per_page)

    if nil == page then
        p('Page should be a valid number')
        return
    end

    -- just show the last page
    if page > pages then
        page = pages
    end

    if page < 1 then
        page = 1
    end

    local page_start = per_page * (page - 1) + 1
    local page_end = per_page * page
    page_end = page_end <= count and page_end or count

    p(format('---- %d Search %s -----', count, count == 1 and 'Result' or 'Results'))
    p(format('Searching for: "%s"', keyword))
    for i = page_start, page_end do
        p(format('[%d] /%s', i, matches[i]))
    end
    p(format('-------- Page %d / %d --------', page, pages))
    --[[]]
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
    Game.player_print(seeds)
end

local function print_version()
    local version_str
    if global.redmew_version then
        version_str = global.redmew_version
    else
        version_str = 'This map was created from source code, only releases (zips with names) and server saves have versions'
    end
    Game.player_print(version_str)
end

--- Prints information about the target player
local function print_player_info(args, player)
    local name = args.player
    local target = game.players[name]
    if not target then
        Game.player_print('Target not found')
        return
    end

    local index = target.index
    local info_t = {
        'redmew_commands.whois_formatter',
        {'format.1_colon_2', 'Name', name},
        {'format.single_item', target.connected and 'Online: yes' or 'Online: no'},
        {'format.1_colon_2', 'Index', target.index},
        {'format.1_colon_2', 'Rank', Rank.get_player_rank_name(name)},
        {'format.single_item', Donator.is_donator(target.name) and 'Donator: yes' or 'Donator: no'},
        {'format.1_colon_2', 'Time played', Utils.format_time(target.online_time)},
        {'format.1_colon_2', 'AFK time', Utils.format_time(target.afk_time or 0)},
        {'format.1_colon_2', 'Force', target.force.name},
        {'format.1_colon_2', 'Surface', target.surface.name},
        {'format.1_colon_2', 'Tag', target.tag},
        {'format.1_colon_2', 'Distance walked', PlayerStats.get_walk_distance(index)},
        {'format.1_colon_2', 'Coin earned', PlayerStats.get_coin_earned(index)},
        {'format.1_colon_2', 'Coin spent', PlayerStats.get_coin_spent(index)},
        {'format.1_colon_2', 'Deaths', PlayerStats.get_death_count(index)},
        {'format.1_colon_2', 'Crafted items', PlayerStats.get_crafted_item(index)},
        {'format.1_colon_2', 'Chat messages', PlayerStats.get_console_chat(index)}
    }
    Game.player_print(info_t)

    if (not player or player.admin) and args.inventory then
        local m_inventory = target.get_inventory(defines.inventory.player_main)
        m_inventory = m_inventory.get_contents()
        local q_inventory = target.get_inventory(defines.inventory.player_quickbar)
        q_inventory = q_inventory.get_contents()
        Game.player_print('Main and hotbar inventories: ')
        Game.player_print(serpent.line(m_inventory))
        Game.player_print(serpent.line(q_inventory))
    end
end

-- Command registrations

Command.add(
    'kill',
    {
        description = 'Will kill you.',
        arguments = {'player'},
        default_values = {player = false},
        allowed_by_server = true
    },
    kill
)

Command.add(
    'afk',
    {
        description = 'Shows how long players have been afk.',
        allowed_by_server = true
    },
    afk
)

Command.add(
    'zoom',
    {
        description = 'Sets your zoom.',
        arguments = {'zoom'}
    },
    zoom
)

Command.add(
    'find',
    {
        description = 'shows an alert on the map where the player is located',
        arguments = {'player'}
    },
    find_player
)

Command.add(
    'show-rail-block',
    {
        description = 'Toggles rail block visualisation.'
    },
    show_rail_block
)

Command.add(
    'server-time',
    {
        description = "Prints the server's time.",
        allowed_by_server = true
    },
    server_time
)

Command.add(
    'search-command',
    {
        description = 'Search for commands matching the keyword in name or description',
        arguments = {'keyword', 'page'},
        default_values = {page = 1},
        allowed_by_server = true
    },
    search_command
)

Command.add(
    'seeds',
    {
        description = 'List the seeds of all surfaces',
        allowed_by_server = true
    },
    list_seeds
)

Command.add(
    'redmew-version',
    {
        description = 'Prints the version of the RedMew scenario',
        allowed_by_server = true
    },
    print_version
)

Command.add(
    'whois',
    {
        description = 'provides information about a given player, admins can see the inventory of a player by adding "yes" as a second argument',
        arguments = {'player', 'inventory'},
        default_values = {inventory = false},
        allowed_by_server = true
    },
    print_player_info
)

-- No man's land / free for all
Command.add(
    'redmew-setting-set',
    {
        description = 'Set a setting for yourself',
        arguments = {'setting_name', 'new_value'},
        capture_excess_arguments = true
    },
    function(arguments, player)
        local value
        local setting_name = arguments.setting_name
        local success,
            data =
            pcall(
            function()
                value = Settings.set(player.index, setting_name, arguments.new_value)
            end
        )

        if not success then
            local i = data:find('%s')
            player.print(data:sub(i + 1))
            return
        end

        player.print(format('Changed "%s" to: "%s"', setting_name, value))
    end
)

Command.add(
    'redmew-setting-get',
    {
        description = 'Display a setting value for yourself',
        arguments = {'setting_name'}
    },
    function(arguments, player)
        local value
        local setting_name = arguments.setting_name
        local success,
            data =
            pcall(
            function()
                value = Settings.get(player.index, setting_name)
            end
        )

        if not success then
            local i = data:find('%s')
            player.print(data:sub(i + 1))
            return
        end

        player.print(format('Setting "%s" has a value of: "%s"', setting_name, value))
    end
)

Command.add(
    'redmew-setting-all',
    {
        description = 'Display all settings for yourself'
    },
    function(_, player)
        for name, value in pairs(Settings.all(player.index)) do
            player.print(format('%s=%s', name, value))
        end
    end
)
