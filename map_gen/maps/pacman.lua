--Pacman void script by TWLTriston

local grid_width = 40
local grid_height = 40
local grid_scale = 32 -- 4/8/16/32 are good values here

 local starting_grid = require "map_gen.maps.pacman_grids.classic"
--local starting_grid = require "map_gen.maps.pacman_grids.rotated_rectangles"

local image_grid = starting_grid.image_grid
local mult = 1 / grid_scale

return function(x, y)
    x = x * mult - 20
    y = y * mult - 21
    x = math.floor(x) % grid_width + 1
    y = math.floor(y) % grid_height + 1

    local pixel = image_grid[y][x]
    return pixel == 1
end
