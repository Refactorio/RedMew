local b = require 'map_gen.shared.builders'
local math = require 'utils.math'
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local degrees = math.degrees

-- change these to change the pattern and scale
local seed1 = 12345
local seed2 = 56789
local fish_scale = 1.75

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.peaceful_mode_on,
        MGSP.water_none
    }
)

local value = b.exponential_value

local pic = require 'map_gen.data.presets.fish'
pic = b.decompress(pic)
local fish = b.picture(pic)

fish = b.change_tile(fish, 'water', false)
fish = b.scale(fish, fish_scale)

local ores = {
    {resource_type = 'iron-ore', value = value(75, 0.25, 1.15)},
    {resource_type = 'copper-ore', value = value(65, 0.2, 1.15)},
    {resource_type = 'stone', value = value(50, 0.2, 1.1)},
    {resource_type = 'coal', value = value(50, 0.15, 1.1)},
    {resource_type = 'uranium-ore', value = value(10, 0.1, 1.075)},
    {resource_type = 'crude-oil', value = value(25000, 25, 1.15)}
}

local cap = b.translate(b.rectangle(48 * fish_scale, 48 * fish_scale), 100 * fish_scale, 0)
local rich_tile = b.rectangle(3, 3)
rich_tile = b.translate(rich_tile, 100 * fish_scale, 0)
local function rich_value()
    return 1111111
end

local iron =
    b.any {
    b.resource(rich_tile, ores[1].resource_type, rich_value),
    b.resource(cap, ores[1].resource_type, ores[1].value)
}
local copper =
    b.any {
    b.resource(rich_tile, ores[2].resource_type, rich_value),
    b.resource(cap, ores[2].resource_type, ores[2].value)
}
local stone =
    b.any {
    b.resource(rich_tile, ores[3].resource_type, rich_value),
    b.resource(cap, ores[3].resource_type, ores[3].value)
}
local coal =
    b.any {
    b.resource(rich_tile, ores[4].resource_type, rich_value),
    b.resource(cap, ores[4].resource_type, ores[4].value)
}
local uranium =
    b.any {
    b.resource(rich_tile, ores[5].resource_type, rich_value),
    b.resource(cap, ores[5].resource_type, ores[5].value)
}
local oil = b.resource(b.throttle_world_xy(cap, 1, 8, 1, 8), ores[6].resource_type, ores[6].value)

local worm_names = {
    'small-worm-turret',
    'medium-worm-turret',
    'big-worm-turret'
}

local max_worm_chance = 1 / 64
local worm_chance_factor = 1 / 256

local function worms(x, y, world)
    if not cap(x, y) then
        return nil
    end
    local wx, wy = world.x, world.y
    local d = math.sqrt(wx * wx + wy * wy)

    local worm_chance = d - 64

    if worm_chance > 0 then
        worm_chance = worm_chance * worm_chance_factor
        worm_chance = math.min(worm_chance, max_worm_chance)

        if math.random() < worm_chance then
            if d < 512 then
                return {name = 'small-worm-turret'}
            else
                local max_lvl
                local min_lvl
                if d < 1024 then
                    max_lvl = 2
                    min_lvl = 1
                else
                    max_lvl = 3
                    min_lvl = 2
                end
                local lvl = math.random() ^ (512 / d) * max_lvl
                lvl = math.ceil(lvl)
                lvl = math.clamp(lvl, min_lvl, 3)
                return {name = worm_names[lvl]}
            end
        end
    end
end

local iron_fish = b.apply_entities(fish, {iron, worms})
local copper_fish = b.apply_entities(fish, {copper, worms})
local stone_fish = b.apply_entities(fish, {stone, worms})
local coal_fish = b.apply_entities(fish, {coal, worms})
local uranium_fish = b.apply_entities(fish, {uranium, worms})
local oil_fish = b.apply_entities(fish, {oil, worms})

local fishes = {
    {iron_fish, 24},
    {copper_fish, 12},
    {stone_fish, 6},
    {coal_fish, 6},
    {uranium_fish, 1},
    {oil_fish, 4}
}

local Random = require 'map_gen.shared.random'
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
            local angle = random:next() * math.tau

            shape = b.rotate(shape, angle)
            shape = b.translate(shape, x, y)

            table.insert(row, shape)
        end
    end
end

local map = b.grid_pattern_full_overlap(pattern, p_cols, p_rows, 215 * fish_scale, 215 * fish_scale)

local start = require 'map_gen.data.presets.soy_sauce'
start = b.decompress(start)
start = b.picture(start)
start = b.change_tile(start, 'water', false)

pic = require 'map_gen.data.presets.fish_black_and_white'
pic = b.decompress(pic)
local fish_bw = b.picture(pic)
fish_bw = b.scale(fish_bw, 0.25, 0.25)

local start_copper = b.rotate(fish_bw, degrees(180))
local start_stone = b.rotate(fish_bw, degrees(90))
local start_coal = b.rotate(fish_bw, degrees(-90))

local start_iron = b.translate(fish_bw, -32, 0)
start_copper = b.translate(start_copper, 32, 0)
start_stone = b.translate(start_stone, 0, 32)
start_coal = b.translate(start_coal, 0, -32)

start_iron = b.resource(start_iron, ores[1].resource_type, value(1000, 0.5, 1))
start_copper = b.resource(start_copper, ores[2].resource_type, value(800, 0.5, 1))
start_stone = b.resource(start_stone, ores[3].resource_type, value(600, 0.5, 1))
start_coal = b.resource(start_coal, ores[4].resource_type, value(600, 0.5, 1))

local start_oil = b.translate(b.rectangle(1, 1), -44, 74)
start_oil = b.resource(start_oil, ores[6].resource_type, value(100000, 0, 1))

local worms_area = b.rectangle(150, 72)
worms_area = b.translate(worms_area, 0, -210)

local function worms_top(x, y, world)
    if worms_area(x, y) then
        local entities = world.surface.find_entities {{world.x, world.y}, {world.x + 1, world.y + 1}}
        for _, e in ipairs(entities) do
            e.destroy()
        end
        return {name = 'big-worm-turret'}
    end
end

--worms = b.entity(worms, 'big-worm-turret')

start = b.apply_entity(start, b.any {start_iron, start_copper, start_stone, start_coal, start_oil, worms_top})

map = b.if_else(start, map)

map = b.change_map_gen_collision_tile(map, 'water-tile', 'grass-1')

local sea = b.tile('water')
sea = b.fish(sea, 0.0025)

map = b.if_else(map, sea)

--map = b.scale(map, 2, 2)

--map = b.apply_entity(b.full_shape, iron)

return map
