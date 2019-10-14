require 'map_gen.maps.space_race.scenario'

local b = require 'map_gen.shared.builders'
local RS = require 'map_gen.shared.redmew_surface'
local Map_gen_presets = require 'resources.map_gen_settings'
local table = require 'utils.table'
local Random = require 'map_gen.shared.random'
local Event = require 'utils.event'
local floor = math.floor
local perlin = require 'map_gen.shared.perlin_noise'
local math = require 'utils.math'

local seed1 = 17000
local seed2 = seed1 * 2

Event.on_init(
    function()
        --game.map_settings.enemy_evolution.time_factor = 0.000002
        --game.map_settings.enemy_evolution.destroy_factor = 0.000010
        --game.map_settings.enemy_evolution.pollution_factor = 0.000075
    end
)

local uranium_none = {
    autoplace_controls = {
        ['uranium-ore'] = {
            frequency = 1,
            richness = 1,
            size = 0
        }
    }
}

RS.set_map_gen_settings({Map_gen_presets.oil_none, uranium_none})

local sand_width = 128
local sand_width_inv = math.tau / sand_width

--perlin options
local noise_variance = 0.025 --The lower this number the smoother the curve is gonna be
local noise_level = 10 --Factor for the magnitude of the curve

local sand_noise_level = noise_level * 0.9

-- Leave nil and they will be set based on the map seed.
local perlin_seed_1 = 17000

local width_1 = 256

local function sand_shape(x, y)
    local p = perlin.noise(x * noise_variance, y * noise_variance, perlin_seed_1) * sand_noise_level
    p = p + math.sin(x * sand_width_inv) * 2
    return p > y
end
local sand_shape_right = b.rotate(sand_shape, -math.pi/2)

local beach = b.line_y(16)
local beach_right = b.subtract(beach, sand_shape_right)
beach_right = b.change_tile(beach_right, true, 'sand-1')

beach_right = b.if_else(beach_right, beach)


local beach_left = b.flip_xy(beach_right)
beach_left = b.change_tile(beach_left, true, 'water-shallow')

beach_left = b.translate(beach_left, -8, 0)
beach_right = b.translate(beach_right, 8, 0)

local water_transition_right = b.add(beach_right, beach_left)
local water_transition_left = b.flip_xy(water_transition_right)

water_transition_right = b.translate(water_transition_right, floor(width_1 / 2), 0)
water_transition_left = b.translate(water_transition_left, -floor(width_1 / 2), 0)

local wilderness_shallow_water = b.line_y(width_1 - 32)
wilderness_shallow_water = b.change_tile(wilderness_shallow_water, true, 'water-shallow') -- water-mud is also walkable but doesn't have any tile transitions

wilderness_shallow_water = b.any({water_transition_right, water_transition_left, wilderness_shallow_water})

local inf = function()
    return 100000000
end

local uranium_island = b.circle(10)
uranium_island = b.remove_map_gen_resources(uranium_island)
local uranium_ore = b.resource(b.rectangle(2, 2), 'uranium-ore', inf, true)
uranium_island = b.apply_entity(uranium_island, uranium_ore)

local uranium_island_water = b.change_tile(b.circle(20), true, 'water')
local uranium_island_bridge = b.all({b.any({b.line_x(2), b.line_y(2)}), b.circle(20)})
uranium_island_bridge = b.change_tile(uranium_island_bridge, true, 'water-shallow')
uranium_island_water = b.if_else(uranium_island_bridge, uranium_island_water)

uranium_island = b.if_else(uranium_island, uranium_island_water)

wilderness_shallow_water = b.if_else(uranium_island, wilderness_shallow_water)

local width_2 = 256
local width_3 = 9

local wilderness_land = b.line_y(width_2)

local function value(base, mult, pow)
    return function(x, y)
        x = x * 10
        local d = math.sqrt(x * x + y * y)
        return base + mult * d ^ pow
    end
end

local function oil_transform(shape)
    shape = b.throttle_world_xy(shape, 1, 6, 1, 6)
    return shape
end

-- Add mirrored oil patches to give each team a fair chance
local ores = {
    {weight = 100},
    {transform = oil_transform, resource = 'crude-oil', value = value(180000, 50, 1.1), weight = 33}
}

local random = Random.new(seed1, seed2)

local total_weights = {}
local t = 0
for _, v in ipairs(ores) do
    t = t + v.weight
    table.insert(total_weights, t)
end

local p_cols = 64
local p_rows = 64
local pattern = {}

for r = 1, p_rows do
    local row = {}
    pattern[r] = row
    for c = 1, p_cols do
        local i = random:next_int(1, t)
        local index = table.binary_search(total_weights, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end
        local ore_data = ores[index]

        local transform = ore_data.transform
        if not transform then
            row[c] = b.no_entity
        else
            local ore_shape = transform(b.circle(10))

            local x = random:next_int(-32, 32)
            local y = random:next_int(-32, 32)

            ore_shape = b.translate(ore_shape, x, y)

            local ore = b.resource(ore_shape, ore_data.resource, ore_data.value, true)
            row[c] = ore
        end
    end
end
local oil = b.grid_pattern_full_overlap(pattern, p_cols, p_rows, width_2, 64)
-- end oil generation


local safe_zone = b.translate(b.circle(256), -(width_2 / 2 + width_3 / 2), 0)

safe_zone = b.remove_map_gen_enemies(safe_zone)

local landfill_water = b.circle(128)

local no_cliff_rectangle = b.rectangle(150, 75)
no_cliff_rectangle = b.translate(no_cliff_rectangle, -32, 0)
no_cliff_rectangle = b.remove_map_gen_entities_by_filter(no_cliff_rectangle, {name = 'cliff'})

landfill_water = b.add(no_cliff_rectangle, landfill_water)

landfill_water = b.translate(landfill_water, -(width_2 / 2 + width_3 / 2), 0)

landfill_water = b.remove_map_gen_enemies(landfill_water)

landfill_water = b.change_map_gen_collision_tile(landfill_water, 'water-tile', 'landfill')

wilderness_land = b.apply_entity(wilderness_land, oil)

wilderness_land = b.add(safe_zone, wilderness_land)

wilderness_land = b.add(landfill_water, wilderness_land)



local small_circle = b.rectangle(40, 40)

local function constant(x)
    return function()
        return x
    end
end

local start_iron = b.resource(small_circle, 'iron-ore', constant(750))
local start_copper = b.resource(small_circle, 'copper-ore', constant(600))
local start_stone = b.resource(small_circle, 'stone', constant(600))
local start_coal = b.resource(small_circle, 'coal', constant(600))
local start_segmented = b.segment_pattern({start_iron, start_iron, start_copper, start_copper, start_iron, start_iron, start_stone, start_coal})
local start_resources = b.apply_entity(small_circle, start_segmented)

local water = b.rectangle(10, 10)
water = b.change_tile(water, true, 'water')
water = b.translate(water, -35, 0)

start_resources = b.add(start_resources, water)

start_resources = b.translate(start_resources, -floor(width_2 / 2 + width_3 / 2 + 60), 0)
start_resources = b.change_map_gen_collision_tile(start_resources, 'water-tile', 'landfill')
start_resources = b.remove_map_gen_enemies(start_resources)

wilderness_land = b.add(start_resources, wilderness_land)

local wilderness_land_left = b.translate(wilderness_land, -(width_1 + width_2) / 2, 0)
local wilderness_land_right = b.translate(b.flip_x(wilderness_land), (width_1 + width_2) / 2, 0)
local wilderness_ditch = b.line_y(width_3)
wilderness_ditch = b.if_else(b.change_tile(b.translate(b.line_y(width_3 - 1), -1, 0), true, 'out-of-map'), wilderness_ditch)
wilderness_ditch = b.if_else(b.change_tile(b.translate(b.rectangle(2, 17), -1, 0), true, 'landfill'), wilderness_ditch)
local rocket_silo_shape = b.rectangle(9, 9)
rocket_silo_shape = b.change_tile(rocket_silo_shape, true, 'landfill')
wilderness_ditch = b.if_else(rocket_silo_shape, wilderness_ditch)

local wilderness_ditch_left = b.translate(wilderness_ditch, -(width_1 / 2 + width_2 + width_3 / 2), 0)
local wilderness_ditch_right = b.translate(b.rotate(wilderness_ditch, math.pi), (width_1 / 2 + width_2 + width_3 / 2), 0)
local wilderness = b.any({wilderness_shallow_water, wilderness_ditch_left, wilderness_ditch_right, wilderness_land_left, wilderness_land_right})

local limited_safe_zone = b.rectangle(512, 512)
local limited_safe_zone_right = b.translate(limited_safe_zone, -(256 + width_1/2 + width_2), 0)
local limited_safe_zone_left = b.translate(limited_safe_zone, 256 + width_1/2 + width_2, 0)

limited_safe_zone = b.add(limited_safe_zone_right, limited_safe_zone_left)
--limited_safe_zone = b.change_tile(limited_safe_zone, true, 'out-of-map')

local map = b.add(wilderness, limited_safe_zone)

--map = b.if_else(wilderness, b.full_shape)

return map
