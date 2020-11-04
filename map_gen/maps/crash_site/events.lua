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
    biter = {'small-biter', 'medium-biter', 'big-biter', 'behemoth-biter'},
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
            data.surface.create_entity(
                {
                    name = data.name,
                    force = 'enemy',
                    position = data.position
                }
            )
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

local function do_evolution(entity_name, entity_force)
    local factor = turret_evolution_factor[entity_name]
    if factor then
        local old = entity_force.evolution_factor
        local new = old + (1 - old) * factor
        entity_force.evolution_factor = math.min(new, 1)
    end
end

local bot_spawn_whitelist = {
    ['gun-turret'] = true,
    ['laser-turret'] = true,
    ['flamethrower-turret'] = true,
    ['artillery-turret'] = true
}

local bot_cause_whitelist = {
    ['character'] = true,
    ['artillery-turret'] = true,
    ['artillery-wagon'] = true,
    ['spidertron'] = true
}

local function do_bot_spawn(entity_name, entity, event)
    if not bot_spawn_whitelist[entity_name] then
        return
    end

    local cause = event.cause
    if not cause or not bot_cause_whitelist[cause.name] then
        return
    end

    local entity_force = entity.force
    local ef = entity_force.evolution_factor

    if ef <= 0.2 then
        return
    end

    local create_entity = entity.surface.create_entity
    local repeat_cycle = 1 -- The number of times a squad of robots are spawned default must be 1
    if ef > .95 then
        repeat_cycle = 2
    end

    local spawn_entity = {
        position = entity.position,
        target = cause,
        force = entity_force
    }

    if cause.name ~= 'character' then
        if entity_name == 'artillery-turret' then
            repeat_cycle = 15
        else
            repeat_cycle = 4
        end
        for i = 1, repeat_cycle do
            spawn_entity.name = 'defender'
            create_entity(spawn_entity)
            create_entity(spawn_entity)

            spawn_entity.name = 'destroyer'
            create_entity(spawn_entity)
            create_entity(spawn_entity)
        end
    elseif entity_name == 'gun-turret' then
        for i = 1, repeat_cycle do
            spawn_entity.name = 'defender'
            create_entity(spawn_entity)
            create_entity(spawn_entity)

            spawn_entity.name = 'destroyer'
            create_entity(spawn_entity)
        end
    elseif entity_name == 'laser-turret' then
        for i = 1, repeat_cycle do
            spawn_entity.name = 'defender'
            create_entity(spawn_entity)

            spawn_entity.name = 'destroyer'
            create_entity(spawn_entity)
            create_entity(spawn_entity)
        end
    else
        for i = 1, repeat_cycle do
            spawn_entity.name = 'distractor-capsule'
            spawn_entity.speed = 0
            create_entity(spawn_entity)
        end
    end
end

-- Drops coins when biter/spitter spawners and worms are killed
local function do_coin_drop(entity_name, entity)
    local position = entity.position
    local bounds = entity_drop_amount[entity_name]
    if not bounds then
        return
    end

    local unit_number = entity.unit_number
    if no_coin_entity[unit_number] then
        no_coin_entity[unit_number] = nil
        return
    end

    local count = random(bounds.low, bounds.high)
    if count > 0 then
        set_timeout_in_ticks(
            1,
            spill_items,
            {
                count = count,
                surface = entity.surface,
                position = position
            }
        )
    end
end

local function do_spawn_entity(entity_name, entity, event)
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

    local position = entity.position
    if worms[name] then
        set_timeout_in_ticks(
            5,
            spawn_worm,
            {
                surface = entity.surface,
                name = name,
                position = position
            }
        )
    else
        set_timeout_in_ticks(
            5,
            spawn_units,
            {
                surface = entity.surface,
                name = name,
                position = position,
                count = spawn.count
            }
        )
    end
end

-- damageable-spider-leg lua module
-- adapted from mod: https://mods.factorio.com/mod/damageable-spider-leg
-- by x2605

local damageable_spider_leg = {}
local debugging = false
local damage_modifier = 1/6

local register_spider =  function(entity)
  if not entity then return end
  if not entity.valid then return end
  if entity.type ~= 'spider-vehicle' then return end
  if not global.damageable_spider_leg then
    global.damageable_spider_leg = {}
  end
  local data = {}
  local spider = entity
  local surface = spider.surface
  local legs = surface.find_entities_filtered{
    position = spider.position,
    radius = 10,
    type = 'spider-leg'
  }
  for _, leg in pairs(legs) do
    if not leg.destructible then
      leg.destructible = true
      data[#data + 1] = leg
    end
  end
  global.damageable_spider_leg[tostring(spider.unit_number)] = data
  script.register_on_entity_destroyed(spider)
  if debugging then
    game.print{"",'legs=',#data,' ',spider.name,spider.unit_number}
  end
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
            do_evolution(entity_name, entity_force)
            do_coin_drop(entity_name, entity)
            do_bot_spawn(entity_name, entity, event)
        end

        do_spawn_entity(entity_name, entity, event)
    end
)

Event.add(
    defines.events.on_player_died,
    function(event)
        local player = game.get_player(event.player_index)
        set_timeout_in_ticks(1, spawn_player, player)
    end
)

Event.add(
    defines.events.on_combat_robot_expired,
    function(event)

        local entity = event.robot
        local position = entity.position
        if entity.force.name == 'enemy' then
            entity.surface.create_entity{name = "cluster-grenade", position=position, target=position, speed=1}
        end

    end
)

Event.add(
    defines.events.on_entity_damaged,
    function(event)
        if not event.entity then return end
        if not event.entity.valid then return end
        if event.entity.type ~= 'spider-leg' then return end
        local leg = event.entity
        local torsos = event.entity.surface.find_entities_filtered{
          position = leg.position,
          radius = 10,
          type = 'spider-vehicle'
        }
        local unit_number = nil
        for _, torso in pairs(torsos) do
          unit_number = tostring(torso.unit_number)
          if global.damageable_spider_leg[unit_number] then
            for _, entity in pairs(global.damageable_spider_leg[unit_number]) do
              if entity == leg then
                leg.health = leg.prototype.max_health
                local damage = event.original_damage_amount * damage_modifier
                -- If there is a resistance reduction value, modify it and then add it to the damage again.
                if torso.prototype.resistances then
                  if torso.prototype.resistances[event.damage_type.name] then
                    damage = damage + torso.prototype.resistances[event.damage_type.name].decrease * (1 - damage_modifier)
                    if damage > event.original_damage_amount then
                      damage = event.original_damage_amount
                    end
                  end
                end
                if event.cause and event.cause.valid then
                  torso.damage(
                    damage,
                    event.force,
                    event.damage_type.name,
                    event.cause
                  )
                else
                  torso.damage(
                    damage,
                    event.force,
                    event.damage_type.name
                  )
                end
                return
              end
            end
          end
        end
    end
)

Event.add(
    defines.events.on_entity_destroyed,
    function(event)
        if debugging then
            local check = nil
            if global.damageable_spider_leg[tostring(event.unit_number)] then check = event.unit_number end
            game.print{"",'removed ',check}
          end
          global.damageable_spider_leg[tostring(event.unit_number)] = nil
    end
)

Event.add(
    defines.events.on_robot_built_entity,
    function(event)
    register_spider(event.created_entity)
  end
)

Event.add(
    defines.events.on_built_entity,
    function(event)
    register_spider(event.created_entity)
  end
)

Event.add(
    defines.events.on_entity_cloned,
    function(event)
    register_spider(event.destination)
  end
)