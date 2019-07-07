local Event = require 'utils.event'
local Color = require 'resources.color_presets'
local Item_to_chest = require 'map_gen.maps.quadrants.item_to_chest'
local Settings = require 'map_gen.maps.quadrants.settings'
local pow = math.pow

local rail_locations = {24, 32, 192, 224}

--192 to 224
--32 to 24

local function clear_inventory_train(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if (not player.driving and event.trigger == nil) or (player.driving and event.trigger) then
        return false
    end
    if not(Settings.features.train_crossings.enabled) then
        return true
    end
    local pos = player.position
    local force = player.force

    local within_range = false
    local rail_location
    if string.find(force.name, 'quadrant') then
        if (force.name == 'quadrant1') then
            within_range = (pos.x >= 0 and pos.y <= 0)
            rail_location = {
                {{x = rail_locations[3], y = -rail_locations[2]}, {x = rail_locations[4], y = -rail_locations[1]}},
                {{x = rail_locations[1], y = -rail_locations[3]}, {x = rail_locations[2], y = -rail_locations[4]}},
                {{x = rail_locations[1], y = -rail_locations[1]}, {x = rail_locations[4], y = -rail_locations[4]}},
                'Quadrant #1'
            }
        elseif (force.name == 'quadrant2') then
            within_range = (pos.x <= 0 and pos.y <= 0)
            rail_location = {
                {{x = -rail_locations[3], y = -rail_locations[2]}, {x = -rail_locations[4], y = -rail_locations[1]}},
                {{x = -rail_locations[1], y = -rail_locations[3]}, {x = -rail_locations[2], y = -rail_locations[4]}},
                {{x = -rail_locations[1], y = -rail_locations[1]}, {x = -rail_locations[4], y = -rail_locations[4]}},
                'Quadrant #2'
            }
        elseif (force.name == 'quadrant3') then
            within_range = (pos.x <= 0 and pos.y >= 0)
            rail_location = {
                {{x = -rail_locations[3], y = rail_locations[2]}, {x = -rail_locations[4], y = rail_locations[1]}},
                {{x = -rail_locations[1], y = rail_locations[3]}, {x = -rail_locations[2], y = rail_locations[4]}},
                {{x = -rail_locations[1], y = rail_locations[1]}, {x = -rail_locations[4], y = rail_locations[4]}},
                'Quadrant #3'
            }
        elseif (force.name == 'quadrant4') then
            within_range = (pos.x >= 0 and pos.y >= 0)
            rail_location = {
                {{x = rail_locations[3], y = rail_locations[2]}, {x = rail_locations[4], y = rail_locations[1]}},
                {{x = rail_locations[1], y = rail_locations[3]}, {x = rail_locations[2], y = rail_locations[4]}},
                {{x = rail_locations[1], y = rail_locations[1]}, {x = rail_locations[4], y = rail_locations[4]}},
                'Quadrant #4'
            }
        end
    end

    if within_range then
        return false
    end
    player.clean_cursor()
    if
        player.get_inventory(defines.inventory.character_main).is_empty() and
            player.get_inventory(defines.inventory.character_trash).is_empty()
     then
        return true
    end

    local distance1 = pow(pow(rail_location[1][1].x - pos.x, 2) + pow(rail_location[1][1].y - pos.y, 2), 0.5)
    local distance2 = pow(pow(rail_location[2][1].x - pos.x, 2) + pow(rail_location[2][1].y - pos.y, 2), 0.5)

    local function wrap_transfer(bounding_box, radius)
        return Item_to_chest.transfer_inventory(
            player_index,
            {defines.inventory.character_main, defines.inventory.character_trash},
            nil,
            radius,
            bounding_box
        )
    end

    local success
    if distance1 <= distance2 then
        success = wrap_transfer(rail_location[1]) or wrap_transfer(rail_location[2])
    else
        success = wrap_transfer(rail_location[2]) or wrap_transfer(rail_location[1])
    end

    if not success then
        success = wrap_transfer(rail_location[3]) or wrap_transfer(nil, 0)
    end

    player.print({"", {'quadrants.train_notice1', rail_location[4]}, " [gps=" .. success.x .. ', ' .. success.y .. "]"}, Color.red)
    return success
end

local function clear_inventory(event)
    event.trigger = true
    if not clear_inventory_train(event) then
        return
    end
    local player = game.get_player(event.player_index)
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
