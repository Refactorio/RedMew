local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Global = require 'utils.global'
local Game = require 'utils.game'

local random = math.random
local set_timeout_in_ticks = Task.set_timeout_in_ticks

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
    ['medium-biter'] = {name = 'small-biter', count = 2, chance = 1},
    ['big-biter'] = {name = 'medium-biter', count = 2, chance = 1},
    ['behemoth-biter'] = {name = 'big-biter', count = 2, chance = 1},
    ['medium-spitter'] = {name = 'small-worm-turret', count = 1, chance = 0.25},
    ['big-spitter'] = {name = 'medium-worm-turret', count = 1, chance = 0.25},
    ['behemoth-spitter'] = {name = 'big-worm-turret', count = 1, chance = 0.25},
    ['biter-spawner'] = {type = 'biter', count = 5, chance = 1},
    ['spitter-spawner'] = {type = 'spitter', count = 5, chance = 1},
    ['stone-furnace'] = {type = 'cause', count = 1, chance = 1},
    ['steel-furnace'] = {type = 'cause', count = 1, chance = 1},
    ['electric-furnace'] = {type = 'cause', count = 2, chance = 1},
    ['assembling-machine-1'] = {type = 'cause', count = 2, chance = 1},
    ['assembling-machine-2'] = {type = 'cause', count = 2, chance = 1},
    ['assembling-machine-3'] = {type = 'cause', count = 2, chance = 1},
    ['chemical-plant'] = {type = 'cause', count = 2, chance = 1},
    ['centrifuge'] = {type = 'cause', count = 3, chance = 1},
    ['oil-refinery'] = {type = 'cause', count = 4, chance = 1},
    ['offshore-pump'] = {type = 'cause', count = 1, chance = 1},
    ['boiler'] = {type = 'cause', count = 1, chance = 1},
    ['heat-exchanger'] = {type = 'cause', count = 2, chance = 1},
    ['steam-engine'] = {type = 'cause', count = 3, chance = 1},
    ['steam-turbine'] = {type = 'cause', count = 5, chance = 1},
    ['nuclear-reactor'] = {type = 'cause', count = 10, chance = 1},
    ['rocket-silo'] = {type = 'cause', count = 20, chance = 1},
    ['train-stop'] = {type = 'cause', count = 1, chance = 1},
    ['burner-mining-drill'] = {type = 'cause', count = 1, chance = 1},
    ['electric-mining-drill'] = {type = 'cause', count = 2, chance = 1},
    ['lab'] = {type = 'cause', count = 3, chance = 1},
    ['solar-panel'] = {type = 'cause', count = 2, chance = 1},
    ['accumulator'] = {type = 'cause', count = 1, chance = 1},
    ['beacon'] = {type = 'cause', count = 3, chance = 1},
    ['radar'] = {type = 'cause', count = 2, chance = 1}
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
    return math.floor(ef * 4) + 1
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

Event.add(
    defines.events.on_entity_died,
    function(event)
        local entity = event.entity
        if not entity or not entity.valid then
            return
        end

        local force = event.force
        if force and force == entity.force then
            return
        end

        local entity_name = entity.name

        local factor = turret_evolution_factor[entity_name]
        if factor then
            local force = entity.force
            if force.name == 'enemy' then
                local old = force.evolution_factor
                local new = old + (1 - old) * factor
                force.evolution_factor = math.min(new, 1)
            end
        end

        local bounds = entity_drop_amount[entity_name]
        if bounds then
            local unit_number = entity.unit_number
            if no_coin_entity[unit_number] then
                no_coin_entity[unit_number] = nil
            else
                local count = math.random(bounds.low, bounds.high)

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

        if spawn then
            local chance = spawn.chance
            if chance == 1 or random() <= chance then
                local name = spawn.name
                if name == nil then
                    local type = spawn.type
                    if type == 'cause' then
                        local cause = event.cause
                        if not cause or force.name == 'player' then
                            return
                        end
                        name = cause.name
                    else
                        name = unit_levels[spawn.type][get_level()]
                    end
                end
                set_timeout_in_ticks(
                    5,
                    spawn_units,
                    {surface = entity.surface, name = name, position = entity.position, count = spawn.count}
                )
            end
        end
    end
)

Event.add(
    defines.events.on_player_died,
    function(event)
        local player = Game.get_player_by_index(event.player_index)
        set_timeout_in_ticks(1, spawn_player, player)
    end
)
