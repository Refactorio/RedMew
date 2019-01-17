local Event = require 'utils.event'
local Utils = require 'utils.core'
local Game = require 'utils.game'
local RS = require 'map_gen.shared.redmew_surface'

global.original_last_users_by_ent_pos = {}

Event.on_init(
    function()
        global.ag_surface = game.create_surface('antigrief', {autoplace_controls = {coal = {frequency = 'normal', richness = 'normal', size = 'none'}, ['copper-ore'] = {frequency = 'normal', richness = 'normal', size = 'none'}, ['crude-oil'] = {frequency = 'normal', richness = 'normal', size = 'none'}, desert = {frequency = 'normal', richness = 'normal', size = 'none'}, dirt = {frequency = 'normal', richness = 'normal', size = 'none'}, ['enemy-base'] = {frequency = 'normal', richness = 'normal', size = 'none'}, grass = {frequency = 'normal', richness = 'normal', size = 'none'}, ['iron-ore'] = {frequency = 'normal', richness = 'normal', size = 'none'}, sand = {frequency = 'normal', richness = 'normal', size = 'none'}, stone = {frequency = 'normal', richness = 'normal', size = 'none'}, trees = {frequency = 'normal', richness = 'normal', size = 'none'}, ['uranium-ore'] = {frequency = 'normal', richness = 'normal', size = 'none'}}, cliff_settings = {cliff_elevation_0 = 1024, cliff_elevation_interval = 10, name = 'cliff'}, height = 2000000, peaceful_mode = false, seed = 3461559752, starting_area = 'very-low', starting_points = {{x = 0, y = 0}}, terrain_segmentation = 'normal', water = 'normal', width = 2000000})
        global.ag_surface.always_day = true
    end
)

local function is_mocked(entity)
    return rawget(entity, 'mock')
end

local function place_entity_on_surface(entity, surface, replace, player)
    local new_entity = nil
    for _, e in ipairs(surface.find_entities_filtered {position = entity.position}) do
        if replace or e.type == 'entity-ghost' then
            e.destroy()
        end
    end
    local entities_to_be_replaced = surface.find_entities_filtered {position = entity.position}
    if (replace or #entities_to_be_replaced == 0 or entities_to_be_replaced[1].type == entity.type) then
        new_entity = surface.create_entity {name = entity.name, position = entity.position, force = entity.force, direction = entity.direction}
        if new_entity then
            if not is_mocked(entity) then
                new_entity.copy_settings(entity)
            end
            if player then
                new_entity.last_user = player
            end
        end
    end
    return new_entity
end

Event.add(
    defines.events.on_chunk_generated,
    function(event)
        if event.surface.name == 'antigrief' then
            local tiles = {}
            for x = event.area.left_top.x, event.area.right_bottom.x - 1 do
                for y = event.area.left_top.y, event.area.right_bottom.y - 1 do
                    table.insert(tiles, {name = 'lab-dark-2', position = {x, y}})
                end
            end
            event.surface.set_tiles(tiles)
        end
    end
)

local function get_position_str(pos)
    return string.format('%d|%d', pos.x, pos.y)
end

local function on_entity_changed(event)
    local entity = event.entity or event.destination
    local player = Game.get_player_by_index(event.player_index)
    if player.admin or not entity.valid then
        return
    end --Freebees for admins
    if entity.last_user ~= player and entity.force == player.force then --commented out to be able to debug
        place_entity_on_surface(entity, global.ag_surface, true, event.player_index)
    end
    if entity.last_user then
        global.original_last_users_by_ent_pos[get_position_str(entity.position)] = entity.last_user.index
    end
end

Event.add(
    defines.events.on_robot_pre_mined,
    function(event)
        --The bot isnt the culprit! The last user is! They marked it for deconstruction!
        if event.entity.valid and event.entity.last_user then
            event.player_index = event.entity.last_user.index
            on_entity_changed(event)
        end
    end
)

local function get_pre_rotate_direction(entity)
    --Some entities have 8 rotation steps and some have 4. So a mathmatical reverse is not possible
    entity.rotate {reverse = true}
    local direction = entity.direction
    entity.rotate()
    return direction
end

Event.add(
    defines.events.on_player_rotated_entity,
    function(event)
        local entity = event.entity

        if not entity.valid then
            return
        end

        local ag_entities = global.ag_surface.find_entities_filtered {position = entity.position}
        --If a player has rotated twice we want to preserve the original state.
        if #ag_entities == 0 or not ag_entities[1].last_user or ag_entities[1].last_user ~= entity.last_user then
            --Mock entity us used because the api doesnt support pre_player_rotated entity.
            --The mocked entity has the entity state before rotation
            --We also dont know who rotated it and dont want the griefers name there so we set it to 1
            local mock_entity = {
                name = entity.name,
                position = entity.position,
                mock = true,
                last_user = Game.get_player_by_index(1),
                force = entity.force,
                direction = get_pre_rotate_direction(entity)
            }
            event.entity = mock_entity
            on_entity_changed(event)
        end
    end
)
Event.add(defines.events.on_pre_entity_settings_pasted, on_entity_changed)

Event.add(
    defines.events.on_entity_died,
    function(event)
        --is a player on the same force as the destroyed object
        if event.entity and event.entity.valid and event.entity.force.name == 'player' and event.cause and event.cause.force == event.entity.force and event.cause.type == 'player' then
            local new_entity = place_entity_on_surface(event.entity, global.ag_surface, true, event.cause.player)
            if new_entity and event.entity.type == 'container' then
                local items = event.entity.get_inventory(defines.inventory.chest).get_contents()
                if items then
                    for item, n in pairs(items) do
                        new_entity.insert {name = item, count = n}
                    end
                end
            end
        end
    end
)

Event.add(defines.events.on_player_mined_entity, on_entity_changed)

Event.add(
    defines.events.on_marked_for_deconstruction,
    function(event)
        if event.entity.last_user then
            global.original_last_users_by_ent_pos[get_position_str(event.entity.position)] = event.entity.last_user.index
        end
    end
)

local Module = {}

Module.undo =
    function(player)
    if type(player) == 'nil' or type(player) == 'string' then
        return --No support for strings!
    elseif type(player) == 'number' then
        player = Game.get_player_by_index(player)
    end

    --Remove all items from all surfaces that player placed an entity on
    for _, surface in pairs(game.surfaces) do
        if surface ~= global.ag_surface then
            for _, e in ipairs(surface.find_entities_filtered {force = player.force.name}) do
                if e.last_user == player then
                    e.destroy()
                end
            end
        end
    end

    for _, e in ipairs(global.ag_surface.find_entities_filtered {}) do
        if e.last_user == player then
            --Place removed entity IF no collision is detected
            local last_user = global.original_last_users_by_ent_pos[get_position_str(e.position)]
            local new_entity = place_entity_on_surface(e, RS.get_surface(), false, last_user)
            --Transfer items
            if new_entity then
                local event_player = Utils.ternary(new_entity.last_user, new_entity.last_user, game.player)
                local event = {created_entity = new_entity, player_index = event_player.index, stack = {}}
                script.raise_event(defines.events.on_built_entity, event)

                if e.type == 'container' then
                    local items = e.get_inventory(defines.inventory.chest).get_contents()
                    if items then
                        for item, n in pairs(items) do
                            new_entity.insert {name = item, count = n}
                        end
                    end
                end
                e.destroy() --destory entity only if a new entity was created
            end
        end
    end
end

Module.antigrief_surface_tp = function()
    if game.player then
        if game.player.surface == global.ag_surface then
            game.player.teleport(game.player.position, RS.get_surface())
        else
            game.player.teleport(game.player.position, global.ag_surface)
        end
    end
end

Module.count_removed_entities = function(player)
    return #Utils.find_entities_by_last_user(player, global.ag_surface)
end

return Module
