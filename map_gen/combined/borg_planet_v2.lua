--Author: MewMew
-- !! ATTENTION !!
-- Use water only in starting area as map setting!!!
local perlin = require 'map_gen.shared.perlin_noise'
local Token = require 'utils.token'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local insert = table.insert
local random = math.random

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

RS.set_map_gen_settings({MGSP.water_none})

local ship_callback =
    Token.register(
    function(entity)
        entity.health = random(entity.health)

        entity.insert(wreck_item_pool[random(#wreck_item_pool)])
        entity.insert(wreck_item_pool[random(#wreck_item_pool)])
        entity.insert(wreck_item_pool[random(#wreck_item_pool)])
    end
)

local clear_types = {'simple-entity', 'tree'}

local function do_clear_entities(world)
    local entities = world.surface.find_entities_filtered({area = world.area, type = clear_types})
    for _, entity in ipairs(entities) do
        entity.destroy()
    end
end

local medium_health =
    Token.register(
    function(e)
        e.health = random(math.floor(e.health * 0.333), math.floor(e.health * 0.666))
    end
)

local low_health =
    Token.register(
    function(e)
        e.health = random(math.floor(e.health * 0.033), math.floor(e.health * 0.330))
    end
)

local turrent_callback =
    Token.register(
    function(e)
        if random(1, 3) == 1 then
            e.insert('piercing-rounds-magazine')
        else
            e.insert('firearm-magazine')
        end
    end
)

return function(_, _, world) -- luacheck: ignore 561
    local entities = {}

    local surface = world.surface

    if not world.island_resort_cleared then
        world.island_resort_cleared = true
        do_clear_entities(world)
    end

    local tile_to_insert = 'sand-1'

    local seed_increment_number = 10000
    local seed = surface.map_gen_settings.seed

    local noise_borg_defense_1 = perlin.noise(((world.x + seed) / 100), ((world.y + seed) / 100), 0)
    seed = seed + seed_increment_number
    local noise_borg_defense_2 = perlin.noise(((world.x + seed) / 20), ((world.y + seed) / 20), 0)
    seed = seed + seed_increment_number
    local noise_borg_defense = noise_borg_defense_1 + noise_borg_defense_2 * 0.15

    local noise_trees_1 = perlin.noise(((world.x + seed) / 50), ((world.y + seed) / 50), 0)
    seed = seed + seed_increment_number
    local noise_trees_2 = perlin.noise(((world.x + seed) / 15), ((world.y + seed) / 15), 0)
    seed = seed + seed_increment_number
    local noise_trees = noise_trees_1 + noise_trees_2 * 0.3

    local noise_walls_1 = perlin.noise(((world.x + seed) / 150), ((world.y + seed) / 150), 0)
    seed = seed + seed_increment_number
    local noise_walls_2 = perlin.noise(((world.x + seed) / 50), ((world.y + seed) / 50), 0)
    seed = seed + seed_increment_number
    local noise_walls_3 = perlin.noise(((world.x + seed) / 20), ((world.y + seed) / 20), 0)
    seed = seed + seed_increment_number
    local noise_walls = noise_walls_1 + noise_walls_2 * 0.1 + noise_walls_3 * 0.03

    if noise_borg_defense > 0.66 then
        if random(25) == 1 then
            insert(entities, {name = 'big-ship-wreck-1', force = 'player', callback = ship_callback})
        elseif random(25) == 1 then
            insert(entities, {name = 'big-ship-wreck-2', force = 'player', callback = ship_callback})
        elseif random(25) == 1 then
            insert(entities, {name = 'big-ship-wreck-3', force = 'player', callback = ship_callback})
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
        insert(entities, {name = 'substation', force = 'enemy'})
    end
    if noise_borg_defense >= 0.54 and noise_borg_defense < 0.65 then
        insert(entities, {name = 'solar-panel', force = 'enemy'})
    end
    if noise_borg_defense > 0.53 and noise_borg_defense < 0.54 then
        insert(entities, {name = 'substation', force = 'enemy'})
    end
    if noise_borg_defense >= 0.51 and noise_borg_defense < 0.53 then
        insert(entities, {name = 'accumulator', force = 'enemy'})
    end
    if noise_borg_defense >= 0.50 and noise_borg_defense < 0.51 then
        insert(entities, {name = 'substation', force = 'enemy'})
    end
    if noise_borg_defense >= 0.487 and noise_borg_defense < 0.50 then
        insert(entities, {name = 'laser-turret', force = 'enemy'})
    end
    if noise_borg_defense >= 0.485 and noise_borg_defense < 0.487 then
        insert(entities, {name = 'substation', force = 'enemy'})
    end
    if noise_borg_defense >= 0.45 and noise_borg_defense < 0.484 then
        insert(entities, {name = 'stone-wall', force = 'enemy'})
    end

    if noise_trees > 0.2 and tile_to_insert == 'sand-3' then
        if random(1, 15) == 1 then
            if random(1, 5) == 1 then
                insert(entities, {name = 'dry-hairy-tree'})
            else
                insert(entities, {name = 'dry-tree'})
            end
        end
    end

    if random(35000) == 1 then
        insert(entities, {name = 'big-ship-wreck-1', force = 'player', callback = ship_callback})
    elseif random(45000) == 1 then
        insert(entities, {name = 'big-ship-wreck-2', force = 'player', callback = ship_callback})
    elseif random(55000) == 1 then
        insert(entities, {name = 'big-ship-wreck-3', force = 'player', callback = ship_callback})
    elseif noise_walls > -0.03 and noise_walls < 0.03 and random(40) == 1 then
        insert(entities, {name = 'gun-turret', force = 'enemy', callback = turrent_callback})
    elseif noise_borg_defense > 0.41 and noise_borg_defense < 0.45 and random(15) == 1 then
        insert(entities, {name = 'gun-turret', force = 'enemy', callback = turrent_callback})
    elseif random(7500) == 1 then
        insert(entities, {name = 'pipe-to-ground', force = 'enemy'})
    elseif tile_to_insert ~= 'stone-path' and tile_to_insert ~= 'concrete' and random(1500) == 1 then
        insert(entities, {name = 'dead-dry-hairy-tree'})
    elseif tile_to_insert ~= 'stone-path' and tile_to_insert ~= 'concrete' and random(1500) == 1 then
        insert(entities, {name = 'dead-grey-trunk'})
    elseif random(25000) == 1 then
        insert(entities, {name = 'medium-ship-wreck', force = 'player', callback = medium_health})
    elseif random(15000) == 1 then
        insert(entities, {name = 'small-ship-wreck', force = 'player', callback = medium_health})
    elseif random(150000) == 1 then
        insert(entities, {name = 'car', force = 'player', callback = low_health})
    elseif random(100000) == 1 then
        insert(entities, {name = 'laser-turret', force = 'enemy', callback = low_health})
    elseif random(1000000) == 1 then
        insert(entities, {name = 'nuclear-reactor', force = 'enemy', callback = medium_health})
    end

    if noise_trees < -0.5 and (tile_to_insert == 'sand-3' or tile_to_insert == 'sand-1') and random(15) == 1 then
        insert(entities, {name = 'rock-big'})
    end

    local noise_water_1 = perlin.noise(((world.x + seed) / 200), ((world.y + seed) / 200), 0)
    seed = seed + seed_increment_number
    local noise_water_2 = perlin.noise(((world.x + seed) / 100), ((world.y + seed) / 100), 0)
    seed = seed + seed_increment_number
    local noise_water_3 = perlin.noise(((world.x + seed) / 25), ((world.y + seed) / 25), 0)
    seed = seed + seed_increment_number
    local noise_water_4 = perlin.noise(((world.x + seed) / 10), ((world.y + seed) / 10), 0)
    seed = seed + seed_increment_number
    local noise_water = noise_water_1 + noise_water_2 + noise_water_3 * 0.07 + noise_water_4 * 0.07

    noise_water_1 = perlin.noise(((world.x + seed) / 200), ((world.y + seed) / 200), 0)
    seed = seed + seed_increment_number
    noise_water_2 = perlin.noise(((world.x + seed) / 100), ((world.y + seed) / 100), 0)
    seed = seed + seed_increment_number
    noise_water_3 = perlin.noise(((world.x + seed) / 25), ((world.y + seed) / 25), 0)
    seed = seed + seed_increment_number
    noise_water_4 = perlin.noise(((world.x + seed) / 10), ((world.y + seed) / 10), 0)
    seed = seed + seed_increment_number
    noise_water_2 = noise_water_1 + noise_water_2 + noise_water_3 * 0.07 + noise_water_4 * 0.07

    if tile_to_insert ~= 'stone-path' and tile_to_insert ~= 'concrete' and noise_water > -0.15 and noise_water < 0.15 and noise_water_2 > 0.5 then
        tile_to_insert = 'water-green'
    end

    if noise_borg_defense <= 0.45 and tile_to_insert ~= 'water-green' then
        local a = -0.01
        local b = 0.01
        if noise_walls > a and noise_walls < b then
            insert(entities, {name = 'stone-wall', force = 'enemy'})
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

    local noise_decoratives_1 = perlin.noise(((world.x + seed) / 50), ((world.y + seed) / 50), 0)
    seed = seed + seed_increment_number
    local noise_decoratives_2 = perlin.noise(((world.x + seed) / 15), ((world.y + seed) / 15), 0)
    local noise_decoratives = noise_decoratives_1 + noise_decoratives_2 * 0.3

    local decoratives
    if noise_decoratives > 0.3 and noise_decoratives < 0.5 then
        if tile_to_insert ~= 'stone-path' and tile_to_insert ~= 'concrete' and tile_to_insert ~= 'water-green' and random(10) == 1 then
            decoratives = {name = 'red-desert-bush', amount = 1}
        end
    end

    return {tile = tile_to_insert, entities = entities, decoratives = decoratives}
end
