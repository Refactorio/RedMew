-- This module allows cars and tanks (any vehicle of type == car) to repair friendly structures
local Event = require 'utils.event'
local Global = require 'utils.global'

local car_entities = {}

Global.register({car_entities = car_entities}, function(tbl)
    car_entities = tbl.car_entities
end)

Event.add(defines.events.on_entity_destroyed, function(event)
    car_entities[event.unit_number] = nil
end)

Event.add(defines.events.on_player_driving_changed_state, function(event)
    local entity = event.entity
    if (entity.type ~= 'car') or not entity or not entity.valid then
        return
    end
    if not entity.get_driver() then -- no driver? Remove that car from the table to check
        car_entities[entity.unit_number] = nil
    else
        local player = game.get_player(event.player_index)
        local driver = entity.get_driver()
        if player ~= driver.player then -- if the player that got in the vehicle is not the driver then return
            return
        else
            car_entities[entity.unit_number] = entity
            script.register_on_entity_destroyed(entity)
        end
    end
end)

local turrets = {
    ['gun-turret'] = true,
    ['laser-turret'] = true,
    ['flamethrower-turret'] = true,
    ['artillery-turret'] = true
}

local function on_nth_tick()
    for _, car in pairs(car_entities) do
        if not car.valid or car.speed ~= 0 then -- only allow cars to repair if they have a driver and are not moving
            goto continue
        end

        local inv = car.get_inventory(defines.inventory.car_trunk)
        local stack = inv.find_item_stack('repair-pack')
        if not stack then
            goto continue
        end

        -- Search for damaged entities and heal them
        local surface = car.surface
        local targets = surface.find_entities_filtered {position = car.position, radius = 20, force = "player"}

        local repair_amount = 150
        for i, entity in pairs(targets) do
            if entity.unit_number and (entity.get_health_ratio() or 1) < 1 then
                -- Rules for when cars/tanks can repair:
                -- if the damaged entity is a turret, the turret cooldown must be complete (entity.active == true) to help reduce turret creeping
                -- if the damaged entity is not the car. Cars can heal other cars but not themselves.
                -- if the damaged entity is not a character
                -- if the entity is not moving. Vehicles must have a speed of 0, entities that can't move will be nil
                if (entity ~= car and (entity.speed == 0 or entity.speed == nil) and entity.name ~= 'character' and not turrets[entity.name]) or (turrets[entity.name] and entity.active == true) then
                    surface.create_entity {
                        name = "electric-beam",
                        position = car.position,
                        source = car.position,
                        target = entity.position, -- use the position not the entity otherwise it will damage the entity
                        speed = 1,
                        duration = 20
                    }
                    local max_health = entity.prototype.max_health
                    if (max_health - entity.health) < repair_amount then
                        repair_amount = max_health - entity.health -- so that the player doesn't lose part of a repair pack partially healing an entity
                    end
                    entity.health = entity.health + repair_amount
                    stack.drain_durability(repair_amount)
                    goto continue -- break out because we only want to heal one entity
                end
            end
        end

        ::continue::
    end
end

Event.on_nth_tick(60, on_nth_tick)
