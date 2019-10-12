local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local Command = require 'utils.command'
local Color = require 'resources.color_presets'
local Global = require 'utils.global'
local Retailer = require 'features.retailer'
local Market_Items = require 'map_gen.maps.space_race.market_items'
local Token = require 'utils.token'
local Task = require 'utils.task'
local config = require 'map_gen.maps.space_race.config'
local Table = require 'utils.table'

local floor = math.floor

require 'map_gen.maps.space_race.map_info'
require 'map_gen.maps.space_race.market_handler'
local Lobby = require 'map_gen.maps.space_race.lobby'

-- GUIs

local load_gui = require 'map_gen.maps.space_race.gui.load_gui'

local Public = {}

local redmew_config = global.config

redmew_config.market.enabled = false
redmew_config.score.enabled = false
redmew_config.player_rewards.enabled = false
redmew_config.apocalypse.enabled = false
redmew_config.turret_active_delay.turret_types = {
    ['ammo-turret'] = 60 * 3,
    ['electric-turret'] = 60 * 10,
    ['fluid-turret'] = 60 * 5,
    ['artillery-turret'] = 60 * 60
}
redmew_config.turret_active_delay.techs = {}
redmew_config.player_create.show_info_at_start = false
redmew_config.camera.enabled = false

local players_needed = config.players_needed_to_start_game
local player_kill_reward = config.player_kill_reward
local startup_timer = config.bootstrap_period

local player_ports = {
    USA = {{x = -409, y = 0}, {x = -380, y = 0}},
    USSR = {{x = 409, y = 0}, {x = 380, y = 0}}
}

local disabled_research = config.disabled_research

local researched_tech = {}

local disabled_recipes = config.disabled_recipes

local primitives = {
    game_started = false,
    game_generating = false,
    started_tick = 0,
    force_USA = nil,
    force_USSR = nil,
    lobby_permissions = nil,
    won = nil
}

Global.register(
    {
        primitives = primitives,
    },
    function(tbl)
        primitives = tbl.primitives
    end
)

function Public.remove_recipes()
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

        force_USSR.research_queue_enabled = true
        force_USA.research_queue_enabled = true

        local lobby_permissions = game.permissions.create_group('lobby')
        lobby_permissions.set_allows_action(defines.input_action.start_walking, false)

        force_USSR.chart(RS.get_surface(), {{x = 380, y = 64}, {x = 420, y = -64}})
        force_USA.chart(RS.get_surface(), {{x = -380, y = 64}, {x = -420, y = -64}})

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
            local items = Table.deep_copy(Market_Items)
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
            local items = Table.deep_copy(Market_Items)
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

        Public.remove_recipes()
    end
)

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

function Public.lost(force)
    local force_USA = primitives.force_USA
    if force == force_USA then
        victory(primitives.force_USSR)
    else
        victory(force_USA)
    end
end

local function on_rocket_launched(event)
    victory(event.entity.force)
end

Event.add(defines.events.on_rocket_launched, on_rocket_launched)

local function on_built_entity(event)
    local entity = event.created_entity

    if not entity or not entity.valid then
        return
    end

    local name = entity.name

    if config.neutral_entities[name] then
        entity.force = 'neutral'
        return
    end

    if config.warning_on_built[name] then
        local position = entity.position
        game.print({'', '[gps=' .. floor(position.x) .. ', ' .. floor(position.y) .. '] [color=yellow]Warning! ', {'entity-name.' .. name}, ' has been deployed![/color]'})
    end
end

Event.add(defines.events.on_built_entity, on_built_entity)

local function allow_teleport(force, position)
    if force == primitives.force_USA and position.x > 0 then
        return false
    elseif force == primitives.force_USSR and position.x < 0 then
        return false
    end
    return math.abs(position.x) > 377 and math.abs(position.x) < 410 and position.y > -10 and position.y < 10
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

local check_map_gen_is_done
check_map_gen_is_done =
    Token.register(
    function()
        local num_usa_players = #primitives.force_USA.connected_players
        local num_ussr_players = #primitives.force_USSR.connected_players
        local num_players = num_usa_players + num_ussr_players
        if not primitives.game_started and num_players >= players_needed then
            local surface = RS.get_surface()
            if surface.get_tile({388.5, 0}).name == 'landfill' and surface.get_tile({-388.5, 0}).name == 'landfill' and surface.get_tile({388.5, 60}).name == 'out-of-map' and surface.get_tile({-388.5, 60}).name == 'out-of-map' then
                primitives.started_tick = 0
                load_gui.remove_gui()
                Event.remove_removable_nth_tick(60, check_map_gen_is_done)
                start_game()
                return
            end
            load_gui.show_gui_to_all()
        else
            primitives.started_tick = 0
            load_gui.remove_gui()
            Event.remove_removable_nth_tick(60, check_map_gen_is_done)
        end
    end
)

local function check_ready_to_start()
    if primitives.game_started then
        return
    end
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

local function print_player_num(_, player)
    local force_USA = primitives.force_USA
    local force_USSR = primitives.force_USSR

    player.print('West: ' .. #force_USA.connected_players ..' online /' .. #force_USA.players .. ' total')
    player.print('East: ' .. #force_USSR.connected_players ..' online /' .. #force_USSR.players .. ' total')
end

Command.add('team_players', {description = 'Use to get number of players on both teams', capture_excess_arguments = false, allowed_by_server = false}, print_player_num)

function Public.get_won()
    return primitives.won
end

function Public.get_teams()
    return {primitives.force_USA, primitives.force_USSR}
end

function Public.get_game_status()
    return primitives.game_started
end

function Public.get_started_tick()
    return primitives.started_tick
end

remote.add_interface('space-race', Public)

--[[TODO

Starting trees!


NOTES:

Mapgen is slow (a loading screen would be nice)

Beach sine wave to break the hard line between shallow water and land

Tiny islands in shallow water, space for a couple of turrets but not much

Weapon damage balance -> Testing, testing, testing

Worms and biters can kill turrets at the spawns

]]
