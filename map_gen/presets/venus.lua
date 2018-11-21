-- todo: remove all trees, plant trees in starting area/add wood to market, add market
-- market.add_market_item(item{price = {{market_item, 2}}, offer = {type = 'give-item', item = 'raw-wood'}})

local b = require 'map_gen.shared.builders'

local function value(base, mult)
    return function(x, y)
        return mult * (math.abs(x) + math.abs(y)) + base
    end
end

local function no_resources(_, _, world, tile)
    for _, e in ipairs(
        world.surface.find_entities_filtered(
            {type = 'resource', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
        )
    ) do
        e.destroy()
    end
    for _, e in ipairs(
        world.surface.find_entities_filtered(
            {type = 'tree', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
        )
    ) do
        e.destroy()
    end
    for _, e in ipairs(
        world.surface.find_entities_filtered(
            {type = 'rock', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
        )
    ) do
        e.destroy()
    end

    return tile
end

--[[local function no_trees(x, y, world, tile)
    for _, e in ipairs(
        world.surface.find_entities_filtered(
            {type = 'tree', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
        )
    ) do
        e.destroy()
    end

    return tile
end]]--

-- create a square on which to place each ore
local square = b.rectangle(12,12)
square = b.change_tile(square, true, 'lab-dark-2')

-- set the ore weights and sizes
local iron = b.resource(b.rectangle(12,12), 'iron-ore', value(200, 1))
local copper = b.resource(b.rectangle(12,12), 'copper-ore', value(150, 0.8))
local stone = b.resource(b.rectangle(12,12), 'stone', value(100, .5))
local coal = b.resource(b.rectangle(12,12), 'coal', value(100, 0.6))

-- place each ore on the square
local iron_sq = b.apply_entity(square, iron)
local copper_sq = b.apply_entity(square, copper)
local stone_sq = b.apply_entity(square, stone)
local coal_sq = b.apply_entity(square, coal)

-- create starting water square and change the type to water
local water_start =
        b.any {
        b.rectangle(12, 12)
    }
water_start = b.change_tile(water_start, true, 'water')

-- create the large safe square
local safe_square =  b.rectangle(80, 80)
safe_square = b.change_tile(safe_square, true, 'lab-dark-2')

-- create the start area using the ore, water and safe squares
local ore_distance = 24
local start_area =
    b.any {
    b.translate(iron_sq, -ore_distance, -ore_distance),
    b.translate(copper_sq, -ore_distance, ore_distance),
    b.translate(stone_sq, ore_distance, -ore_distance),
    b.translate(coal_sq, ore_distance, ore_distance),
    water_start,
    safe_square
}
start_area = b.apply_effect(start_area, no_resources)
--start_area = b.apply_effect(start_area, no_trees)


local map = start_area
map = b.change_map_gen_collision_tile(map, 'water-tile', 'grass-1')
map = b.change_tile(map, false, 'sand-1')
map = b.translate(map, 6, -10) -- translate the whole map away, otherwise we'll spawn in the water

--return start_area
return map
