local b = require 'map_gen.shared.builders'
local Perlin = require 'map_gen.shared.perlin_noise'
local Global = require 'utils.global'
local math = require "utils.math"
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local oil_seed
local uranium_seed
local density_seed

local oil_scale = 1 / 64
local oil_threshold = 0.6

local uranium_scale = 1 / 128
local uranium_threshold = 0.65

local density_scale = 1 / 48
local density_threshold = 0.5
local density_multiplier = 50

RS.set_first_player_position_check_override(true)
RS.set_spawn_island_tile('grass-1')
RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none
    }
)

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
    end
)

local value = b.euclidean_value

local oil_shape = b.throttle_world_xy(b.full_shape, 1, 8, 1, 8)
local oil_resource = b.resource(oil_shape, 'crude-oil', value(150000, 100))

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
    b.resource(ore_circle, 'iron-ore', value(500, 0)),
    b.resource(ore_circle, 'copper-ore', value(250, 0)),
    b.resource(ore_circle, 'coal', value(500, 0)),
    b.resource(ore_circle, 'stone', value(250, 0))
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

local worms = {
    'small-worm-turret',
    'medium-worm-turret',
    'big-worm-turret'
}

local max_worm_chance = 1 / 384
local worm_chance_factor = 1 / (192 * 512)

local function enemy(_, _, world)
    local wx, wy = world.x, world.y
    local d = math.sqrt(wx * wx + wy * wy)

    local worm_chance = d - 128

    if worm_chance > 0 then
        worm_chance = worm_chance * worm_chance_factor
        worm_chance = math.min(worm_chance, max_worm_chance)

        if math.random() < worm_chance then
            if d < 384 then
                return {name = 'small-worm-turret'}
            else
                local max_lvl
                local min_lvl
                if d < 768 then
                    max_lvl = 2
                    min_lvl = 1
                else
                    max_lvl = 3
                    min_lvl = 2
                end
                local lvl = math.random() ^ (768 / d) * max_lvl
                lvl = math.ceil(lvl)
                lvl = math.clamp(lvl, min_lvl, 3)
                return {name = worms[lvl]}
            end
        end
    end
end

local water = b.circle(8)
water = b.change_tile(water, true, 'water')
water = b.any {b.rectangle(16, 4), b.rectangle(4, 16), water}

local start = b.if_else(water, b.full_shape)
start = b.change_map_gen_collision_tile(start, 'water-tile', 'grass-1')

local map = b.choose(ore_circle, start, b.full_shape)

map = b.apply_entity(map, ore)
map = b.apply_entity(map, enemy)

return map
