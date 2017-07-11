if shape_module then return end
shape_module = true

function run_shape_module(event)
	local area = event.area 
	local surface = event.surface
	local tiles = {}
	if area.left_top.x < -75 or area.left_top.y > 32 or area.left_top.y < -400 then
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