--Pacman void script by TWLTriston

local grid_width = 40
local grid_height = 40
local grid_scale = 32 -- 4/8/16/32 are good values here

-- local starting_grid = require "pacman_grids.classic"
local starting_grid = require "pacman_grids.rotated_rectangles"
local image_grid = starting_grid.image_grid

function run_shape_module(event)
	local area = event.area
	local surface = event.surface
	local tiles = {}

	local top_left_x = area.left_top.x	--make a more direct reference
	local top_left_y = area.left_top.y	--make a more direct reference
--	chunk_region = top_left_x / grid_scale

	for x = top_left_x, top_left_x + 32, grid_scale do
		image_grid_position_x = ( ( x / grid_scale ) + 20 ) % grid_width + 1
		for y = top_left_y, top_left_y + 32, grid_scale do
			image_grid_position_y = ( ( y / grid_scale ) + 19 ) % grid_height + 1
			if image_grid[image_grid_position_y][image_grid_position_x] ~= nil then
				if image_grid[image_grid_position_y][image_grid_position_x] == 0 then
					for x_1 = x, x + grid_scale do
						for y_1 = y, y + grid_scale do
							table.insert(tiles, {name = "out-of-map", position = {x_1,y_1}})
						end
					end
				end
			end
		end
	end

	surface.set_tiles(tiles)
	return true
end
