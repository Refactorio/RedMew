local module = {}

function module.on_chunk_generated(event)
	local area = event.area
	local surface = event.surface
	local tiles = {}
	if area.left_top.y > 50 or area.left_top.x > 96 or area.left_top.x < -128 then
		for x = area.left_top.x, area.right_bottom.x do
			for y = area.left_top.y, area.right_bottom.y do
				table.insert(tiles, {name = "out-of-map", position = {x,y}})
			end
		end
		surface.set_tiles(tiles)
		return false
	end
	return true
end

return module
