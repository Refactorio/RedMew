map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 4 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local seed1 = 666
local seed2 = 999

local function value(a, b)
    return 1000000
end

local Random = require "map_gen.shared.random"
local random = Random.new(seed1, seed2)

local pic = require "map_gen.data.presets.cookie"
local pic = decompress(pic)
local cookie1 = picture_builder(pic)
local cookie = scale(cookie1, 0.1, 0.1)

local ore_shape = circle_builder(1.5)

local ores = {
    {resource_module_builder(ore_shape, "iron-ore", value), 24},
    {resource_module_builder(ore_shape, "copper-ore", value), 12},
    {resource_module_builder(ore_shape, "stone", value), 4},
    {resource_module_builder(ore_shape, "coal", value), 8},
    {resource_module_builder(ore_shape, "uranium-ore", value), 1},
    {resource_module_builder(circle_builder(1), "crude-oil", manhattan_ore_value(250000, 250)), 3},
--{empty_builder, 10}
}

local total_weights = {}
local t = 0
for _, v in pairs(ores) do
    t = t + v[2]
    table.insert(total_weights, t)
end

local function makeChips()
    local n = random:next_int(1, t)
    
    local index = table.binary_search(total_weights, n)
    if (index < 0) then
        index = bit32.bnot(index)
    end
    
    local shape = ores[index][1]
    if shape == empty_builder then
        return nil
    end
    
    local chips = {}
    for i = 1, 6 do
        local x_offset = random:next_int(-20, 20)
        local y_offset = random:next_int(-20, 20)
        
        local shape2 = translate(shape, x_offset, y_offset)
        
        table.insert(chips, shape2)
    end
    
    return chips
end

local p_cols = 50
local p_rows = 50
local pattern = {}

for c = 1, p_cols do
    local row = {}
    table.insert(pattern, row)
    for r = 1, p_rows do
        local chips = makeChips()
        
        local shape
        if chips then
            shape = builder_with_resource(cookie, compound_or(chips))
        else
            shape = cookie
        end
        
        local angle = random:next_int(-30, 30)
        local s = random:next() * .25 + 1
        local x_offset = random:next_int(-8, 8)
        local y_offset = random:next_int(-8, 8)
        
        shape = rotate(shape, degrees(angle))
        shape = scale(shape, s, s * 0.75)
        shape = translate(shape, x_offset, y_offset)
        
        table.insert(row, shape)
    end
end

local cookies = grid_pattern_full_overlap_builder(pattern, p_cols, p_rows, 64 * 1.25, 41 * 1.25 * 0.5)
cookies = flip_y(cookies)

local tablecloth = {
    height = 2,
    width = 2,
    data = {
        {"concrete", "water"},
        {"water", "deepwater", }
    }
}
local tablecloth = picture_builder(tablecloth)
tablecloth = single_pattern_builder(tablecloth, 2, 2)
tablecloth = scale(tablecloth, 42, 42)
tablecloth = spawn_fish(tablecloth, 0.005)

map = shape_or_else(cookies, tablecloth)

return map
