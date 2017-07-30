--X shape map script --by Neko_Baron

--edit this
local tiles_wide = 128
local tiles_intersect = 384

---dont edit these
local tiles_half = tiles_wide * 0.5

function run_shape_module(event)
	local area = event.area
	local surface = event.surface
	local tiles = {}

	top_left = area.left_top	--make a more direct reference

	for x = top_left.x-1, top_left.x + 32 do
		for y = top_left.y-1, top_left.y + 32 do
		
			local offset_1 = x + y + tiles_half
			local offset_2 = x - y + tiles_half
		
			if offset_1 % tiles_intersect > tiles_wide then
				if offset_2 % tiles_intersect > tiles_wide then
					table.insert(tiles, {name = "out-of-map", position = {x,y}})
				end
			end

		end
	end
	surface.set_tiles(tiles)

	return true
end