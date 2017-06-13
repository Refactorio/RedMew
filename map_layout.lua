if not global.map_layout_name then global.map_layout_name = "" end

local function chunk_modification(event)	
	if global.map_layout_name == "Up" then
		local tiles = {}
		if event.area.left_top.y > 50 or event.area.left_top.x > 96 or event.area.left_top.x < -128 then
			for x = event.area.left_top.x, event.area.right_bottom.x do
				for y = event.area.left_top.y, event.area.right_bottom.y do                     
					table.insert(tiles, {name = "out-of-map", position = {x,y}})            
				end
			end
			surface.set_tiles(tiles)
		end
	end
end
Event.register(defines.events.on_chunk_generated, chunk_modification)
