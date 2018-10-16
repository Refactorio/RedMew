local Task = require 'utils.Task'
local Event = require 'utils.event'
local Token = require 'utils.global_token'
local UserGroups = require 'user_groups'
local Utils = require 'utils.utils'
local Game = require 'utils.game'
--local Antigrief = require 'antigrief'

function player_print(str)
    if game.player then
        game.player.print(str)
    else
        print(str)
    end
end

function cant_run(name)
    player_print("Can't run command (" .. name .. ') - insufficient permission.')
end

local function invoke(cmd)
    if not (game.player and game.player.admin) then
        cant_run(cmd.name)
        return
    end
    local target = cmd['parameter']
    if target == nil or game.players[target] == nil then
        player_print('Unknown player.')
        return
    end
    local pos = game.player.surface.find_non_colliding_position('player', game.player.position, 0, 1)
    game.players[target].teleport({pos.x, pos.y}, game.player.surface)
    game.print(target .. ', get your ass over here!')
end

local function teleport_player(cmd)
    if not (game.player and game.player.admin) then
        cant_run(cmd.name)
        return
    end
    local target = cmd['parameter']
    if target == nil or game.players[target] == nil then
        player_print('Unknown player.')
        return
    end
    local surface = game.players[target].surface
    local pos = surface.find_non_colliding_position('player', game.players[target].position, 0, 1)
    game.player.teleport(pos, surface)
    game.print(target .. "! watcha doin'?!")
end

local function teleport_location(cmd)
    if not (game.player and game.player.admin) then
        cant_run(cmd.name)
        return
    end
    if game.player.selected == nil then
        player_print('Nothing selected.')
        return
    end
    local pos = game.player.surface.find_non_colliding_position('player', game.player.selected.position, 0, 1)
    game.player.teleport(pos)
end

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

local function kill(cmd)
    local player = game.player
    local param = cmd.parameter
    local target
    if param then
        target = game.players[param]
        if not target then
            player_print(table.concat {"Sorry, player '", param, "' was not found."})
            return
        end
    end

    if not target and player then
        if not do_fish_kill(player, true) then
            player_print("Sorry, you don't have a character to kill.")
        end
    elseif player then
        if target == player then
            if not do_fish_kill(player, true) then
                player_print("Sorry, you don't have a character to kill.")
            end
        elseif target and player.admin then
            if not do_fish_kill(target) then
                player_print(table.concat {"'Sorry, '", target.name, "' doesn't have a character to kill."})
            end
        else
            player_print("Sorry you don't have permission to use the kill command on other players.")
        end
    elseif target then
        if not do_fish_kill(target) then
            player_print(table.concat {"'Sorry, '", target.name, "' doesn't have a character to kill."})
        end
    else
        if param then
            player_print(table.concat {"Sorry, player '", param, "' was not found."})
        else
            player_print('Usage: /kill <player>')
        end
    end
end

global.walking = {}

local custom_commands_return_player =
    Token.register(
    function(args)
        local player = args.player
        if not player.valid then
            return
        end

        global.walking[player.index] = false

        local walkabout_character = player.character
        if walkabout_character and walkabout_character.valid then
            walkabout_character.destroy()
        end

        local character = args.character
        if character ~= nil and character.valid then
            player.character = character
        else
            player.create_character()
            player.teleport(args.position)
        end

        player.force = args.force

        game.print(args.player.name .. ' came back from his walkabout.')
    end
)

local function walkabout(cmd)
    if game.player and not game.player.admin then
        cant_run(cmd.name)
        return
    end
    local params = {}
    if cmd.parameter == nil then
        player_print('Walkabout failed, check /help walkabout.')
        return
    end
    for param in string.gmatch(cmd.parameter, '%S+') do
        table.insert(params, param)
    end
    local player_name = params[1]
    local duration = 60
    if #params > 2 then
        player_print('Walkabout failed, check /help walkabout.')
        return
    elseif #params == 2 and tonumber(params[2]) == nil then
        player_print(params[2] .. ' is not a number.')
        return
    elseif #params == 2 and tonumber(params[2]) then
        duration = tonumber(params[2])
    end
    if duration < 15 then
        duration = 15
    end

    local player = game.players[player_name]
    if player == nil or not player.valid or global.walking[player.index] then
        player_print(player_name .. ' could not go on a walkabout.')
        return
    end
    local chunks = {}
    for chunk in player.surface.get_chunks() do
        table.insert(chunks, chunk)
    end

    local surface = player.surface
    local chunk = surface.get_random_chunk()
    local pos = {x = chunk.x * 32, y = chunk.y * 32}
    local non_colliding_pos = surface.find_non_colliding_position('player', pos, 100, 1)

    local character = player.character
    if character and character.valid then
        character.walking_state = {walking = false}
    end

    if non_colliding_pos then
        game.print(player_name .. ' went on a walkabout, to find himself.')
        Task.set_timeout(
            duration,
            custom_commands_return_player,
            {
                player = player,
                force = player.force,
                position = {x = player.position.x, y = player.position.y},
                character = character
            }
        )
        player.character = nil
        player.create_character()
        player.teleport(non_colliding_pos)
        player.force = 'neutral'
        global.walking[player.index] = true
    else
        player_print('Walkabout failed: could not find non colliding position')
    end
end

local function regular(cmd)
    if game.player and not game.player.admin then
        cant_run(cmd.name)
        return
    end

    if cmd.parameter == nil then
        player_print('Command failed. Usage: /regular <promote, demote>, <player>')
        return
    end
    local params = {}
    for param in string.gmatch(cmd.parameter, '%S+') do
        table.insert(params, param)
    end
    if params[2] == nil then
        player_print('Command failed. Usage: /regular <promote, demote>, <player>')
        return
    elseif (params[1] == 'promote') then
        UserGroups.add_regular(params[2])
    elseif (params[1] == 'demote') then
        UserGroups.remove_regular(params[2])
    else
        player_print('Command failed. Usage: /regular <promote, demote>, <player>')
    end
end

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
            player_print(v.name .. ' has been afk for' .. time)
        end
    end
end

local function follow(cmd)
    if not game.player then
        log("<Server can't do that.")
        return
    end
    if cmd.parameter ~= nil and game.players[cmd.parameter] ~= nil then
        global.follows[game.player.name] = cmd.parameter
        global.follows.n_entries = global.follows.n_entries + 1
    else
        player_print('Usage: /follow <player> makes you follow the player. Use /unfollow to stop following a player.')
    end
end

local function unfollow(cmd)
    if not game.player then
        log("<Server can't do that.")
        return
    end
    if global.follows[game.player.name] ~= nil then
        global.follows[game.player.name] = nil
        global.follows.n_entries = global.follows.n_entries - 1
    end
end

global.tp_players = {}
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

local function toggle_tp_mode(cmd)
    if not (game.player and game.player.admin) then
        cant_run(cmd.name)
        return
    end

    local index = game.player.index
    local toggled = global.tp_players[index]

    if toggled then
        global.tp_players[index] = nil
        player_print('tp mode is now off')
    else
        global.tp_players[index] = true
        player_print('tp mode is now on - place a ghost entity to teleport there.')
    end
end

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

function custom_commands_untempban(param)
    game.print(param.name .. ' is out of timeout.')
    game.permissions.get_group('Default').add_player(param.name)
end

local custom_commands_untempban =
    Token.register(
    function(param)
        game.print(param.name .. ' is out of timeout.')
        game.permissions.get_group('Default').add_player(param.name)
    end
)

local function tempban(cmd)
    if (not game.player) or not game.player.admin then
        cant_run(cmd.name)
        return
    end
    if cmd.parameter == nil then
        player_print('Tempban failed. Usage: /tempban <player> <minutes> Temporarily bans a player.')
        return
    end
    local params = {}
    for param in string.gmatch(cmd.parameter, '%S+') do
        table.insert(params, param)
    end
    if #params < 2 or not tonumber(params[2]) then
        player_print('Tempban failed. Usage: /tempban <player> <minutes> Temporarily bans a player.')
        return
    end
    if not game.players[params[1]] then
        player_print("Player doesn't exist.")
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

local function zoom(cmd)
    if game.player and cmd and cmd.parameter and tonumber(cmd.parameter) then
        game.player.zoom = tonumber(cmd.parameter)
    end
end

local function pool()
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

--[[ global.undo_warned_players = {}
local function undo(cmd)
    if (not game.player) or not game.player.admin then
        cant_run(cmd.name)
        return
    end
    if cmd.parameter and game.players[cmd.parameter] then
        if
            not global.undo_warned_players[game.player.index] or
                global.undo_warned_players[game.player.index] ~= game.players[cmd.parameter].index
         then
            global.undo_warned_players[game.player.index] = game.players[cmd.parameter].index
            game.player.print(
                string.format(
                    'Warning! You are about to remove %s entities and restore %s entities.',
                    #Utils.find_entities_by_last_user(game.players[cmd.parameter], game.surfaces.nauvis),
                    Antigrief.count_removed_entities(game.players[cmd.parameter])
                )
            )
            game.player.print('To execute the command please run it again.')
            return
        end
        Antigrief.undo(game.players[cmd.parameter])
        game.print(string.format('Undoing everything %s did...', cmd.parameter))
        global.undo_warned_players[game.player.index] = nil
    else
        player_print('Usage: /undo <player>')
    end
end

local function antigrief_surface_tp()
    if (not game.player) or not game.player.admin then
        cant_run(cmd.name)
        return
    end
    Antigrief.antigrief_surface_tp()
end ]]
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

local function jail_player(cmd)
    -- Set the name of the jail permission group
    local jail_name = 'Jail'

    local player = game.player
    -- Check if the player can run the command
    if player and not player.admin then
        cant_run(cmd.name)
        return
    end
    -- Check if the target is valid
    local target = cmd['parameter']
    if target == nil then
        player_print('Usage: /jail <player>')
        return
    end

    local target_player = game.players[target]

    if not target_player then
        player_print('Unknown player.')
        return
    end

    local permissions = game.permissions

    -- Check if the permission group exists, if it doesn't, create it.
    local permission_group = permissions.get_group(jail_name)
    if not permission_group then
        permission_group = permissions.create_group(jail_name)
    end

    if target_player.permission_group == permission_group then
        player_print('The player ' .. target .. ' is already in Jail.')
        return
    end

    -- Set all permissions to disabled
    for action_name, _ in pairs(defines.input_action) do
        permission_group.set_allows_action(defines.input_action[action_name], false)
    end
    -- Enable writing to console to allow a person to speak
    permission_group.set_allows_action(defines.input_action.write_to_console, true)
    permission_group.set_allows_action(defines.input_action.edit_permission_group, true)

    -- Kick player out of vehicle
	target_player.driving=false
    -- Add player to jail group
	permission_group.add_player(target_player)
	-- Check if a player is shooting while jailed, if they are, remove the weapon in their active gun slot.
	if target_player.shooting_state.state ~= 0 then
		-- Use a while loop because if a player has guns in inventory they will auto-refill the slot.
		while target_player.get_inventory(defines.inventory.player_guns)[target_player.character.selected_gun_index].valid_for_read do
			target_player.remove_item(target_player.get_inventory(defines.inventory.player_guns)[target_player.character.selected_gun_index])
		end
		target_player.print(
            'Your active weapon has been removed because you were shooting while jailed. Your gun will *not* be returned to you in the event of being unjailed.'
        )
	end

    -- Check that it worked
    if target_player.permission_group == permission_group then
        -- Let admin know it worked, let target know what's going on.
        player_print(target .. ' has been jailed. They have been advised of this.')
        target_player.print(
            'You have been placed in jail by a server admin. The only action you can currently perform is chatting. Please respond to inquiries from the admin.'
        )
    else
        -- Let admin know it didn't work.
        player_print(
            'Something went wrong in the jailing of ' ..
                target .. '. You can still change their group via /permissions.'
        )
    end
end

local function unjail_player(cmd)
    local default_group = 'Default'
    local player = game.player
    -- Check if the player can run the command
    if player and not player.admin then
        cant_run(cmd.name)
        return
    end
    -- Check if the target is valid (copied from the invoke command)
    local target = cmd['parameter']
    if target == nil then
        player_print('Usage: /unjail <player>')
        return
    end

    local target_player = game.players[target]
    if not target_player then
        player_print('Unknown player.')
        return
    end

    local permissions = game.permissions

    -- Check if the permission group exists, if it doesn't, create it.
    local permission_group = permissions.get_group(default_group)
    if not permission_group then
        permission_group = permissions.create_group(default_group)
    end

    local jail_permission_group = permissions.get_group('Jail')
    if (not jail_permission_group) or target_player.permission_group ~= jail_permission_group then
        player_print('The player ' .. target .. ' is already not in Jail.')
        return
    end

    -- Move player
    permission_group.add_player(target)
	-- Set player to a non-shooting state (solves a niche case where players jailed while shooting will be locked into a shooting state)
	target_player.shooting_state.state = 0

    -- Check that it worked
    if target_player.permission_group == permission_group then
        -- Let admin know it worked, let target know what's going on.
        player_print(target .. ' has been returned to the default group. They have been advised of this.')
        target_player.print('Your ability to perform actions has been restored')
    else
        -- Let admin know it didn't work.
        player_print(
            'Something went wrong in the unjailing of ' ..
                target .. '. You can still change their group via /permissions and inform them.'
        )
    end
end

local function all_tech()
    if game.player then
        game.player.force.research_all_technologies()
        player_print('Your force has been granted all technologies')
    end
end

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
                    --player_print(error) -- This casues desyncs
                    player_print('Sorry there was an error running ' .. cmd.name)
                end
            end
        )
    end
end

local function admin_chat(cmd)
    if not game.player or game.player.admin then --admins AND server
        for _, p in pairs(game.players) do
            if p.admin then
                local tag = ''
                if game.player.tag and game.player.tag ~= '' then
                    tag = ' ' .. game.player.tag
                end
                p.print(string.format('(Admin) %s%s: %s', game.player.name, tag, cmd.parameter), game.player.chat_color)
            end
        end
    end
end

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

commands.add_command('kill', 'Will kill you.', kill)
commands.add_command('tpplayer', '<player> - Teleports you to the player. (Admins only)', teleport_player)
commands.add_command('invoke', '<player> - Teleports the player to you. (Admins only)', invoke)
commands.add_command('tppos', 'Teleports you to a selected entity. (Admins only)', teleport_location)
commands.add_command('walkabout', '<player> <duration> - Send someone on a walk.  (Admins only)', walkabout)
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
if _DEBUG then
    commands.add_command('all-tech', 'researches all technologies (debug only)', all_tech)
end
commands.add_command(
    'hax',
    'Toggles your hax (makes recipes cost nothing)',
    function()
        if game.player and game.player.admin then
            game.player.cheat_mode = not game.player.cheat_mode
        end
    end
)
commands.add_command('pool', 'Spawns a pool', pool)
--[[ commands.add_command('undo', '<player> undoes everything a player has done (Admins only)', undo)
commands.add_command(
    'antigrief_surface',
    'moves you to the antigrief surface or back (Admins only)',
    antigrief_surface_tp
) ]]
commands.add_command('find-player', '<player> shows an alert on the map where the player is located', find_player)
commands.add_command(
    'jail',
    '<player> disables all actions a player can perform except chatting. (Admins only)',
    jail_player
)
commands.add_command(
    'unjail',
    '<player> restores ability for a player to perform actions. (Admins only)',
    unjail_player
)
commands.add_command('a', 'Admin chat. Messages all other admins (Admins only)', admin_chat)

local Report = require('report')

local function report(cmd)
    local reporting_player = game.player
    if reporting_player then
        local params = {}
        for param in string.gmatch(cmd.parameter, '%S+') do
            table.insert(params, param)
        end
        if #params < 2 then
            reporting_player.print('Please enter then name of the offender and the reason for the report.')
            return nil
        end
        local reported_player_name = params[1] or ''
        local reported_player = game.players[reported_player_name]

        if not reported_player then
            reporting_player.print(reported_player_name .. ' does not exist.')
            return nil
        end
        Report.report(reporting_player, reported_player, string.sub(cmd.parameter, string.len(params[1]) + 2))
    end
end

commands.add_command('report', '<griefer-name> <message> Reports a user to admins', report)

commands.add_command(
    'showreports',
    'Shows user reports (Admins only)',
    function(event)
        if game.player and game.player.admin then
            Report.show_reports(Game.get_player_by_index(event.player_index))
        end
    end
)

commands.add_command('show-rail-block', 'Toggles rail block visualisation', show_rail_block)
