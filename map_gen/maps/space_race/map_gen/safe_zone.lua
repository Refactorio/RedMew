local b = require 'map_gen.shared.builders'

local Map_gen_config = (require 'map_gen.maps.space_race.config').map_gen

local width_1 = Map_gen_config.width_1
local width_2 = Map_gen_config.width_2

local safe_zone_width = 512

-- Limited Safe zone

local limited_safe_zone = b.rectangle(safe_zone_width, 512)

local landfill_water = b.circle(128)

landfill_water = b.translate(landfill_water, safe_zone_width/2, 0)

landfill_water = b.remove_map_gen_enemies(landfill_water)

landfill_water = b.change_map_gen_collision_tile(landfill_water, 'water-tile', 'landfill')

-- landfill_water = b.change_tile(landfill_water, true, 'lab-white')

local safe_zone_resources = require 'map_gen.maps.space_race.map_gen.safe_zone_ores'

limited_safe_zone = b.apply_entity(limited_safe_zone, safe_zone_resources)

limited_safe_zone = b.add(landfill_water, limited_safe_zone)

limited_safe_zone = b.remove_map_gen_enemies(limited_safe_zone)
limited_safe_zone = b.remove_map_gen_entities_by_filter(limited_safe_zone, {name = 'cliff'})


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

start_resources = b.translate(start_resources, (safe_zone_width/2 - 60), 0)
start_resources = b.change_map_gen_collision_tile(start_resources, 'water-tile', 'landfill')
start_resources = b.remove_map_gen_enemies(start_resources)

limited_safe_zone = b.add(start_resources, limited_safe_zone)


local limited_safe_zone_right = b.translate(limited_safe_zone, -(256 + width_1 / 2 + width_2), 0)
local limited_safe_zone_left = b.translate(b.flip_x(limited_safe_zone), 256 + width_1 / 2 + width_2, 0)

limited_safe_zone = b.add(limited_safe_zone_right, limited_safe_zone_left)

return limited_safe_zone
