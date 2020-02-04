-- Map by Jayefuu and grilled ham, concept by claude47, 2018-12-02

-- Hover over the market and run:
--      /silent-command game.player.selected.add_market_item{price={{MARKET_ITEM, 100}}, offer={type="give-item", item="landfill"}}


local b = require 'map_gen.shared.builders'
local math = require "utils.math"
local Perlin = require 'map_gen.shared.perlin_noise'
local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local degrees = math.rad

local enemy_seed = 420420

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none,
        MGSP.enemy_none,
        MGSP.peaceful_mode_on
    }
)

local function value(base, mult, pow)
    return function(x, y)
        local d_sq = x * x + y * y
        return base + mult * d_sq ^ (pow / 2) -- d ^ pow
    end
end

local spiral = b.circular_spiral(80, 90)
spiral = b.any {spiral, b.translate(b.circle(128), 12, -12)}

local wide_spiral = b.circular_spiral(60, 90)       -- looks prettier, for use with starting ore and water
wide_spiral = b.any {wide_spiral, b.translate(b.circle(128), 12, -12)}

-- provides a shortcut between the spirals, at the cost of expensive landfill from the market
local function water_cross(x,y)
    local abs_x = math.abs(x)
    local abs_y = math.abs(y)
    return not (abs_x > 4 and abs_y > 4)
end
water_cross = b.change_tile(water_cross, true, 'water')

-- make a spiral starting ore patch
local start_ore_patch = b.scale(wide_spiral, 0.1)
local function constant(amount)
    return function()
        return amount
    end
end
local iron = b.resource(start_ore_patch, 'iron-ore', constant(500))
local copper = b.resource(start_ore_patch, 'copper-ore', constant(500))
local stone = b.resource(start_ore_patch, 'stone', constant(500))
local coal = b.resource(start_ore_patch, 'coal', constant(500))
start_ore_patch = b.segment_pattern {iron, copper, stone, coal}
local start_ore_bounds = b.circle(32)
start_ore_patch = b.choose(start_ore_bounds, start_ore_patch, b.empty_shape)
start_ore_patch = b.translate(start_ore_patch, 0, 32)

-- make some starting water
local start_water = b.scale(wide_spiral, 0.1)
start_water = b.choose(b.circle(26), start_water, b.empty_shape)
start_water = b.change_tile(start_water, true, 'water')
start_water = b.translate(start_water,0,-130)

-- ore generation
local patch = b.circle(18)
local small_patch = b.circle(12)
local patches = b.single_x_pattern(patch, 90)
local patches_wide = b.single_x_pattern(patch, 180)
local patches_wide_small = b.single_x_pattern(small_patch, 180)

local iron_patches = b.resource(patches, 'iron-ore', value(500, 0.8, 1.075))
local copper_patches = b.resource(patches, 'copper-ore',  value(400, 0.75, 1.1))
local coal_patches = b.resource(patches_wide, 'coal',  value(650, 0.75, 1.1))
local stone_patches = b.resource(patches_wide, 'stone',  value(400, 0.75, 1.1))
local oil_patches = b.resource(b.throttle_world_xy(patches_wide_small,1,6,1,6), 'crude-oil', value(33000, 50, 1.05))
local uranium_patches = b.resource(patches_wide_small, 'uranium-ore', value(200, 0.75, 1.1))

local function ore_arm_bounds(x, _)
    return x < 20
end

iron_patches = b.translate(b.choose(ore_arm_bounds, iron_patches, b.empty_shape),-160,0)
copper_patches = b.translate(b.choose(ore_arm_bounds, copper_patches, b.empty_shape),-210,0)
stone_patches = b.translate(b.choose(ore_arm_bounds, stone_patches, b.empty_shape),-230,0)
uranium_patches = b.translate(b.choose(ore_arm_bounds, uranium_patches, b.empty_shape),-320,0)
coal_patches = b.translate(b.choose(ore_arm_bounds, coal_patches, b.empty_shape),-180,0)
oil_patches = b.translate(b.choose(ore_arm_bounds, oil_patches, b.empty_shape),-270,0)

spiral = b.change_tile(spiral, true, 'grass-1')
spiral = b.apply_entity(spiral, b.rotate(coal_patches,degrees(45)))
spiral = b.apply_entity(spiral, b.rotate(oil_patches,degrees(45))) -- oil and coal have double spacing so they are interleaved
spiral = b.apply_entity(spiral, b.rotate(iron_patches,degrees(45+90)))
spiral = b.apply_entity(spiral, b.rotate(stone_patches,degrees(45+180)))
spiral = b.apply_entity(spiral, b.rotate(uranium_patches,degrees(45+180))) -- stone and uranium have double spacing so they are interleaved
spiral = b.apply_entity(spiral, b.rotate(copper_patches,degrees(45+270)))

-- Re-add the spawners we removed at the beginning so we can apply a pattern (cross) to their positions, aligning them with the ores
local worm_names = {'small-worm-turret', 'medium-worm-turret', 'big-worm-turret'}
local spawner_names = {'biter-spawner', 'spitter-spawner'}
local factor = 16 / (1024 * 32)
local max_chance = 1 / 4

local scale_factor = 4
local sf = 1 / scale_factor
local m = 1 / 600
local function enemy(x, y, world)
    local d = math.sqrt(world.x * world.x + world.y * world.y)

    if d < 80 then
        return nil
    end

    local threshold = 1 - d * m
    threshold = math.max(threshold, 0.5) -- -0.125)

    x, y = x * sf, y * sf
    if Perlin.noise(x, y, enemy_seed) > threshold then
        if math.random(8) <= 2 then
            local lvl
            if d < 300 then
                lvl = 1
            elseif d < 650 then
                lvl = 2
            else
                lvl = 3
            end

            local chance = math.min(max_chance, d * factor)

            if math.random() < chance then
                local worm_id
                if d > 1000 then
                    local power = 1000 / d
                    worm_id = math.ceil((math.random() ^ power) * lvl)
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
    end
end

-- Maltese cross shape so the biter patches get wider the further from base
local gradient = 0.1
local tiles_half = (50) * 0.5
local function enemy_cross(x,y)
    local abs_x = math.abs(x)
    local abs_y = math.abs(y)
    return not (abs_x > (tiles_half+(abs_y*gradient)) and abs_y > (tiles_half+(abs_x*gradient)))
end
enemy_cross = b.rotate(enemy_cross,degrees(45))
enemy = b.choose(enemy_cross,enemy,b.empty_shape)

water_cross = b.fish(water_cross, 0.01)
local map = b.any{
    start_water,
    spiral,
    water_cross
}
map = b.apply_entity(map,start_ore_patch)
map = b.apply_entity(map, enemy)        -- add the enemies we generated

local function on_init()
    local player_force = game.forces.player
    local enemy_force = game.forces.enemy
    player_force.technologies["landfill"].enabled = false -- disable landfill
    enemy_force.set_ammo_damage_modifier('melee', 1) -- +100% biter damage
    enemy_force.set_ammo_damage_modifier('biological', 0.5) -- +50% spitter/worm damage
    game.map_settings.enemy_expansion.enabled = false -- turn off expansion to compensave for harder biters
end

Event.on_init(on_init)

return map
