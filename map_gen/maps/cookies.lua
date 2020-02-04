local b = require "map_gen.shared.builders"
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local degrees = require "utils.math".degrees

local seed1 = 666
local seed2 = 999

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none
    }
)

local function value()
    return 1000000
end

local Random = require "map_gen.shared.random"
local random = Random.new(seed1, seed2)

local pic = require "map_gen.data.presets.cookie"
pic = b.decompress(pic)
local cookie1 = b.picture(pic)
local cookie = b.scale(cookie1, 0.1, 0.1)

local ore_shape = b.circle(1.5)

local ores = {
    {b.resource(ore_shape, "iron-ore", value), 24},
    {b.resource(ore_shape, "copper-ore", value), 12},
    {b.resource(ore_shape, "stone", value), 4},
    {b.resource(ore_shape, "coal", value), 8},
    {b.resource(ore_shape, "uranium-ore", value), 1},
    {b.resource(b.circle(1), "crude-oil", b.manhattan_value(250000, 250)), 3},
--{b.empty_shape, 10}
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
    if shape == b.empty_shape then
        return nil
    end

    local chips = {}
    for i = 1, 6 do
        local x_offset = random:next_int(-20, 20)
        local y_offset = random:next_int(-20, 20)

        local shape2 = b.translate(shape, x_offset, y_offset)

        table.insert(chips, shape2)
    end

    return chips
end

local p_cols = 50
local p_rows = 50
local pattern = {}

for _ = 1, p_cols do
    local row = {}
    table.insert(pattern, row)
    for _ = 1, p_rows do
        local chips = makeChips()

        local shape
        if chips then
            shape = b.apply_entity(cookie, b.any(chips))
        else
            shape = cookie
        end

        local angle = random:next_int(-30, 30)
        local s = random:next() * .25 + 1
        local x_offset = random:next_int(-8, 8)
        local y_offset = random:next_int(-8, 8)

        shape = b.rotate(shape, degrees(angle))
        shape = b.scale(shape, s, s * 0.75)
        shape = b.translate(shape, x_offset, y_offset)

        table.insert(row, shape)
    end
end

local cookies = b.grid_pattern_full_overlap(pattern, p_cols, p_rows, 64 * 1.25, 41 * 1.25 * 0.5)
cookies = b.flip_y(cookies)

local tablecloth = {
    height = 2,
    width = 2,
    data = {
        {"concrete", "water"},
        {"water", "deepwater", }
    }
}
tablecloth = b.picture(tablecloth)
tablecloth = b.single_pattern(tablecloth, 2, 2)
tablecloth = b.scale(tablecloth, 42, 42)
tablecloth = b.fish(tablecloth, 0.005)

local map = b.if_else(cookies, tablecloth)

return map
