
function run_shape_module(event)
	local area = event.area
	local surface = event.surface
	local tiles = {}

	top_left = area.left_top	--make a more direct reference

	--if top_left.y > 80 or top_left.x > 180 or top_left.x < -180 then
		for x = top_left.x-1, top_left.x + 32 do
			for y = top_left.y-1, top_left.y + 32 do

				local distance = math.sqrt(x*x + y*y)
				if distance > 128 then
					local angle = (180 + math.deg(math.atan2(x,y)))*3

					local offset = distance * 0.75
					if angle ~= 0 then offset = offset + angle /3.75 end
					--if angle ~= 0 then offset = offset + angle /1.33333333 end

					if offset % 96 < 48 then
						local offset2 = distance * 0.125
						if angle ~= 0 then offset2 = offset2 - angle /3.75 end

						if offset2 % 96 < 80 then
							table.insert(tiles, {name = "out-of-map", position = {x,y}})
						end
					end
				end
			end
		end
		surface.set_tiles(tiles)

		--return false
	--end

	return true
end
