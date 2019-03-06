local RS = require 'map_gen.shared.redmew_surface'
local Game = require 'utils.game'
local Event = require 'utils.event'

local Public = {}

local function create_chest(player, position)
    local surface = RS.get_surface()
    position = position ~= nil and position or player.position
    local pos = surface.find_non_colliding_position('steel-chest', position, 0, 1)
    local chest = surface.create_entity { name = 'steel-chest', position = pos, force = player.force }
    chest.minable = false
    return chest
end

function Public.transfer_inventory(player_index, inventories, position)
    if inventories == nil or player_index == nil then
        return 'You need to specify a player index and a table of define.inventory'
    end
    local player = Game.get_player_by_index(player_index)
    local chest = create_chest(player, position)
    for _, inventory in pairs(inventories) do
        inventory = player.get_inventory(inventory)
        for name, count in pairs(inventory.get_contents()) do
            local ItemStack = { name = name, count = count }
            inventory.remove(ItemStack)
            while count > 0 do
                if not chest.can_insert(ItemStack) then
                    chest = create_chest(player)
                end
                count = count - chest.insert(ItemStack)
                ItemStack = { name = name, count = count }
            end
        end
    end
    return true
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
