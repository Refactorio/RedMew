local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'

local config = require 'config'
turret_types = config.turret_active_delay.turret_types

local tau = 2 * math.pi
local start_angle = -tau / 4
local update_rate = 4 -- ticks between updates
local time_to_live = update_rate + 1

local draw_arc = rendering.draw_arc
local set_timeout_in_ticks = Task.set_timeout_in_ticks

local entity_built_callback
entity_built_callback =
    Token.register(
    function(data)
        local entity = data.entity

        if not entity.valid then
            return
        end

        if entity.health == 0 then
            entity.active = true
            entity.die('enemy')
            return
        end

        local tick = data.tick
        local now = game.tick
        if now >= tick then
            entity.active = true
            return
        end

        local fraction = ((now - tick) / data.delay) + 1

        draw_arc(
            {
                color = {1 - fraction, fraction, 0},
                max_radius = 0.5,
                min_radius = 0.4,
                start_angle = start_angle,
                angle = fraction * tau,
                target = entity,
                surface = entity.surface,
                time_to_live = time_to_live
            }
        )

        set_timeout_in_ticks(update_rate, entity_built_callback, data)
    end
)

local function entity_built(event)
    local entity = event.created_entity

    if not entity.valid then
        return
    end

    local delay = turret_types[entity.type]
    if not delay then
        return
    end

    entity.active = false
    set_timeout_in_ticks(
        update_rate,
        entity_built_callback,
        {entity = entity, tick = event.tick + delay, delay = delay}
    )
end

Event.add(defines.events.on_built_entity, entity_built)
Event.add(defines.events.on_robot_built_entity, entity_built)
