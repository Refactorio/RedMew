local b = require 'map_gen.shared.builders'
local Perlin = require 'map_gen.shared.perlin_noise'
local Event = require 'utils.event'
local Global = require 'utils.global'
local math = require "utils.math"
local RS = require 'map_gen.shared.redmew_surface'
local table = require 'utils.table'

local match = string.match
local remove = table.remove

local oil_seed
local uranium_seed
local density_seed
local enemy_seed

local oil_scale = 1 / 64
local oil_threshold = 0.6

local uranium_scale = 1 / 128
local uranium_threshold = 0.65

local density_scale = 1 / 48
local density_threshold = 0.5
local density_multiplier = 50

Global.register_init(
    {},
    function(tbl)
        tbl.seed = RS.get_surface().map_gen_settings.seed
    end,
    function(tbl)
        local seed = tbl.seed
        oil_seed = seed
        uranium_seed = seed * 2
        density_seed = seed * 3
        enemy_seed = seed * 4
    end
)

local market_items = require 'resources.market_items'
for i = #market_items, 1, -1 do
    if match(market_items[i].name, 'flamethrower') then
        remove(market_items, i)
    end
end

Event.add(
    defines.events.on_research_finished,
    function(event)
        local p_force = game.forces.player
        local r = event.research

        if r.name == 'flamethrower' then
            p_force.recipes['flamethrower'].enabled = false
            p_force.recipes['flamethrower-turret'].enabled = false
        end
    end
)

local trees = {
    'tree-01',
    'tree-02',
    'tree-02-red',
    'tree-03',
    'tree-04',
    'tree-05',
    'tree-06',
    'tree-06-brown',
    'tree-07',
    'tree-08',
    'tree-08-brown',
    'tree-08-red',
    'tree-09',
    'tree-09-brown',
    'tree-09-red'
}

local trees_count = #trees

local function tree_shape(_, _, world)
    local x, y = world.x, world.y
    local tree = trees[math.random(trees_count)]

    local dx = math.random(-1, 1)
    local dy = math.random(-1, 1)

    return {name = tree, position = {x + dx, y + dy}}
    --return {name = tree}
end

tree_shape = b.throttle_world_xy(tree_shape, 1, 2, 1, 2)

local worm_names = {'small-worm-turret', 'medium-worm-turret', 'big-worm-turret'}
local spawner_names = {'biter-spawner', 'spitter-spawner'}
local factor = 10 / (768 * 32)
local max_chance = 1 / 6

local scale_factor = 48
local sf = 1 / scale_factor
local m = 1 / 650
local function enemy(x, y, world)
    local d = math.sqrt(world.x * world.x + world.y * world.y)

    if d < 68 then
        return nil
    end

    if d < 100 then
        return tree_shape(x, y, world)
    end

    local threshold = 1 - d * m
    threshold = math.max(threshold, 0.5) -- -0.125)

    x, y = x * sf, y * sf
    if Perlin.noise(x, y, enemy_seed) > threshold then
        if math.random(8) == 1 then
            local lvl
            if d < 400 then
                lvl = 1
            elseif d < 650 then
                lvl = 2
            else
                lvl = 3
            end

            local chance = math.min(max_chance, d * factor)

            if math.random() < chance then
                local worm_id
                if d > 512 then
                    local power = 512 / d
                    worm_id = math.ceil((math.random() ^ power) * lvl)
                    worm_id = math.clamp(worm_id, 1, 3)
                else
                    worm_id = math.random(lvl)
                end

                return {name = worm_names[worm_id]}
            end
        else
            local chance = math.min(max_chance, d * factor)
            if math.random() < chance then
                local spawner_id = math.random(2)
                return {name = spawner_names[spawner_id]}
            end
        end
    else
        return tree_shape(x, y, world)
    end
end

local value = b.euclidean_value

local oil_shape = b.throttle_world_xy(b.full_shape, 1, 8, 1, 8)
local oil_resource = b.resource(oil_shape, 'crude-oil', value(250000, 200))

local uranium_resource = b.resource(b.full_shape, 'uranium-ore', value(200, 1))

local ores = {
    {resource = b.resource(b.full_shape, 'iron-ore', value(25, 0.5)), weight = 6},
    {resource = b.resource(b.full_shape, 'copper-ore', value(25, 0.5)), weight = 4},
    {resource = b.resource(b.full_shape, 'stone', value(25, 0.5)), weight = 1},
    {resource = b.resource(b.full_shape, 'coal', value(25, 0.5)), weight = 2}
}

local weighted_ores = b.prepare_weighted_array(ores)
local total_ores = weighted_ores.total

local spawn_zone = b.circle(64)

local ore_circle = b.circle(68)
local start_ores = {
    b.resource(ore_circle, 'iron-ore', value(100, 0)),
    b.resource(ore_circle, 'copper-ore', value(50, 0)),
    b.resource(ore_circle, 'coal', value(100, 0)),
    b.resource(ore_circle, 'stone', value(50, 0))
}

local start_segment = b.segment_pattern(start_ores)

local function ore(x, y, world)
    if spawn_zone(x, y) then
        return
    end

    local start_ore = start_segment(x, y, world)
    if start_ore then
        return start_ore
    end

    local oil_x, oil_y = x * oil_scale, y * oil_scale

    local oil_noise = Perlin.noise(oil_x, oil_y, oil_seed)
    if oil_noise > oil_threshold then
        return oil_resource(x, y, world)
    end

    local uranium_x, uranium_y = x * uranium_scale, y * uranium_scale
    local uranium_noise = Perlin.noise(uranium_x, uranium_y, uranium_seed)
    if uranium_noise > uranium_threshold then
        return uranium_resource(x, y, world)
    end

    local i = math.random() * total_ores
    local index = table.binary_search(weighted_ores, i)
    if (index < 0) then
        index = bit32.bnot(index)
    end

    local resource = ores[index].resource

    local entity = resource(x, y, world)
    local density_x, density_y = x * density_scale, y * density_scale
    local density_noise = Perlin.noise(density_x, density_y, density_seed)

    if density_noise > density_threshold then
        entity.amount = entity.amount * density_multiplier
    end
    entity.enable_tree_removal = false
    return entity
end

local water = b.circle(8)
water = b.change_tile(water, true, 'water-green')
water = b.any {b.rectangle(16, 4), b.rectangle(4, 16), water}

local start = b.if_else(water, b.full_shape)
start = b.change_map_gen_collision_tile(start, 'water-tile', 'grass-1')

local map = b.choose(ore_circle, start, b.full_shape)

map = b.apply_entity(map, ore)
map = b.apply_entity(map, enemy)

map = b.change_map_gen_tile(map, 'water', 'water-green')
map = b.change_map_gen_tile(map, 'deepwater', 'deepwater-green')

return map
