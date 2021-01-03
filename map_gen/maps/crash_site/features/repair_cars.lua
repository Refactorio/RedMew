local Event = require 'utils.event'
local Global = require 'utils.global'

local car_entities = {}

Global.register({car_entities = car_entities}, function(tbl)
    car_entities = tbl.car_entities
end)

local function register_car(entity)
    if not entity then
        return
    end
    if not entity.valid then
        return
    end
    if entity.name ~= 'car' then
        return
    end
    car_entities[entity.unit_number] = entity
    script.register_on_entity_destroyed(entity)
end

Event.add(defines.events.on_entity_destroyed, function(event)
    car_entities[event.unit_number] = nil
end)

Event.add(defines.events.on_robot_built_entity, function(event)
    register_car(event.created_entity)
end)

Event.add(defines.events.on_built_entity, function(event)
    register_car(event.created_entity)
end)

Event.add(defines.events.on_entity_cloned, function(event)
    register_car(event.destination)
end)

local turrets = {
    ['gun-turret'] = true,
    ['laser-turret'] = true,
    ['flamethrower-turret'] = true,
    ['artillery-turret'] = true
}

local function on_nth_tick()
    for _, car in pairs(car_entities) do
        if not car.valid or not car.get_driver() or car.speed ~= 0 then -- only allow cars to repair if they have a driver and are not moving
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
                -- Rules for when car can repair:
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
