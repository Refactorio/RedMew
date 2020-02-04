local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Global = require 'utils.global'
local math = require 'utils.math'
local table = require 'utils.table'

local random = math.random
local set_timeout_in_ticks = Task.set_timeout_in_ticks
local ceil = math.ceil
local draw_arc = rendering.draw_arc
local fast_remove = table.fast_remove

local tau = 2 * math.pi
local start_angle = -tau / 4
local update_rate = 4 -- ticks between updates
local time_to_live = update_rate + 1
local pole_respawn_time = 60 * 60

local no_coin_entity = {}

Global.register(
    {no_coin_entity = no_coin_entity},
    function(tbl)
        no_coin_entity = tbl.no_coin_entity
    end
)

local entity_drop_amount = {
    --[[['small-biter'] = {low = -62, high = 1},
    ['small-spitter'] = {low = -62, high = 1},
    ['medium-biter'] = {low = -14, high = 1},
    ['medium-spitter'] = {low = -14, high = 1},
    ['big-biter'] = {low = -2, high = 1},
    ['big-spitter'] = {low = -2, high = 1},
    ['behemoth-biter'] = {low = 1, high = 1},
    ['behemoth-spitter'] = {low = 1, high = 1}, ]]
    ['biter-spawner'] = {low = 8, high = 24},
    ['spitter-spawner'] = {low = 8, high = 24},
    ['small-worm-turret'] = {low = 3, high = 10},
    ['medium-worm-turret'] = {low = 8, high = 24},
    ['big-worm-turret'] = {low = 15, high = 30},
    ['behemoth-worm-turret'] = {low = 25, high = 45}
}

local spill_items =
    Token.register(
    function(data)
        local stack = {name = 'coin', count = data.count}
        data.surface.spill_item_stack(data.position, stack, true)
    end
)

local entity_spawn_map = {
    ['medium-biter'] = {name = 'small-worm-turret', count = 1, chance = 0.2},
    ['big-biter'] = {name = 'medium-worm-turret', count = 1, chance = 0.2},
    ['behemoth-biter'] = {name = 'big-worm-turret', count = 1, chance = 0.2},
    ['medium-spitter'] = {name = 'small-worm-turret', count = 1, chance = 0.2},
    ['big-spitter'] = {name = 'medium-worm-turret', count = 1, chance = 0.2},
    ['behemoth-spitter'] = {name = 'big-worm-turret', count = 1, chance = 0.2},
    ['biter-spawner'] = {type = 'biter', count = 5, chance = 1},
    ['spitter-spawner'] = {type = 'spitter', count = 5, chance = 1},
    ['behemoth-worm-turret'] = {
        type = 'compound',
        spawns = {
            {name = 'behemoth-spitter', count = 2},
            {name = 'behemoth-biter', count = 2}
        },
        chance = 1
    },
    ['stone-furnace'] = {type = 'cause', count = 2, chance = 1},
    ['steel-furnace'] = {type = 'cause', count = 2, chance = 1},
    ['electric-furnace'] = {type = 'cause', count = 4, chance = 1},
    ['assembling-machine-1'] = {type = 'cause', count = 4, chance = 1},
    ['assembling-machine-2'] = {type = 'cause', count = 4, chance = 1},
    ['assembling-machine-3'] = {type = 'cause', count = 4, chance = 1},
    ['chemical-plant'] = {type = 'cause', count = 4, chance = 1},
    ['centrifuge'] = {type = 'cause', count = 6, chance = 1},
    ['pumpjack'] = {type = 'cause', count = 6, chance = 1},
    ['storage-tank'] = {type = 'cause', count = 4, chance = 1},
    ['oil-refinery'] = {type = 'cause', count = 8, chance = 1},
    ['offshore-pump'] = {type = 'cause', count = 2, chance = 1},
    ['boiler'] = {type = 'cause', count = 2, chance = 1},
    ['heat-exchanger'] = {type = 'cause', count = 4, chance = 1},
    ['steam-engine'] = {type = 'cause', count = 6, chance = 1},
    ['steam-turbine'] = {type = 'cause', count = 10, chance = 1},
    ['nuclear-reactor'] = {type = 'cause', count = 20, chance = 1},
    ['rocket-silo'] = {type = 'cause', count = 40, chance = 1},
    ['train-stop'] = {type = 'cause', count = 2, chance = 1},
    ['burner-mining-drill'] = {type = 'cause', count = 2, chance = 1},
    ['electric-mining-drill'] = {type = 'cause', count = 4, chance = 1},
    ['lab'] = {type = 'cause', count = 6, chance = 1},
    ['solar-panel'] = {type = 'cause', count = 4, chance = 1},
    ['accumulator'] = {type = 'cause', count = 2, chance = 1},
    ['beacon'] = {type = 'cause', count = 6, chance = 1},
    ['radar'] = {type = 'cause', count = 4, chance = 1}
}

local unit_levels = {
    biter = {
        'small-biter',
        'medium-biter',
        'big-biter',
        'behemoth-biter'
    },
    spitter = {
        'small-spitter',
        'medium-spitter',
        'big-spitter',
        'behemoth-spitter'
    }
}

local worms = {
    ['small-worm-turret'] = true,
    ['medium-worm-turret'] = true,
    ['big-worm-turret'] = true,
    ['behemoth-worm-turret'] = true
}

local allowed_cause_source = {
    ['small-biter'] = true,
    ['medium-biter'] = true,
    ['big-biter'] = true,
    ['behemoth-biter'] = true,
    ['small-spitter'] = true,
    ['medium-spitter'] = true,
    ['big-spitter'] = true,
    ['behemoth-spitter'] = true
}

local turret_evolution_factor = {
    ['gun-turret'] = 0.001,
    ['laser-turret'] = 0.002,
    ['flamethrower-turret'] = 0.0015,
    ['artillery-turret'] = 0.004
}

local spawn_worm =
    Token.register(
    function(data)
        local surface = data.surface
        local name = data.name
        local position = data.position

        local p = surface.find_non_colliding_position(name, position, 8, 1)

        if p then
            local entity = surface.create_entity({name = data.name, position = data.position})
            no_coin_entity[entity.unit_number] = true
        end
    end
)

local function get_level()
    local ef = game.forces.enemy.evolution_factor
    if ef == 0 then
        return 1
    else
        return ceil(ef * 4)
    end
end

local spawn_units =
    Token.register(
    function(data)
        local surface = data.surface
        local name = data.name
        local position = data.position
        for _ = 1, data.count do
            local p = surface.find_non_colliding_position(name, position, 8, 1)
            if p then
                surface.create_entity {name = name, position = p}
            end
        end
    end
)

local spawn_player =
    Token.register(
    function(player)
        if player and player.valid then
            player.ticks_to_respawn = 3600
        end
    end
)

local function has_valid_turret(turrets)
    for i = #turrets, 1, -1 do
        local turret = turrets[i]
        if turret.valid then
            return true
        else
            fast_remove(turrets, i)
        end
    end

    return false
end

local pole_callback
pole_callback =
    Token.register(
    function(data)
        if not has_valid_turret(data.turrets) then
            return
        end

        local tick = data.tick
        local now = game.tick

        if now >= tick then
            data.surface.create_entity({name = data.name, force = 'enemy', position = data.position})
            return
        end

        local fraction = ((now - tick) / pole_respawn_time) + 1

        draw_arc(
            {
                color = {1 - fraction, fraction, 0},
                max_radius = 0.5,
                min_radius = 0.4,
                start_angle = start_angle,
                angle = fraction * tau,
                target = data.position,
                surface = data.surface,
                time_to_live = time_to_live
            }
        )

        set_timeout_in_ticks(update_rate, pole_callback, data)
    end
)

local filter = {area = nil, name = 'laser-turret', force = 'enemy'}

local function do_pole(entity)
    if entity.type ~= 'electric-pole' then
        return
    end

    local supply_area_distance = entity.prototype.supply_area_distance
    if not supply_area_distance then
        return
    end

    local surface = entity.surface
    local position = entity.position
    local x, y = position.x, position.y
    local d = supply_area_distance / 2
    filter.area = {{x - d, y - d}, {x + d, y + d}}

    local turrets = surface.find_entities_filtered(filter)

    if #turrets == 0 then
        return
    end

    set_timeout_in_ticks(
        update_rate,
        pole_callback,
        {
            name = entity.name,
            position = position,
            surface = surface,
            tick = game.tick + pole_respawn_time,
            turrets = turrets
        }
    )
end

Event.add(
    defines.events.on_entity_died,
    function(event)
        local entity = event.entity
        if not entity or not entity.valid then
            return
        end

        local entity_force = entity.force
        local entity_name = entity.name

        if entity_force.name == 'enemy' then
            do_pole(entity)

            local factor = turret_evolution_factor[entity_name]
            if factor then
                local old = entity_force.evolution_factor
                local new = old + (1 - old) * factor
                entity_force.evolution_factor = math.min(new, 1)
            end
        end

        local bounds = entity_drop_amount[entity_name]
        if bounds then
            local unit_number = entity.unit_number
            if no_coin_entity[unit_number] then
                no_coin_entity[unit_number] = nil
            else
                local count = random(bounds.low, bounds.high)

                if count > 0 then
                    set_timeout_in_ticks(
                        1,
                        spill_items,
                        {count = count, surface = entity.surface, position = entity.position}
                    )
                end
            end
        end

        local spawn = entity_spawn_map[entity_name]
        if not spawn then
            return
        end

        local chance = spawn.chance
        if chance ~= 1 and random() > chance then
            return
        end

        local name = spawn.name
        if name == nil then
            local type = spawn.type
            if type == 'cause' then
                local cause = event.cause
                if not cause then
                    return
                end
                name = cause.name
                if not allowed_cause_source[cause.name] then
                    return
                end
            elseif type == 'compound' then
                local spawns = spawn.spawns
                spawn = spawns[random(#spawns)]
                name = spawn.name
            else
                name = unit_levels[type][get_level()]
            end
        end

        if worms[name] then
            set_timeout_in_ticks(5, spawn_worm, {surface = entity.surface, name = name, position = entity.position})
        else
            set_timeout_in_ticks(
                5,
                spawn_units,
                {surface = entity.surface, name = name, position = entity.position, count = spawn.count}
            )
        end
    end
)

Event.add(
    defines.events.on_player_died,
    function(event)
        local player = game.get_player(event.player_index)
        set_timeout_in_ticks(1, spawn_player, player)
    end
)
