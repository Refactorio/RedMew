local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local Command = require 'utils.command'
local Color = require 'resources.color_presets'
local Global = require 'utils.global'
local Retailer = require 'features.retailer'
local Market_Items = require 'map_gen.maps.space_race.market_items'
local Token = require 'utils.token'
local Task = require 'utils.task'

local floor = math.floor

require 'map_gen.maps.space_race.map_info'
require 'map_gen.maps.space_race.market_handler'
local Lobby = require 'map_gen.maps.space_race.lobby'

local Public = {}

local config = global.config

config.market.enabled = false
config.score.enabled = false
config.player_rewards.enabled = false
config.apocalypse.enabled = false
config.turret_active_delay.turret_types = {
    ['ammo-turret'] = 60 * 3,
    ['electric-turret'] = 60 * 10,
    ['fluid-turret'] = 60 * 5,
    ['artillery-turret'] = 60 * 60
}
config.turret_active_delay.techs = {}
config.player_create.show_info_at_start = false

local players_needed = 1
local player_kill_reward = 25
local entity_kill_reward = 1
local startup_timer = 60 * 60 * 2

local player_ports = {
    USA = {{x = -409, y = 0}, {x = -380, y = 0}},
    USSR = {{x = 409, y = 0}, {x = 380, y = 0}}
}

local disabled_research = {
    ['military'] = {player = 2, entity = 8},
    ['military-2'] = {player = 6, entity = 24, unlocks = 'military'},
    ['military-3'] = {player = 12, entity = 48, unlocks = 'military-2'},
    ['military-4'] = {player = 24, entity = 96, unlocks = 'military-3'},
    ['stone-walls'] = {player = 2, entity = 8, invert = true},
    ['heavy-armor'] = {player = 12, entity = 48, invert = true},
    ['artillery-shell-range-1'] = nil
}

local researched_tech = {}

local disabled_recipes = {
    'tank',
    'rocket-silo'
}

local primitives = {
    game_started = false,
    game_generating = false,
    started_tick = 0,
    force_USA = nil,
    force_USSR = nil,
    lobby_permissions = nil,
    won = nil
}

local unlock_progress = {
    force_USA = {
        players_killed = 0,
        entities_killed = 0
    },
    force_USSR = {
        players_killed = 0,
        entities_killed = 0
    }
}

Global.register(
    {
        primitives = primitives,
        unlock_progress = unlock_progress
    },
    function(tbl)
        primitives = tbl.primitives
        unlock_progress = tbl.unlock_progress
    end
)

local function remove_recipes()
    local USA_recipe = primitives.force_USA.recipes
    local USSR_recipe = primitives.force_USSR.recipes
    for _, recipe in pairs(disabled_recipes) do
        USA_recipe[recipe].enabled = false
        USSR_recipe[recipe].enabled = false
    end
end

local remove_permission_group =
    Token.register(
    function(params)
        params.permission_group.remove_player(params.player)
    end
)

local function deepcopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
    else
        copy = orig
    end
    return copy
end

Event.on_init(
    function()
        game.difficulty_settings.technology_price_multiplier = 0.5

        local force_USA = game.create_force('United Factory Workers')
        local force_USSR = game.create_force('Union of Factory Employees')

        local surface = RS.get_surface()

        force_USSR.set_spawn_position({x = 409, y = 0}, surface)
        force_USA.set_spawn_position({x = -409, y = 0}, surface)

        force_USSR.laboratory_speed_modifier = 1
        force_USA.laboratory_speed_modifier = 1

        local lobby_permissions = game.permissions.create_group('lobby')
        lobby_permissions.set_allows_action(defines.input_action.start_walking, false)

        force_USSR.chart(RS.get_surface(), {{x = 380, y = 16}, {x = 420, y = -16}})
        force_USA.chart(RS.get_surface(), {{x = -380, y = 16}, {x = -420, y = -16}})

        --game.forces.player.chart(RS.get_surface(), {{x = 400, y = 65}, {x = -400, y = -33}})
        local silo
        silo = surface.create_entity {name = 'rocket-silo', position = {x = 388.5, y = -0.5}, force = force_USSR}
        silo.minable = false

        silo = surface.create_entity {name = 'rocket-silo', position = {x = -388.5, y = 0.5}, force = force_USA}
        silo.minable = false

        local gun_turret
        gun_turret = surface.create_entity {name = 'gun-turret', position = {x = 383, y = 0}, force = force_USSR}
        gun_turret.insert({name = 'firearm-magazine', count = 200})

        gun_turret = surface.create_entity {name = 'gun-turret', position = {x = -383, y = 0}, force = force_USA}
        gun_turret.insert({name = 'firearm-magazine', count = 200})

        local market
        market = surface.create_entity {name = 'market', position = {x = 404, y = 0}, force = force_USSR}
        market.destructible = false

        Retailer.add_market('USSR_market', market)

        market = surface.create_entity {name = 'market', position = {x = -404, y = 0}, force = force_USA}
        market.destructible = false

        Retailer.add_market('USA_market', market)

        if table.size(Retailer.get_items('USSR_market')) == 0 then
            local items = deepcopy(Market_Items)
            for _, prototype in pairs(items) do
                local name = prototype.name
                prototype.price = (disabled_research[name] and disabled_research[name].player) and disabled_research[name].player * player_kill_reward or prototype.price
                local unlock_requires = disabled_research[name]
                if prototype.disabled and unlock_requires then
                    if unlock_requires.invert then
                        prototype.disabled_reason = {'', 'Unlocks when ' .. unlock_requires.player .. ' players have been killed or\n' .. unlock_requires.entity .. ' entities have been destroyed'}
                    else
                        prototype.disabled_reason = {'', 'To unlock kill ' .. unlock_requires.player .. ' players or\ndestroy ' .. unlock_requires.entity .. ' entities'}
                    end
                end
                Retailer.set_item('USSR_market', prototype)
            end
        end

        if table.size(Retailer.get_items('USA_market')) == 0 then
            local items = deepcopy(Market_Items)
            for _, prototype in pairs(items) do
                local name = prototype.name
                prototype.price = (disabled_research[name] and disabled_research[name].player) and disabled_research[name].player * player_kill_reward or prototype.price
                local unlock_requires = disabled_research[name]
                if prototype.disabled and unlock_requires then
                    if unlock_requires.invert then
                        prototype.disabled_reason = {'', 'Unlocks when ' .. unlock_requires.player .. ' players have been killed or\n ' .. unlock_requires.entity .. ' entities have been destroyed'}
                    else
                        prototype.disabled_reason = {'', 'To unlock kill ' .. unlock_requires.player .. ' players or\n destroy ' .. unlock_requires.entity .. ' entities'}
                    end
                end
                Retailer.set_item('USA_market', prototype)
            end
        end

        --[[
            Items support the following structure:
    {
        name: the (raw) item inserted in inventory, does nothing when type is not item
        name_label: the name shown in the GUI. If omitted and a prototype exists for 'name', it will use that LocalisedString, can be a LocalisedString
        sprite: a custom sprite, will use 'item/<name>' if omitted
        price: the price of an item, supports floats (0.95 for example)
        description: an additional description displayed in the tooltip, can be a LocalisedString
        disabled: whether or not the item should be disabled by default
        disabled_reason: the reason the item is disabled, can be a LocalisedString
    }
        ]]
        --ensures that the spawn points are not water
        surface.set_tiles(
            {
                {name = 'stone-path', position = {x = 409.5, y = 0.5}},
                {name = 'stone-path', position = {x = 409.5, y = -0.5}},
                {name = 'stone-path', position = {x = 408.5, y = -0.5}},
                {name = 'stone-path', position = {x = 408.5, y = 0.5}},
                {name = 'stone-path', position = {x = -409.5, y = 0.5}},
                {name = 'stone-path', position = {x = -409.5, y = -0.5}},
                {name = 'stone-path', position = {x = -408.5, y = -0.5}},
                {name = 'stone-path', position = {x = -408.5, y = 0.5}}
            }
        )

        for force_side, ports in pairs(player_ports) do
            local force
            if force_side == 'USA' then
                force = force_USA
            elseif force_side == 'USSR' then
                force = force_USSR
            end
            for _, port in pairs(ports) do
                rendering.draw_text {text = {'', 'Use the /warp command to teleport across'}, surface = surface, target = port, color = Color.red, forces = {force}, alignment = 'center', scale = 0.5}
            end
        end

        local USA_tech = force_USA.technologies
        local USSR_tech = force_USSR.technologies
        for research, _ in pairs(disabled_research) do
            USA_tech[research].enabled = false
            USSR_tech[research].enabled = false
        end
        for research, _ in pairs(researched_tech) do
            USA_tech[research].researched = true
            USSR_tech[research].researched = true
        end

        primitives.force_USA = force_USA
        primitives.force_USSR = force_USSR

        primitives.lobby_permissions = lobby_permissions

        remove_recipes()
    end
)

local function invert_force(force)
    local force_USA = primitives.force_USA
    local force_USSR = primitives.force_USSR
    if force == force_USA then
        return force_USSR
    elseif force == force_USSR then
        return force_USA
    end
end

local unlock_reasons = {
    player_killed = 1,
    entity_killed = 2
}

local function unlock_market_item(force, item_name)
    local group_name
    if force == primitives.force_USA then
        group_name = 'USA_market'
    elseif force == primitives.force_USSR then
        group_name = 'USSR_market'
    end
    if group_name then
        Retailer.enable_item(group_name, item_name)
        if not (item_name == 'tank') then
            Debug.print('Unlocked: ' .. item_name .. ' | For: ' .. group_name)
        end
    end
end

local function check_for_market_unlocks(force)
    local force_USA = primitives.force_USA
    local force_USSR = primitives.force_USSR

    for research, conditions in pairs(disabled_research) do
        local _force = force
        local inverted = conditions.invert
        local unlocks = conditions.unlocks

        if inverted then
            _force = invert_force(_force)
        end

        if force == force_USA then
            if conditions.player <= unlock_progress.force_USA.players_killed or conditions.entity <= unlock_progress.force_USA.entities_killed then
                unlock_market_item(_force, research)
                if unlocks then
                    unlock_market_item(invert_force(_force), unlocks)
                end
            end
        elseif force == force_USSR then
            if conditions.player <= unlock_progress.force_USSR.players_killed or conditions.entity <= unlock_progress.force_USSR.entities_killed then
                unlock_market_item(_force, research)
                if unlocks then
                    unlock_market_item(invert_force(_force), unlocks)
                end
            end
        end
    end

    if force_USA.technologies.tanks.researched then
        unlock_market_item(force_USA, 'tank')
    end
    if force_USSR.technologies.tanks.researched then
        unlock_market_item(force_USSR, 'tank')
    end
end

local function update_unlock_progress(force, unlock_reason)
    local players_killed
    local entities_killed
    local force_USA = primitives.force_USA
    local force_USSR = primitives.force_USSR
    if force == force_USA then
        players_killed = unlock_progress.force_USA.players_killed
        entities_killed = unlock_progress.force_USA.entities_killed
        if unlock_reason == unlock_reasons.player_killed then
            unlock_progress.force_USA.players_killed = players_killed + 1
        elseif unlock_reason == unlock_reasons.entity_killed then
            unlock_progress.force_USA.entities_killed = entities_killed + 1
        end
    elseif force == force_USSR then
        players_killed = unlock_progress.force_USSR.players_killed
        entities_killed = unlock_progress.force_USSR.entities_killed
        if unlock_reason == unlock_reasons.player_killed then
            unlock_progress.force_USSR.players_killed = players_killed + 1
        elseif unlock_reason == unlock_reasons.entity_killed then
            unlock_progress.force_USSR.entities_killed = entities_killed + 1
        end
    else
        return
    end

    check_for_market_unlocks(force)
end

local function restore_character(player)
    if primitives.game_started then
        player.set_controller {type = defines.controllers.god}
        player.create_character()
        Task.set_timeout_in_ticks(1, remove_permission_group, {permission_group = primitives.lobby_permissions, player = player})
        game.permissions.get_group('Default').add_player(player)
        for _, item in pairs(config.player_create.starting_items) do
            player.insert(item)
        end
    end
end

local function start_game()
    primitives.game_started = true
    primitives.started_tick = game.tick
    game.forces.enemy.evolution_factor = 0
    for _, player in pairs(primitives.force_USA.players) do
        restore_character(player)
    end
    for _, player in pairs(primitives.force_USSR.players) do
        restore_character(player)
    end
end

local function victory(force)
    primitives.won = force
    game.print('Congratulations to ' .. force.name .. '. You have gained factory dominance!')
    Lobby.all_to_lobby()
end

local function lost(force)
    local force_USA = primitives.force_USA
    if force == force_USA then
        victory(primitives.force_USSR)
    else
        victory(force_USA)
    end
end

local function on_entity_died(event)
    local entity = event.entity

    if entity.type == 'character' then
        return
    end

    local force = entity.force
    if entity.name == 'rocket-silo' then
        lost(force)
    end

    if force == 'player' or force == 'neutral' or force == 'enemy' then
        return
    end

    local cause = event.cause
    local cause_force = event.force

    if cause_force then
        if not (cause and cause.valid) then
            local force_USA = primitives.force_USA
            cause_force = (force == force_USA) and primitives.force_USSR or force_USA
            cause = entity.surface.find_entities_filtered {position = entity.position, radius = 50, type = 'character', force = cause_force, limit = 1}[1]
        end
    end

    if cause and cause.valid then
        if cause.prototype.name == 'character' then
            cause_force = cause.force
            if not (force == cause_force) then
                cause.insert({name = 'coin', count = entity_kill_reward})
                update_unlock_progress(cause_force, unlock_reasons.entity_killed)
            end
        end
    end
end

local function on_rocket_launched(event)
    victory(event.entity.force)
end

local function on_research_finished(event)
    check_for_market_unlocks(event.research.force)
    remove_recipes()
end

Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_rocket_launched, on_rocket_launched)
Event.add(defines.events.on_research_finished, on_research_finished)

local function on_player_died(event)
    local cause = event.cause
    if cause and cause.valid and cause.type == 'character' then
        local cause_force = cause.force
        if not (game.get_player(event.player_index).force == cause_force) then
            cause.insert({name = 'coin', count = player_kill_reward})
            update_unlock_progress(cause_force, unlock_reasons.player_killed)
        end
    end
end

local function on_built_entity(event)
    local entity = event.created_entity

    if not entity or not entity.valid then
        return
    end

    local name = entity.name
    if name == 'artillery-turret' or name == 'artillery-wagon' or name == 'tank' then
        local position = entity.position
        game.print({'', '[gps=' .. floor(position.x) .. ', ' .. floor(position.y) .. '] [color=yellow]Warning! ', {'entity-name.' .. name}, ' has been deployed![/color]'})
    end
end

Event.add(defines.events.on_player_died, on_player_died)
Event.add(defines.events.on_built_entity, on_built_entity)

local function allow_teleport(force, position)
    if force == primitives.force_USA and position.x > 0 then
        return false
    elseif force == primitives.force_USSR and position.x < 0 then
        return false
    end
    return math.abs(position.x) > 377 and math.abs(position.x) < 400 and position.y > -10 and position.y < 10
end

local function get_teleport_location(force, to_safe_zone)
    local port_number = to_safe_zone and 1 or 2
    local position
    if force == primitives.force_USA then
        position = player_ports.USA[port_number]
    elseif force == primitives.force_USSR then
        position = player_ports.USSR[port_number]
    else
        position = {0, 0}
    end
    local non_colliding_pos = RS.get_surface().find_non_colliding_position('character', position, 6, 1)
    position = non_colliding_pos and non_colliding_pos or position
    return position
end

local function teleport(_, player)
    local character = player.character
    if not character or not character.valid then
        player.print('[color=yellow]Could not warp, you are not part of a team yet![/color]')
        return
    end
    local tick = game.tick - primitives.started_tick
    if tick < startup_timer then
        local time_left = startup_timer - tick
        if time_left > 60 then
            local minutes = (time_left / 3600)
            minutes = minutes - minutes % 1
            time_left = time_left - (minutes * 3600)
            local seconds = (time_left / 60)
            seconds = seconds - seconds % 1
            time_left = minutes .. ' minutes and ' .. seconds .. ' seconds left'
        else
            local seconds = (time_left - (time_left % 60)) / 60
            time_left = seconds .. ' seconds left'
        end
        player.print('[color=yellow]Could not warp, in setup fase![/color] [color=red]' .. time_left .. '[/color]')
        return
    end
    local position = character.position
    local force = player.force
    if allow_teleport(force, position) then
        if math.abs(position.x) < 388.5 then
            player.teleport(get_teleport_location(force, true))
        else
            player.teleport(get_teleport_location(force, false))
        end
    else
        player.print('[color=yellow]Could not warp, you are too far from rocket silo![/color]')
    end
end

Command.add('warp', {description = 'Use to switch between PVP and Safe-zone in Space Race', capture_excess_arguments = false, allowed_by_server = false}, teleport)

local Gui = require 'utils.gui'

local function loading_gui(event)
    local frame
    local player = game.get_player(event.player_index)
    local center = player.gui.center
    local gui = center['Space-Race-Waiting']
    if (gui) then
        Gui.destroy(gui)
    end

    frame = player.gui.center.add {name = 'Space-Race-Waiting', type = 'frame', direction = 'vertical', style = 'captionless_frame'}

    frame.style.minimal_width = 300

    --Header
    local top_flow = frame.add {type = 'flow', direction = 'horizontal'}
    top_flow.style.horizontal_align = 'center'
    top_flow.style.horizontally_stretchable = true

    local title_flow = top_flow.add {type = 'flow'}
    title_flow.style.horizontal_align = 'center'
    title_flow.style.top_padding = 8
    title_flow.style.horizontally_stretchable = false

    local title = title_flow.add {type = 'label', caption = 'Welcome to Space Race'}
    title.style.font = 'default-large-bold'

    --Body

    local content_flow = frame.add {type = 'flow'}
    content_flow.style.top_padding = 8
    content_flow.style.horizontal_align = 'center'
    content_flow.style.horizontally_stretchable = true

    local label_flow = content_flow.add {type = 'flow', direction = 'vertical'}
    label_flow.style.horizontal_align = 'center'

    label_flow.style.horizontally_stretchable = true
    local label = label_flow.add {type = 'label', caption = 'Waiting for map to generate\nPlease wait\n'}
    label.style.horizontal_align = 'center'
    label.style.single_line = false
    label.style.font = 'default'
    label.style.font_color = Color.yellow

    local time = game.tick - primitives.started_tick

    if time > 60 then
        local minutes = (time / 3600)
        minutes = minutes - minutes % 1
        time = time - (minutes * 3600)
        local seconds = (time / 60)
        seconds = seconds - seconds % 1
        time = minutes .. ' minutes and ' .. seconds .. ' seconds'
    else
        local seconds = (time - (time % 60)) / 60
        time = seconds .. ' seconds'
    end

    label = label_flow.add {type = 'label', caption = '[color=blue]Time elapsed: ' .. time .. ' [/color]'}
    label.style.horizontal_align = 'center'
    label.style.single_line = false
    label.style.font = 'default'
end

local function show_waiting_gui()
    for _, player in pairs(game.connected_players) do
        loading_gui({player_index = player.index})
    end
end

local function remove_waiting_gui()
    for _, player in pairs(game.connected_players) do
        local center = player.gui.center
        local gui = center['Space-Race-Waiting']
        if (gui) then
            Gui.destroy(gui)
        end
    end
end

local check_map_gen_is_done
check_map_gen_is_done =
    Token.register(
    function()
        local num_usa_players = #primitives.force_USA.connected_players
        local num_ussr_players = #primitives.force_USSR.connected_players
        local num_players = num_usa_players + num_ussr_players
        if not primitives.game_started and num_players >= players_needed then
            local surface = RS.get_surface()
            if surface.get_tile({388.5, 0}).name == 'landfill' and surface.get_tile({-388.5, 0}).name == 'landfill' then
                primitives.started_tick = 0
                remove_waiting_gui()
                Event.remove_removable_nth_tick(60, check_map_gen_is_done)
                start_game()
                return
            end
            show_waiting_gui()
        else
            primitives.started_tick = 0
            remove_waiting_gui()
            Event.remove_removable_nth_tick(60, check_map_gen_is_done)
        end
    end
)

local function check_ready_to_start()
    local num_usa_players = #primitives.force_USA.connected_players
    local num_ussr_players = #primitives.force_USSR.connected_players
    local num_players = num_usa_players + num_ussr_players
    if not primitives.game_started and num_players >= players_needed then
        if primitives.started_tick == 0 then
            primitives.started_tick = game.tick
            Event.add_removable_nth_tick(60, check_map_gen_is_done)
        end
    else
        game.print(
            '[color=yellow]' ..
                primitives.force_USA.name ..
                    ' has [/color][color=red]' ..
                        num_usa_players ..
                            '[/color][color=yellow] players | ' .. primitives.force_USSR.name .. ' has [/color][color=red]' .. num_ussr_players .. '[/color][color=yellow] players | [/color][color=red]' .. players_needed - num_players .. '[/color][color=yellow] more players needed to start! [/color]'
        )
    end
end

local function check_player_balance(force)
    local force_USSR = primitives.force_USSR
    local force_USA = primitives.force_USA

    local usa_players = #force_USA.players
    local ussr_players = #force_USSR.players

    local usa_connected = #force_USA.connected_players
    local ussr_connected = #force_USSR.connected_players

    if force == force_USSR then
        return ussr_players - 2 <= usa_players and ussr_connected <= usa_connected
    elseif force == force_USA then
        return ussr_players >= usa_players - 2 and ussr_connected >= usa_connected
    end
end

function Public.join_usa(_, player)
    local force_USA = primitives.force_USA
    local force_USSR = primitives.force_USSR

    local force = player.force
    if not check_player_balance(force_USA) then
        player.print('[color=red]Failed to join [/color][color=yellow]United Factory Workers,[/color][color=red] teams would become unbalanced![/color]')
        return false
    end
    if not primitives.game_started or (force ~= force_USSR and force ~= force_USA) then
        player.force = force_USA
        player.print('[color=green]You have joined United Factory Workers![/color]')
        restore_character(player)
        player.teleport(get_teleport_location(force_USA, true), RS.get_surface())
        check_ready_to_start()
        return true
    end
    player.print('Failed to join new team, do not be a spy!')
end

Command.add('join-UFW', {description = 'Use to join United Factory Workers in Space Race', capture_excess_arguments = false, allowed_by_server = false}, Public.join_usa)

function Public.join_ussr(_, player)
    local force_USA = primitives.force_USA
    local force_USSR = primitives.force_USSR

    local force = player.force
    if not check_player_balance(force_USSR) then
        player.print('[color=red]Failed to join [/color][color=yellow]Union of Factory Employees[/color][color=red], teams would become unbalanced![/color]')
        return false
    end
    if not primitives.game_started or (force ~= force_USSR and force ~= force_USA) then
        player.force = force_USSR
        player.print('[color=green]You have joined Union of Factory Employees![/color]')
        restore_character(player)
        player.teleport(get_teleport_location(force_USSR, true), RS.get_surface())
        check_ready_to_start()
        return true
    end
    player.print('Failed to join new team, do not be a spy!')
end

Command.add('join-UFE', {description = 'Use to join Union of Factory Employees in Space Race', capture_excess_arguments = false, allowed_by_server = false}, Public.join_ussr)

function Public.get_won()
    return primitives.won
end

function Public.get_teams()
    return {primitives.force_USA, primitives.force_USSR}
end

function Public.get_game_status()
    return primitives.game_started
end

remote.add_interface('space-race', Public)

--[[TODO

Introduction / Map information

Starting trees!


NOTES:

Mapgen is slow (a loading screen would be nice)

Beach sine wave to break the hard line between shallow water and land

Tiny islands in shallow water, space for a couple of turrets but not much

Weapon damage balance -> Testing, testing, testing

Worms and biters can kill turrets at the spawns

]]
