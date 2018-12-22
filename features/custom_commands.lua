local Report = require 'features.report'
local UserGroups = require 'features.user_groups'
local Game = require 'utils.game'
local Server = require 'features.server'
local Timestamp = require 'utils.timestamp'
local Command = require 'utils.command'

local format = string.format
local ceil = math.ceil

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

--- Lets a player set their zoom level
local function zoom(cmd)
    if game.player and cmd and cmd.parameter and tonumber(cmd.parameter) then
        game.player.zoom = tonumber(cmd.parameter)
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

commands.add_command('kill', 'Will kill you.', kill)
commands.add_command('regulars', 'Prints a list of game regulars.', UserGroups.print_regulars)
commands.add_command('afk', 'Shows how long players have been afk.', afk)
commands.add_command('zoom', '<number> Sets your zoom.', zoom)
commands.add_command('find', '<player> shows an alert on the map where the player is located', find_player)
commands.add_command('report', '<griefer-name> <message> Reports a user to admins', Report.cmd_report)
commands.add_command('show-rail-block', 'Toggles rail block visualisation', show_rail_block)
commands.add_command('server-time', "Prints the server's time", server_time)

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
