local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local Command = require 'utils.command'
local Color = require 'resources.color_presets'
local insert = table.insert

require 'map_gen.maps.space_race.map_info'

local config = global.config

config.market.enabled = false

local force_USA
local force_USSR

local lobby_permissions

local player_ports = {
    USA = {{x = -397, y = 0}, {x = -380, y = 0}},
    USSR = {{x = 397, y = 0}, {x = 380, y = 0}}
}

Event.on_init(
    function()
        force_USA = game.create_force('United Factory Employees')
        force_USSR = game.create_force('Union of Factory Workers')

        local surface = RS.get_surface()

        force_USSR.set_spawn_position({x = 397, y = 0}, surface)
        force_USA.set_spawn_position({x = -397, y = 0}, surface)

        lobby_permissions = game.permissions.create_group('lobby')
        lobby_permissions.set_allows_action(defines.input_action.start_walking, false)

        --game.forces.player.chart(RS.get_surface(), {{x = 380, y = 16}, {x = 400, y = -16}})
        --game.forces.player.chart(RS.get_surface(), {{x = -380, y = 16}, {x = -400, y = -16}})

        --game.forces.player.chart(RS.get_surface(), {{x = 400, y = 65}, {x = -400, y = -33}})

        surface.create_entity {name = 'rocket-silo', position = {x = 388.5, y = -0.5}, force = force_USSR}
        surface.create_entity {name = 'rocket-silo', position = {x = -388.5, y = 0.5}, force = force_USA}

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
    end
)

local function victory(force)
    game.print('Congratulations to ' .. force.name .. '. You have gained factory dominance!')
end

local function lost(force)
    if force == force_USA then
        victory(force_USSR)
    else
        victory(force_USA)
    end
end

local function on_entity_died(event)
    local entity = event.entity
    if entity.name == 'rocket-silo' then
        lost(entity.force)
    end
end

local function on_rocket_launched(event)
    victory(event.entity.force)
end

local function to_lobby(player_index)
    local player = game.get_player(player_index)
    lobby_permissions.add_player(player)
    player.character.destroy()
    player.set_controller {type = defines.controllers.ghost}
    player.print('Waiting for lobby!')
end

local function on_player_created(event)
    to_lobby(event.player_index)
end

Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_rocket_launched, on_rocket_launched)
Event.add(defines.events.on_player_created, on_player_created)

local function allow_teleport(force, position)
    if force == force_USA and position.x > 0 then
        return false
    elseif force == force_USSR and position.x < 0 then
        return false
    end
    return math.abs(position.x) > 377 and math.abs(position.x) < 400 and position.y > -10 and position.y < 10
end

local function get_teleport_location(force, to_safe_zone)
    local port_number = to_safe_zone and 1 or 2
    local position
    if force == force_USA then
        position = player_ports.USA[port_number]
    elseif force == force_USSR then
        position = player_ports.USSR[port_number]
    else
        position = {0, 0}
    end
    return position
end

local function teleport(_, player)
    local position = player.character.position
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

local function join_usa(_, player)
    local force = player.force
    if force ~= force_USSR and force ~= force_USA then
        player.force = force_USA
        player.print('You have joined United Factory Employees!')
        player.set_controller {type = defines.controllers.god}
        player.create_character()
        lobby_permissions.remove_player(player)
        player.teleport(get_teleport_location(force_USA, true))
        return
    end
    player.print('Failed to join new team, do not be a spy!')
end

Command.add('join-usa', {description = 'Use to join United Factory Employees in Space Race', capture_excess_arguments = false, allowed_by_server = false}, join_usa)

local function join_ussr(_, player)
    local force = player.force
    if force ~= force_USSR and force ~= force_USA then
        player.force = force_USSR
        player.print('You have joined Union of Factory Workers!')
        player.set_controller {type = defines.controllers.god}
        player.create_character()
        lobby_permissions.remove_player(player)
        player.teleport(get_teleport_location(force_USSR, true))
        return
    end
    player.print('Failed to join new team, do not be a spy!')
end

Command.add('join-ussr', {description = 'Use to join Union of Factory Workers in Space Race', capture_excess_arguments = false, allowed_by_server = false}, join_ussr)

--393 384 -4 +5 {{x = -393, y = -4}, {x = -384, y = 5}}

--[[TODO

Disable artillery turret range research

Spawn points for the two forces

Coin rewards
Custom market with rewards brought with coins (and uranium)

Side selection

Waiting for players

Artillery turret long warm up + Global warning when setup

Disable tank recipe -> Brought with coins in the market + Global warning when deployed

Introduction / Map information

Starting trees!

]]
