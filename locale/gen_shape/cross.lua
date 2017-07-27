--X shape map script --by Neko_Baron

--edit this
local tiles_wide = 172

---dont edit these
local tiles_half = tiles_wide * 0.5

function run_shape_module(event)
	local area = event.area
	local surface = event.surface
	local tiles = {}

	top_left = area.left_top	--make a more direct reference

	for x = top_left.x-1, top_left.x + 32 do
		for y = top_left.y-1, top_left.y + 32 do
		
			local abs_x = math.abs(x)
			local abs_y = math.abs(y)
			if abs_x < abs_y - tiles_half or abs_x > abs_y + tiles_half then
				table.insert(tiles, {name = "out-of-map", position = {x,y}})
			end
		end
	end
	surface.set_tiles(tiles)

	return true
end