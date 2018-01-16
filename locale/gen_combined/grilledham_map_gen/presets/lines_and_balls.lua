map_gen_decoratives = false -- Generate our own decoratives
map_gen_rows_per_tick = 4 -- Inclusive integer between 1 and 32. Used for map_gen_threaded, higher numbers will generate map quicker but cause more lag.

-- Recommend to use map_gen, but map_gen_not_threaded may be useful for testing / debugging.
require "locale.gen_combined.grilledham_map_gen.map_gen_not_threaded"
--require "locale.gen_combined.grilledham_map_gen.map_gen"
require "locale.gen_combined.grilledham_map_gen.builders"

local big_circle = circle_builder(150)
local small_circle = circle_builder(140)
local crop = rectangle_builder(300,150)
crop = translate(crop,0,-75)
local arc = compound_and{big_circle, invert(small_circle), invert(crop)}
arc = scale(arc,12,4)

local circle = circle_builder(150)
local ball1 = translate(circle, 0,770)
local ball2 = translate(circle, -920,690)
local ball3 = translate(circle, 920,690)
local rectangle = rectangle_builder(25,40)
local arm1 = translate(rectangle, 0, 610)
local arm2 = translate(rectangle, -920, 530)
local arm3 = translate(rectangle, 920, 530)

local arc1 = compound_or{arc, ball1,ball2,ball3,arm1,arm2,arm3}
arc1 = single_pattern_builder(arc1, 2760,2760)

local root2 = math.sqrt(2)
circle = circle_builder(150 / root2)
ball1 = translate(circle, -0,720)
ball2 = translate(circle, -920,640)
ball3 = translate(circle, 920,640)
rectangle = rectangle_builder(25,40)
arm1 = translate(rectangle, 0, 610)
arm2 = translate(rectangle, -920, 530)
arm3 = translate(rectangle, 920, 530)

local arc2 = compound_or{arc, ball1,ball2,ball3,arm1,arm2,arm3}
arc2 = single_pattern_builder(arc2, 2760,2760)

local arc2 = rotate(arc2,degrees(45))
arc2 = scale(arc2, root2,root2)
arc2 = translate(arc2, -330,-1375)

local map = compound_or{arc1,arc2}
map = translate(map,0,-700)
--map = scale(map, .2, .2)

return map

--[[ 
local path = rectangle_builder(300,20)
local arm = rectangle_builder(20,20)
arm = translate(arm,0,20)
local ball = circle_builder(100)
ball = translate(ball, 0, 120)

local under = compound_or({path, arm, ball})
local over = flip_y(under)

local pattern = 
{
    {path, path, under, over, path, over},
    {path, over, under, path, under, path},
    {under, path, path, over, path, over},
    {under, path, under, over, under, path},
    
}

local grid1 = grid_pattern_builder(pattern,6,4,300,500)

local path2 = rectangle_builder(20,1000)
local ball2 = circle_builder(25)
local grid2 = compound_or{path2,ball2, translate(ball2, 0, 500),translate(ball2, 0, 1000),translate(ball2, 0, -500),translate(ball2, 0, -1000)}

local grid2 = single_pattern_builder(grid2,1800,1000)
 ]]



--local start = circle_builder(100)

--local map = compound_or({grid1,grid2})
--map = choose(start, start, grid)
--map = rotate(map,degrees(45))