--Author: MewMew
-- !! ATTENTION !!
-- Use water only in starting area as map setting!!!
local perlin = require 'map_gen.shared.perlin_noise'

local wreck_item_pool = {
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

local directions = {
    defines.direction.north,
    defines.direction.east,
    defines.direction.south,
    defines.direction.west
}

local function place_entities(surface, entity_list)
    for _, entity in ipairs(entity_list) do
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

local clear_types = {'simple-entity', 'tree'}

local function do_clear_entities(world)
    local entities = world.surface.find_entities_filtered({area = world.area, type = clear_types})
    for _, entity in ipairs(entities) do
        entity.destroy()
    end
end

return function(x, y, world)
    local entities = {}
    local decoratives = {}

    local area = world.area
    local surface = world.surface

    if not world.island_resort_cleared then
        world.island_resort_cleared = true
        do_clear_entities(world)
    end

    local pos = {x = world.x, y = world.y}
    local tile = surface.get_tile(world.x, world.y)
    local tile_to_insert = 'sand-1'
    local entity_placed = false

    local seed_increment_number = 10000
    local seed = surface.map_gen_settings.seed

    local noise_borg_defense_1 = perlin:noise(((world.x + seed) / 100), ((world.y + seed) / 100), 0)
    seed = seed + seed_increment_number
    local noise_borg_defense_2 = perlin:noise(((world.x + seed) / 20), ((world.y + seed) / 20), 0)
    seed = seed + seed_increment_number
    local noise_borg_defense = noise_borg_defense_1 + noise_borg_defense_2 * 0.15

    local noise_trees_1 = perlin:noise(((world.x + seed) / 50), ((world.y + seed) / 50), 0)
    seed = seed + seed_increment_number
    local noise_trees_2 = perlin:noise(((world.x + seed) / 15), ((world.y + seed) / 15), 0)
    seed = seed + seed_increment_number
    local noise_trees = noise_trees_1 + noise_trees_2 * 0.3

    local noise_walls_1 = perlin:noise(((world.x + seed) / 150), ((world.y + seed) / 150), 0)
    seed = seed + seed_increment_number
    local noise_walls_2 = perlin:noise(((world.x + seed) / 50), ((world.y + seed) / 50), 0)
    seed = seed + seed_increment_number
    local noise_walls_3 = perlin:noise(((world.x + seed) / 20), ((world.y + seed) / 20), 0)
    seed = seed + seed_increment_number
    local noise_walls = noise_walls_1 + noise_walls_2 * 0.1 + noise_walls_3 * 0.03

    if noise_borg_defense > 0.66 then
        local entity_list = {}
        table.insert(entity_list, {name = 'big-ship-wreck-1', pos = {world.x, world.y}, chance = 25})
        table.insert(entity_list, {name = 'big-ship-wreck-2', pos = {world.x, world.y}, chance = 25})
        table.insert(entity_list, {name = 'big-ship-wreck-3', pos = {world.x, world.y}, chance = 25})
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

    if noise_trees > 0.17 then
        tile_to_insert = 'sand-3'
    end
    if noise_borg_defense > 0.4 then
        tile_to_insert = 'concrete'
    end
    if noise_borg_defense > 0.35 and noise_borg_defense < 0.4 then
        tile_to_insert = 'stone-path'
    end
    if noise_borg_defense > 0.65 and noise_borg_defense < 0.66 then
        if surface.can_place_entity {name = 'substation', position = {world.x, world.y}, force = 'enemy'} then
            surface.create_entity {name = 'substation', position = {world.x, world.y}, force = 'enemy'}
        end
    end
    if noise_borg_defense >= 0.54 and noise_borg_defense < 0.65 then
        if surface.can_place_entity {name = 'solar-panel', position = {world.x, world.y}, force = 'enemy'} then
            surface.create_entity {name = 'solar-panel', position = {world.x, world.y}, force = 'enemy'}
        end
    end
    if noise_borg_defense > 0.53 and noise_borg_defense < 0.54 then
        if surface.can_place_entity {name = 'substation', position = {world.x, world.y}, force = 'enemy'} then
            surface.create_entity {name = 'substation', position = {world.x, world.y}, force = 'enemy'}
        end
    end
    if noise_borg_defense >= 0.51 and noise_borg_defense < 0.53 then
        if surface.can_place_entity {name = 'accumulator', position = {world.x, world.y}, force = 'enemy'} then
            surface.create_entity {name = 'accumulator', position = {world.x, world.y}, force = 'enemy'}
        end
    end
    if noise_borg_defense >= 0.50 and noise_borg_defense < 0.51 then
        if surface.can_place_entity {name = 'substation', position = {world.x, world.y}, force = 'enemy'} then
            surface.create_entity {name = 'substation', position = {world.x, world.y}, force = 'enemy'}
        end
    end
    if noise_borg_defense >= 0.487 and noise_borg_defense < 0.50 then
        if surface.can_place_entity {name = 'laser-turret', position = {world.x, world.y}, force = 'enemy'} then
            surface.create_entity {name = 'laser-turret', position = {world.x, world.y}, force = 'enemy'}
        end
    end
    if noise_borg_defense >= 0.485 and noise_borg_defense < 0.487 then
        if surface.can_place_entity {name = 'substation', position = {world.x, world.y}, force = 'enemy'} then
            surface.create_entity {name = 'substation', position = {world.x, world.y}, force = 'enemy'}
        end
    end
    if noise_borg_defense >= 0.45 and noise_borg_defense < 0.484 then
        if surface.can_place_entity {name = 'stone-wall', position = {world.x, world.y}, force = 'enemy'} then
            surface.create_entity {name = 'stone-wall', position = {world.x, world.y}, force = 'enemy'}
        end
    end

    if noise_trees > 0.2 and tile_to_insert == 'sand-3' then
        if math.random(1, 15) == 1 then
            if math.random(1, 5) == 1 then
                if surface.can_place_entity {name = 'dry-hairy-tree', position = {world.x, world.y}} then
                    surface.create_entity {name = 'dry-hairy-tree', position = {world.x, world.y}}
                end
            else
                if surface.can_place_entity {name = 'dry-tree', position = {world.x, world.y}} then
                    surface.create_entity {name = 'dry-tree', position = {world.x, world.y}}
                end
            end
        end
    end

    local entity_list = {}
    table.insert(entity_list, {name = 'big-ship-wreck-1', pos = {world.x, world.y}, chance = 35000, health = 'random'})
    table.insert(entity_list, {name = 'big-ship-wreck-2', pos = {world.x, world.y}, chance = 45000, health = 'random'})
    table.insert(entity_list, {name = 'big-ship-wreck-3', pos = {world.x, world.y}, chance = 55000, health = 'random'})
    if noise_walls > -0.03 and noise_walls < 0.03 then
        table.insert(entity_list, {name = 'gun-turret', pos = {world.x, world.y}, force = 'enemy', chance = 40})
    end
    if noise_borg_defense > 0.41 and noise_borg_defense < 0.45 then
        table.insert(entity_list, {name = 'gun-turret', pos = {world.x, world.y}, force = 'enemy', chance = 15})
    end
    table.insert(entity_list, {name = 'pipe-to-ground', pos = {world.x, world.y}, force = 'enemy', chance = 7500})
    if tile_to_insert ~= 'stone-path' and tile_to_insert ~= 'concrete' then
        table.insert(
            entity_list,
            {name = 'dead-dry-hairy-tree', pos = {world.x, world.y}, force = 'enemy', chance = 1500}
        )
        table.insert(entity_list, {name = 'dead-grey-trunk', pos = {world.x, world.y}, force = 'enemy', chance = 1500})
    end
    table.insert(entity_list, {name = 'medium-ship-wreck', pos = {world.x, world.y}, chance = 25000, health = 'medium'})
    table.insert(entity_list, {name = 'small-ship-wreck', pos = {world.x, world.y}, chance = 15000, health = 'medium'})
    table.insert(entity_list, {name = 'car', pos = {world.x, world.y}, chance = 150000, health = 'low'})
    table.insert(
        entity_list,
        {name = 'laser-turret', pos = {world.x, world.y}, chance = 100000, force = 'enemy', health = 'low'}
    )
    table.insert(
        entity_list,
        {name = 'nuclear-reactor', pos = {world.x, world.y}, chance = 1000000, force = 'enemy', health = 'medium'}
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
                if surface.can_place_entity {name = 'rock-big', position = {world.x, world.y}} then
                    surface.create_entity {name = 'rock-big', position = {world.x, world.y}}
                end
            end
        end
    end

    local noise_water_1 = perlin:noise(((world.x + seed) / 200), ((world.y + seed) / 200), 0)
    seed = seed + seed_increment_number
    local noise_water_2 = perlin:noise(((world.x + seed) / 100), ((world.y + seed) / 100), 0)
    seed = seed + seed_increment_number
    local noise_water_3 = perlin:noise(((world.x + seed) / 25), ((world.y + seed) / 25), 0)
    seed = seed + seed_increment_number
    local noise_water_4 = perlin:noise(((world.x + seed) / 10), ((world.y + seed) / 10), 0)
    seed = seed + seed_increment_number
    local noise_water = noise_water_1 + noise_water_2 + noise_water_3 * 0.07 + noise_water_4 * 0.07

    local noise_water_1 = perlin:noise(((world.x + seed) / 200), ((world.y + seed) / 200), 0)
    seed = seed + seed_increment_number
    local noise_water_2 = perlin:noise(((world.x + seed) / 100), ((world.y + seed) / 100), 0)
    seed = seed + seed_increment_number
    local noise_water_3 = perlin:noise(((world.x + seed) / 25), ((world.y + seed) / 25), 0)
    seed = seed + seed_increment_number
    local noise_water_4 = perlin:noise(((world.x + seed) / 10), ((world.y + seed) / 10), 0)
    seed = seed + seed_increment_number
    local noise_water_2 = noise_water_1 + noise_water_2 + noise_water_3 * 0.07 + noise_water_4 * 0.07

    if tile_to_insert ~= 'stone-path' and tile_to_insert ~= 'concrete' then
        if noise_water > -0.15 and noise_water < 0.15 and noise_water_2 > 0.5 then
            tile_to_insert = 'water-green'
            local a = world.x + 1
            table.insert(tiles, {name = tile_to_insert, position = {a, world.y}})
            local a = world.y + 1
            table.insert(tiles, {name = tile_to_insert, position = {world.x, a}})
            local a = world.x - 1
            table.insert(tiles, {name = tile_to_insert, position = {a, world.y}})
            local a = world.y - 1
            table.insert(tiles, {name = tile_to_insert, position = {world.x, a}})
            table.insert(tiles, {name = tile_to_insert, position = {world.x, world.y}})
        end
    end

    if noise_borg_defense <= 0.45 and tile_to_insert ~= 'water-green' then
        local a = -0.01
        local b = 0.01
        if noise_walls > a and noise_walls < b then
            if surface.can_place_entity {name = 'stone-wall', position = {world.x, world.y}, force = 'enemy'} then
                surface.create_entity {name = 'stone-wall', position = {world.x, world.y}, force = 'enemy'}
            end
        end
        if noise_walls >= a and noise_walls <= b then
            tile_to_insert = 'concrete'
        end
        if noise_borg_defense < 0.40 then
            if noise_walls > b and noise_walls < b + 0.03 then
                tile_to_insert = 'stone-path'
            end
            if noise_walls > a - 0.03 and noise_walls < a then
                tile_to_insert = 'stone-path'
            end
        end
    end

    local noise_decoratives_1 = perlin:noise(((world.x + seed) / 50), ((world.y + seed) / 50), 0)
    seed = seed + seed_increment_number
    local noise_decoratives_2 = perlin:noise(((world.x + seed) / 15), ((world.y + seed) / 15), 0)
    seed = seed + seed_increment_number
    local noise_decoratives = noise_decoratives_1 + noise_decoratives_2 * 0.3

    if noise_decoratives > 0.3 and noise_decoratives < 0.5 then
        if tile_to_insert ~= 'stone-path' and tile_to_insert ~= 'concrete' and tile_to_insert ~= 'water-green' then
            if math.random(1, 10) == 1 then
                table.insert(decoratives, {name = 'red-desert-bush', position = {world.x, world.y}, amount = 1})
            end
        end
    end
    table.insert(tiles, {name = tile_to_insert, position = {world.x, world.y}})

    surface.set_tiles(tiles, true)

    for _, deco in pairs(decoratives) do
        surface.create_decoratives {check_collision = false, decoratives = {deco}}
    end
end
