local Event = require 'utils.event'
local Global = require 'utils.global'
local math = require 'utils.math'
local Token = require 'utils.token'
local Task = require 'utils.task'

local floor = math.floor
local max = math.max

local chest = defines.inventory.chest
local stun_sticker_duration = 3 -- seconds

local died_entities = {}

Global.register(
    died_entities,
    function(tbl)
        died_entities = tbl
    end
)

local Public = {}

local cause_by_type = {
    ['character'] = function(cause)
        return cause.player
    end,
    ['car'] = function(cause)
        local d = cause.get_driver()
        if d then
            return (d.object_name == 'LuaEntity') and d.player or d
        else
            return cause.last_user
        end
    end,
    ['spider-vehicle'] = function(cause)
        local d = cause.get_driver()
        if d then
            return (d.object_name == 'LuaEntity') and d.player or d
        else
            return cause.last_user
        end
    end,
    ['land-mine'] = function(cause)
        return cause.last_user
    end,
}

local stun_player_callback
stun_player_callback = Token.register(function(data)
    local entity = data.entity
    if not entity.valid then
        return
    end

    local time_to_live = data.time_to_live
    if time_to_live <= 0 then
        return
    end

    data.time_to_live = time_to_live - stun_sticker_duration
    entity.surface.create_entity {
        name = 'stun-sticker',
        target = entity,
        position = entity.position,
    }
    Task.set_timeout(stun_sticker_duration, stun_player_callback, data)
end)

---@param config table
---@field entity_name? string, resource to be spawned (default: coal)
---@field time_penalty? number, time lost by the player when misbehaving (default: 18s, 0 to apply none)
---@field spare_vehicle? boolean, saves the involved vehicle, if any (default: false)
Public.register = function(config)
    local entity_name = config.entity_name or 'coal'
    local time_penalty = config.time_penalty or 18
    local spare_vehicle = config.spare_vehicle or false

    Event.add(defines.events.on_entity_died, function(event)
        local entity = event.entity

        if not entity.valid then
            return
        end

        local type = entity.type
        if type ~= 'container' and type ~= 'logistic-container' then
            return
        end

        local inventory = entity.get_inventory(chest)
        if not inventory or not inventory.valid then
            return
        end

        local count = 0
        local deadlock_stack_size = (settings.startup['deadlock-stack-size'] or {}).value or 1
        local contents = inventory.get_contents()
        for _, item_stack in pairs(contents) do
            local real_count
            if item_stack.name:sub(1, #'deadlock-stack') == 'deadlock-stack' then
                real_count = item_stack.count * deadlock_stack_size
            else
                real_count = item_stack.count
            end

            count = count + real_count
        end

        if count == 0 then
            return
        end

        local area = entity.bounding_box
        local left_top, right_bottom = area.left_top, area.right_bottom
        local x1, y1 = floor(left_top.x), floor(left_top.y)
        local x2, y2 = floor(right_bottom.x), floor(right_bottom.y)

        local size_x = x2 - x1 + 1
        local size_y = y2 - y1 + 1
        local amount = floor(count / (size_x * size_y))
        amount = max(amount, 1)

        local create_entity = entity.surface.create_entity

        for x = x1, x2 do
            for y = y1, y2 do
                create_entity({name = entity_name, position = {x, y}, amount = amount})
            end
        end

        died_entities[entity.unit_number] = true

        local cause = event.cause
        if not (cause and cause.valid and cause.force and cause.force.name == 'player') then
            return
        end

        local handler = cause_by_type[cause.type]
        local actor = handler and handler(cause)
        if not (actor and actor.valid) then
            return
        end

        local character = actor.character
        if not (character and character.valid) then
            return
        end

        actor.print('The ore fights back!', { color = { 255, 128, 0 } })
        Task.set_timeout_in_ticks(1, stun_player_callback, {
            entity = character,
            time_to_live = time_penalty,
        })

        if (not spare_vehicle) and (cause.type == 'car' or cause.type == 'spider-vehicle') then
            cause.die('neutral')
        end
    end)

    Event.add(defines.events.on_post_entity_died, function(event)
        local unit_number = event.unit_number
        if not unit_number then
            return
        end

        if not died_entities[unit_number] then
            return
        end

        died_entities[unit_number] = nil

        local ghost = event.ghost
        if not ghost or not ghost.valid then
            return
        end

        ghost.destroy()
    end)
end

return Public
