local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Global = require 'utils.global'

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
    ['biter-spawner'] = {low = 5, high = 15},
    ['spitter-spawner'] = {low = 5, high = 15},
    ['small-worm-turret'] = {low = 2, high = 8},
    ['medium-worm-turret'] = {low = 5, high = 15},
    ['big-worm-turret'] = {low = 10, high = 20}
}

local spill_items =
    Token.register(
    function(data)
        local stack = {name = 'coin', count = data.count}
        data.surface.spill_item_stack(data.position, stack, true)
    end
)

local entity_spawn_map = {
    ['medium-biter'] = 'small-worm-turret',
    ['big-biter'] = 'medium-worm-turret',
    ['behemoth-biter'] = 'big-worm-turret'
}

local biters = {
    'small-biter',
    'medium-biter',
    'big-biter',
    'behemoth-biter'
}

local spitters = {
    'small-spitter',
    'medium-spitter',
    'big-spitter',
    'behemoth-spitter'
}

local turret_evolution_factor = {
    ['gun-turret'] = 0.002,
    ['laser-turret'] = 0.004,
    ['flamethrower-turret'] = 0.003,
    ['artillery-turret'] = 0.008
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
    return math.floor(ef * 4) + 1
end

local spawn_units =
    Token.register(
    function(data)
        local surface = data.surface
        local name = data.name
        local position = data.position
        for _ = 1, 5 do
            local p = surface.find_non_colliding_position(name, position, 8, 1)
            if p then
                surface.create_entity {name = name, position = p}
            end
        end
    end
)

Event.add(
    defines.events.on_entity_died,
    function(event)
        local entity = event.entity
        if not entity or not entity.valid then
            return
        end

        local name = entity.name

        local bounds = entity_drop_amount[name]
        if bounds then
            local unit_number = entity.unit_number
            if no_coin_entity[unit_number] then
                no_coin_entity[unit_number] = nil
            else
                local count = math.random(bounds.low, bounds.high)

                if count > 0 then
                    Task.set_timeout_in_ticks(
                        1,
                        spill_items,
                        {count = count, surface = entity.surface, position = entity.position}
                    )
                end
            end
        end

        local spawn = entity_spawn_map[name]

        if spawn then
            if math.random() <= 0.25 then
                Task.set_timeout_in_ticks(
                    1,
                    spawn_worm,
                    {surface = entity.surface, name = spawn, position = entity.position}
                )
            end
        else
            if name == 'biter-spawner' then
                local unit = biters[get_level()]
                Task.set_timeout_in_ticks(
                    10,
                    spawn_units,
                    {surface = entity.surface, name = unit, position = entity.position}
                )
            elseif name == 'spitter-spawner' then
                local unit = spitters[get_level()]
                Task.set_timeout_in_ticks(
                    10,
                    spawn_units,
                    {surface = entity.surface, name = unit, position = entity.position}
                )
            end
        end

        local factor = turret_evolution_factor[name]
        if factor then
            local force = entity.force
            if force.name == 'enemy' then
                local old = force.evolution_factor
                local new = old + (1 - old) * factor
                force.evolution_factor = math.min(new, 1)
            end
        end
    end
)
