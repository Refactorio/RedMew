local Event = require 'utils.event'
local Global = require 'utils.global'
local Toast = require 'features.gui.toast'
local Retailer = require 'features.retailer'
local Token = require 'utils.token'

local tank_entities = {}
local tank_research = {interval_level = 1}

Global.register(
    {tank_entities = tank_entities,
    tank_research = tank_research},
    function(tbl)
        tank_entities = tbl.tank_entities
        tank_research = tbl.tank_research
    end
)

local function register_tank(entity)
    if not entity then
        return
    end
    if not entity.valid then
        return
    end
    if entity.name ~= 'tank' then
        return
    end
    tank_entities[entity.unit_number] = entity
    script.register_on_entity_destroyed(entity)
end

Event.add(defines.events.on_entity_destroyed, function(event)
    tank_entities[event.unit_number] = nil
end)

Event.add(defines.events.on_robot_built_entity, function(event)
    register_tank(event.created_entity)
end)

Event.add(defines.events.on_built_entity, function(event)
    register_tank(event.created_entity)
end)

Event.add(defines.events.on_entity_cloned, function(event)
    register_tank(event.destination)
end)

local static_entities_to_check = {
    'spitter-spawner',
    'biter-spawner',
    'small-worm-turret',
    'medium-worm-turret',
    'big-worm-turret',
    'behemoth-worm-turret'
}
--[[local function on_tick()
    for k, v in pairs(tank_entities) do
        local unit_number = k
        local tank = v
        local s = game.surfaces["redmew"]
        if tank.get_driver() then   -- only allow tanks to fire rockets when the tank has a driver
            local inv = tank.get_inventory(defines.inventory.car_trunk)
            local rocket_count = inv.get_item_count("rocket")
            if rocket_count > 0 then
                local target = s.find_entities_filtered {
                    position = tank.position,
                    radius = 30,
                    force = "enemy",
                    name = static_entities_to_check,
                    limit = 1
                }
                if target[1] then
                    s.create_entity {name = "rocket", position = tank.position, target = target[1], speed = 0.2}
                    inv.remove({name = "rocket", count = 1})
                end
            end
        end
    end
end]]
local on_tick
on_tick = Token.register(
    function()
    for k, v in pairs(tank_entities) do
        local unit_number = k
        local tank = v
        local s = game.surfaces["redmew"]
        if tank.get_driver() then   -- only allow tanks to fire rockets when the tank has a driver
            local inv = tank.get_inventory(defines.inventory.car_trunk)
            local rocket_count = inv.get_item_count("rocket")
            if rocket_count > 0 then
                local target = s.find_entities_filtered {
                    position = tank.position,
                    radius = 30,
                    force = "enemy",
                    name = static_entities_to_check,
                    limit = 1
                }
                if target[1] then
                    s.create_entity {name = "rocket", position = tank.position, target = target[1], speed = 0.2}
                    inv.remove({name = "rocket", count = 1})
                end
            end
        end
    end
end
)

local rocket_tank_level_intervals = {
    [2] = 180,
    [3] = 120,
    [4] = 60,
    [5] = 30 
}

--Event.on_nth_tick(180, on_tick)
--Event.on_nth_tick(rocket_tank_level_intervals[tank_research.interval_level], on_tick)

Event.add(Retailer.events.on_market_purchase, function(event)

    local market_id = event.group_name
    local group_label = Retailer.get_market_group_label(market_id)
    if group_label ~= 'Spawn' then
        return
    end

    local item = event.item
    if item.type ~= 'rocket_tanks' then
        return
    end

    local interval_level = tank_research.interval_level
    local name = item.name
    local max_level = 5
    if  (name == 'rocket_tanks_fire_rate') and (interval_level < max_level) then
        tank_research.interval_level = tank_research.interval_level + 1

        Toast.toast_all_players(15, {'command_description.crash_site_rocket_tank_upgrade_success', interval_level})
        item.name_label = {'command_description.crash_site_rocket_tanks_name_label', (interval_level + 1)}
        item.price = (interval_level+1)*7500
        item.description = 'Upgrade the tank rocket firing rate to reduce the rocket interval.\n\nPlace rockets in the tank inventory to have them automatically target enemy worms and nests.'
        Retailer.set_item(market_id, item) -- this updates the retailer with the new item values.
    end
    if interval_level == 5 then
        -- This doesn't work....
        Retailer.remove_item('Spawn', 'rocket_tanks_fire_rate')
    end
    if interval_level > 2 then
        Event.remove_removable_nth_tick(rocket_tank_level_intervals[tank_research.interval_level-1], on_tick)
    end
    Event.add_removable_nth_tick(rocket_tank_level_intervals[tank_research.interval_level], on_tick)

end)
