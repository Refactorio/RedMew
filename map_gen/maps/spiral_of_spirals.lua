local b = require 'map_gen.shared.builders'
local table = require 'utils.table'
local Random = require 'map_gen.shared.random'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local ore_seed1 = 2000
local ore_seed2 = ore_seed1 * 2

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none,
        MGSP.enemy_none
    }
)

local random = Random.new(ore_seed1, ore_seed2)

local spiral = b.rectangular_spiral(1)

local factor = 9
local map = b.single_spiral_rotate_pattern(spiral, factor)

map = b.single_spiral_rotate_pattern(map, factor * factor)

map = b.scale(map, 64)

local function value(base, mult, pow)
    return function(x, y)
        local d_sq = x * x + y * y
        return base + mult * d_sq ^ (pow / 2) --d ^ pow
    end
end

local patch = b.rectangular_spiral(5)
local bounds = b.rectangle(46, 43)
bounds = b.translate(bounds, 0, 3)
patch = b.all {bounds, patch}

local patch_value = value(600, 0.75, 1.2)

local ores = {
    {resource = b.resource(b.full_shape, 'iron-ore', patch_value), weight = 6},
    {resource = b.resource(b.full_shape, 'copper-ore', patch_value), weight = 4},
    {resource = b.resource(b.full_shape, 'stone', patch_value), weight = 1},
    {resource = b.resource(b.full_shape, 'coal', patch_value), weight = 1}
}

local total_ore_weights = {}
local ore_t = 0
for _, v in ipairs(ores) do
    ore_t = ore_t + v.weight
    table.insert(total_ore_weights, ore_t)
end

local function do_ore(x, y, world)
    if not patch(x, y) then
        return nil
    end

    local i = math.random(ore_t)
    local index = table.binary_search(total_ore_weights, i)
    if (index < 0) then
        index = bit32.bnot(index)
    end

    return ores[index].resource(x, y, world)
end

local small_patch = b.rectangular_spiral(5)
local small_bounds = b.rectangle(25, 33)
small_bounds = b.translate(small_bounds, -1, -2)
small_patch = b.all {small_bounds, small_patch}
local oil_patch = b.throttle_world_xy(small_patch, 1, 5, 1, 5)

local resources = {
    {resource = do_ore, weight = 16},
    {resource = b.resource(oil_patch, 'crude-oil', value(75000, 50, 1.025)), weight = 5},
    {resource = b.resource(small_patch, 'uranium-ore', value(200, 0.3, 1.025)), weight = 2},
    {resource = b.no_entity, weight = 130}
}

local total_resource_weights = {}
local resource_t = 0
for _, v in ipairs(resources) do
    resource_t = resource_t + v.weight
    table.insert(total_resource_weights, resource_t)
end

local resource_pattern = {}
for r = 1, 50 do
    local row = {}
    resource_pattern[r] = row
    for c = 1, 50 do
        local i = random:next_int(1, resource_t)
        local index = table.binary_search(total_resource_weights, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end

        row[c] = resources[index].resource
    end
end

local resources_shape = b.grid_pattern(resource_pattern, 50, 50, 64, 64)

local start_stone =
    b.resource(
    patch,
    'stone',
    function()
        return 600
    end
)
local start_coal =
    b.resource(
    patch,
    'coal',
    function()
        return 2400
    end
)
local start_copper =
    b.resource(
    patch,
    'copper-ore',
    function()
        return 800
    end
)
local start_iron =
    b.resource(
    patch,
    'iron-ore',
    function()
        return 1600
    end
)
local start_spiral = b.segment_pattern({start_iron, start_copper, start_coal, start_stone})

start_spiral = b.translate(start_spiral, 0, -5)

local start_bounds = b.rectangle(64)

resources_shape = b.choose(start_bounds, start_spiral, resources_shape)

local worm_names = {'small-worm-turret', 'medium-worm-turret', 'big-worm-turret'}
local safe_d = 300
local half_spawn_d = 100000 -- distance at which there is a half chance of a worm spawning
local max_spawn_rate = 1 / 18
local level_factor = 32 -- higher factor -> more likly to spawn higher level worms
local min_big_worm_d = 900

local hd = 1 / (2 * half_spawn_d)
local inv_level_factor = 1 / level_factor

local function worms(_, _, world)
    local x, y = world.x, world.y
    local d = math.sqrt(x * x + y * y)

    d = d - safe_d
    if d <= 0 then
        return nil
    end

    local chance = d * hd
    if math.random() > math.min(chance, max_spawn_rate) then
        return nil
    end

    local lf = inv_level_factor / chance

    local lvl = math.floor(math.random() ^ lf * 3) + 1

    if d < min_big_worm_d and lvl == 3 then
        lvl = 2
    end

    return {name = worm_names[lvl]}
end

map = b.apply_entity(map, resources_shape)
map = b.apply_entity(map, worms)

map = b.change_map_gen_collision_tile(map, 'water-tile', 'grass-1')
map = b.change_tile(map, false, 'water')

map = b.fish(map, 0.0025)

return map
