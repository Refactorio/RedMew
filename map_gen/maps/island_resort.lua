-- Original author: MewMew
local perlin = require 'map_gen.shared.perlin_noise'
local b = require 'map_gen.shared.builders'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings' -- map gen settings presets

local random = math.random
local max = math.max
local abs = math.abs
local noise = perlin.noise

local radius = 129
local radsquare = radius * radius

local start_seed = 1234567

RS.set_map_gen_settings(
    {
        MGSP.tree_none,
        MGSP.ore_oil_none,
        MGSP.enemy_very_high,
        MGSP.cliff_none,
        MGSP.grass_only,
        MGSP.enable_water
    }
)

local function map(x, y, world)
    local entities = {}
    local decoratives = {}

    local seed = start_seed
    local seed_increment = 10000

    seed = seed + seed_increment
    local noise_island_starting_1 = noise(((x + seed) / 30), ((y + seed) / 30), 0)
    seed = seed + seed_increment
    local noise_island_starting_2 = noise(((x + seed) / 10), ((y + seed) / 10), 0)
    seed = seed + seed_increment
    local noise_island_starting = noise_island_starting_1 + (noise_island_starting_2 * 0.3)
    noise_island_starting = noise_island_starting * 8000

    seed = seed + seed_increment
    local noise_island_iron_and_copper_1 = noise(((x + seed) / 300), ((y + seed) / 300), 0)
    seed = seed + seed_increment
    local noise_island_iron_and_copper_2 = noise(((x + seed) / 40), ((y + seed) / 40), 0)
    seed = seed + seed_increment
    local noise_island_iron_and_copper_3 = noise(((x + seed) / 10), ((y + seed) / 10), 0)
    local noise_island_iron_and_copper = noise_island_iron_and_copper_1 + (noise_island_iron_and_copper_2 * 0.1) + (noise_island_iron_and_copper_3 * 0.05)

    seed = seed + seed_increment
    local noise_island_stone_and_coal_1 = noise(((x + seed) / 300), ((y + seed) / 300), 0)
    seed = seed + seed_increment
    local noise_island_stone_and_coal_2 = noise(((x + seed) / 40), ((y + seed) / 40), 0)
    seed = seed + seed_increment
    local noise_island_stone_and_coal_3 = noise(((x + seed) / 10), ((y + seed) / 10), 0)
    local noise_island_stone_and_coal = noise_island_stone_and_coal_1 + (noise_island_stone_and_coal_2 * 0.1) + (noise_island_stone_and_coal_3 * 0.05)

    seed = seed + seed_increment
    local noise_island_oil_and_uranium_1 = noise(((x + seed) / 300), ((y + seed) / 300), 0)
    seed = seed + seed_increment
    local noise_island_oil_and_uranium_2 = noise(((x + seed) / 40), ((y + seed) / 40), 0)
    seed = seed + seed_increment
    local noise_island_oil_and_uranium_3 = noise(((x + seed) / 10), ((y + seed) / 10), 0)
    local noise_island_oil_and_uranium = noise_island_oil_and_uranium_1 + (noise_island_oil_and_uranium_2 * 0.1) + (noise_island_oil_and_uranium_3 * 0.05)

    seed = seed + seed_increment
    local noise_island_resource = noise(((x + seed) / 60), ((y + seed) / 60), 0)
    seed = seed + seed_increment
    local noise_island_resource_2 = noise(((x + seed) / 10), ((y + seed) / 10), 0)
    noise_island_resource = noise_island_resource + noise_island_resource_2 * 0.15

    seed = seed + seed_increment
    local noise_trees_1 = noise(((x + seed) / 30), ((y + seed) / 30), 0)
    seed = seed + seed_increment
    local noise_trees_2 = noise(((x + seed) / 10), ((y + seed) / 10), 0)
    local noise_trees = noise_trees_1 + noise_trees_2 * 0.5

    seed = seed + seed_increment
    local noise_decoratives_1 = noise(((x + seed) / 50), ((y + seed) / 50), 0)
    seed = seed + seed_increment
    local noise_decoratives_2 = noise(((x + seed) / 10), ((y + seed) / 10), 0)
    local noise_decoratives = noise_decoratives_1 + noise_decoratives_2 * 0.5

    local tile_to_insert = 'water'

    --Create starting Island
    local dist_1 = y * y
    local dist_2 = x * x
    local tile_distance_to_center = dist_1 + dist_2
    if tile_distance_to_center + noise_island_starting <= radsquare then
        tile_to_insert = 'grass-1'
    end

    if tile_distance_to_center + noise_island_starting > radsquare + 20000 then
        --Placement of Island Tiles

        if noise_island_oil_and_uranium > 0.53 then
            tile_to_insert = 'red-desert-1'
        end
        if noise_island_oil_and_uranium < -0.53 then
            tile_to_insert = 'red-desert-0'
        end

        if noise_island_stone_and_coal > 0.47 then
            tile_to_insert = 'grass-3'
        end
        if noise_island_stone_and_coal < -0.47 then
            tile_to_insert = 'grass-2'
        end

        if noise_island_iron_and_copper > 0.47 then
            tile_to_insert = 'sand-1'
        end
        if noise_island_iron_and_copper < -0.47 then
            tile_to_insert = 'sand-3'
        end
    end

    --Placement of Trees
    if tile_to_insert ~= 'water' then
        if noise_trees > 0.1 then
            local tree = 'tree-01'
            if tile_to_insert == 'grass-1' then
                tree = 'tree-05'
            end
            if tile_to_insert == 'grass-2' then
                tree = 'tree-02'
            end
            if tile_to_insert == 'grass-3' then
                tree = 'tree-04'
            end
            if tile_to_insert == 'sand-1' then
                tree = 'tree-07'
            end
            if tile_to_insert == 'sand-3' then
                tree = 'dry-hairy-tree'
            end
            if tile_to_insert == 'red-desert-1' then
                tree = 'dry-tree'
            end
            if tile_to_insert == 'red-desert-0' then
                if random(1, 3) == 1 then
                    tree = 'sand-rock-big'
                else
                    tree = 'sand-rock-big'
                end
            end
            if random(1, 8) == 1 then
                entities[#entities + 1] = {name = tree}
            end
        end
    end

    if tile_to_insert == 'sand-1' or tile_to_insert == 'sand-3' then
        if random(1, 200) == 1 then
            entities[#entities + 1] = {name = 'rock-big'}
        end
    end
    if tile_to_insert == 'grass-1' or tile_to_insert == 'grass-2' or tile_to_insert == 'grass-3' then
        if random(1, 2000) == 1 then
            entities[#entities + 1] = {name = 'rock-big'}
        end
    end

    --Placement of Decoratives
    if tile_to_insert ~= 'water' then
        if noise_decoratives > 0.3 then
            local decorative = 'green-carpet-grass-1'
            if tile_to_insert == 'grass-1' then
                decorative = 'green-pita'
            end
            if tile_to_insert == 'grass-2' then
                decorative = 'green-pita'
            end
            if tile_to_insert == 'grass-3' then
                decorative = 'green-pita'
            end
            if tile_to_insert == 'sand-1' then
                decorative = 'green-asterisk'
            end
            if tile_to_insert == 'sand-3' then
                decorative = 'green-asterisk'
            end
            if tile_to_insert == 'red-desert-1' then
                decorative = 'red-asterisk'
            end
            if tile_to_insert == 'red-desert-0' then
                decorative = 'red-asterisk'
            end
            if random(1, 5) == 1 then
                decoratives[#decoratives + 1] = {name = decorative, position = {x, y}, amount = 1}
            end
        end
        if tile_to_insert == 'red-desert-0' then
            if random(1, 50) == 1 then
                decoratives[#decoratives + 1] = {name = 'rock-medium', position = {x, y}, amount = 1}
            end
        end
    end

    --Placement of Island Resources
    if tile_to_insert ~= 'water' then
        local c = max(abs(world.x), abs(world.y))

        local resource_amount_distance_multiplicator = (((c + 1) / 75) / 75) + 1
        local noise_resource_amount_modifier = noise(((world.x + seed) / 200), ((world.y + seed) / 200), 0)
        local resource_amount = 1 + ((500 + (500 * noise_resource_amount_modifier * 0.2)) * resource_amount_distance_multiplicator)

        if tile_to_insert == 'sand-1' or tile_to_insert == 'sand-3' then
            if noise_island_iron_and_copper > 0.5 and noise_island_resource > 0.2 then
                entities[#entities + 1] = {name = 'iron-ore', amount = resource_amount}
            end
            if noise_island_iron_and_copper < -0.5 and noise_island_resource > 0.2 then
                entities[#entities + 1] = {name = 'copper-ore', amount = resource_amount}
            end
        end

        if tile_to_insert == 'grass-3' or tile_to_insert == 'grass-2' then
            if noise_island_stone_and_coal > 0.5 and noise_island_resource > 0.2 then
                entities[#entities + 1] = {name = 'stone', amount = resource_amount}
            end
            if noise_island_stone_and_coal < -0.5 and noise_island_resource > 0.2 then
                entities[#entities + 1] = {name = 'coal', amount = resource_amount}
            end
        end

        if tile_to_insert == 'red-desert-1' or tile_to_insert == 'red-desert-0' then
            if noise_island_oil_and_uranium > 0.55 and noise_island_resource > 0.25 and random(60) == 1 then
                entities[#entities + 1] = {name = 'crude-oil', amount = resource_amount * 400}
            end
            if noise_island_oil_and_uranium < -0.55 and noise_island_resource > 0.35 then
                entities[#entities + 1] = {name = 'uranium-ore', amount = resource_amount}
            end
        end

        noise_island_starting = noise_island_starting * 0.08
        --Starting Resources
        if tile_distance_to_center <= radsquare then
            if tile_distance_to_center + noise_island_starting > radsquare * 0.09 and tile_distance_to_center + noise_island_starting <= radsquare * 0.15 then
                entities[#entities + 1] = {name = 'stone', amount = resource_amount * 1.5}
            end
            if tile_distance_to_center + noise_island_starting > radsquare * 0.05 and tile_distance_to_center + noise_island_starting <= radsquare * 0.09 then
                entities[#entities + 1] = {name = 'coal', amount = resource_amount * 1.5}
            end
            if tile_distance_to_center + noise_island_starting > radsquare * 0.02 and tile_distance_to_center + noise_island_starting <= radsquare * 0.05 then
                entities[#entities + 1] = {name = 'iron-ore', amount = resource_amount * 1.5}
            end
            if tile_distance_to_center + noise_island_starting > radsquare * 0.003 and tile_distance_to_center + noise_island_starting <= radsquare * 0.02 then
                entities[#entities + 1] = {name = 'copper-ore', amount = resource_amount * 1.5}
            end
            if tile_distance_to_center + noise_island_starting <= radsquare * 0.002 then
                entities[#entities + 1] = {name = 'crude-oil', amount = resource_amount * 400}
            end
        end
    end

    return {tile = tile_to_insert, entities = entities, decoratives = decoratives}
end

return b.fish(map, 0.0025)
