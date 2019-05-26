-- Map by grilledham & Jayefuu

local b = require 'map_gen.shared.builders'
local math = require 'utils.math'
local table = require 'utils.table'
local degrees = math.rad
local ore_seed1 = 7000
local ore_seed2 = ore_seed1 * 2
local noise = require 'map_gen.shared.perlin_noise'.noise
local abs = math.abs


local Random = require 'map_gen.shared.random'
local random = Random.new(ore_seed1, ore_seed2)
local math_random = math.random

local enable_sand_border = false

local function value(base, mult, pow)
    return function(x, y)
        local d_sq = x * x + y * y
        return base + mult * d_sq ^ (pow / 2) -- d ^ pow
    end
end

-- Removes vanilla resources when called
local function no_resources(_, _, world, tile)
    for _, e in ipairs(
        world.surface.find_entities_filtered(
            {type = 'resource', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
        )
    ) do
        e.destroy()
    end
    return tile
end

local m_t_width = 12 -- map size in number of tiles
local t_width = 16 -- tile width
local t_h_width = t_width / 2

-- https://wiki.factorio.com/Data.raw#tile for the tile types you can send to this function
local function two_tone_square(inner, outer) -- r_tile is a bool flag to show if it should have chance of resources on it
    local outer_tile = b.any {b.rectangle(t_width, t_width)}
    outer_tile = b.change_tile(outer_tile, true, outer)
    local inner_tile = b.any {b.rectangle(t_width - 2, t_width - 2)}
    inner_tile = b.change_tile(inner_tile, true, inner)
    local land_tile = b.any {inner_tile, outer_tile}

    return land_tile
end

local tet_bounds = b.rectangle(t_width * 4)
tet_bounds = b.translate(tet_bounds, t_width, t_width)
local function tetrify(pattern, block)
    for r = 1, 4 do
        local row = pattern[r]
        for c = 1, 4 do
            if row[c] == 1 then
                row[c] = block
            else
                row[c] = b.empty_shape()
            end
        end
    end
    local grid = b.grid_pattern(pattern, 4, 4, t_width, t_width)
    grid = b.translate(grid, -t_width / 2, -t_width / 2)
    grid = b.choose(tet_bounds, grid, b.empty_shape)
    grid = b.translate(grid, -t_width, -t_width)
    return grid
end

local tet_O =
    tetrify(
    {
        {0, 0, 0, 0},
        {0, 1, 1, 0},
        {0, 1, 1, 0},
        {0, 0, 0, 0}
    },
    two_tone_square('dirt-7', 'sand-1')
)

local tet_I =
    tetrify(
    {
        {0, 1, 0, 0},
        {0, 1, 0, 0},
        {0, 1, 0, 0},
        {0, 1, 0, 0}
    },
    two_tone_square('grass-2', 'sand-1')
)

local tet_J =
    tetrify(
    {
        {0, 0, 0, 0},
        {0, 0, 1, 0},
        {0, 0, 1, 0},
        {0, 1, 1, 0}
    },
    two_tone_square('grass-1', 'sand-1')
)

local tet_L =
    tetrify(
    {
        {0, 0, 0, 0},
        {0, 1, 0, 0},
        {0, 1, 0, 0},
        {0, 1, 1, 0}
    },
    two_tone_square('dirt-4', 'sand-1')
)

local tet_S =
    tetrify(
    {
        {0, 0, 0, 0},
        {0, 1, 1, 0},
        {1, 1, 0, 0},
        {0, 0, 0, 0}
    },
    two_tone_square('grass-4', 'sand-1')
)

local tet_Z =
    tetrify(
    {
        {0, 0, 0, 0},
        {1, 1, 0, 0},
        {0, 1, 1, 0},
        {0, 0, 0, 0}
    },
    two_tone_square('grass-3', 'sand-1')
)

local tet_T =
    tetrify(
    {
        {0, 0, 0, 0},
        {0, 1, 0, 0},
        {1, 1, 1, 0},
        {0, 0, 0, 0}
    },
    two_tone_square('red-desert-2', 'sand-1')
)

local tetriminos = {tet_I, tet_O, tet_T, tet_S, tet_Z, tet_J, tet_L}
local tetriminos_count = #tetriminos

local quarter = math.tau / 4

local p_cols = 1 --m_t_width / 4
local p_rows = 50
local pattern = {}

for _ = 1, p_rows do
    local row = {}
    table.insert(pattern, row)
    for _ = 1, p_cols do
        local i = random:next_int(1, tetriminos_count * 1.5)
        local shape = tetriminos[i] or b.empty_shape

        local angle = random:next_int(0, 3) * quarter
        shape = b.rotate(shape, angle)

        local x_offset = random:next_int(-10, 8) * t_width
        shape = b.translate(shape, x_offset, 0)

        table.insert(row, shape)
    end
end

local ore_shape = b.rectangle(t_width * 0.8)
local oil_shape = b.throttle_world_xy(ore_shape, 1, 4, 1, 4)

local ores = {
    {b.resource(ore_shape, 'iron-ore', value(50, 0.225, 1.15)), 10},
    {b.resource(ore_shape, 'copper-ore', value(40, 0.225, 1.15)), 6},
    {b.resource(ore_shape, 'stone', value(70, 0.12, 1.075)), 3},
    {b.resource(ore_shape, 'coal', value(40, 0.24, 1.075)), 5},
    {b.resource(b.scale(ore_shape, 0.5), 'uranium-ore', value(60, 0.09, 1.05)), 2},
    {b.resource(oil_shape, 'crude-oil', value(120000, 50, 1.15)), 1},
    {b.empty_shape, 100}
}

local total_weights = {}
local t = 0
for _, v in pairs(ores) do
    t = t + v[2]
    table.insert(total_weights, t)
end

p_cols = 50
p_rows = 50

pattern = {}

for _ = 1, p_rows do
    local row = {}
    table.insert(pattern, row)
    for _ = 1, p_cols do
        local i = random:next_int(1, t)

        local index = table.binary_search(total_weights, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end

        local shape = ores[index][1]
        table.insert(row, shape)
    end
end

local worm_names = {
    'small-worm-turret',
    'medium-worm-turret',
    'big-worm-turret'
}

local max_worm_chance = 1 / 128
local max_spawner_chance = 1/64
local worm_chance_factor = 1 / (192 * 512)

local function worms(position)
    local d = abs(position.y)
    local worm_chance = d - 300

    if worm_chance > 0 then
        worm_chance = worm_chance * worm_chance_factor
        worm_chance = math.min(worm_chance, max_worm_chance)

        if math_random() < worm_chance then
            if d < 600 then
                return {name = 'small-worm-turret', position = position}
            else
                local max_lvl
                local min_lvl
                if d < 800 then
                    max_lvl = 2
                    min_lvl = 1
                else
                    max_lvl = 3
                    min_lvl = 2
                end
                local lvl = math_random() ^ (512 / d) * max_lvl
                lvl = math.ceil(lvl)
                lvl = math.clamp(lvl, min_lvl, 3)
                return {name = worm_names[lvl], position = position}
            end
        end
    end
end

local spawner_names = {
    'spitter-spawner',
    'biter-spawner'
}

local function spawners(position)

    local spawner_chance = abs(position.y) - 600

    if spawner_chance > 0 then
        spawner_chance = spawner_chance * worm_chance_factor
        spawner_chance = math.min(spawner_chance, max_spawner_chance)

        if math_random() < spawner_chance then
            return {name = spawner_names[math_random(1,2)], position = position}
        end
    end
end

-- Starting area
local start_patch = b.rectangle(t_width * 0.8)
    local start_iron_patch =
        b.resource(
        b.translate(start_patch, -t_width/2, -t_width/2),
        'iron-ore',
        function()
            return 1500
        end
    )
    local start_copper_patch =
        b.resource(
        b.translate(start_patch, t_width/2, -t_width/2),
        'copper-ore',
        function()
            return 1200
        end
    )
    local start_stone_patch =
        b.resource(
        b.translate(start_patch, t_width/2, t_width/2),
        'stone',
        function()
            return 900
        end
    )
    local start_coal_patch =
        b.resource(
        b.translate(start_patch, -t_width/2, t_width/2),
        'coal',
        function()
            return 1350
        end
    )
local start_resources = b.any({start_iron_patch, start_copper_patch, start_stone_patch, start_coal_patch})
local tet_O_start = b.apply_entity(tet_O, start_resources)

local starting_area = b.any{
    b.translate(tet_I,t_width,-t_width*2),
    b.translate(tet_O_start,t_width*2,-t_width),
    b.translate(tet_T,-t_width,-t_width),
    b.translate(tet_Z,-t_width*6,-t_width),
    b.translate(tet_L,-t_width*8,-t_width*2)
}

ores = b.grid_pattern_overlap(pattern, p_cols, p_rows, t_width, t_width)
ores = b.translate(ores, t_h_width, t_h_width)

local water_tile = two_tone_square('water', 'deepwater')
local half_sea_width = m_t_width * t_width - t_width
local function sea_bounds(x, y)
    return x > -half_sea_width and x < half_sea_width and y < 0
end

local sea = b.single_grid_pattern(water_tile, t_width, t_width)
sea = b.translate(sea, t_h_width, -t_h_width)
sea = b.choose(sea_bounds, sea, b.empty_shape)

local map = b.choose(sea_bounds, starting_area, b.empty_shape)
map = b.if_else(map, sea)

local half_border_width = half_sea_width + t_width
local function border_bounds(x, y)
    return x > -half_border_width and x < half_border_width and y < t_width
end

border_bounds = b.subtract(border_bounds, sea_bounds)
local border = b.change_tile(border_bounds, true, 'sand-1')
if enable_sand_border then
    map = b.add(map, border)
end
local music_island = b.translate(b.rotate(tet_I,degrees(90)),0, 2*t_width)
map = b.add(map,music_island)
map = b.translate(map, 0, -t_width / 2 + 24)

map = b.apply_effect(map, no_resources)

local bounds = t_width * 2

local Module = {}

local bounds_size = t_width * 4

function Module.spawn_tetri(surface, pos, number)
    local tiles = {}
    local shape = tetriminos[number]

    local offset = math_random(1,1000) * bounds_size

    local create_entity = surface.create_entity

    local tree = 'tree-0' .. math_random(1,9)

    for x = -bounds, bounds do
        for y = -bounds, bounds do
            local x2, y2 = x + 0.5, y + 0.5
            local name = shape(x2, y2)
            if name then
                local position = {x = pos.x + x, y = pos.y + y}
                table.insert(tiles, {name = name, position = position})

                if math_random() > 0.8 and (noise(0.02 * x, 0.02 * y,0)) > 0.3 then
                    create_entity {name = tree, position = position}
                else
                    local n = math_random(1, 599)
                    if n > 590 then
                        create_entity{name = 'tree-0' .. n % 10, position = position}
                    end
                end

                local ore = ores(x2, y2 - offset, position)
                if ore then
                    ore.position = position
                    ore.enable_tree_removal = false
                    create_entity(ore)
                end

                local worm = worms(position)
                if worm then
                    create_entity(worm)
                else
                    local spawner = spawners(position)
                    if spawner then
                        create_entity(spawner)
                    end
                end
            end
        end
    end
    surface.set_tiles(tiles)
end

Module.disable = function()
    tetriminos = {}
end

Module.get_map = function()
    return map
end

return Module
