local b = require "map_gen.shared.builders"

local pic = require "map_gen.data.presets.goat"
pic = b.decompress(pic)

local goat1 = b.picture(pic)
goat1 = b.invert(goat1)
local crop = b.rectangle(pic.width, pic.height)
goat1 = b.all{goat1, crop}

local floor = b.translate(b.rectangle(pic.width, 32), 0 , (pic.height / 2) + 12)

local goats = { floor, goat1 }

local sf = 0.75
local tf = 0.7
local s = 1
local t = 0
for i = 1, 5 do
    s = s * sf
    t = t + (s * tf * pic.height)
    local goat = b.translate(b.scale(goat1, s, s), 0, -t)
    table.insert( goats, goat )
end

local ceiling = b.translate(b.rectangle(pic.width, 32), 0 , -t - 32)
table.insert( goats, ceiling )

local shape = b.translate(b.any(goats), 0, (t / 2) - 60)

-- for custom goat ores
--[[
local function rot(table)
    local len = #table
    local copy = {}
    for i = 1, len -1 do
        copy[i+1] = table[i]
    end
    copy[1] = table[len]
    return copy
end

local patch = b.flip_x(goat1)
--patch = b.throttle_xy(patch, 1, 2, 1 ,2)
local iron_patch = b.resource(b.scale(patch,0.12,0.12), "iron-ore", function(x,y) return 500 end)
local copper_patch = b.resource(b.scale(patch,0.12,0.12), "copper-ore", function(x,y) return 500 end)
local coal_patch = b.resource(b.scale(patch,0.12,0.12), "coal", function(x,y) return 500 end)
local stone_patch = b.resource(b.scale(patch,0.12,0.12), "stone", function(x,y) return 500 end)
local uraniumn_patch = b.resource(b.scale(patch,0.12,0.12), "uraniumn-ore", function(x,y) return 500 end)
local oil_patch = b.resource(b.scale(patch,0.12,0.12), "crude-oil", function(x,y) return 500 end)
local patch1 = b.translate(b.scale(patch,0.2,0.2),0,170)
local patch2 = b.translate(b.scale(patch,0.15,0.15),0,25)
local patch3 = b.translate(b.scale(patch,0.12,0.12),0,-88)
local patch4 = b.translate(b.scale(patch,0.1,0.1),0,-173)
local patch5 = b.translate(b.scale(patch,0.08,0.08),0,-238)
local patch6 = b.translate(b.scale(patch,0.04,0.04),0,-282)
local patch_table = { patch1, patch2, patch3, patch4, patch5, patch6 }
local function do_nothing(builder, x, y) return builder(x, y) end
local function throttle(builder, x, y)
    if x % 4 < 1 and y % 4 < 1 then
        return builder(x, y)
    else
        return false
    end
end
local function linear(base, mult)
    return function(x, y)
        return base + (math.abs(x) + math.abs(y)) * mult
    end
end
local res1 = {do_nothing, "iron-ore", linear(500, 1) }
local res2 = {do_nothing,"copper-ore", linear(400, 0.8) }
local res3 = {do_nothing,"coal", linear(400, 0.7) }
local res4 = {do_nothing,"stone", linear(200, 0.6) }
local res5 = {do_nothing,"uranium-ore", linear(50, 0.1) }
local res6 = {throttle, "crude-oil", linear(18750, 300) }
local res_table = { res2, res3, res4, res5, res6, res1 }

local res_tables = {}
for i = 1, 6 do
    table.insert(res_tables, res_table)
    res_table = rot(res_table)
end
local function res_builder(x, y, world_x, world_y)
    local col_pos = math.floor(world_x / ISLAND_X_DISTANCE + 0.5)
    local row_pos = math.floor(world_y / ISLAND_Y_DISTANCE + 0.5)
    local offset = ((math.abs(col_pos) + math.abs(row_pos)) % 6) + 1
    local rt = res_tables[offset]
    for k, v in ipairs(patch_table) do
            local r = rt[k]
            local f = r[1]
            local name = r[2]
            local amount = r[3]
        if f(v,x,y) then
            return name, amount(world_x, world_y)
        end
    end
end
--local patches = b.any(patch_table)
--local iron = b.resource(patches,"iron-ore", function(x,y) return 400 end)
--local iron_goat = b.apply_entity(shape, iron)
local res_goat = b.apply_entity(shape, res_builder)
shape = res_goat
--]]

local shape2 = b.flip_x(shape)
local shape3 = b.flip_y(shape)
local shape4 = b.flip_y(shape2)

local pattern =
{
    {shape, shape2},
    {shape3, shape4},
}

local map = b.grid_pattern(pattern, 2, 2, pic.width, pic.height + t - 105)
map = b.change_map_gen_collision_tile(map,"water-tile", "water-green")

return map
