local Global = require 'utils.global'

local resource_rate = 768 -- Number of tiles per resouce on average.

local seed = nil -- Set to number to force seed.
local generator

Global.register_init(
    {},
    function(tbl)
        tbl.generator = game.create_random_generator()
        tbl.seed = seed or game.surfaces[1].map_gen_settings.seed
    end,
    function(tbl)
        generator = tbl.generator
        seed = tbl.seed
    end
)

local function value(base, mult, pow)
    return function(x, y)
        local d = math.sqrt(x * x + y * y)
        return base + mult * d ^ pow
    end
end

local ores = {
    {'iron-ore', value(40000, 20, 1.5), 100},
    {'copper-ore', value(40000, 20, 1.5), 60},
    {'coal', value(40000, 20, 1.25), 25},
    {'stone', value(20000, 20, 1.25), 15},
    {'uranium-ore', value(5000, 5, 1.35), 5},
    {'crude-oil', value(600000, 200, 1.25), 4}
}

local total_weights = {}
local t = 0
for _, v in ipairs(ores) do
    t = t + v[3]
    table.insert(total_weights, t)
end

t = resource_rate * t
table.insert(ores, {false})
table.insert(total_weights, t)

return function(x, y)
    local r_seed = bit32.band(x * 374761393 + y * 668265263 + seed, 4294967295)
    generator.re_seed(r_seed)
    local i = generator(t)

    local index = table.binary_search(total_weights, i)
    if (index < 0) then
        index = bit32.bnot(index)
    end

    local ore_data = ores[index]
    local ore = ore_data[1]
    if not ore then
        return
    end

    local amount = ore_data[2](x, y)

    return {name = ore, amount = amount}
end
