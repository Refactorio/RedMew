require 'map_gen.maps.space_race.scenario'

local b = require 'map_gen.shared.builders'
local RS = require 'map_gen.shared.redmew_surface'
local Map_gen_presets = require 'resources.map_gen_settings'
local table = require 'utils.table'
local Random = require 'map_gen.shared.random'
local Event = require 'utils.event'

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

local width_1 = 256 -- Do not reduce this, it prevents artillary spam

local wilderness_shallow_water = b.line_y(width_1)
wilderness_shallow_water = b.change_tile(wilderness_shallow_water, true, 'water-shallow') -- water-mud is also walkable

local inf = function()
    return 100000000
end

-- Remove vanilla ores from this area
local function no_ores(_, _, world, tile)
    if not tile then
        return
    end
    for _, e in ipairs(world.surface.find_entities_filtered({type = 'resource', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}})) do
        e.destroy()
    end
    return tile
end

local uranium_island = b.circle(10)
uranium_island = b.apply_effect(uranium_island, no_ores)
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

local function no_biters(_, _, world, tile)
    if not tile then
        return
    end
    for _, e in ipairs(world.surface.find_entities_filtered({type = 'unit-spawner', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}})) do
        e.destroy()
    end
    for _, e in ipairs(world.surface.find_entities_filtered({type = 'turret', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}})) do
        e.destroy()
    end
    for _, e in ipairs(world.surface.find_entities_filtered({type = 'unit', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}})) do
        e.destroy()
    end
    return tile
end

safe_zone = b.apply_effect(safe_zone, no_biters)

local landfill_water = b.translate(b.circle(128), -(width_2 / 2 + width_3 / 2), 0)
landfill_water = b.change_map_gen_collision_tile(landfill_water, 'water-tile', 'landfill')

landfill_water = b.apply_effect(landfill_water, no_biters)

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

start_resources = b.translate(start_resources, -math.floor(width_2 / 2 + width_3 / 2 + 60), 0)
start_resources = b.change_map_gen_collision_tile(start_resources, 'water-tile', 'landfill')
start_resources = b.apply_effect(start_resources, no_biters)

wilderness_land = b.add(start_resources, wilderness_land)

local wilderness_land_left = b.translate(wilderness_land, -(width_1 + width_2) / 2, 0)
local wilderness_land_right = b.translate(b.flip_x(wilderness_land), (width_1 + width_2) / 2, 0)
local wilderness_ditch = b.line_y(width_3)
wilderness_ditch = b.change_tile(wilderness_ditch, true, 'out-of-map')
wilderness_ditch = b.if_else(b.change_tile(b.rectangle(3, 17), true, 'landfill'), wilderness_ditch)
local rocket_silo_shape = b.rectangle(9, 9)
rocket_silo_shape = b.change_tile(rocket_silo_shape, true, 'landfill')
wilderness_ditch = b.if_else(rocket_silo_shape, wilderness_ditch)

local wilderness_ditch_left = b.translate(wilderness_ditch, -(width_1 / 2 + width_2 + width_3 / 2), 0)
local wilderness_ditch_right = b.translate(b.rotate(wilderness_ditch, math.pi), (width_1 / 2 + width_2 + width_3 / 2), 0)
local wilderness = b.any({wilderness_shallow_water, wilderness_ditch_left, wilderness_ditch_right, wilderness_land_left, wilderness_land_right})

local map = b.if_else(wilderness, b.full_shape)

return map
