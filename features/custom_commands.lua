local Task = require 'utils.Task'
local Event = require 'utils.event'
local Token = require 'utils.token'
local UserGroups = require 'features.user_groups'
local Utils = require 'utils.core'
local Game = require 'utils.game'
local Report = require 'features.report'
local Server = require 'features.server'
local Timestamp = require 'utils.timestamp'
local Command = require 'utils.command'
local format = string.format
local ceil = math.ceil

local deprecated_command_alternatives = {
    ['silent-command'] = 'sc'
}

Event.add(defines.events.on_console_command, function (event)
        local alternative = deprecated_command_alternatives[event.command]
        if alternative then
            local print = log
            if event.player_index then
                print = Game.get_player_by_index(event.player_index).print
            end
            print(string.format('Warning! Usage of the command /"%s" is deprecated. Please use "%s" instead.', event.command, alternative))
        end
    end
)

--- Takes a target and teleports them to player. (admin only)
local function invoke(cmd)
    if not (game.player and game.player.admin) then
        Utils.cant_run(cmd.name)
        return
    end
    local target = cmd['parameter']
    if target == nil or game.players[target] == nil then
        Game.player_print('Unknown player.')
        return
    end
    local pos = game.player.surface.find_non_colliding_position('player', game.player.position, 0, 1)
    game.players[target].teleport({pos.x, pos.y}, game.player.surface)
    game.print(target .. ', get your ass over here!')
end

--- Takes a target and teleports player to target. (admin only)
local function teleport_player(cmd)
    if not (game.player and game.player.admin) then
        Utils.cant_run(cmd.name)
        return
    end
    local target = cmd['parameter']
    if target == nil or game.players[target] == nil then
        Game.player_print('Unknown player.')
        return
    end
    local surface = game.players[target].surface
    local pos = surface.find_non_colliding_position('player', game.players[target].position, 0, 1)
    game.player.teleport(pos, surface)
    game.print(target .. "! watcha doin'?!")
    game.player.print('You have teleported to ' .. game.players[target].name)
end

--- Takes a selected entity and teleports player to entity. (admin only)
local function teleport_location(cmd)
    if not (game.player and game.player.admin) then
        Utils.cant_run(cmd.name)
        return
    end
    if game.player.selected == nil then
        Game.player_print('Nothing selected.')
        return
    end
    local pos = game.player.surface.find_non_colliding_position('player', game.player.selected.position, 0, 1)
    game.player.teleport(pos)
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
local function kill(cmd)
    local player = game.player
    local param = cmd.parameter
    local target
    if param then
        target = game.players[param]
        if not target then
            Game.player_print(table.concat {"Sorry, player '", param, "' was not found."})
            return
        end
    end

    if global.walking then
        if (player and global.walking[player.index]) or (target and global.walking[target.index]) then
            Game.player_print("A player on walkabout cannot be killed by a mere fish, don't waste your efforts.")
            return
        end
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
    else
        if param then
            Game.player_print(table.concat {"Sorry, player '", param, "' was not found."})
        else
            Game.player_print('Usage: /kill <player>')
        end
    end
end

local function regular(cmd)
    if game.player and not game.player.admin then
        Utils.cant_run(cmd.name)
        return
    end
    if cmd.parameter == nil then
        Game.player_print('Command failed. Usage: /regular <promote, demote>, <player>')
        return
    end

    local params = {}
    for param in string.gmatch(cmd.parameter, '%S+') do
        table.insert(params, param)
    end
    if #params == 2 then
        if params[1] == 'promote' then
            UserGroups.add_regular(params[2])
        elseif params[1] == 'demote' then
            UserGroups.remove_regular(params[2])
        else
            Game.player_print('Command failed. Usage: /regular <promote, demote>, <player>')
        end
    elseif #params == 1 and params[1] ~= 'promote' and params[1] ~= 'demote' then
        UserGroups.add_regular(params[1])
    else
        Game.player_print('Command failed. Usage: /regular <promote, demote>, <player>')
    end
end

--- Check players' afk times
local function afk()
    for _, v in pairs(game.players) do
        if v.afk_time > 300 then
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
end

--- Follows a player
local function follow(cmd)
    if not game.player then
        log("<Server can't do that.")
        return
    end
    if cmd.parameter ~= nil and game.players[cmd.parameter] ~= nil then
        global.follows[game.player.name] = cmd.parameter
        global.follows.n_entries = global.follows.n_entries + 1
    else
        Game.player_print(
            'Usage: /follow <player> makes you follow the player. Use /unfollow to stop following a player.'
        )
    end
end

--- Stops following a player
local function unfollow()
    if not game.player then
        log("<Server can't do that.")
        return
    end
    if global.follows[game.player.name] ~= nil then
        global.follows[game.player.name] = nil
        global.follows.n_entries = global.follows.n_entries - 1
    end
end

--- A table of players with tpmode turned on
global.tp_players = {}

--- If a player is in the global.tp_players list, remove ghosts they place and teleport them to that position
local function built_entity(event)
    local index = event.player_index

    if global.tp_players[index] then
        local entity = event.created_entity

        if not entity or not entity.valid or entity.type ~= 'entity-ghost' then
            return
        end

        Game.get_player_by_index(index).teleport(entity.position)
        entity.destroy()
    end
end
Event.add(defines.events.on_built_entity, built_entity)

--- Adds/removes players from the tp_players table (admin only)
local function toggle_tp_mode(cmd)
    if not (game.player and game.player.admin) then
        Utils.cant_run(cmd.name)
        return
    end

    local index = game.player.index
    local toggled = global.tp_players[index]

    if toggled then
        global.tp_players[index] = nil
        Game.player_print('tp mode is now off')
    else
        global.tp_players[index] = true
        Game.player_print('tp mode is now on - place a ghost entity to teleport there.')
    end
end

--- Checks if we have a permission group named 'banned' and if we don't, create it
local function get_group()
    local group = game.permissions.get_group('Banned')
    if not group then
        game.permissions.create_group('Banned')
        group = game.permissions.get_group('Banned')
        if group then
            for i = 2, 174 do
                group.set_allows_action(i, false)
            end
        else
            game.print(
                'This would have nearly crashed the server, please consult the next best scenario dev (valansch or TWLtriston).'
            )
        end
    end
    return group
end

--- Removes player from the tempban list (by changing them back to the default permissions group)
local custom_commands_untempban =
    Token.register(
    function(param)
        game.print(param.name .. ' is out of timeout.')
        game.permissions.get_group('Default').add_player(param.name)
    end
)

--- Gives a player a temporary ban
local function tempban(cmd)
    if (not game.player) or not game.player.admin then
        Utils.cant_run(cmd.name)
        return
    end
    if cmd.parameter == nil then
        Game.player_print('Tempban failed. Usage: /tempban <player> <minutes> Temporarily bans a player.')
        return
    end
    local params = {}
    for param in string.gmatch(cmd.parameter, '%S+') do
        table.insert(params, param)
    end
    if #params < 2 or not tonumber(params[2]) then
        Game.player_print('Tempban failed. Usage: /tempban <player> <minutes> Temporarily bans a player.')
        return
    end
    if not game.players[params[1]] then
        Game.player_print("Player doesn't exist.")
        return
    end
    local group = get_group()

    game.print(Utils.get_actor() .. ' put ' .. params[1] .. ' in timeout for ' .. params[2] .. ' minutes.')
    if group then
        group.add_player(params[1])
        if not tonumber(cmd.parameter) then
            Task.set_timeout(60 * tonumber(params[2]), custom_commands_untempban, {name = params[1]})
        end
    end
end

local custom_commands_replace_ghosts =
    Token.register(
    function(param)
        for _, ghost in pairs(param.ghosts) do
            local new_ghost =
                game.surfaces[param.surface_index].create_entity {
                name = 'entity-ghost',
                position = ghost.position,
                inner_name = ghost.ghost_name,
                expires = false,
                force = 'enemy',
                direction = ghost.direction
            }
            new_ghost.last_user = ghost.last_user
        end
    end
)

--- Lets a player set their zoom level
local function zoom(cmd)
    if game.player and cmd and cmd.parameter and tonumber(cmd.parameter) then
        game.player.zoom = tonumber(cmd.parameter)
    end
end

--- Creates a rectangle of water below an admin
local function pool(cmd)
    if game.player and game.player.admin then
        local t = {}
        local p = game.player.position
        for x = p.x - 3, p.x + 3 do
            for y = p.y + 2, p.y + 7 do
                table.insert(t, {name = 'water', position = {x, y}})
            end
        end
        game.player.surface.set_tiles(t)
        game.player.surface.create_entity {name = 'fish', position = {p.x + 0.5, p.y + 5}}
    end
end

--- Creates an alert for the player at the location of their target
local function find_player(cmd)
    local player = game.player
    if not player then
        return
    end

    local name = cmd.parameter
    if not name then
        player.print('Usage: /find-player <player>')
        return
    end

    local target = game.players[name]
    if not target then
        player.print('player ' .. name .. ' not found')
        return
    end

    target = target.character
    if not target or not target.valid then
        player.print('player ' .. name .. ' does not have a character')
        return
    end

    player.add_custom_alert(target, {type = 'virtual', name = 'signal-F'}, name, true)
end

--- Places a target in jail (a permissions group which is unable to act aside from chatting)(admin only)
local function jail_player(cmd)
    local player = game.player
    -- Check if the player can run the command
    if player and not player.admin then
        Utils.cant_run(cmd.name)
        return
    end
    -- Check if the target is valid
    local target_name = cmd['parameter']
    if not target_name then
        Game.player_print('Usage: /jail <player>')
        return
    end
    local target = game.players[target_name]
    Report.jail(target, player)
end

local function all_tech()
    if game.player then
        game.player.force.research_all_technologies()
        Game.player_print('Your force has been granted all technologies')
    end
end

--- Traps errors if not in DEBUG.
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

--- Sends a message to all online admins
local function admin_chat(cmd)
    if not game.player then -- server
        Utils.print_admins(cmd.parameter, false)
    elseif game.player.admin then --admin
        Utils.print_admins(cmd.parameter, game.player)
    else
        Utils.cant_run(cmd.name)
        return
    end
end

--- Turns on rail block visualization for player
local function show_rail_block()
    local player = game.player
    if not player then
        return
    end

    local vs = player.game_view_settings
    local show = not vs.show_rail_block_visualisation
    vs.show_rail_block_visualisation = show

    player.print('show_rail_block_visualisation set to ' .. tostring(show))
end

local function server_time()
    local player = game.player
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

--- Add all commands to command list
if _DEBUG or _CHEATS then
    commands.add_command('all-tech', 'researches all technologies (debug only)', all_tech)
end

Command.add(
    'sc',
    {
        description = 'silent-command',
        arguments = {'str'},
        admin_only = true,
        capture_excess_arguments = true,
        allowed_by_server = true,
        allowed_by_player = true
    },
    function(args, player)
        local p
        if player then
            p = player.print
        else
            p = print
        end

        local func, err = loadstring(args.str)
        if not func then
            p(err)
        end

        local _, err2 = pcall(func)
        if err2 then
            local i = err2:find('\n')
            p(err2:sub(1, i))
        end
    end
)

--- Enables cheat mode (free pocket crafting) for player
commands.add_command(
    'hax',
    'Toggles your hax (makes recipes cost nothing)',
    function()
        if game.player and game.player.admin then
            game.player.cheat_mode = not game.player.cheat_mode
        end
    end
)

--- Show reports coming from users
commands.add_command(
    'showreports',
    'Shows user reports (Admins only)',
    function(event)
        if game.player and game.player.admin then
            Report.show_reports(Game.get_player_by_index(event.player_index))
        end
    end
)

commands.add_command('kill', 'Will kill you.', kill)
commands.add_command('tpplayer', '<player> - Teleports you to the player. (Admins only)', teleport_player)
commands.add_command('invoke', '<player> - Teleports the player to you. (Admins only)', invoke)
commands.add_command('tppos', 'Teleports you to a selected entity. (Admins only)', teleport_location)
commands.add_command('regulars', 'Prints a list of game regulars.', UserGroups.print_regulars)
commands.add_command('regular', '<promote, demote>, <player> Change regular status of a player. (Admins only)', regular)
commands.add_command('afk', 'Shows how long players have been afk.', afk)
commands.add_command(
    'follow',
    '<player> makes you follow the player. Use /unfollow to stop following a player.',
    follow
)
commands.add_command('unfollow', 'stops following a player.', unfollow)
commands.add_command(
    'tpmode',
    'Toggles tp mode. When on place a ghost entity to teleport there (Admins only)',
    toggle_tp_mode
)
commands.add_command('tempban', '<player> <minutes> Temporarily bans a player (Admins only)', tempban)
commands.add_command('zoom', '<number> Sets your zoom.', zoom)
commands.add_command('pool', 'Spawns a pool', pool)
commands.add_command('find', '<player> shows an alert on the map where the player is located', find_player)
commands.add_command(
    'jail',
    '<player> disables all actions a player can perform except chatting. (Admins only)',
    jail_player
)
commands.add_command(
    'unjail',
    '<player> restores ability for a player to perform actions. (Admins only)',
    Report.unjail_player
)
commands.add_command('a', 'Admin chat. Messages all other admins (Admins only)', admin_chat)
commands.add_command('report', '<griefer-name> <message> Reports a user to admins', Report.cmd_report)
commands.add_command('show-rail-block', 'Toggles rail block visualisation', show_rail_block)
commands.add_command('server-time', "Prints the server's time", server_time)

--[[ commands.add_command('undo', '<player> undoes everything a player has done (Admins only)', undo)
commands.add_command(
    'antigrief_surface',
    'moves you to the antigrief surface or back (Admins only)',
    antigrief_surface_tp
) ]]

Command.add('search-command', {
    description = 'Search for commands matching the keyword in name or description',
    arguments = {'keyword', 'page'},
    default_values = {page = 1},
}, function (arguments, player)
    local keyword = arguments.keyword
    local p = player.print
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
end)
