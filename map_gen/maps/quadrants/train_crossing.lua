local Event = require 'utils.event'
local Game = require 'utils.game'
local Item_to_chest = require 'map_gen.maps.quadrants.item_to_chest'
local pow = math.pow

local rail_locations = {26, 208}

local function clear_inventory_train(event)
    local player = Game.get_player_by_index(event.player_index)
    if (not player.driving and event.trigger == nil) or (player.driving and event.trigger) then
        return false
    end
    local pos = player.position
    local force = player.force

    local within_range = false
    local rail_location
    if string.find(force.name, 'quadrant') then
        if (force.name == 'quadrant1') then
            within_range = (pos.x >= 0 and pos.y <= 0)
            rail_location = {
                {x = rail_locations[1], y = -rail_locations[2]},
                {x = rail_locations[2], y = -rail_locations[1]}
            }
        elseif (force.name == 'quadrant2') then
            within_range = (pos.x <= 0 and pos.y <= 0)
            rail_location = {
                {x = -rail_locations[1], y = -rail_locations[2]},
                {x = -rail_locations[2], y = -rail_locations[1]}
            }
        elseif (force.name == 'quadrant3') then
            within_range = (pos.x <= 0 and pos.y >= 0)
            rail_location = {
                {x = -rail_locations[1], y = rail_locations[2]},
                {x = -rail_locations[2], y = rail_locations[1]}
            }
        elseif (force.name == 'quadrant4') then
            within_range = (pos.x >= 0 and pos.y >= 0)
            rail_location = {
                {x = rail_locations[1], y = rail_locations[2]},
                {x = rail_locations[2], y = rail_locations[1]}
            }
        end
    end

    if within_range then
        return false
    end
    player.clean_cursor()
    if
        player.get_inventory(defines.inventory.player_main).is_empty() and
            player.get_inventory(defines.inventory.player_trash).is_empty()
     then
        return true
    end

    local distance1 = pow(pow(rail_location[1].x - pos.x, 2) + pow(rail_location[1].y - pos.y, 2), 0.5)
    local distance2 = pow(pow(rail_location[2].x - pos.x, 2) + pow(rail_location[2].y - pos.y, 2), 0.5)
    if distance1 <= distance2 then
        Item_to_chest.transfer_inventory(
            event.player_index,
            {defines.inventory.player_main, defines.inventory.player_trash},
            rail_location[1]
        )
    else
        Item_to_chest.transfer_inventory(
            event.player_index,
            {defines.inventory.player_main, defines.inventory.player_trash},
            rail_location[2]
        )
    end
    return true
end

local function clear_inventory(event)
    event.trigger = true
    if not clear_inventory_train(event) then
        return
    end
    local player = Game.get_player_by_index(event.player_index)
    local pos = player.position
    local quadrant
    if (pos.x >= 0 and pos.y <= 0) then
        quadrant = 1
    elseif (pos.x <= 0 and pos.y <= 0) then
        quadrant = 2
    elseif (pos.x <= 0 and pos.y >= 0) then
        quadrant = 3
    elseif (pos.x >= 0 and pos.y >= 0) then
        quadrant = 4
    end

    player.force = game.forces['quadrant' .. quadrant]
end

Event.add(defines.events.on_player_driving_changed_state, clear_inventory)
Event.add(defines.events.on_player_dropped_item, clear_inventory_train)
Event.add(defines.events.on_player_fast_transferred, clear_inventory_train)
Event.add(defines.events.on_gui_opened, clear_inventory_train)
