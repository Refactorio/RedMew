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

-- change these to change the pattern.
local seed1 = 9999
local seed2 = 6666

local function value(base, mult)
    return function(x, y)
        return mult * (math.abs(x) + math.abs(y)) + base
    end
end

local big_circle = circle_builder(48)
local small_circle = circle_builder(24)

local ring = compound_and{big_circle, invert(small_circle)}

local ores =
    {
        {resource_type = "iron-ore", value = value(125, 0.5)},
        {resource_type = "copper-ore", value = value(100, 0.4)},
        {resource_type = "stone", value = value(100, 0.2)},
        {resource_type = "coal", value = value(100, 0.1)},
        {resource_type = "uranium-ore", value = value(50, 0.1)},
        {resource_type = "crude-oil", value = value(10000, 50)},
    }

local iron = resource_module_builder(full_builder, ores[1].resource_type, ores[1].value)
local copper = resource_module_builder(full_builder, ores[2].resource_type, ores[2].value)
local stone = resource_module_builder(full_builder, ores[3].resource_type, ores[3].value)
local coal = resource_module_builder(full_builder, ores[4].resource_type, ores[4].value)
local uranium = resource_module_builder(full_builder, ores[5].resource_type, ores[5].value)
local oil = resource_module_builder(throttle_world_xy(full_builder, 1, 4, 1, 4), ores[6].resource_type, ores[6].value)

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

local segmented = segment_pattern_builder({iron, copper, stone, coal})

local tree = spawn_entity(throttle_world_xy(full_builder, 1, 3, 1, 3), "tree-01")

local start_iron = resource_module_builder(ring, ores[1].resource_type, value(500, 0.5))
local start_copper = resource_module_builder(ring, ores[2].resource_type, value(400, 0.5))
local start_stone = resource_module_builder(ring, ores[3].resource_type, value(300, 0.5))
local start_coal = resource_module_builder(ring, ores[4].resource_type, value(300, 0.5))
local start_segmented = segment_pattern_builder({start_iron, start_copper, start_stone, start_coal})
local start_tree = spawn_entity(throttle_world_xy(small_circle, 1, 3, 1, 3), "tree-01")

local iron_loop = builder_with_resource(ring, iron)
local copper_loop = builder_with_resource(ring, copper)
local stone_loop = builder_with_resource(ring, stone)
local coal_loop = builder_with_resource(ring, coal)
local uranium_loop = builder_with_resource(ring, uranium)
local oil_loop = builder_with_resource(ring, oil)
local striped_loop = builder_with_resource(ring, striped)
local sprinkle_loop = builder_with_resource(ring, sprinkle)
local segmented_loop = builder_with_resource(ring, segmented)
local tree_loop = builder_with_resource(ring, tree)
local start_loop = builder_with_resource(big_circle, compound_or{start_segmented, start_tree})

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
            
            shape = translate(shape, x, y)
            
            table.insert(row, shape)
        end
    end
end

local map = grid_pattern_overlap_builder(pattern, p_cols, p_rows, 128, 128)

map = change_map_gen_collision_tile(map, "water-tile", "grass-1")

local sea = change_tile(full_builder, true, "water")
local sea = spawn_fish(sea, 0.025)

map = shape_or_else(map, sea)

--map = translate(map, -32, 0)
--map = scale(map, 1, 1)
return map
