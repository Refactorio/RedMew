local Event = require 'utils.event'
local Global = require 'utils.global'
local Toast = require 'features.gui.toast'
local Retailer = require 'features.retailer'
local Token = require 'utils.token'

local tank_entities = {}
local tank_research = {interval_level = 1}

Global.register({tank_entities = tank_entities, tank_research = tank_research}, function(tbl)
    tank_entities = tbl.tank_entities
    tank_research = tbl.tank_research
end)

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

local on_tick = Token.register(function()
    for _, tank in pairs(tank_entities) do
        if not tank.valid or not tank.get_driver() then -- only allow tanks to fire rockets when the tank has a driver
            goto continue
        end

        local inv = tank.get_inventory(defines.inventory.car_trunk)
        local rocket_count = inv.get_item_count("rocket")
        if rocket_count <= 0 then
            goto continue
        end

        local surface = tank.surface
        local targets = surface.find_entities_filtered {
            position = tank.position,
            radius = 30,
            force = "enemy",
            name = static_entities_to_check,
            limit = 1
        }

        local target = targets[1]
        if target then
            surface.create_entity {name = "rocket", position = tank.position, target = target, speed = 0.2}
            inv.remove({name = "rocket", count = 1})
        end

        ::continue::
    end
end)

Event.add(Retailer.events.on_market_purchase, function(event)
    local market_id = event.group_name
    local group_label = Retailer.get_market_group_label(market_id)
    if group_label ~= 'Spawn' then
        return
    end

    local item = event.item
    if item.type ~= 'rocket_tanks' or item.name ~= 'rocket_tanks_fire_rate' then
        return
    end

    local interval_level = tank_research.interval_level
    local max_level = 5
    if interval_level < max_level then
        tank_research.interval_level = tank_research.interval_level + 1

        Toast.toast_all_players(15, {'command_description.crash_site_rocket_tank_upgrade_success', interval_level})
        item.name_label = {'command_description.crash_site_rocket_tanks_name_label', (interval_level + 1)}
        item.price = (interval_level + 1) * 1000
        Retailer.set_item(market_id, item) -- this updates the retailer with the new item values.
    end
    if interval_level >= 4 then -- update label, set price to 0, disable further purchases
        item.price = 0
        item.name_label = {'command_description.crash_site_rocket_tanks_name_label', {'command_description.max_level'}}
        item.disabled = true
        item.disabled_reason = {'command_description.max_level'}
        Retailer.set_item(market_id, item)
    end

    -- Interval for each level should decrease 30 from 120 ticks each level. 120, 90, 60, 30.
    if interval_level > 2 then
        Event.remove_removable_nth_tick((120-(((interval_level-1)-2)*30)), on_tick)
    end
    Event.add_removable_nth_tick((120-((interval_level-2)*30)), on_tick)
end)
