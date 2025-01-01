local Global = require 'utils.global'
local Rank = require 'features.rank_system'
local Report = require 'features.report'
local Utils = require 'utils.core'
local Game = require 'utils.game'
local Event = require 'utils.event'
local Command = require 'utils.command'
local Color = require 'resources.color_presets'
local Ranks = require 'resources.ranks'

--- A table of players with tpmode turned on
local tp_players = {}
local players_last_command = {}

Global.register(
    {
        tp_players = tp_players,
        players_last_command = players_last_command
    },
    function(tbl)
        tp_players = tbl.tp_players
        players_last_command = tbl.players_last_command
    end
)

--- Informs the actor that there is no target. Acts as a central place where this message can be changed.
local function print_no_target(target_name, player)
    Game.player_print({'common.fail_no_target', target_name}, Color.fail, player)
end

local function know_player_or_rerun(player_name, actor, command_name)
    if Rank.know_player(player_name) then
        return true
    end

    local actor_last_command = players_last_command[actor]
    if actor_last_command and actor_last_command.command == command_name and actor_last_command.parameters == player_name then
        return true;
    end

    Game.player_print({'common.rerun_no_target', player_name}, Color.fail, actor)
    return false
end

local function console_command(event)
    local actor = Utils.get_admin_or_server_actor(event.player_index)
    if actor then
        players_last_command[actor] = {command = event.command, parameters = event.parameters}
    end
end

--- Sends a message to all online admins
local function admin_chat(args, player)
    Utils.print_admins(args.msg, player, true)
end

--- Toggles cheat mode for a player
local function toggle_cheat_mode(_, player)
    player.cheat_mode = not player.cheat_mode
    Game.player_print({'admin_commands.toggle_cheat_mode', tostring(player.cheat_mode)}, nil, player)
end

--- Promote someone to regular
local function add_regular(args, player)
    local target_name = args.player
    local maybe_target_player = game.get_player(target_name)
    local actor = args.actor or Utils.get_actor()

    if not maybe_target_player and not know_player_or_rerun(target_name, actor, 'regular') then
        return
    end

    if Rank.less_than(target_name, Ranks.guest) then
        Game.player_print({'admin_commands.regular_add_fail_probation'}, Color.fail, player)
        return
    end

    local success = Rank.increase_player_rank_to(target_name, Ranks.regular)
    if success then
        game.print({'admin_commands.regular_add_success', actor, target_name}, {color = Color.info})
        if maybe_target_player then
            maybe_target_player.print({'admin_commands.regular_add_notify_target'}, {color = Color.warning})
        end
    else
        Game.player_print({'admin_commands.regular_add_fail', target_name, Rank.get_player_rank_name(target_name)}, Color.fail, player)
    end
end

--- Demote someone from regular
local function remove_regular(args, player)
    local target_name = args.player
    local maybe_target_player = game.get_player(target_name)
    local actor = args.actor or Utils.get_actor()

    if not maybe_target_player and not know_player_or_rerun(target_name, actor, 'regular-remove') then
        return
    end

    if Rank.equal(target_name, Ranks.regular) then
        local _, new_rank = Rank.reset_player_rank(target_name)
        game.print({'admin_commands.regular_remove_success', actor, target_name, new_rank}, {color = Color.info})
        if maybe_target_player then
            maybe_target_player.print({'admin_commands.regular_remove_notify_target'}, {color = Color.warning})
        end
    else
        local rank_name = Rank.get_player_rank_name(target_name)
        Game.player_print({'admin_commands.regular_remove_fail', target_name, rank_name}, Color.fail, player)
    end
end

--- Put someone on probation
local function probation_add(args, player)
    local target_name = args.player
    local maybe_target_player = game.get_player(target_name)
    local actor = args.actor or Utils.get_actor()

    if not maybe_target_player and not know_player_or_rerun(target_name, actor, 'probation') then
        return
    end

    if Rank.equal(target_name, Ranks.admin) then
        Game.player_print({'admin_commands.probation_add_fail_admin'}, Color.fail, player)
        if maybe_target_player then
            maybe_target_player.print({'admin_commands.probation_warn_admin', actor}, {color = Color.warning})
        end
        return
    end

    local success = Rank.decrease_player_rank_to(target_name, Ranks.probation)
    if success then
        game.print({'admin_commands.probation_add_success', actor, target_name}, {color = Color.info})
        if maybe_target_player then
            maybe_target_player.print({'admin_commands.probation_add_notify_target'}, {color = Color.warning})
        end
    else
        Game.player_print({'admin_commands.probation_add_fail', target_name}, Color.fail, player)
    end
end

--- Remove someone from probation
local function probation_remove(args, player)
    local target_name = args.player
    local maybe_target_player = game.get_player(target_name)
    local actor = args.actor or Utils.get_actor()

    if not maybe_target_player and not know_player_or_rerun(target_name, actor, 'probation-remove') then
        return
    end

    if Rank.equal(target_name, Ranks.probation) then
        Rank.reset_player_rank(target_name)
        game.print({'admin_commands.probation_remove_success', actor, target_name}, {color = Color.info})
        if maybe_target_player then
            maybe_target_player.print({'admin_commands.probation_remove_notify_target'}, {color = Color.warning})
        end
    else
        Game.player_print({'admin_commands.probation_remove_fail', target_name}, Color.fail, player)
    end
end

--- Displays reported players
local function show_reports(_, player)
    Report.show_reports(player)
end

--- Places a target in jail (a permissions group which is unable to act aside from chatting)
local function jail_player(args, player)
    local target_ident = args.player
    local target = Utils.validate_player(target_ident)

    if not target then
        print_no_target(target_ident, player)
        return
    end

    Report.jail(target, player)
end

--- Removes a target from jail
local function unjail_player(args, player)
    local target_ident = args.player
    local target = Utils.validate_player(target_ident)

    if not target then
        print_no_target(target_ident, player)
        return
    end
    Report.unjail(target, player)
end

--- Creates a rectangle of water below an admin
local function pool(_, player)
    local t = {}
    local p = player.physical_position
    for x = p.x - 3, p.x + 3 do
        for y = p.y + 2, p.y + 7 do
            table.insert(t, {name = 'water', position = {x, y}})
        end
    end
    player.physical_surface.set_tiles(t)
    player.physical_surface.create_entity {name = 'fish', position = {p.x + 0.5, p.y + 5}}
    Game.player_print({'admin_commands.create_pool'}, Color.success, player)
end

--- Takes a target and teleports them to player
local function invoke(args, player)
    local target_ident = args.player
    local target = Utils.validate_player(target_ident)

    if not target then
        print_no_target(target_ident, player)
        return
    end

    local pos = player.physical_surface.find_non_colliding_position('character', player.physical_position, 50, 1)
    if not pos then
        Game.player_print({'admin_commands.invoke_fail_no_location'}, player)
        return
    end
    target.teleport({pos.x, pos.y}, player.physical_surface)
    game.print({'admin_commands.invoke_announce', target.name})
end

--- Takes a target and teleports player to target. (admin only)
local function teleport_player(args, player)
    local target_ident = args.player
    local target = Utils.validate_player(target_ident)

    if not target then
        print_no_target(target_ident, player)
        return
    end

    local target_name = target.name
    local surface = target.surface
    local position = target.position
    if target.is_player() then
        position = target.physical_position
        surface = target.physical_surface
    end
    local pos = surface.find_non_colliding_position('character', position, 50, 1)
    if not pos then
        Game.player_print({'admin_commands.tp_fail_no_location'}, Color.fail, player)
        return
    end
    player.teleport(pos, surface)
    game.print({'admin_commands.tp_player_announce', target_name})
    Game.player_print({'admin_commands.tp_player_success', target_name}, Color.success, player)
end

--- Takes a selected entity and teleports player to it
local function teleport_location(_, player)
    if not player.selected then
        Game.player_print({'admin_commands.tp_ent_fail_no_ent'}, Color.fail, player)
        return
    end
    local surface = player.selected.surface
    local pos = surface.find_non_colliding_position('character', player.selected.position, 50, 1)
    if not pos then
        Game.player_print({'admin_commands.tp_fail_no_location'}, Color.fail, player)
        return
    end
    player.teleport(pos, surface)
    Game.player_print({'admin_commands.tp_end_success'}, Color.success, player)
end

--- If a player is in the tp_players list, remove ghosts they place and teleport them to that position
local function built_entity(event)
    local index = event.player_index

    if tp_players[index] then
        local entity = event.entity

        if not entity or not entity.valid or entity.type ~= 'entity-ghost' then
            return
        end

        game.get_player(index).teleport(entity.position, entity.surface)
        entity.destroy()
    end
end

--- Adds/removes players from the tp_players table (admin only)
local function toggle_tp_mode(_, player)
    local index = player.index
    local toggled = tp_players[index]

    if toggled then
        tp_players[index] = nil
        Game.player_print({'admin_commands.tp_mode_off'}, nil, player)
    else
        tp_players[index] = true
        Game.player_print({'admin_commands.tp_mode_on'}, nil, player)
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
    local pos = player.physical_position
    local count = 0
    for _, e in pairs(player.physical_surface.find_entities_filtered {area = {{pos.x - radius, pos.y - radius}, {pos.x + radius, pos.y + radius}}, type = 'entity-ghost'}) do
        e.revive()
        count = count + 1
    end
    Game.player_print({'admin_commands.revive_ghosts', count}, Color.success, player)
end

--- Destroys the player's selected entity
local function destroy_selected(_, player)
    local ent = player.selected
    if ent then
        Game.player_print({'admin_commands.destroy_success', ent.localised_name}, player)
        ent.destroy()
    else
        Game.player_print({'admin_commands.destroy_fail'}, player)
    end
end

-- Event registrations

Event.add(defines.events.on_built_entity, built_entity)
Event.add(defines.events.on_console_command, console_command)

-- Command registrations

Command.add(
    'a',
    {
        description = {'command_description.a'},
        arguments = {'msg'},
        required_rank = Ranks.admin,
        capture_excess_arguments = true,
        allowed_by_server = true,
        log_command = false
    },
    admin_chat
)

Command.add(
    'hax',
    {
        description = {'command_description.hax'},
        required_rank = Ranks.admin
    },
    toggle_cheat_mode
)

Command.add(
    'regular',
    {
        description = {'command_description.regular'},
        arguments = {'player'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    add_regular
)

Command.add(
    'regular-remove',
    {
        description = {'command_description.regular_remove'},
        arguments = {'player'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    remove_regular
)

Command.add(
    'probation',
    {
        description = {'command_description.probation'},
        arguments = {'player'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    probation_add
)

Command.add(
    'probation-remove',
    {
        description = {'command_description.probation_remove'},
        arguments = {'player'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    probation_remove
)

Command.add(
    'showreports',
    {
        description = {'command_description.showreports'},
        required_rank = Ranks.admin
    },
    show_reports
)

Command.add(
    'jail',
    {
        description = {'command_description.jail'},
        arguments = {'player'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    jail_player
)

Command.add(
    'unjail',
    {
        description = {'command_description.unjail'},
        arguments = {'player'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    unjail_player
)

Command.add(
    'pool',
    {
        description = {'command_description.pool'},
        required_rank = Ranks.admin
    },
    pool
)

Command.add(
    'invoke',
    {
        description = {'command_description.invoke'},
        arguments = {'player'},
        required_rank = Ranks.admin
    },
    invoke
)

Command.add(
    'tp',
    {
        description = {'command_description.tp'},
        arguments = {'mode|player'},
        default_values = {['mode|player'] = false},
        required_rank = Ranks.admin,
        custom_help_text = {'command_custom_help.tp'}
    },
    teleport_command
)

Command.add(
    'revive-ghosts',
    {
        description = {'command_description.revive_ghosts'},
        arguments = {'radius'},
        default_values = {radius = 10},
        required_rank = Ranks.admin
    },
    revive_ghosts
)

Command.add(
    'destroy',
    {
        description = {'command_description.destroy'},
        required_rank = Ranks.admin
    },
    destroy_selected
)

return {
    create_pool = pool,
    destroy_selected = destroy_selected,
    invoke_player = invoke,
    jail_player = jail_player,
    probation_add = probation_add,
    probation_remove = probation_remove,
    regular_add = add_regular,
    regular_remove = remove_regular,
    revive_ghosts = revive_ghosts,
    show_reports = show_reports,
    teleport_command = teleport_command,
    toggle_cheat_mode = toggle_cheat_mode,
    unjail_player = unjail_player,
}