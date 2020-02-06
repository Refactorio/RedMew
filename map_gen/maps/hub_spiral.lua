local b = require 'map_gen.shared.builders'
local math = require "utils.math"
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none,
        MGSP.enemy_none
    }
)

local value = b.exponential_value

local ore_shape = b.circular_spiral_grow_n_threads(16, 128, 2048, 8)
ore_shape = b.flip_x(ore_shape)

local iron = b.apply_entity(b.full_shape, b.resource(ore_shape, 'iron-ore', value(200, 0.5, 1.075), true))
local copper = b.apply_entity(b.full_shape, b.resource(ore_shape, 'copper-ore', value(125, 0.4, 1.075), true))
local stone = b.apply_entity(b.full_shape, b.resource(ore_shape, 'stone', value(200, 0.15, 1.01), true))
local coal = b.apply_entity(b.full_shape, b.resource(ore_shape, 'coal', value(400, 0.2, 1.025), true))
local uranium = b.apply_entity(b.full_shape, b.resource(ore_shape, 'uranium-ore', value(50, 0.1, 1.01), true))
local oil =
    b.apply_entity(
    b.full_shape,
    b.resource(b.throttle_world_xy(ore_shape, 1, 8, 1, 8), 'crude-oil', value(150000, 5, 1.05), true)
)
local tree = b.apply_entity(b.full_shape, b.entity(ore_shape, 'tree-01'))
local rock = b.apply_entity(b.full_shape, b.entity(ore_shape, 'rock-big'))

local walk_spiral1 = b.circular_spiral_n_threads(3, 512, 8)
walk_spiral1 = b.flip_x(walk_spiral1)
walk_spiral1 = b.choose(b.circle(206), b.empty_shape, walk_spiral1)
walk_spiral1 = b.change_tile(walk_spiral1, true, 'water')

local walk_spiral2 = b.circular_spiral_n_threads(7, 512, 8)
walk_spiral2 = b.flip_x(walk_spiral2)
walk_spiral2 = b.choose(b.circle(206), walk_spiral2, b.empty_shape)
walk_spiral2 = b.choose(b.circle(72), b.empty_shape, walk_spiral2)

local map = b.circular_spiral_grow_pattern(16, 32, 512, {tree, iron, stone, coal, rock, copper, uranium, oil})

local start_cirle = b.circle(64)
start_cirle = b.change_map_gen_collision_tile(start_cirle, 'water-tile', 'grass-1')
local spawn_water = b.circle(4)
spawn_water = b.translate(spawn_water, 0, 6)
spawn_water = b.change_tile(spawn_water, true, 'water')
spawn_water = b.fish(spawn_water, 1)
start_cirle = b.any {spawn_water, start_cirle}

map = b.any {start_cirle, walk_spiral1, map, walk_spiral2}

local worm_names = {
    'small-worm-turret',
    'medium-worm-turret',
    'big-worm-turret'
}

local max_worm_chance = 1 / 128
local worm_chance_factor = 1 / (192 * 512)

local function worms(_, _, world)
    local wx, wy = world.x, world.y
    local d = math.sqrt(wx * wx + wy * wy)

    local worm_chance = d - 160

    if worm_chance > 0 then
        worm_chance = worm_chance * worm_chance_factor
        worm_chance = math.min(worm_chance, max_worm_chance)

        if math.random() < worm_chance then
            if d < 256 then
                return {name = 'small-worm-turret'}
            else
                local max_lvl
                local min_lvl
                if d < 512 then
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

map = b.apply_entity(map, worms)

return map
