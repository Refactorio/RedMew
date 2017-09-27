-- Author: flowild

local arm_width = 96

local function is_on_spiral(x, y, distance, angle_offset)
	local angle = angle_offset + math.deg(math.atan2(x,y))

	local offset = distance
	if angle ~= 0 then offset = offset + angle / 3.75 * 2 end
	return offset % 96 * 2 >= 48 * 2
end

function run_shape_module(event)
	local tiles = {}
	local left_top = event.area.left_top
		for x = left_top.x-1, left_top.x + 32 do
			for y = left_top.y-1, left_top.y + 32 do
					local pseudo_x = x / (arm_width / 48)
					local pseudo_y = y / (arm_width / 48)
					local distance = math.sqrt(pseudo_x * pseudo_x + pseudo_y * pseudo_y)
					if distance > 100 and not is_on_spiral(x,y, distance, 0) then
						table.insert(tiles, {name = "out-of-map", position = {x,y}})
					end
			end
		end
		event.surface.set_tiles(tiles)
	return true
end
