-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local function value(base, mult)
    return function(x, y) 
        return mult * (math.abs(x) + math.abs(y)) + base
    end
end

local function no_resources(x, y, world, tile)    
    for _, e in ipairs(world.surface.find_entities_filtered({ type = "resource", area = {{world.x, world.y  }, {world.x + 1, world.y + 1 } } })) do
        e.destroy()
    end

    return tile
end

local arm1 = translate(rectangle_builder(2, 3), 0, -5)
local arm2 = translate(rectangle_builder(6, 2), 0, 22)

local inner = circle_builder(22)
local outer = circle_builder(24)
local ring = compound_and{outer, invert(inner)}

map = compound_or{map, ring}

local arms = compound_or{arm1, arm2}
arms = translate(arms, 0, -16)
arms = compound_or
{
    arms, 
    rotate(arms, degrees(120)),
    rotate(arms, degrees(-120))
}
local frame = compound_or{arms, ring}

local ball = circle_builder(8)

local iron = resource_module_builder(circle_builder(6), "iron-ore", value(1000, 1))
local copper = resource_module_builder(circle_builder(6), "copper-ore", value(800, 0.8))
local stone = resource_module_builder(circle_builder(4), "stone", value(500, .5))
local coal = resource_module_builder(circle_builder(6), "coal", value(600, 0.6))
local uranium = resource_module_builder(circle_builder(4), "uranium-ore", value(400, 1))
local oil = resource_module_builder(throttle_world_xy(circle_builder(6), 1, 4, 1, 4), "crude-oil", value(100000, 50))

local iron_ball = change_map_gen_collision_tile(builder_with_resource(ball, iron),"water-tile", "grass-1")
local copper_ball = change_map_gen_collision_tile(builder_with_resource(ball, copper),"water-tile", "grass-1")
local stone_ball = change_map_gen_collision_tile(builder_with_resource(ball, stone),"water-tile", "grass-1")
local coal_ball = change_map_gen_collision_tile(builder_with_resource(ball, coal),"water-tile", "grass-1")
local uranium_ball = change_map_gen_collision_tile(builder_with_resource(ball, uranium),"water-tile", "grass-1")
local oil_ball = change_map_gen_collision_tile(builder_with_resource(ball, oil),"water-tile", "grass-1")

local balls1 = compound_or
{
    translate(iron_ball, 0, -12),
    rotate(translate(copper_ball, 0, -12), degrees(120)),
    rotate(translate(coal_ball, 0, -12), degrees(-120)),  
    frame
}
--shape = rotate(shape, degrees(rot))
balls1 = rotate(balls1, degrees(180))
balls1 = choose(outer, balls1, empty_builder)
balls1 = translate(balls1, 0, -36)

local balls2 = compound_or
{
    translate(iron_ball, 0, -12),
    rotate(translate(copper_ball, 0, -12), degrees(120)),
    rotate(translate(stone_ball, 0, -12), degrees(-120)),  
    frame
}
balls2 = rotate(balls2, degrees(180))
balls2  = choose(outer, balls2, empty_builder)
balls2 = translate(balls2, 0, -36)
balls2 = rotate(balls2, degrees(120))

local balls3 = compound_or
{
    translate(iron_ball, 0, -12),
    rotate(translate(uranium_ball, 0, -12), degrees(120)),
    rotate(translate(oil_ball, 0, -12), degrees(-120)),  
    frame
}
balls3 = rotate(balls3, degrees(180))
balls3  = choose(outer, balls3, empty_builder)
balls3 = translate(balls3, 0, -36)
balls3 = rotate(balls3, degrees(-120))


local balls4 = compound_or
{
    balls1,
    balls2,
    balls3,
    scale(frame, 3, 3)
}
balls4 = rotate(balls4, degrees(180))
balls4 = apply_effect(balls4, no_resources)
balls4 = choose(scale(outer, 3, 3), balls4, empty_builder)

local function make_ball(shape, sf)
    local s1 = translate(shape, 0, -12 * sf)
    local shape = compound_or
    {
        s1, 
        rotate(s1, degrees(120)),
        rotate(s1, degrees(-120)),
        scale(frame, sf, sf)
    }
    shape = rotate(shape, degrees(180))

    local bound = scale(outer, sf, sf)

    return choose(bound, shape, empty_builder)    
end

local ratio = 24 / 8 
local map = balls4
local total_sf = 1 * ratio * ratio
for i = 1, 6 do    
    map = make_ball(map, total_sf)    
    total_sf = ratio * total_sf
end

map = translate(map, 0, -19680)
map = scale(map, 1.5, 1.5)

return map
