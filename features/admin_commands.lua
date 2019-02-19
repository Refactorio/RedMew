local Task = require 'utils.task'
local Token = require 'utils.token'
local Global = require 'utils.global'
local Rank = require 'features.rank_system'
local Report = require 'features.report'
local Utils = require 'utils.core'
local Game = require 'utils.game'
local Event = require 'utils.event'
local Command = require 'utils.command'
local Color = require 'resources.color_presets'
local Ranks = require 'resources.ranks'

local format = string.format
local loadstring = loadstring

--- A table of players with tpmode turned on
local tp_players = {}

Global.register(
    {
        tp_players = tp_players
    },
    function(tbl)
        tp_players = tbl.tp_players
    end
)

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
        return
    end

    local _, err2 = pcall(func)
    if err2 then
        local i = err2:find('\n')
        if i then
            p(err2:sub(1, i))
            return
        end

        i = err2:find('%s')
        if i then
            p(err2:sub(i + 1))
        end
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
    local add_remove = args['add|remove']
    local name = args['name']

    if not game.players[name] then
        Game.player_print('The player you targeted has never joined this game, please ensure no typo in name.', Color.red)
        return
    end

    if add_remove == 'add' then
        if Rank.less_than(name, Ranks.guest) then
            -- Cannot promote someone on probation to regular. You must remove them from probation and then promote them.
            Game.player_print({'admin_commands.regular_add_fail_probation'}, Color.red)
        end
        local success, rank = Rank.increase_player_rank_to(name, Ranks.regular)
        if success then
            -- __1__ promoted __2__ to __3__.
            game.print({'admin_commands.regular_add_success', Utils.get_actor(), name, rank}, Color.yellow)
        else
            -- __1__ is already rank __2__.
            Game.player_print({'admin_commands.regular_add_fail', name, rank}, Color.red)
        end
    elseif add_remove == 'remove' then
        if Rank.equal(name, Ranks.regular) then
            local new_rank = Rank.decrease_player_rank(name)
            -- __1__ demoted __2__ to __3__.
            game.print({'admin_commands.regular_remove_success', Utils.get_actor(), name, new_rank}, Color.yellow)
        else
            local rank_name = Rank.get_player_rank_name(name)
            -- __1__ is rank __2__ their regular status cannot be removed.
            Game.player_print({'admin_commands.regular_remove_fail', name, rank_name}, Color.red)
        end
    end
end

--- Add or remove someone from probation
local function probation(args)
    local add_remove = args['add|remove']
    local name = args['name']
    local target_player = game.players[name]

    if not target_player then
        Game.player_print('The player you targeted has never joined this game, please ensure no typo in name.', Color.red)
        return
    end

    if add_remove == 'add' then
        local success = Rank.decrease_player_rank_to(name, Ranks.probation)
        if success and Rank.equal(name, Ranks.admin) then
            target_player.print(format('%s tried to put you on probation, can you believe that shit?', Utils.get_actor()), Color.yellow)
            Game.player_print('You failed to put your fellow admin on probation. Shame on you for trying.', Color.yellow)
            Rank.reset_player_rank(name)
        elseif success then
            game.print(format('%s put %s on probation.', Utils.get_actor(), name), Color.yellow)
            target_player.print('You have been placed on probation. You have limited access to normal functions.', Color.yellow)
        else
            Game.player_print(format('%s already has probation rank or lower.', name), Color.red)
        end
    elseif add_remove == 'remove' then
        local success = Rank.increase_player_rank_to(name, Ranks.guest)
        if success then
            game.print(format('%s took %s off of probation.', Utils.get_actor(), name), Color.yellow)
            target_player.print('Your probation status has been removed. You may now perform functions as usual', Color.yellow)
        else
            Game.player_print(format('%s is not on probation.', name), Color.red)
        end
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

--- If a player is in the tp_players list, remove ghosts they place and teleport them to that position
local function built_entity(event)
    local index = event.player_index

    if tp_players[index] then
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
    local toggled = tp_players[index]

    if toggled then
        tp_players[index] = nil
        Game.player_print('tp mode is now off')
    else
        tp_players[index] = true
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

--- Destroys the player's selected entity
local function destroy_selected(_, player)
    local ent = player.selected
    if ent then
        Game.player_print(ent.name .. ' destroyed')
        ent.destroy()
    else
        Game.player_print('Nothing found to destroy. (You must have an entity under your cursor when you hit enter)')
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
        required_rank = Ranks.admin,
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
        required_rank = Ranks.admin,
        capture_excess_arguments = true,
        allowed_by_server = true
    },
    silent_command
)

Command.add(
    'hax',
    {
        description = 'Toggles your hax (makes recipes cost nothing)',
        required_rank = Ranks.admin
    },
    toggle_cheat_mode
)

Command.add(
    'all-tech',
    {
        description = 'researches all technologies',
        required_rank = Ranks.admin,
        debug_only = true,
        cheat_only = true
    },
    all_tech
)

Command.add(
    'regular',
    {
        description = 'Add/remove player from regualrs. Use /regular <add|remove> <name> to add/remove a regular.',
        arguments = {'add|remove', 'name'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    regular
)

Command.add(
    'probation',
    {
        description = 'Add/remove player from probation. Use /probation <add|remove> <name> to add/remove someone from probation.',
        arguments = {'add|remove', 'name'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    probation
)

Command.add(
    'showreports',
    {
        description = 'Shows user reports',
        required_rank = Ranks.admin
    },
    show_reports
)

Command.add(
    'jail',
    {
        description = 'Puts a player in jail',
        arguments = {'player'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    jail_player
)

Command.add(
    'unjail',
    {
        description = 'Removes a player from jail',
        arguments = {'player'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    unjail_player
)

Command.add(
    'tempban',
    {
        description = 'Temporarily bans a player',
        arguments = {'player', 'minutes'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    tempban
)

Command.add(
    'pool',
    {
        description = 'Spawns a pool of water',
        required_rank = Ranks.admin
    },
    pool
)

Command.add(
    'invoke',
    {
        description = 'Teleports the player to you.',
        arguments = {'player'},
        required_rank = Ranks.admin
    },
    invoke
)

Command.add(
    'tp',
    {
        description = 'if blank, teleport to selected entity. mode = toggle tp mode where you can teleport to a placed ghost. player = teleport to player.',
        arguments = {'mode|player'},
        default_values = {['mode|player'] = false},
        required_rank = Ranks.admin,
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
        required_rank = Ranks.admin
    },
    revive_ghosts
)

Command.add(
    'destroy',
    {
        description = 'Destroys the entity under your cursor when you run this command',
        required_rank = Ranks.admin
    },
    destroy_selected
)
