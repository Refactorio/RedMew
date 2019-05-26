-- Map by Jayefuu, plague006 and grilledham
-- Map in the shape of a maltese cross, with narrow water bridges around the spawn to force "interesting" transfer of materials

local b = require 'map_gen.shared.builders'
local math = require 'utils.math'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local degrees = math.rad

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none,
        MGSP.grass_only,
        MGSP.enable_water
    }
)

local function value(base, mult, pow)
    return function(x, y)
        local d_sq = x * x + y * y
        return base + mult * d_sq ^ (pow / 2) -- d ^ pow
    end
end

local function no_trees(world, tile)
    if not tile then
        return
    end
    for _, e in ipairs(world.surface.find_entities_filtered({type = 'tree', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}})) do
        e.destroy()
    end
    return tile
end

local starting_area = 59

local gradient = 0.05
local tiles_half = (starting_area) * 0.5

local function maltese_cross(x, y)
    --Create maltese shape

    local abs_x = math.abs(x)
    local abs_y = math.abs(y)

    return not (abs_x > (tiles_half + (abs_y * gradient)) and abs_y > (tiles_half + (abs_x * gradient)))
end

-- create water crossings and pattern
local water_line =
    b.any {
    b.rectangle(10, 8)
}
water_line = b.change_tile(water_line, true, 'water')

local waters = b.single_y_pattern(water_line, 9)
local bounds = b.rectangle(10, starting_area + 1)
waters = b.choose(bounds, waters, b.empty_shape)
waters = b.translate(waters, 34, 0)

local water_pattern =
    b.any {
    waters,
    b.rotate(waters, degrees(90)),
    b.rotate(waters, degrees(180)),
    b.rotate(waters, degrees(270))
}

-- create the starting area as a grass square
local starting_square = b.rectangle(60, 60)
starting_square = b.change_tile(starting_square, true, 'grass-1')

local starting_patch = b.circle(20)
local starting_coal = b.resource(starting_patch, 'coal', value(1800, 0.8, 1.5))
local starting_iron = b.resource(starting_patch, 'iron-ore', value(3000, 0.8, 1.5))
local starting_copper = b.resource(starting_patch, 'copper-ore', value(2200, 0.75, 1.5))
local starting_stone = b.resource(starting_patch, 'stone', value(1100, 0.75, 1.5))
local null = b.no_entity
local starting_resources = b.segment_pattern({null, starting_coal, null, starting_copper, null, starting_stone, null, starting_iron})
starting_resources = b.rotate(starting_resources, degrees(45 / 2))
-- starting_circle = b.circle(14)

-- ore generation
local patch = b.circle(20)
local small_patch = b.circle(8)
local patches = b.single_pattern(patch, 220, 220)

local stone = b.resource(patch, 'stone', value(100, 0.75, 1.1))
local oil = b.resource(b.throttle_world_xy(small_patch, 1, 4, 1, 4), 'crude-oil', value(33000, 50, 1.05))
local coal = b.resource(patch, 'coal', value(100, 0.75, 1.1))
local uranium = b.resource(small_patch, 'uranium-ore', value(200, 0.75, 1.1))

local pattern1 = {
    {stone, oil, stone},
    {stone, oil, oil},
    {stone, stone, stone}
}
local stone_arm = b.grid_pattern(pattern1, 3, 3, 220, 220)

local pattern2 = {
    {coal, coal, coal},
    {coal, coal, coal},
    {coal, coal, uranium}
}
local coal_arm = b.grid_pattern(pattern2, 3, 3, 220, 220)
local iron = b.resource(patches, 'iron-ore', value(500, 0.8, 1.075))
local copper = b.resource(patches, 'copper-ore', value(400, 0.75, 1.1))

local resources = b.segment_pattern({null, coal_arm, null, copper, null, stone_arm, null, iron})
resources = b.rotate(resources, degrees(45 / 2))

-- worm islands
local worm_island = b.rectangle(20, 300)
local worm_island_end = b.circle(10)
worm_island =
    b.any {
    worm_island_end,
    b.translate(worm_island, 0, -150),
    b.translate(worm_island_end, 0, -300)
}
worm_island = b.change_tile(worm_island, true, 'grass-1')
 --

--[[
local worm_names = {
    'small-worm-turret',
    'medium-worm-turret',
    'big-worm-turret'
}
]] local max_worm_chance = 64 / 128
local worm_chance_factor = 1 --/ (192 * 512)
local function worms(_, _, world)
    local wx, wy = world.x, world.y
    local d = math.sqrt(wx * wx + wy * wy)
    local worm_chance = d - 20
    if worm_chance > 0 then
        worm_chance = worm_chance * worm_chance_factor
        worm_chance = math.min(worm_chance, max_worm_chance)
        if math.random() < worm_chance then
            return {name = 'big-worm-turret'}
        end
    end
end

worm_island = b.apply_entity(worm_island, worms)
worm_island = b.apply_effect(worm_island, no_trees)

local worm_islands =
    b.any {
    b.rotate(b.translate(worm_island, 0, -110), degrees(45)),
    b.rotate(b.translate(worm_island, 0, -110), degrees(45 + 90)),
    b.rotate(b.translate(worm_island, 0, -110), degrees(45 + 180)),
    b.rotate(b.translate(worm_island, 0, -110), degrees(45 + 270))
}

-- create the start area using the water and grass square
local start_area =
    b.any {
    water_pattern,
    starting_square
}

-- finalising some bits
start_area = b.apply_entity(start_area, starting_resources) -- adds a different density ore patch to start
maltese_cross = b.change_tile(maltese_cross, true, 'grass-1')
maltese_cross = b.apply_entity(maltese_cross, resources) -- adds our custom ore gen
local sea = b.change_tile(b.full_shape, true, 'water') -- turn the void to water
sea = b.fish(sea, 0.00125) -- feesh!
local map = b.any {worm_islands, start_area, maltese_cross, sea} -- combine everything

return map
