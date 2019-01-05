-- luacheck: ignore
-- This file is a linting disaster and needs an overhaul
--Author: MewMew
-- !! ATTENTION !!
-- Use water only in starting area as map setting!!!
local perlin = require 'map_gen.shared.perlin_noise'
local RS = require 'map_gen.shared.redmew_surface'

wreck_item_pool = {}
wreck_item_pool = {
    {name = 'iron-gear-wheel', count = 32},
    {name = 'iron-plate', count = 64},
    {name = 'rocket-control-unit', count = 1},
    {name = 'rocket-fuel', count = 7},
    {name = 'coal', count = 8},
    {name = 'rocket-launcher', count = 1},
    {name = 'rocket', count = 32},
    {name = 'copper-cable', count = 128},
    {name = 'land-mine', count = 64},
    {name = 'railgun', count = 1},
    {name = 'railgun-dart', count = 128},
    {name = 'fast-inserter', count = 8},
    {name = 'stack-filter-inserter', count = 2},
    {name = 'belt-immunity-equipment', count = 1},
    {name = 'fusion-reactor-equipment', count = 1},
    {name = 'electric-engine-unit', count = 8},
    {name = 'exoskeleton-equipment', count = 1},
    {name = 'rocket-fuel', count = 10},
    {name = 'used-up-uranium-fuel-cell', count = 3},
    {name = 'uranium-fuel-cell', count = 2},
    {name = 'power-armor', count = 1},
    {name = 'modular-armor', count = 1},
    {name = 'water-barrel', count = 4},
    {name = 'sulfuric-acid-barrel', count = 6},
    {name = 'crude-oil-barrel', count = 8},
    {name = 'energy-shield-equipment', count = 1},
    {name = 'explosive-rocket', count = 32}
}

local function place_entities(surface, entity_list)
    local directions = {
        defines.direction.north,
        defines.direction.east,
        defines.direction.south,
        defines.direction.west
    }
    for _, entity in pairs(entity_list) do
        local r = math.random(1, entity.chance)
        if r == 1 then
            if not entity.force then
                entity.force = 'player'
            end
            local r = math.random(1, 4)
            if
                surface.can_place_entity {
                    name = entity.name,
                    position = entity.pos,
                    direction = directions[r],
                    force = entity.force
                }
             then
                local e =
                    surface.create_entity {
                    name = entity.name,
                    position = entity.pos,
                    direction = directions[r],
                    force = entity.force
                }
                if entity.health then
                    if entity.health == 'low' then
                        e.health = ((e.health / 1000) * math.random(33, 330))
                    end
                    if entity.health == 'medium' then
                        e.health = ((e.health / 1000) * math.random(333, 666))
                    end
                    if entity.health == 'high' then
                        e.health = ((e.health / 1000) * math.random(666, 999))
                    end
                    if entity.health == 'random' then
                        e.health = ((e.health / 1000) * math.random(1, 1000))
                    end
                end
                return true, e
            end
        end
    end
    return false
end

local function find_tile_placement_spot_around_target_position(tilename, position, mode, density)
    local x = position.x
    local y = position.y
    if not surface then
        surface = RS.get_surface()
    end
    local scan_radius = 50
    if not tilename then
        return
    end
    if not mode then
        mode = 'ball'
    end
    if not density then
        density = 1
    end
    local cluster_tiles = {}
    local auto_correct = true

    local scanned_tile = surface.get_tile(x, y)
    if scanned_tile.name ~= tilename then
        table.insert(cluster_tiles, {name = tilename, position = {x, y}})
        surface.set_tiles(cluster_tiles, auto_correct)
        return true, x, y
    end

    local i = 2
    local r = 1

    if mode == 'ball' then
        if math.random(1, 2) == 1 then
            density = density * -1
        end
        r = math.random(1, 4)
    end
    if mode == 'line' then
        density = 1
        r = math.random(1, 4)
    end
    if mode == 'line_down' then
        density = density * -1
        r = math.random(1, 4)
    end
    if mode == 'line_up' then
        density = 1
        r = math.random(1, 4)
    end
    if mode == 'block' then
        r = 1
        density = 1
    end

    if r == 1 then
        --start placing at -1,-1
        while i <= scan_radius do
            y = y - density
            x = x - density
            for a = 1, i, 1 do
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table.insert(cluster_tiles, {name = tilename, position = {x, y}})
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
                x = x + density
            end
            for a = 1, i, 1 do
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table.insert(cluster_tiles, {name = tilename, position = {x, y}})
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
                y = y + density
            end
            for a = 1, i, 1 do
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table.insert(cluster_tiles, {name = tilename, position = {x, y}})
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
                x = x - density
            end
            for a = 1, i, 1 do
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table.insert(cluster_tiles, {name = tilename, position = {x, y}})
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
                y = y - density
            end
            i = i + 2
        end
    end

    if r == 2 then
        --start placing at 0,-1
        while i <= scan_radius do
            y = y - density
            x = x - density
            for a = 1, i, 1 do
                x = x + density
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table.insert(cluster_tiles, {name = tilename, position = {x, y}})
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
            end
            for a = 1, i, 1 do
                y = y + density
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table.insert(cluster_tiles, {name = tilename, position = {x, y}})
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
            end
            for a = 1, i, 1 do
                x = x - density
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table.insert(cluster_tiles, {name = tilename, position = {x, y}})
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
            end
            for a = 1, i, 1 do
                y = y - density
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table.insert(cluster_tiles, {name = tilename, position = {x, y}})
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
            end
            i = i + 2
        end
    end

    if r == 3 then
        --start placing at 1,-1
        while i <= scan_radius do
            y = y - density
            x = x + density
            for a = 1, i, 1 do
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table.insert(cluster_tiles, {name = tilename, position = {x, y}})
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
                y = y + density
            end
            for a = 1, i, 1 do
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table.insert(cluster_tiles, {name = tilename, position = {x, y}})
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
                x = x - density
            end
            for a = 1, i, 1 do
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table.insert(cluster_tiles, {name = tilename, position = {x, y}})
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
                y = y - density
            end
            for a = 1, i, 1 do
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table.insert(cluster_tiles, {name = tilename, position = {x, y}})
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
                x = x + density
            end
            i = i + 2
        end
    end

    if r == 4 then
        --start placing at 1,0
        while i <= scan_radius do
            y = y - density
            x = x + density
            for a = 1, i, 1 do
                y = y + density
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table.insert(cluster_tiles, {name = tilename, position = {x, y}})
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
            end
            for a = 1, i, 1 do
                x = x - density
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table.insert(cluster_tiles, {name = tilename, position = {x, y}})
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
            end
            for a = 1, i, 1 do
                y = y - density
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table.insert(cluster_tiles, {name = tilename, position = {x, y}})
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
            end
            for a = 1, i, 1 do
                x = x + density
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table.insert(cluster_tiles, {name = tilename, position = {x, y}})
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
            end
            i = i + 2
        end
    end
    return false
end

local function create_tile_cluster(tilename, position, amount)
    local mode = 'ball'
    local pos = position
    for i = 1, amount, 1 do
        local b, x, y = find_tile_placement_spot_around_target_position(tilename, pos, mode)
        if b == true then
            if 1 == math.random(1, 2) then
                pos.x = x
                pos.y = y
            end
        end
        if b == false then
            return false, x, y
        end
        if i >= amount then
            return true, x, y
        end
    end
end

function run_combined_module(event)
    if not global.perlin_noise_seed then
        global.perlin_noise_seed = math.random(1000, 1000000)
    end
    if not global.void_slime then
        global.void_slime = {x = 0, y = 0}
    end
    if not global.void_slime_is_alive then
        global.void_slime_is_alive = true
    end
    local area = event.area
    local surface = event.surface
    local tiles = {}
    local resource_tiles = {}
    local special_tiles = true

    local entities = surface.find_entities(area)
    for _, entity in pairs(entities) do
        if entity.type == 'resource' then
            --table.insert(resource_tiles, {name = "sand-3", position = entity.position})
            special_tiles = false
        end
        if entity.type == 'simple-entity' or entity.type == 'tree' then
            if entity.name ~= 'dry-tree' then
                entity.destroy()
            end
        end
    end

    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local pos_x = event.area.left_top.x + x
            local pos_y = event.area.left_top.y + y
            local pos = {x = pos_x, y = pos_y}
            local tile = surface.get_tile(pos_x, pos_y)
            local tile_to_insert = 'sand-1'
            local entity_placed = false

            local seed_increment_number = 10000
            local seed = global.perlin_noise_seed

            local noise_borg_defense_1 = perlin.noise(((pos_x + seed) / 100), ((pos_y + seed) / 100), 0)
            seed = seed + seed_increment_number
            local noise_borg_defense_2 = perlin.noise(((pos_x + seed) / 20), ((pos_y + seed) / 20), 0)
            seed = seed + seed_increment_number
            local noise_borg_defense = noise_borg_defense_1 + noise_borg_defense_2 * 0.15

            local noise_trees_1 = perlin.noise(((pos_x + seed) / 50), ((pos_y + seed) / 50), 0)
            seed = seed + seed_increment_number
            local noise_trees_2 = perlin.noise(((pos_x + seed) / 15), ((pos_y + seed) / 15), 0)
            seed = seed + seed_increment_number
            local noise_trees = noise_trees_1 + noise_trees_2 * 0.3

            if noise_borg_defense > 0.66 then
                local entity_list = {}
                table.insert(entity_list, {name = 'big-ship-wreck-1', pos = {pos_x, pos_y}, chance = 25})
                table.insert(entity_list, {name = 'big-ship-wreck-2', pos = {pos_x, pos_y}, chance = 25})
                table.insert(entity_list, {name = 'big-ship-wreck-3', pos = {pos_x, pos_y}, chance = 25})
                local b, placed_entity = place_entities(surface, entity_list)
                if b == true then
                    if
                        placed_entity.name == 'big-ship-wreck-1' or placed_entity.name == 'big-ship-wreck-2' or
                            placed_entity.name == 'big-ship-wreck-3'
                     then
                        placed_entity.insert(wreck_item_pool[math.random(1, #wreck_item_pool)])
                        placed_entity.insert(wreck_item_pool[math.random(1, #wreck_item_pool)])
                        placed_entity.insert(wreck_item_pool[math.random(1, #wreck_item_pool)])
                    end
                end
            end

            if noise_trees > 0.4 then
                tile_to_insert = 'sand-3'
            end
            if noise_borg_defense > 0.4 then
                tile_to_insert = 'concrete'
            end
            if noise_borg_defense > 0.3 and noise_borg_defense < 0.4 then
                tile_to_insert = 'stone-path'
            end
            if noise_borg_defense > 0.65 and noise_borg_defense < 0.66 then
                if event.surface.can_place_entity {name = 'substation', position = {pos_x, pos_y}, force = 'enemy'} then
                    event.surface.create_entity {name = 'substation', position = {pos_x, pos_y}, force = 'enemy'}
                end
            end
            if noise_borg_defense >= 0.54 and noise_borg_defense < 0.65 then
                if event.surface.can_place_entity {name = 'solar-panel', position = {pos_x, pos_y}, force = 'enemy'} then
                    event.surface.create_entity {name = 'solar-panel', position = {pos_x, pos_y}, force = 'enemy'}
                end
            end
            if noise_borg_defense > 0.53 and noise_borg_defense < 0.54 then
                if event.surface.can_place_entity {name = 'substation', position = {pos_x, pos_y}, force = 'enemy'} then
                    event.surface.create_entity {name = 'substation', position = {pos_x, pos_y}, force = 'enemy'}
                end
            end
            if noise_borg_defense > 0.51 and noise_borg_defense < 0.53 then
                if event.surface.can_place_entity {name = 'accumulator', position = {pos_x, pos_y}, force = 'enemy'} then
                    event.surface.create_entity {name = 'accumulator', position = {pos_x, pos_y}, force = 'enemy'}
                end
            end
            if noise_borg_defense > 0.50 and noise_borg_defense < 0.51 then
                if event.surface.can_place_entity {name = 'substation', position = {pos_x, pos_y}, force = 'enemy'} then
                    event.surface.create_entity {name = 'substation', position = {pos_x, pos_y}, force = 'enemy'}
                end
            end
            if noise_borg_defense > 0.49 and noise_borg_defense < 0.50 then
                if event.surface.can_place_entity {name = 'laser-turret', position = {pos_x, pos_y}, force = 'enemy'} then
                    event.surface.create_entity {name = 'laser-turret', position = {pos_x, pos_y}, force = 'enemy'}
                end
            end
            if noise_borg_defense > 0.485 and noise_borg_defense < 0.49 then
                if event.surface.can_place_entity {name = 'substation', position = {pos_x, pos_y}, force = 'enemy'} then
                    event.surface.create_entity {name = 'substation', position = {pos_x, pos_y}, force = 'enemy'}
                end
            end
            if noise_borg_defense > 0.45 and noise_borg_defense < 0.48 then
                if event.surface.can_place_entity {name = 'stone-wall', position = {pos_x, pos_y}, force = 'enemy'} then
                    event.surface.create_entity {name = 'stone-wall', position = {pos_x, pos_y}, force = 'enemy'}
                end
            end

            local noise_walls_1 = perlin.noise(((pos_x + seed) / 200), ((pos_y + seed) / 200), 0)
            seed = seed + seed_increment_number
            local noise_walls_2 = perlin.noise(((pos_x + seed) / 100), ((pos_y + seed) / 100), 0)
            seed = seed + seed_increment_number
            local noise_walls_3 = perlin.noise(((pos_x + seed) / 25), ((pos_y + seed) / 25), 0)
            seed = seed + seed_increment_number
            local noise_walls = noise_walls_1 + noise_walls_2 + noise_walls_3 * 0.05

            if noise_walls > 0.01 and noise_walls < 0.03 then
                if event.surface.can_place_entity {name = 'stone-wall', position = {pos_x, pos_y}, force = 'enemy'} then
                    event.surface.create_entity {name = 'stone-wall', position = {pos_x, pos_y}, force = 'enemy'}
                end
            end
            if noise_walls > -0.01 and noise_walls < 0.05 then
                tile_to_insert = 'concrete'
            end
            if noise_walls > -0.03 and noise_walls < -0.01 then
                tile_to_insert = 'stone-path'
            end
            if noise_walls > 0.05 and noise_walls < 0.07 then
                tile_to_insert = 'stone-path'
            end

            if noise_trees > 0.4 and tile_to_insert == 'sand-3' then
                if math.random(1, 20) == 1 then
                    if event.surface.can_place_entity {name = 'dry-tree', position = {pos_x, pos_y}} then
                        event.surface.create_entity {name = 'dry-tree', position = {pos_x, pos_y}}
                    end
                end
            end

            local entity_list = {}
            table.insert(
                entity_list,
                {name = 'big-ship-wreck-1', pos = {pos_x, pos_y}, chance = 65000, health = 'random'}
            )
            table.insert(
                entity_list,
                {name = 'big-ship-wreck-2', pos = {pos_x, pos_y}, chance = 65000, health = 'random'}
            )
            table.insert(
                entity_list,
                {name = 'big-ship-wreck-3', pos = {pos_x, pos_y}, chance = 65000, health = 'random'}
            )
            table.insert(entity_list, {name = 'gun-turret', pos = {pos_x, pos_y}, force = 'enemy', chance = 4000})
            table.insert(
                entity_list,
                {name = 'medium-ship-wreck', pos = {pos_x, pos_y}, chance = 25000, health = 'medium'}
            )
            table.insert(
                entity_list,
                {name = 'small-ship-wreck', pos = {pos_x, pos_y}, chance = 15000, health = 'medium'}
            )
            table.insert(entity_list, {name = 'car', pos = {pos_x, pos_y}, chance = 150000, health = 'low'})
            table.insert(
                entity_list,
                {name = 'laser-turret', pos = {pos_x, pos_y}, chance = 100000, force = 'enemy', health = 'low'}
            )
            table.insert(
                entity_list,
                {name = 'nuclear-reactor', pos = {pos_x, pos_y}, chance = 1000000, force = 'enemy', health = 'medium'}
            )
            local b, placed_entity = place_entities(surface, entity_list)
            if b == true then
                if
                    placed_entity.name == 'big-ship-wreck-1' or placed_entity.name == 'big-ship-wreck-2' or
                        placed_entity.name == 'big-ship-wreck-3'
                 then
                    placed_entity.insert(wreck_item_pool[math.random(1, #wreck_item_pool)])
                    placed_entity.insert(wreck_item_pool[math.random(1, #wreck_item_pool)])
                    placed_entity.insert(wreck_item_pool[math.random(1, #wreck_item_pool)])
                end
                if placed_entity.name == 'gun-turret' then
                    if math.random(1, 3) == 1 then
                        placed_entity.insert('piercing-rounds-magazine')
                    else
                        placed_entity.insert('firearm-magazine')
                    end
                end
            end

            if noise_trees < -0.5 then
                if tile_to_insert == 'sand-3' or tile_to_insert == 'sand-1' then
                    if math.random(1, 15) == 1 then
                        if event.surface.can_place_entity {name = 'rock-big', position = {pos_x, pos_y}} then
                            event.surface.create_entity {name = 'rock-big', position = {pos_x, pos_y}}
                        end
                    end
                end
            end

            table.insert(tiles, {name = tile_to_insert, position = {pos_x, pos_y}})
        end
    end
    surface.set_tiles(tiles, true)
    surface.set_tiles(resource_tiles, true)

    if special_tiles == true then
        local pos_x = event.area.left_top.x + math.random(10, 21)
        local pos_y = event.area.left_top.y + math.random(10, 21)
        local pos = {x = pos_x, y = pos_y}
        if math.random(1, 20) == 1 then
            create_tile_cluster('water-green', pos, 300)
        end
    end
end

--[[
local function on_tick()
        if game.tick % 180 == 0 then
            if global.void_slime_is_alive == true then
                local b,x,y = create_tile_cluster("lab-dark-1",global.void_slime,math.random(1,4))
                global.void_slime.x = x
                global.void_slime.y = y
                if b == false then
                    global.void_slime_is_alive = false
                    game.print("The void slime died.")
                end
            end
        end
end


Event.add(defines.events.on_tick, on_tick)  --]]
