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
local seed1 = 1234
local seed2 = 5678

local value = manhattan_ore_value

local pic = require "map_gen.data.presets.fish"
local pic = decompress(pic)
local fish = picture_builder(pic)

fish = change_tile(fish, "water", false)

local ores =
    {
        {resource_type = "iron-ore", value = value(250, 1)},
        {resource_type = "copper-ore", value = value(200, 0.8)},
        {resource_type = "stone", value = value(200, 0.4)},
        {resource_type = "coal", value = value(400, 0.4)},
        {resource_type = "uranium-ore", value = value(50, 0.2)},
        {resource_type = "crude-oil", value = value(50000, 250)},
    }

local cap = translate(rectangle_builder(48, 48), 100, 0)

local iron = resource_module_builder(cap, ores[1].resource_type, ores[1].value)
local copper = resource_module_builder(cap, ores[2].resource_type, ores[2].value)
local stone = resource_module_builder(cap, ores[3].resource_type, ores[3].value)
local coal = resource_module_builder(cap, ores[4].resource_type, ores[4].value)
local uranium = resource_module_builder(cap, ores[5].resource_type, ores[5].value)
local oil = resource_module_builder(throttle_world_xy(cap, 1, 8, 1, 8), ores[6].resource_type, ores[6].value)

local iron_fish = builder_with_resource(fish, iron)
local copper_fish = builder_with_resource(fish, copper)
local stone_fish = builder_with_resource(fish, stone)
local coal_fish = builder_with_resource(fish, coal)
local uranium_fish = builder_with_resource(fish, uranium)
local oil_fish = builder_with_resource(fish, oil)

local fishes =
    {
        {iron_fish, 24},
        {copper_fish, 12},
        {stone_fish, 6},
        {coal_fish, 6},
        {uranium_fish, 1},
        {oil_fish, 4},
    }

local Random = require "map_gen.shared.random"
local random = Random.new(seed1, seed2)

local total_weights = {}
local t = 0
for _, v in pairs(fishes) do
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
        if (r <= 1) and (c <= 2 or c > p_cols - 1) then
            table.insert(row, empty_builder)
        else
            local i = random:next_int(1, t)
            
            local index = table.binary_search(total_weights, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end
            
            local shape = fishes[index][1]
            
            local x = random:next_int(-48, 48)
            local y = random:next_int(-48, 48)
            local r = random:next() * tau
            
            shape = rotate(shape, r)
            shape = translate(shape, x, y)
            
            table.insert(row, shape)
        end
    end
end

local map = grid_pattern_full_overlap_builder(pattern, p_cols, p_rows, 215, 215)

local start = require "map_gen.data.presets.soy_sauce"
start = decompress(start)
start = picture_builder(start)
start = change_tile(start, "water", false)

local pic = require "map_gen.data.presets.fish_black_and_white"
local pic = decompress(pic)
local fish_bw = picture_builder(pic)
fish_bw = scale(fish_bw, 0.25, 0.25)

local start_copper = rotate(fish_bw, degrees(180))
local start_stone = rotate(fish_bw, degrees(90))
local start_coal = rotate(fish_bw, degrees(-90))

local start_iron = translate(fish_bw, -32, 0)
start_copper = translate(start_copper, 32, 0)
start_stone = translate(start_stone, 0, 32)
start_coal = translate(start_coal, 0, -32)

start_iron = resource_module_builder(start_iron, ores[1].resource_type, value(1000, 0.5))
start_copper = resource_module_builder(start_copper, ores[2].resource_type, value(800, 0.5))
start_stone = resource_module_builder(start_stone, ores[3].resource_type, value(600, 0.5))
start_coal = resource_module_builder(start_coal, ores[4].resource_type, value(600, 0.5))

local start_oil = translate(rectangle_builder(1, 1), -44, 74)
start_oil = resource_module_builder(start_oil, ores[6].resource_type, value(100000, 0))

local worms = rectangle_builder(150, 72)
worms = translate(worms, 0, -210)
worms = spawn_entity(worms, "big-worm-turret")

local start = builder_with_resource(start, compound_or{start_iron, start_copper, start_stone, start_coal, start_oil, worms})

map = shape_or_else(start, map)

map = change_map_gen_collision_tile(map, "water-tile", "grass-1")

local sea = tile_builder("water")
local sea = spawn_fish(sea, 0.025)

map = shape_or_else(map, sea)

--map = scale(map, 2, 2)
return map
