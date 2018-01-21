map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 8 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use generate, but generate_not_threaded may be useful for testing / debugging.
--require "map_gen.shared.generate_not_threaded"
require "map_gen.shared.generate"

local stripe_thickness = 24
local stripe_distance = 384

local stripes = throttle_y(full_builder,stripe_thickness,stripe_distance)
local joint = rectangle_builder(64)
joint = rotate(joint,degrees(45))
joint = translate(joint, 0, stripe_thickness / 2)
local joints = single_y_pattern_builder(joint, stripe_distance)

stripes = compound_or{stripes, joints}

local lines = {}
local count = 8
local angle = 360 / count
local offset = (180 / count) + 90
for i = 0, count - 1 do
    local line =rotate(stripes, degrees(i * angle + offset))
    table.insert(lines, line)
end

local web = segment_pattern_builder(lines)
web = rotate(web, degrees(180 / count))

local path = path_builder(stripe_thickness)

local leg = rectangle_builder(32,480)
local head = translate (oval_builder(32, 64), 0, -64)
local body = translate (circle_builder(64), 0, 64)

local count = 10
local angle = 360 / count
local list = { head, body }
for i = 1, (count / 2) - 1 do
    local shape = rotate(leg, degrees(i * angle))
    table.insert( list, shape )
end  

local spider = compound_or(list) 
spider = scale(spider,2,2)

local e = empty_builder
local function s(r)
    return rotate(spider, degrees(r))
end

local pattern =
{
    {e     , s(90) , e     , s(0) , e      , s(270)},
    {s(0)  , e     , e     , e     , e     , e     },
    {e     , e     , s(45) , e     , s(315), e     },
    {s(90) , e     , e     , e     , e     , e     },
    {e     , e     , s(135), e     , s(225), e     },
    {s(180), e     , e     , e     , e     , e     },
}

local spiders = grid_pattern_builder(pattern, 6, 6, 820, 820)

local map = compound_or{ web, path, rotate(path, degrees(45)), spiders }

local start = circle_builder(150)
map = choose(start, full_builder, map)

--map = scale(map, 0.5, 0.5)
return map