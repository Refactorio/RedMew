local Task = require 'utils.task'
local Token = require 'utils.token'
local UserGroups = require 'features.user_groups'
local Report = require 'features.report'
local Utils = require 'utils.core'
local Game = require 'utils.game'
local Event = require 'utils.event'
local Command = require 'utils.command'

local format = string.format

--- A table of players with tpmode turned on
global.tp_players = {}

--- Sends a message to all online admins
local function admin_chat(args, player)
    Utils.print_admins(args.msg, player)
end

--- Runs a command silently. Traps and prints errors for the player/server
local function silent_command(args, player)
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

--- Toggles cheat mode for a player
local function toggle_cheat_mode(_, player)
    player.cheat_mode = not player.cheat_mode
    Game.player_print('Cheat mode set to ' .. tostring(player.cheat_mode))
end

--- Enables all researches for a player's force
local function all_tech(_, player)
    player.force.research_all_technologies()
    Game.player_print('Your force has been granted all technologies')
end

--- Add or remove someone from the list of regulars
local function regular(args)
    local add_target = args['name|remove']
    local remove_target = args['name']

    if remove_target and add_target == 'remove' then
        UserGroups.remove_regular(remove_target)
    else
        UserGroups.add_regular(add_target)
    end
end

--- Displays reported players
local function show_reports(_, player)
    Report.show_reports(player)
end

--- Places a target in jail (a permissions group which is unable to act aside from chatting)
local function jail_player(args, player)
    -- Check if the target is valid
    local target = game.players[args.player]
    Report.jail(target, player)
end

--- Removes a target from jail
local function unjail_player(args, player)
    -- Check if the target is valid
    local target = game.players[args.player]
    Report.unjail(target, player)
end

--- Checks if we have a permission group named 'banned' and if we don't, create it
local function get_tempban_group()
    local group = game.permissions.get_group('Banned')
    if not group then
        game.permissions.create_group('Banned')
        group = game.permissions.get_group('Banned')
        if group then
            for i = 2, 174 do
                group.set_allows_action(i, false)
            end
        end
    end
    return group
end

--- Removes player from the tempban list (by changing them back to the default permissions group)
local redmew_commands_untempban =
    Token.register(
    function(param)
        game.print(param.name .. ' is out of timeout.')
        game.permissions.get_group('Default').add_player(param.name)
    end
)

--- Gives a player a temporary ban
local function tempban(args, player)
    local target_name = args.player
    local target = game.players[target_name]
    local duration = args.minutes
    if not target then
        Game.player_print("Player doesn't exist.")
        return
    end
    if not tonumber(duration) then
        Game.player_print('Tempban failed. Minutes must be a number.')
        return
    end

    local group = get_tempban_group()
    local actor
    if player then
        actor = player.name
    else
        actor = 'server'
    end
    game.print(format('%s put %s in timeout for %s minutes.', actor, target_name, duration))
    if group then
        group.add_player(target_name)
        Task.set_timeout(60 * tonumber(duration), redmew_commands_untempban, {name = target_name})
    end
end

--- Creates a rectangle of water below an admin
local function pool(_, player)
    local t = {}
    local p = player.position
    for x = p.x - 3, p.x + 3 do
        for y = p.y + 2, p.y + 7 do
            table.insert(t, {name = 'water', position = {x, y}})
        end
    end
    player.surface.set_tiles(t)
    player.surface.create_entity {name = 'fish', position = {p.x + 0.5, p.y + 5}}
end

--- Takes a target and teleports them to player
local function invoke(args, player)
    local target = game.players[args.player]
    if not target then
        Game.player_print('Unknown player.')
        return
    end
    local pos = player.surface.find_non_colliding_position('player', player.position, 50, 1)
    if not pos then
        Game.player_print('Unable to find suitable location to teleport to.')
        return
    end
    target.teleport({pos.x, pos.y}, player.surface)
    game.print(args.player .. ', get your ass over here!')
end

--- Takes a target and teleports player to target. (admin only)
local function teleport_player(args, player)
    local target_name = args.player
    local target
    if target_name then
        target = game.players[target_name]
    end
    if not target then
        Game.player_print('Unknown player.')
        return
    end
    local surface = target.surface
    local pos = surface.find_non_colliding_position('player', target.position, 50, 1)
    if not pos then
        Game.player_print('Unable to find suitable location to teleport to.')
        return
    end
    player.teleport(pos, surface)
    game.print(target_name .. "! watcha doin'?!")
    Game.player_print('You have teleported to ' .. target_name)
end

--- Takes a selected entity and teleports player to it
local function teleport_location(_, player)
    if not player.selected then
        Game.player_print('No entity under cursor.')
        return
    end
    local pos = player.surface.find_non_colliding_position('player', player.selected.position, 50, 1)
    if not pos then
        Game.player_print('Unable to find suitable location to teleport to.')
        return
    end
    player.teleport(pos)
    Game.player_print('Teleporting to your selected entity.')
end

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

--- Adds/removes players from the tp_players table (admin only)
local function toggle_tp_mode(_, player)
    local index = player.index
    local toggled = global.tp_players[index]

    if toggled then
        global.tp_players[index] = nil
        Game.player_print('tp mode is now off')
    else
        global.tp_players[index] = true
        Game.player_print('tp mode is now on - place a ghost entity to teleport there.')
    end
end

--- Takes argument from the tp command and calls the appropriate function
local function teleport_command(args, player)
    local arg = args['mode|player']
    if not arg then
        teleport_location(nil, player)
    elseif arg == 'mode' then
        toggle_tp_mode(nil, player)
    else
        teleport_player({player = arg}, player)
    end
end

--- Revives ghosts around the player
local function revive_ghosts(args, player)
    local radius = args.radius
    local pos = player.position
    for _, e in pairs(player.surface.find_entities_filtered {area = {{pos.x - radius, pos.y - radius}, {pos.x + radius, pos.y + radius}}, type = 'entity-ghost'}) do
        e.revive()
    end
end

-- Event registrations

Event.add(defines.events.on_built_entity, built_entity)

-- Command registrations

Command.add(
    'a',
    {
        description = 'Admin chat. Messages all other admins.',
        arguments = {'msg'},
        admin_only = true,
        capture_excess_arguments = true,
        allowed_by_server = true
    },
    admin_chat
)

Command.add(
    'sc',
    {
        description = 'silent-command',
        arguments = {'str'},
        admin_only = true,
        capture_excess_arguments = true,
        allowed_by_server = true
    },
    silent_command
)

Command.add(
    'hax',
    {
        description = 'Toggles your hax (makes recipes cost nothing)',
        admin_only = true
    },
    toggle_cheat_mode
)

Command.add(
    'all-tech',
    {
        description = 'researches all technologies',
        admin_only = true,
        debug_only = true,
        cheat_only = true
    },
    all_tech
)

Command.add(
    'regular',
    {
        description = 'Add/remove player from regualrs. Use /regular <name> to add or /regular remove <name> to remove.',
        arguments = {'name|remove', 'name'},
        default_values = {['name'] = false},
        admin_only = true,
        capture_excess_arguments = false,
        allowed_by_server = false
    },
    regular
)

Command.add(
    'showreports',
    {
        description = 'Shows user reports',
        admin_only = true
    },
    show_reports
)

Command.add(
    'jail',
    {
        description = 'Puts a player in jail',
        arguments = {'player'},
        admin_only = true,
        allowed_by_server = true
    },
    jail_player
)

Command.add(
    'unjail',
    {
        description = 'Removes a player from jail',
        arguments = {'player'},
        admin_only = true,
        allowed_by_server = true
    },
    unjail_player
)

Command.add(
    'tempban',
    {
        description = 'Temporarily bans a player',
        arguments = {'player', 'minutes'},
        admin_only = true,
        allowed_by_server = true
    },
    tempban
)

Command.add(
    'pool',
    {
        description = 'Spawns a pool of water',
        admin_only = true
    },
    pool
)

Command.add(
    'invoke',
    {
        description = 'Teleports the player to you.',
        arguments = {'player'},
        admin_only = true
    },
    invoke
)

Command.add(
    'tp',
    {
        description = 'if blank, teleport to selected entity. mode = toggle tp mode where you can teleport to a placed ghost. player = teleport to player.',
        arguments = {'mode|player'},
        default_values = {['mode|player'] = false},
        admin_only = true,
        custom_help_text = '<blank|mode|player> 3 different uses: "/tp" to tp to selected entity. "/tp mode" to toggle tp mode. "/tp Newcott" to tp to Newcott'
    },
    teleport_command
)

Command.add(
    'revive-ghosts',
    {
        description = 'Revives the ghosts within the provided radius around you',
        arguments = {'radius'},
        default_values = {radius = 10},
        admin_only = true
    },
    revive_ghosts
)
