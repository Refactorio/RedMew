-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
require "map_gen.shared.generate_not_threaded"
--require "map_gen.shared.generate"

--[[ 
local arm1 = translate(rectangle_builder(2, 8), 0, -11.5)
local arm2 = translate(rectangle_builder(12, 2), 0, 24)

local inner = circle_builder(30)
local outer = circle_builder(32)
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

local function make_ball(shape, sf, rot)
    local s1 = translate(shape, 0, -16 * sf)
    local shape = compound_or
    {
        s1, 
        rotate(s1, degrees(120)),
        rotate(s1, degrees(-120)),
        scale(frame, sf, sf)
    }
    shape = rotate(shape, degrees(rot))

    local bound = scale(outer, sf, sf)

    return choose(bound, shape, empty_builder)
end

local ratio = 4
local map = circle_builder(8)
local total_sf = 1
--local spawn = 0
--local spawn_factor = 2
local total_rot = -0
for i = 1, 6 do
    total_rot = total_rot + 180
    map = make_ball(map, total_sf, total_rot)    
    total_sf = ratio * total_sf
    --spawn = spawn + ratio ^ spawn_factor
    --spawn_factor = spawn_factor + 1
end

--map = rotate(map, degrees(-total_rot))
--map = translate(map, 0, spawn)
map = translate(map, 0, 11568)


--map = scale(map, 8, 8)
map = scale(map, .25, .25)

return map 
]]

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

local function make_ball(shape, sf, rot)
    local s1 = translate(shape, 0, -12 * sf)
    local shape = compound_or
    {
        s1, 
        rotate(s1, degrees(120)),
        rotate(s1, degrees(-120)),
        scale(frame, sf, sf)
    }
    shape = rotate(shape, degrees(rot))

    local bound = scale(outer, sf, sf)

    return choose(bound, shape, empty_builder)    
end

local ratio = 24 / 8 
local map = circle_builder(8)
local total_sf = 1
local total_rot = -180
for i = 1, 8 do
    total_rot = total_rot + 180
    map = make_ball(map, total_sf, total_rot)    
    total_sf = ratio * total_sf
end

map = translate(map, 0, -31488)
--map = scale(map, 8, 8)

return map
