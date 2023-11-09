local Event = require 'utils.event'

return function(config)
    local refund_tile = config.refund_tile or 'refined-concrete'
    local replace_tile = config.tile or 'blue-refined-concrete'

    local replace_tiles = {['landfill'] = true, [replace_tile] = true}
    local brush_tools = {[refund_tile] = true} -- , ['refined-hazard-concrete'] = true}

    local character_main = defines.inventory.character_main
    local robot_cargo = defines.inventory.robot_cargo

    local function refund_tiles(surface, inventory, tiles)
        local refund_count = 0
        for i = 1, #tiles do
            local tile = tiles[i]
            local old_name = tile.old_tile.name

            if replace_tiles[old_name] then
                surface.set_hidden_tile(tile.position, 'landfill')
            end

            if old_name == replace_tile then
                refund_count = refund_count + 1
            end
        end

        if inventory and inventory.valid and refund_count > 0 then
            inventory.insert {name = refund_tile, count = refund_count}
        end
    end

    local function change_tiles(surface, inventory, tiles)
        local new_tiles = {}
        local refund_count = 0
        for i = 1, #tiles do
            local tile = tiles[i]
            local position = tile.position
            local old_name = tile.old_tile.name

            if replace_tiles[old_name] or replace_tiles[surface.get_hidden_tile(position)] then
                new_tiles[#new_tiles + 1] = {name = replace_tile, position = position}
                surface.set_hidden_tile(position, 'landfill')
            end

            if old_name == replace_tile then
                refund_count = refund_count + 1
            end
        end

        surface.set_tiles(new_tiles)
        if inventory and inventory.valid and refund_count > 0 then
            inventory.insert {name = refund_tile, count = refund_count}
        end
    end

    local function on_tile_built(event, inventory)
        local item = event.item
        if not item then
            return
        end

        local surface = game.get_surface(event.surface_index)
        if not surface or not surface.valid then
            return
        end

        local item_name = item.name
        local tiles = event.tiles

        if not brush_tools[item_name] then
            refund_tiles(surface, inventory, tiles)
            return
        end

        change_tiles(surface, inventory, tiles)
    end

    local function player_built_tile(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local inventory = player.get_inventory(character_main)
        on_tile_built(event, inventory)
    end

    local function robot_built_tile(event)
        local robot = event.robot
        if not robot or not robot.valid then
            return
        end

        local inventory = robot.get_inventory(robot_cargo)
        on_tile_built(event, inventory)
    end

    local function built_entity(event)
        local entity = event.created_entity
        if not entity or not entity.valid or entity.name ~= 'tile-ghost' or not brush_tools[entity.ghost_name] then
            return
        end

        local tile = entity.surface.get_tile(entity.position)
        if tile and tile.valid and tile.name == replace_tile then
            entity.destroy()
        end
    end

    Event.add(defines.events.on_player_built_tile, player_built_tile)
    Event.add(defines.events.on_robot_built_tile, robot_built_tile)
    Event.add(defines.events.on_built_entity, built_entity)
end
