--Reactors melt down if:
--temperature is at 1000°C and health is 0 or reactor is picked up
--
--a reactors loses 2 damage per second at 1000°C

local Event = require 'utils.event'
local Game = require 'utils.game'
local Command = require 'utils.command'
local Global = require 'utils.global'
local Ranks = require 'resources.ranks'
local Color = require 'resources.color_presets'

local primitives = {reactors_enabled = global.config.reactor_meltdown.on_by_default}
local wastelands = {}
local reactors = {}

Global.register(
    {
        primitives = primitives,
        wastelands = wastelands,
        reactors = reactors
    },
    function(tbl)
        primitives = tbl.primitives
        wastelands = tbl.wastelands
        reactors = tbl.reactors
    end
)

local wasteland_duration_seconds = 300

local function spawn_wasteland(surface, position)
    local positions = {
        {0, 0},
        {0, 12},
        {0, -12},
        {12, 0},
        {-12, 0},
        {-8.5, 8.5},
        {-8.5, -8.5},
        {8.5, -8.5},
        {8.5, 8.5},
        {4, 4},
        {-4, 4},
        {-4, -4},
        {4, -4},
        {13, 7.5},
        {-13, 7.5},
        {-13, -7.5},
        {13, -7.5},
        {7.5, 13},
        {-7.5, 13},
        {-7.5, -13},
        {7.5, -13},
        {0, 15},
        {-15, 0},
        {15, 0},
        {0, -15}
    }
    for _, rel_position in pairs(positions) do
        surface.create_entity {
            name = 'poison-capsule',
            position = position,
            target = {position.x + rel_position[1], position.y + rel_position[2]},
            speed = 0.4
        }
    end
end

local function entity_destroyed(event)
    if not primitives.reactors_enabled or not event.entity.valid or event.entity.name ~= 'nuclear-reactor' then
        return
    end

    local reactor = event.entity

    if reactor.temperature > 700 then
        reactor.surface.create_entity {name = 'atomic-rocket', position = reactor.position, target = reactor, speed = 1}
        spawn_wasteland(reactor.surface, reactor.position)
        wastelands[reactor.position.x .. '/' .. reactor.position.y] = {
            position = reactor.position,
            surface_id = reactor.surface.index,
            creation_time = game.tick
        }
    end
end

local function alert(reactor)
    for _, p in pairs(game.players) do
        p.add_custom_alert(reactor, {type = 'item', name = 'nuclear-reactor'}, string.format('Reactor at %s°C', math.floor(reactor.temperature)), true)
    end
end

local function check_reactors()
    for _ in pairs(game.surfaces) do
        for i, reactor in pairs(reactors) do
            if reactor.valid then
                if reactor.temperature > 800 then
                    alert(reactor)
                end
                if reactor.temperature == 1000 then
                    reactor.force = 'enemy'
                    reactor.destructible = false
                    reactor.health = 0
                    reactor.surface.create_entity {
                        name = 'atomic-rocket',
                        position = reactor.position,
                        target = reactor,
                        speed = 1
                    }
                    spawn_wasteland(reactor.surface, reactor.position)
                    wastelands[reactor.position.x .. '/' .. reactor.position.y] = {
                        position = reactor.position,
                        surface_id = reactor.surface.index,
                        creation_time = game.tick
                    }
                    table.remove(reactors, i)
                else
                    reactor.health = 500 - (reactor.temperature - 800) * 2.5
                end
            else
                table.remove(reactors, i)
            end
        end
        --global.last_reactor_warning = last_reactor_warning
    end
end

local function check_wastelands()
    for index, wl in pairs(wastelands) do
        local age = game.tick - wl.creation_time
        wl.last_checked = wl.last_checked or 0
        if (game.tick - wl.last_checked) > 899 then
            wl.last_checked = game.tick
            spawn_wasteland(game.surfaces[wl.surface_id], wl.position)
            if age > wasteland_duration_seconds * 60 - 1 then
                wastelands[index] = nil
                local wasteland_reactors =
                    game.surfaces[wl.surface_id].find_entities_filtered {
                    position = wl.position,
                    name = 'nuclear-reactor'
                }
                if wasteland_reactors[1] then
                    wasteland_reactors[1].destroy({raise_destroy = true})
                end
            end
        end
    end
end

local function on_tick()
    if primitives.reactors_enabled then
        check_wastelands()
        check_reactors()
    end
end

local function entity_build(event)
    if not event.created_entity.valid then
        return
    end
    if event.created_entity.name == 'nuclear-reactor' and event.created_entity.surface.name ~= 'antigrief' then
        table.insert(reactors, event.created_entity)
    end
end

--- Prints whether meltdown is on or off
local function get_meltdown()
    if primitives.reactors_enabled then
        Game.player_print({'meltdown.is_enabled'})
    else
        Game.player_print({'meltdown.is_disabled'})
    end
end

--- Toggles meltdown on or off
local function set_meltdown(args)
    local on_off = args['on|off']
    if on_off == 'on' then
        primitives.reactors_enabled = true
        game.print({'meltdown.enable'})
    elseif on_off == 'off' then
        primitives.reactors_enabled = nil
        game.print({'meltdown.disable'})
    else
        Game.player_print({'meltdown.error_not_on_off'}, Color.fail)
    end
end

Command.add(
    'meltdown-get',
    {
        description = {'command_description.meltdown_get'},
        allowed_by_server = true
    },
    get_meltdown
)

Command.add(
    'meltdown-set',
    {
        description = {'command_description.meltdown_set'},
        arguments = {'on|off'},
        allowed_by_server = true,
        required_rank = Ranks.admin,
        log_command = true
    },
    set_meltdown
)

Event.on_nth_tick(60, on_tick)
Event.add(defines.events.on_player_mined_entity, entity_destroyed)
Event.add(defines.events.on_robot_mined_entity, entity_destroyed)
Event.add(defines.events.on_entity_died, entity_destroyed)
Event.add(defines.events.on_built_entity, entity_build)
Event.add(defines.events.on_robot_built_entity, entity_build)
