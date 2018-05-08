--[[
This map uses custom ore gen. When generating the map, under the resource settings tab use Size = 'None' for all resources.
This map removes and adds it's own water, in terrain settings use water frequency = very low and water size = only in starting area.
This map has isolated areas, it's recommend turning biters to peaceful to reduce stress on the pathfinder.
]]

local b = require "map_gen.shared.builders"

-- change these to change the pattern.
local seed1 = 1234
local seed2 = 5678

local value = b.manhattan_value

local pic = require "map_gen.data.presets.fish"
local pic = b.decompress(pic)
local fish = b.picture(pic)

fish = b.change_tile(fish, "water", false)

local ores =
    {
        {resource_type = "iron-ore", value = value(250, 1)},
        {resource_type = "copper-ore", value = value(200, 0.8)},
        {resource_type = "stone", value = value(200, 0.4)},
        {resource_type = "coal", value = value(400, 0.4)},
        {resource_type = "uranium-ore", value = value(50, 0.2)},
        {resource_type = "crude-oil", value = value(50000, 250)},
    }

local cap = b.translate(b.rectangle(48, 48), 100, 0)

local iron = b.resource(cap, ores[1].resource_type, ores[1].value)
local copper = b.resource(cap, ores[2].resource_type, ores[2].value)
local stone = b.resource(cap, ores[3].resource_type, ores[3].value)
local coal = b.resource(cap, ores[4].resource_type, ores[4].value)
local uranium = b.resource(cap, ores[5].resource_type, ores[5].value)
local oil = b.resource(b.throttle_world_xy(cap, 1, 8, 1, 8), ores[6].resource_type, ores[6].value)

local iron_fish = b.apply_entity(fish, iron)
local copper_fish = b.apply_entity(fish, copper)
local stone_fish = b.apply_entity(fish, stone)
local coal_fish = b.apply_entity(fish, coal)
local uranium_fish = b.apply_entity(fish, uranium)
local oil_fish = b.apply_entity(fish, oil)

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
            table.insert(row, b.empty_shape)
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
            
            shape = b.rotate(shape, r)
            shape = b.translate(shape, x, y)
            
            table.insert(row, shape)
        end
    end
end

local map = b.grid_pattern_full_overlap(pattern, p_cols, p_rows, 215, 215)

local start = require "map_gen.data.presets.soy_sauce"
start = b.decompress(start)
start = b.picture(start)
start = b.change_tile(start, "water", false)

local pic = require "map_gen.data.presets.fish_black_and_white"
local pic = b.decompress(pic)
local fish_bw = b.picture(pic)
fish_bw = b.scale(fish_bw, 0.25, 0.25)

local start_copper = b.rotate(fish_bw, degrees(180))
local start_stone = b.rotate(fish_bw, degrees(90))
local start_coal = b.rotate(fish_bw, degrees(-90))

local start_iron = b.translate(fish_bw, -32, 0)
start_copper = b.translate(start_copper, 32, 0)
start_stone = b.translate(start_stone, 0, 32)
start_coal = b.translate(start_coal, 0, -32)

start_iron = b.resource(start_iron, ores[1].resource_type, value(1000, 0.5))
start_copper = b.resource(start_copper, ores[2].resource_type, value(800, 0.5))
start_stone = b.resource(start_stone, ores[3].resource_type, value(600, 0.5))
start_coal = b.resource(start_coal, ores[4].resource_type, value(600, 0.5))

local start_oil = b.translate(b.rectangle(1, 1), -44, 74)
start_oil = b.resource(start_oil, ores[6].resource_type, value(100000, 0))

local worms = b.rectangle(150, 72)
worms = b.translate(worms, 0, -210)
worms = b.entity(worms, "big-worm-turret")

local start = b.apply_entity(start, b.any{start_iron, start_copper, start_stone, start_coal, start_oil, worms})

map = b.if_else(start, map)

map = b.change_map_gen_collision_tile(map, "water-tile", "grass-1")

local sea = b.tile("water")
local sea = b.fish(sea, 0.025)

map = b.if_else(map, sea)

--map = b.scale(map, 2, 2)
return map
