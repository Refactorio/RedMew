local RS = require 'map_gen.shared.redmew_surface'
local Event = require 'utils.event'

local Public = {}

local function create_chest(player, position, radius, bounding_box)
    local surface = RS.get_surface()
    position = position ~= nil and position or player.position

    local pos
    if radius then
        pos = surface.find_non_colliding_position('steel-chest', position, radius, 1)
    elseif bounding_box then
        pos = surface.find_non_colliding_position_in_box('steel-chest', bounding_box, 1)
    end

    if pos ~= nil then
        local chest = surface.create_entity {name = 'steel-chest', position = pos, force = player.force}
        chest.minable = false
        return chest
    end

    return false
end

function Public.transfer_inventory(player_index, inventories, position, radius, bounding_box)
    if inventories == nil or player_index == nil then
        return 'You need to specify a player index and a table of define.inventory'
    end
    local player = game.get_player(player_index)
    player.clean_cursor()
    while player.crafting_queue_size ~= 0 do
        player.cancel_crafting(player.crafting_queue[1])
    end

    local chest
    for _, inventory in pairs(inventories) do
        inventory = player.get_inventory(inventory)
        for name, count in pairs(inventory.get_contents()) do
            local ItemStack = {name = name, count = count}
            inventory.remove(ItemStack)
            while count > 0 do
                if not chest or not chest.can_insert(ItemStack) then
                    chest = create_chest(player, position, radius, bounding_box)
                    if not chest then
                        return false
                    end
                end
                count = count - chest.insert(ItemStack)
                ItemStack = {name = name, count = count}
            end
        end
    end
    if not chest then
        return false
    end
    return chest.position
end

local function on_gui_closed(event)
    local entity = event.entity
    if entity == nil or not entity.valid then
        return
    end
    if entity.name == 'steel-chest' and entity.minable == false and not entity.has_items_inside() then
        entity.destroy()
    end
end

local function ctrl_empty(event)
    local entity = event.last_entity
    if entity == nil or not entity.valid then
        return
    end
    if entity.name == 'steel-chest' and not entity.minable then
        event.entity = entity
        on_gui_closed(event)
    end
end

Event.add(defines.events.on_gui_closed, on_gui_closed)
Event.add(defines.events.on_selected_entity_changed, ctrl_empty)
Event.add(defines.events.on_pre_player_mined_item)

return Public
