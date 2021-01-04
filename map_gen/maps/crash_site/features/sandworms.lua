-- This module starts spawning worms every 5 to 10 minutes (approx) when a roboport is placed.
-- Makes it necessary to defend roboports and limits the usefulness of large roboport networks
local Event = require 'utils.event'
local Global = require 'utils.global'
local Task = require 'utils.task'
local Token = require 'utils.token'

local set_timeout_in_ticks = Task.set_timeout_in_ticks
local min_worm_period_secs = 360 -- 6 minutes
local max_worm_period_secs = 1200 -- 20 minutes
local max_worm_spawn_radius = 30

local roboports = {}
Global.register({roboports = roboports}, function(tbl)
    roboports = tbl.roboports

end)

local sandworms = {
    ['medium-worm-turret'] = {evo_min = 0.4, evo_max = 0.6},
    ['big-worm-turret'] = {evo_min = 0.6, evo_max = 0.9},
    ['behemoth-worm-turret'] = {evo_min = 0.9, evo_max = 1}
}

local sandworm_biters = {
    ['medium-worm-turret'] = {['small-biter'] = {min = 2.5, max = 3.5}, ['medium-biter'] = {min = 1.0, max = 2}},
    ['big-worm-turret'] = {
        ['small-biter'] = {min = 2.5, max = 4},
        ['medium-biter'] = {min = 1.5, max = 2.2},
        ['medium-spitter'] = {min = 1.5, max = 2.2}
    },
    ['behemoth-worm-turret'] = {
        ['small-biter'] = {min = 4, max = 5.2},
        ['medium-biter'] = {min = 2.5, max = 3.8},
        ['big-biter'] = {min = 1.2, max = 2.4},
        ['big-spitter'] = {min = 1.2, max = 2.4}
    }
}

local function spawn_sandworms(entity)
    local evolution = game.forces["enemy"].evolution_factor
    if evolution < 0.4 then
        return
    end
    for index, worm_type in pairs(sandworms) do
        -- Determine which worm type to spawn based on the evolution
        if (evolution > worm_type.evo_min) and (evolution <= worm_type.evo_max) then
            local s = entity.surface
            local worm_position = {
                entity.position.x + math.random(max_worm_spawn_radius * -1, max_worm_spawn_radius),
                entity.position.y + math.random(max_worm_spawn_radius * -1, max_worm_spawn_radius)
            }
            worm_position = s.find_non_colliding_position(index, worm_position, 5, 1)
            if worm_position then
                s.create_entity {name = index, position = worm_position, force = "enemy"}
            end
            -- For the appropriate worm for each evolution region, spawn some accompanying biters to attack the roboport
            for worm, biters in pairs(sandworm_biters) do
                if worm == index then
                    for biter, data in pairs(biters) do
                        local amount = math.random(data.min, data.max)
                        local extra_chance = amount % 1
                        if extra_chance > 0 then
                            if math.random(0,1) <= extra_chance then
                                amount = math.ceil(amount)
                            else
                                amount = math.floor(amount)
                            end
                        end
                        for _ = 1, amount do
                           local pos = s.find_non_colliding_position(biter, worm_position, 5, 1)
                           if pos then
                            local spawned_biter = s.create_entity {name = biter, position = pos, force = "enemy"}
                            spawned_biter.set_command({type = defines.command.attack, target = entity})
                           end
                        end
                    end
                end
            end
        end
    end
end

local thump_text_callback
thump_text_callback = Token.register(function(entity)
    local s = entity.surface
    local entity_position = entity.position
    s.create_entity{name="flying-text", position={(entity_position.x + math.random(-3,3)),(entity_position.y + math.random(0,3))}, text="*thump*", color={r=0.6,g=0.4,b=0}}
end)

local worm_callback
worm_callback = Token.register(function(entity)
    if entity then -- stops the callback if the roboport has been removed
        spawn_sandworms(entity)
        local callback_timer = math.random(min_worm_period_secs * 60, max_worm_period_secs * 60)
        set_timeout_in_ticks(callback_timer, worm_callback, entity)
    end
end)

local function start_worm_attacks(entity)
    if not entity then
        return
    end
    local callback_timer = math.random(min_worm_period_secs * 60, max_worm_period_secs * 60)
    set_timeout_in_ticks(callback_timer, worm_callback, entity)
    for i = 1, 5 do
        set_timeout_in_ticks(60*i, thump_text_callback, entity)
    end
end

Event.add(defines.events.on_robot_built_entity, function(event)
    if event.created_entity.name == 'roboport' then
        start_worm_attacks(event.created_entity)
        
    end
end)

Event.add(defines.events.on_built_entity, function(event)
    if event.created_entity.name == 'roboport' then
        start_worm_attacks(event.created_entity)
        local player = game.get_player(event.player_index)
        player.print("A sandworm approaches.....")
    end
end)

Event.add(defines.events.on_entity_cloned, function(event)
    if event.created_entity.name == 'roboport' then
        start_worm_attacks(event.created_entity)
    end
end)
