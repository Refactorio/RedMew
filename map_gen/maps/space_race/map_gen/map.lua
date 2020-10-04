require 'map_gen.maps.space_race.scenario'

local b = require 'map_gen.shared.builders'
local RS = require 'map_gen.shared.redmew_surface'
local Map_gen_presets = require 'resources.map_gen_settings'
local Event = require 'utils.event'
local floor = math.floor
local perlin = require 'map_gen.shared.perlin_noise'
local math = require 'utils.math'

local Map_gen_config = (require 'map_gen.maps.space_race.config').map_gen

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

RS.set_map_gen_settings({Map_gen_presets.oil_none, uranium_none, Map_gen_presets.ore_none, Map_gen_presets.water_none})

local sand_width = 128
local sand_width_inv = math.tau / sand_width

--perlin options
local noise_variance = 0.025 --The lower this number the smoother the curve is gonna be
local noise_level = 10 --Factor for the magnitude of the curve

local sand_noise_level = noise_level * 0.9

-- Leave nil and they will be set based on the map seed.
local perlin_seed_1 = 17000

local width_1 = Map_gen_config.width_1
local width_2 = Map_gen_config.width_2
local width_3 = Map_gen_config.width_3

local function sand_shape(x, y)
    local p = perlin.noise(x * noise_variance, y * noise_variance, perlin_seed_1) * sand_noise_level
    p = p + math.sin(x * sand_width_inv) * 2
    return p > y
end
local sand_shape_right = b.rotate(sand_shape, -math.pi / 2)

local beach = b.line_y(16)
local beach_right = b.subtract(beach, sand_shape_right)

local beach_left = b.flip_xy(beach_right)

beach_left = b.translate(beach_left, -8, 0)
beach_right = b.translate(beach_right, 8, 0)

local water_transition_right = b.add(beach_right, beach_left)
local water_transition_left = b.flip_xy(water_transition_right)

water_transition_right = b.translate(water_transition_right, floor(width_1 / 2), 0)
water_transition_left = b.translate(water_transition_left, -floor(width_1 / 2), 0)

local water_transition = b.add(water_transition_right, water_transition_left)

local wilderness_shallow_water = b.line_y(width_1)
wilderness_shallow_water = b.change_tile(wilderness_shallow_water, true, 'water-shallow') -- water-mud is also walkable but doesn't have any tile transitions

wilderness_shallow_water = b.if_else(water_transition, wilderness_shallow_water)

local uranium_island = require 'map_gen.maps.space_race.map_gen.uranium_island'

wilderness_shallow_water = b.if_else(uranium_island, wilderness_shallow_water)

local wilderness_land = b.line_y(width_2)

local safe_zone = b.circle(256)
safe_zone = b.subtract(safe_zone, b.translate(b.rectangle(512, 512), -256, 0))
safe_zone = b.translate(safe_zone, -(width_2 / 2 + width_3 / 2), 0)

safe_zone = b.remove_map_gen_enemies(safe_zone)
wilderness_land = b.add(safe_zone, wilderness_land)

local landfill_water = b.circle(128)

local no_cliff_rectangle = b.rectangle(75, 75)
no_cliff_rectangle = b.translate(no_cliff_rectangle, 0, 0)
no_cliff_rectangle = b.remove_map_gen_entities_by_filter(no_cliff_rectangle, {name = 'cliff'})

landfill_water = b.add(no_cliff_rectangle, landfill_water)

landfill_water = b.translate(landfill_water, -(width_2 / 2 + width_3 / 2), 0)

landfill_water = b.remove_map_gen_enemies(landfill_water)

landfill_water = b.change_map_gen_collision_tile(landfill_water, 'water-tile', 'landfill')

landfill_water = b.subtract(landfill_water, b.translate(b.rectangle(256, 256), -256, 0))
-- landfill_water = b.change_tile(landfill_water, true, 'lab-white')

local wilderness_resources = require 'map_gen.maps.space_race.map_gen.wilderness_ores'

local mirrored_water = wilderness_resources[2]
local mirrored_ore = wilderness_resources[1]

mirrored_water = b.subtract(mirrored_water, b.invert(wilderness_land))

wilderness_land = b.add(mirrored_water, wilderness_land)
wilderness_land = b.apply_entity(wilderness_land, mirrored_ore)

-- wilderness_land = b.change_tile(wilderness_land, true, 'lab-white')

wilderness_land = b.add(landfill_water, wilderness_land)

local wilderness_land_left = b.translate(wilderness_land, -(width_1 + width_2) / 2, 0)
local wilderness_land_right = b.translate(b.flip_x(wilderness_land), (width_1 + width_2) / 2, 0)
local wilderness_ditch = b.line_y(width_3)
wilderness_ditch = b.if_else(b.change_tile(b.translate(b.line_y(width_3 - 1), -1, 0), true, 'out-of-map'), wilderness_ditch)
wilderness_ditch = b.if_else(b.change_tile(b.translate(b.rectangle(2, 17), -1, 0), true, 'landfill'), wilderness_ditch)
local rocket_silo_shape = b.rectangle(9, 9)
rocket_silo_shape = b.change_tile(rocket_silo_shape, true, 'landfill')
rocket_silo_shape = b.remove_map_gen_trees(rocket_silo_shape)
rocket_silo_shape = b.remove_map_gen_simple_entity(rocket_silo_shape)   -- Removes rocks.
wilderness_ditch = b.if_else(rocket_silo_shape, wilderness_ditch)

local wilderness_ditch_left = b.translate(wilderness_ditch, -(width_1 / 2 + width_2 + width_3 / 2), 0)
local wilderness_ditch_right = b.translate(b.rotate(wilderness_ditch, math.pi), (width_1 / 2 + width_2 + width_3 / 2), 0)
local wilderness = b.any({wilderness_shallow_water, wilderness_ditch_left, wilderness_ditch_right, wilderness_land_left, wilderness_land_right})

local limited_safe_zone = require 'map_gen.maps.space_race.map_gen.safe_zone'

local map = b.add(wilderness, limited_safe_zone)

--map = b.if_else(wilderness, b.full_shape)

return map
