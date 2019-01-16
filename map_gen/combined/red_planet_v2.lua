--Author: MewMew

-- !! ATTENTION !!
-- Use water only in starting area as map setting!!!

local perlin = require 'map_gen.shared.perlin_noise'
local Task = require 'utils.task'
local RS = require 'map_gen.shared.redmew_surface'

wreck_item_pool = {}
wreck_item_pool = {
    {name = 'iron-gear-wheel', count = 32},
    {name = 'iron-plate', count = 64},
    {name = 'rocket-control-unit', count = 1},
    {name = 'coal', count = 4},
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
    {name = 'uranium-fuel-cell', count = 2}
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

local c = 0.5
local resource_amount_distance_multiplicator = (((c + 1) / 75) / 75) + 1

function run_combined_module(event)
    if not global.perlin_noise_seed then
        global.perlin_noise_seed = math.random(1000, 1000000)
    end
    local surface = RS.get_surface()

    local entities = surface.find_entities(event.area)
    for _, entity in pairs(entities) do
        if entity.type == 'simple-entity' or entity.type == 'resource' or entity.type == 'tree' then
            entity.destroy()
        end
    end

    Task.queue_task('run_planet_init', {})
    --run_planet_init()
    for x = 0, 31, 1 do
        Task.queue_task('run_planet', {area = event.area, surface = event.surface, x = x})
        --run_planet( {area = event.area, surface = event.surface, x = x})
    end
    --run_planet_place_tiles( {surface = event.surface} )
    Task.queue_task('run_planet_place_tiles', {surface = event.surface})
end

global.planet_tiles_hold = {}
global.planet_decoratives_hold = {}

function run_planet_init(params)
    global.planet_tiles_hold = {}
    global.planet_decoratives_hold = {}
end

function run_planet_place_tiles(params)
    local surface = params.surface
    surface.set_tiles(global.planet_tiles_hold)
    for _, deco in pairs(global.planet_decoratives_hold) do
        surface.create_decoratives {check_collision = false, decoratives = {deco}}
    end
end

function run_planet(params)
    local tree_to_place = {'dry-tree', 'dry-hairy-tree', 'tree-06', 'tree-06', 'tree-01', 'tree-02', 'tree-03'}
    local area = params.area
    local surface = params.surface

    local x = params.x
    local pos_x = area.left_top.x + x

    for y = 0, 31, 1 do
        local pos_y = area.left_top.y + y
        local seed = surface.map_gen_settings.seed
        local tile = surface.get_tile(pos_x, pos_y)
        local tile_to_insert = 'concrete'

        local a = pos_x
        local b = pos_y
        local resource_entity_placed = false

        local entity_list = {}
        table.insert(entity_list, {name = 'big-ship-wreck-1', pos = {pos_x, pos_y}, chance = 65000, health = 'random'})
        table.insert(entity_list, {name = 'big-ship-wreck-2', pos = {pos_x, pos_y}, chance = 65000, health = 'random'})
        table.insert(entity_list, {name = 'big-ship-wreck-3', pos = {pos_x, pos_y}, chance = 65000, health = 'random'})
        table.insert(entity_list, {name = 'medium-ship-wreck', pos = {pos_x, pos_y}, chance = 25000, health = 'medium'})
        table.insert(entity_list, {name = 'small-ship-wreck', pos = {pos_x, pos_y}, chance = 15000, health = 'medium'})
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
        end

        local seed_increment_number = 10000

        local noise_terrain_1 = perlin.noise(((pos_x + seed) / 400), ((pos_y + seed) / 400), 0)
        noise_terrain_1 = noise_terrain_1 * 100
        seed = seed + seed_increment_number
        local noise_terrain_2 = perlin.noise(((pos_x + seed) / 250), ((pos_y + seed) / 250), 0)
        noise_terrain_2 = noise_terrain_2 * 100
        seed = seed + seed_increment_number
        local noise_terrain_3 = perlin.noise(((pos_x + seed) / 100), ((pos_y + seed) / 100), 0)
        noise_terrain_3 = noise_terrain_3 * 50
        seed = seed + seed_increment_number
        local noise_terrain_4 = perlin.noise(((pos_x + seed) / 20), ((pos_y + seed) / 20), 0)
        noise_terrain_4 = noise_terrain_4 * 10
        seed = seed + seed_increment_number
        local noise_terrain_5 = perlin.noise(((pos_x + seed) / 5), ((pos_y + seed) / 5), 0)
        noise_terrain_5 = noise_terrain_5 * 4
        seed = seed + seed_increment_number
        local noise_sand = perlin.noise(((pos_x + seed) / 18), ((pos_y + seed) / 18), 0)
        noise_sand = noise_sand * 10

        --DECORATIVES
        seed = seed + seed_increment_number
        local noise_decoratives_1 = perlin.noise(((pos_x + seed) / 20), ((pos_y + seed) / 20), 0)
        noise_decoratives_1 = noise_decoratives_1
        seed = seed + seed_increment_number
        local noise_decoratives_2 = perlin.noise(((pos_x + seed) / 30), ((pos_y + seed) / 30), 0)
        noise_decoratives_2 = noise_decoratives_2
        seed = seed + seed_increment_number
        local noise_decoratives_3 = perlin.noise(((pos_x + seed) / 30), ((pos_y + seed) / 30), 0)
        noise_decoratives_3 = noise_decoratives_3

        seed = seed + seed_increment_number
        local noise_water_1 = perlin.noise(((pos_x + seed) / 250), ((pos_y + seed) / 300), 0)
        noise_water_1 = noise_water_1 * 100
        seed = seed + seed_increment_number
        local noise_water_2 = perlin.noise(((pos_x + seed) / 100), ((pos_y + seed) / 150), 0)
        noise_water_2 = noise_water_2 * 50

        --RESOURCES
        seed = seed + seed_increment_number
        local noise_resources = perlin.noise(((pos_x + seed) / 100), ((pos_y + seed) / 100), 0)
        seed = seed + seed_increment_number
        local noise_resources_2 = perlin.noise(((pos_x + seed) / 40), ((pos_y + seed) / 40), 0)
        seed = seed + seed_increment_number
        local noise_resources_3 = perlin.noise(((pos_x + seed) / 20), ((pos_y + seed) / 20), 0)
        noise_resources = noise_resources * 50 + noise_resources_2 * 20 + noise_resources_3 * 20
        noise_resources = noise_resources_2 * 100

        seed = seed + seed_increment_number
        local noise_resource_amount_modifier = perlin.noise(((pos_x + seed) / 200), ((pos_y + seed) / 200), 0)
        local resource_amount =
            1 + ((400 + (400 * noise_resource_amount_modifier * 0.2)) * resource_amount_distance_multiplicator)
        seed = seed + seed_increment_number
        local noise_resources_iron_and_copper = perlin.noise(((pos_x + seed) / 250), ((pos_y + seed) / 250), 0)
        noise_resources_iron_and_copper = noise_resources_iron_and_copper * 100
        seed = seed + seed_increment_number
        local noise_resources_coal_and_uranium = perlin.noise(((pos_x + seed) / 250), ((pos_y + seed) / 250), 0)
        noise_resources_coal_and_uranium = noise_resources_coal_and_uranium * 100
        seed = seed + seed_increment_number
        local noise_resources_stone_and_oil = perlin.noise(((pos_x + seed) / 150), ((pos_y + seed) / 150), 0)
        noise_resources_stone_and_oil = noise_resources_stone_and_oil * 100

        seed = seed + seed_increment_number
        local noise_red_desert_rocks_1 = perlin.noise(((pos_x + seed) / 20), ((pos_y + seed) / 20), 0)
        noise_red_desert_rocks_1 = noise_red_desert_rocks_1 * 100
        seed = seed + seed_increment_number
        local noise_red_desert_rocks_2 = perlin.noise(((pos_x + seed) / 10), ((pos_y + seed) / 10), 0)
        noise_red_desert_rocks_2 = noise_red_desert_rocks_2 * 50
        seed = seed + seed_increment_number
        local noise_red_desert_rocks_3 = perlin.noise(((pos_x + seed) / 5), ((pos_y + seed) / 5), 0)
        noise_red_desert_rocks_3 = noise_red_desert_rocks_3 * 100
        seed = seed + seed_increment_number
        local noise_forest = perlin.noise(((pos_x + seed) / 100), ((pos_y + seed) / 100), 0)
        noise_forest = noise_forest * 100
        seed = seed + seed_increment_number
        local noise_forest_2 = perlin.noise(((pos_x + seed) / 20), ((pos_y + seed) / 20), 0)
        noise_forest_2 = noise_forest_2 * 20

        local terrain_smoothing = math.random(0, 1)
        local place_tree_number

        if noise_terrain_1 < 8 + terrain_smoothing + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
            tile_to_insert = 'red-desert-1'
            if
                noise_water_1 + noise_water_2 + noise_sand > -10 and noise_water_1 + noise_water_2 + noise_sand < 25 and
                    noise_terrain_1 < -52 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 + noise_terrain_5
             then
                tile_to_insert = 'sand-1'
                place_tree_number = math.random(3, #tree_to_place)
            else
                place_tree_number = math.random(1, (#tree_to_place - 3))
            end

            if
                noise_water_1 + noise_water_2 > 0 and noise_water_1 + noise_water_2 < 15 and
                    noise_terrain_1 < -60 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 + noise_terrain_5
             then
                tile_to_insert = 'water'
                local a = pos_x + 1
                table.insert(global.planet_tiles_hold, {name = tile_to_insert, position = {a, pos_y}})
                local a = pos_y + 1
                table.insert(global.planet_tiles_hold, {name = tile_to_insert, position = {pos_x, a}})
                local a = pos_x - 1
                table.insert(global.planet_tiles_hold, {name = tile_to_insert, position = {a, pos_y}})
                local a = pos_y - 1
                table.insert(global.planet_tiles_hold, {name = tile_to_insert, position = {pos_x, a}})
                if noise_water_1 + noise_water_2 < 2 or noise_water_1 + noise_water_2 > 13 then
                    if math.random(1, 15) == 1 then
                        table.insert(
                            global.planet_decoratives_hold,
                            {name = 'green-carpet-grass', position = {pos_x, pos_y}, amount = 1}
                        )
                    end
                end
            end

            if tile_to_insert ~= 'water' then
                if
                    noise_water_1 + noise_water_2 > 16 and noise_water_1 + noise_water_2 < 25 and
                        noise_terrain_1 < -55 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 + noise_terrain_5
                 then
                    if math.random(1, 35) == 1 then
                        table.insert(
                            global.planet_decoratives_hold,
                            {name = 'brown-carpet-grass', position = {pos_x, pos_y}, amount = 1}
                        )
                    end
                end
                if
                    noise_water_1 + noise_water_2 > -10 and noise_water_1 + noise_water_2 < -1 and
                        noise_terrain_1 < -55 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 + noise_terrain_5
                 then
                    if math.random(1, 35) == 1 then
                        table.insert(
                            global.planet_decoratives_hold,
                            {name = 'brown-carpet-grass', position = {pos_x, pos_y}, amount = 1}
                        )
                    end
                end
                if noise_decoratives_1 > 0.5 and noise_decoratives_1 <= 0.8 then
                    if math.random(1, 12) == 1 then
                        table.insert(
                            global.planet_decoratives_hold,
                            {name = 'red-desert-bush', position = {pos_x, pos_y}, amount = 1}
                        )
                    end
                end
                if noise_decoratives_1 > 0.4 and noise_decoratives_1 <= 0.5 then
                    if math.random(1, 4) == 1 then
                        table.insert(
                            global.planet_decoratives_hold,
                            {name = 'red-desert-bush', position = {pos_x, pos_y}, amount = 1}
                        )
                    end
                end
            end

            --HAPPY TREES
            if noise_terrain_1 < -30 + noise_terrain_2 + noise_terrain_3 + noise_terrain_5 + noise_forest_2 then
                if noise_forest > 0 and noise_forest <= 10 then
                    if math.random(1, 50) == 1 then
                        if surface.can_place_entity {name = tree_to_place[place_tree_number], position = {pos_x, pos_y}} then
                            surface.create_entity {name = tree_to_place[place_tree_number], position = {pos_x, pos_y}}
                        end
                    end
                end
                if noise_forest > 10 and noise_forest <= 20 then
                    if math.random(1, 25) == 1 then
                        if surface.can_place_entity {name = tree_to_place[place_tree_number], position = {pos_x, pos_y}} then
                            surface.create_entity {name = tree_to_place[place_tree_number], position = {pos_x, pos_y}}
                        end
                    end
                end
                if noise_forest > 20 then
                    if math.random(1, 10) == 1 then
                        if surface.can_place_entity {name = tree_to_place[place_tree_number], position = {pos_x, pos_y}} then
                            surface.create_entity {name = tree_to_place[place_tree_number], position = {pos_x, pos_y}}
                        end
                    end
                end
            end

            if tile_to_insert ~= 'water' then
                if
                    noise_terrain_1 < 8 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 and
                        noise_terrain_1 > -5 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4
                 then
                    if math.random(1, 180) == 1 then
                        table.insert(
                            global.planet_decoratives_hold,
                            {name = 'rock-medium', position = {pos_x, pos_y}, amount = 1}
                        )
                    end
                    if math.random(1, 80) == 1 then
                        table.insert(
                            global.planet_decoratives_hold,
                            {name = 'sand-rock-small', position = {pos_x, pos_y}, amount = 1}
                        )
                    end
                else
                    if math.random(1, 1500) == 1 then
                        table.insert(
                            global.planet_decoratives_hold,
                            {name = 'rock-medium', position = {pos_x, pos_y}, amount = 1}
                        )
                    end
                    if math.random(1, 180) == 1 then
                        table.insert(
                            global.planet_decoratives_hold,
                            {name = 'sand-rock-small', position = {pos_x, pos_y}, amount = 1}
                        )
                    end
                end
            end
        else
            tile_to_insert = 'red-desert-0'
        end
        if
            resource_entity_placed == false and noise_resources_coal_and_uranium + noise_resources < -72 and
                noise_terrain_1 > 65 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4
         then
            if surface.can_place_entity {name = 'uranium-ore', position = {pos_x, pos_y}} then
                surface.create_entity {name = 'uranium-ore', position = {pos_x, pos_y}, amount = resource_amount}
                resource_entity_placed = true
            end
        end
        if
            resource_entity_placed == false and noise_resources_iron_and_copper + noise_resources > 72 and
                noise_terrain_1 > 15 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4
         then
            if surface.can_place_entity {name = 'iron-ore', position = {pos_x, pos_y}} then
                surface.create_entity {name = 'iron-ore', position = {pos_x, pos_y}, amount = resource_amount}
                resource_entity_placed = true
            end
        end
        if
            resource_entity_placed == false and noise_resources_coal_and_uranium + noise_resources > 70 and
                noise_terrain_1 > 15 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4
         then
            if surface.can_place_entity {name = 'coal', position = {pos_x, pos_y}} then
                surface.create_entity {name = 'coal', position = {pos_x, pos_y}, amount = resource_amount}
                resource_entity_placed = true
            end
        end
        if
            resource_entity_placed == false and noise_resources_iron_and_copper + noise_resources < -72 and
                noise_terrain_1 > 15 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4
         then
            if surface.can_place_entity {name = 'copper-ore', position = {pos_x, pos_y}} then
                surface.create_entity {name = 'copper-ore', position = {pos_x, pos_y}, amount = resource_amount}
                resource_entity_placed = true
            end
        end
        if
            resource_entity_placed == false and noise_resources_stone_and_oil + noise_resources > 72 and
                noise_terrain_1 > 15 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4
         then
            if surface.can_place_entity {name = 'stone', position = {pos_x, pos_y}} then
                surface.create_entity {name = 'stone', position = {pos_x, pos_y}, amount = resource_amount}
                resource_entity_placed = true
            end
        end
        if
            resource_entity_placed == false and noise_resources_stone_and_oil + noise_resources < -70 and
                noise_terrain_1 < -50 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4
         then
            if math.random(1, 42) == 1 then
                if surface.can_place_entity {name = 'crude-oil', position = {pos_x, pos_y}} then
                    surface.create_entity {
                        name = 'crude-oil',
                        position = {pos_x, pos_y},
                        amount = (resource_amount * 500)
                    }
                    resource_entity_placed = true
                end
            end
        end

        if
            resource_entity_placed == false and
                noise_red_desert_rocks_1 + noise_red_desert_rocks_2 + noise_red_desert_rocks_3 > 20 and
                noise_red_desert_rocks_1 + noise_red_desert_rocks_2 < 60 and
                noise_terrain_1 > 7 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4
         then
            if math.random(1, 3) == 1 then
                if math.random(1, 3) == 1 then
                    if surface.can_place_entity {name = 'sand-rock-big', position = {pos_x, pos_y}} then
                        surface.create_entity {name = 'sand-rock-big', position = {pos_x, pos_y}}
                    end
                else
                    if surface.can_place_entity {name = 'sand-rock-big', position = {pos_x, pos_y}} then
                        surface.create_entity {name = 'sand-rock-big', position = {pos_x, pos_y}}
                    end
                end
            end
        end

        if
            noise_red_desert_rocks_1 + noise_red_desert_rocks_2 + noise_red_desert_rocks_3 + noise_terrain_4 >= 10 and
                noise_red_desert_rocks_1 + noise_red_desert_rocks_2 + noise_red_desert_rocks_3 < 20 and
                noise_terrain_1 > 7 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4
         then
            if math.random(1, 5) == 1 then
                table.insert(
                    global.planet_decoratives_hold,
                    {name = 'rock-medium', position = {pos_x, pos_y}, amount = 1}
                )
            end
        else
            if tile_to_insert ~= 'water' and tile_to_insert ~= 'sand-1' then
                if math.random(1, 15) == 1 then
                    table.insert(
                        global.planet_decoratives_hold,
                        {name = 'sand-rock-small', position = {pos_x, pos_y}, amount = 1}
                    )
                else
                    if math.random(1, 8) == 1 then
                        table.insert(
                            global.planet_decoratives_hold,
                            {name = 'sand-rock-small', position = {pos_x, pos_y}, amount = 1}
                        )
                    end
                end
            end
        end
        if tile_to_insert ~= 'water' then
            if noise_decoratives_2 > 0.6 then
                if math.random(1, 9) == 1 then
                    table.insert(
                        global.planet_decoratives_hold,
                        {name = 'red-asterisk', position = {pos_x, pos_y}, amount = 1}
                    )
                end
            else
                if noise_decoratives_2 > 0.4 then
                    if math.random(1, 17) == 1 then
                        table.insert(
                            global.planet_decoratives_hold,
                            {name = 'red-asterisk', position = {pos_x, pos_y}, amount = 1}
                        )
                    end
                end
            end
            if noise_decoratives_3 < -0.6 then
                if math.random(1, 2) == 1 then
                    table.insert(
                        global.planet_decoratives_hold,
                        {name = 'brown-fluff-dry', position = {pos_x, pos_y}, amount = 1}
                    )
                end
            else
                if noise_decoratives_3 < -0.4 then
                    if math.random(1, 5) == 1 then
                        table.insert(
                            global.planet_decoratives_hold,
                            {name = 'brown-fluff-dry', position = {pos_x, pos_y}, amount = 1}
                        )
                    end
                end
            end
        end
        table.insert(global.planet_tiles_hold, {name = tile_to_insert, position = {pos_x, pos_y}})
    end
end
