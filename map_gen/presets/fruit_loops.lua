--[[
This map uses custom ore gen. When generating the map, under the resource settings tab use Size = 'None' for all resources.
This map removes and adds it's own water, in terrain settings use water frequency = very low and water size = only in starting area.
This map has isolated areas, it's recommend turning biters to peaceful to reduce stress on the pathfinder.
]]
map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 4 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local b = require "map_gen.shared.builders"

-- change these to change the pattern.
local seed1 = 9999
local seed2 = 6666

local function value(base, mult)
    return function(x, y)
        return mult * (math.abs(x) + math.abs(y)) + base
    end
end

local big_circle = b.circle(48)
local small_circle = b.circle(24)

local ring = b.all{big_circle, b.invert(small_circle)}

local ores =
    {
        {resource_type = "iron-ore", value = value(125, 0.5)},
        {resource_type = "copper-ore", value = value(100, 0.4)},
        {resource_type = "stone", value = value(100, 0.2)},
        {resource_type = "coal", value = value(100, 0.1)},
        {resource_type = "uranium-ore", value = value(50, 0.1)},
        {resource_type = "crude-oil", value = value(10000, 50)},
    }

local iron = b.resource(b.full_shape, ores[1].resource_type, ores[1].value)
local copper = b.resource(b.full_shape, ores[2].resource_type, ores[2].value)
local stone = b.resource(b.full_shape, ores[3].resource_type, ores[3].value)
local coal = b.resource(b.full_shape, ores[4].resource_type, ores[4].value)
local uranium = b.resource(b.full_shape, ores[5].resource_type, ores[5].value)
local oil = b.resource(b.throttle_world_xy(b.full_shape, 1, 4, 1, 4), ores[6].resource_type, ores[6].value)

local function striped(x, y, world_x, world_y, surface)
    local t = (world_x + world_y) % 4 + 1
    local ore = ores[t]
    
    return {
        name = ore.resource_type,
        position = {world_x, world_y},
        amount = ore.value(world_x, world_y)
    }
end

local function sprinkle(x, y, world_x, world_y, surface)
    
    local t = math.random(1, 4)
    local ore = ores[t]
    
    return {
        name = ore.resource_type,
        position = {world_x, world_y},
        amount = ore.value(world_x, world_y)
    }
end

local segmented = b.segment_pattern({iron, copper, stone, coal})

local tree = b.entity(b.throttle_world_xy(b.full_shape, 1, 3, 1, 3), "tree-01")

local start_iron = b.resource(ring, ores[1].resource_type, value(500, 0.5))
local start_copper = b.resource(ring, ores[2].resource_type, value(400, 0.5))
local start_stone = b.resource(ring, ores[3].resource_type, value(300, 0.5))
local start_coal = b.resource(ring, ores[4].resource_type, value(300, 0.5))
local start_segmented = b.segment_pattern({start_iron, start_copper, start_stone, start_coal})
local start_tree = b.entity(b.throttle_world_xy(small_circle, 1, 3, 1, 3), "tree-01")

local iron_loop = b.apply_entity(ring, iron)
local copper_loop = b.apply_entity(ring, copper)
local stone_loop = b.apply_entity(ring, stone)
local coal_loop = b.apply_entity(ring, coal)
local uranium_loop = b.apply_entity(ring, uranium)
local oil_loop = b.apply_entity(ring, oil)
local striped_loop = b.apply_entity(ring, striped)
local sprinkle_loop = b.apply_entity(ring, sprinkle)
local segmented_loop = b.apply_entity(ring, segmented)
local tree_loop = b.apply_entity(ring, tree)
local start_loop = b.apply_entity(big_circle, b.any{start_segmented, start_tree})

local loops =
    {
        {striped_loop, 3},
        {sprinkle_loop, 3},
        {segmented_loop, 3},
        {tree_loop, 6},
        {iron_loop, 24},
        {copper_loop, 12},
        {stone_loop, 9},
        {coal_loop, 9},
        {uranium_loop, 9},
        {oil_loop, 9},
    }

local Random = require "map_gen.shared.random"
local random = Random.new(seed1, seed2)

local total_weights = {}
local t = 0
for _, v in pairs(loops) do
    t = t + v[2]
    table.insert(total_weights, t)
end

local p_cols = 50
local p_rows = 50
local pattern = {}

for c = 1, p_cols do
    local row = {}
    table.insert(pattern, row)
    for r = 1, p_rows do
        if c == 1 and r == 1 then
            table.insert(row, start_loop)
        else
            local i = random:next_int(1, t)
            
            local index = table.binary_search(total_weights, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end
            
            local shape = loops[index][1]
            
            local x = random:next_int(-32, 32)
            local y = random:next_int(-32, 32)
            
            shape = b.translate(shape, x, y)
            
            table.insert(row, shape)
        end
    end
end

local map = b.grid_pattern_full_overlap(pattern, p_cols, p_rows, 128, 128)

map = b.change_map_gen_collision_tile(map, "water-tile", "grass-1")

local sea = b.change_tile(b.full_shape, true, "water")
local sea = b.fish(sea, 0.025)

map = b.if_else(map, sea)

--map = b.translate(map, -32, 0)
--map = b.scale(map, 1, 1)
return map
