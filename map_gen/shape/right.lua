function run_shape_module(event)
	local area = event.area
	local surface = event.surface
	local tiles = {}

	top_left = area.left_top	--make a more direct reference

	if top_left.x < -150 or top_left.y > 32 or top_left.y < -568 then
		for x = top_left.x-1, top_left.x + 32 do
			for y = top_left.y-1, top_left.y + 32 do
				table.insert(tiles, {name = "out-of-map", position = {x,y}})
			end
		end
		surface.set_tiles(tiles)

		return false
	end

	return true
end
