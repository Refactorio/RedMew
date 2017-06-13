if not global.map_layout_name then global.map_layout_name = "" end

local function removeChunk(event) 
	local surface = event.surface
	local tiles = {}
	for x = event.area.left_top.x, event.area.right_bottom.x do
		for y = event.area.left_top.y, event.area.right_bottom.y do                     
			table.insert(tiles, {name = "out-of-map", position = {x,y}})            
		end
	end
	surface.set_tiles(tiles)
end

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
	
	
	if global.map_layout_name == "HolyLand" then
		local islandWidth = 512
		local islandHeight = 512
		local distanceToContinent = 1000
		local pathHeight = 32
		local tiles = {}
		local x = event.area.left_top.x
		local y = event.area.left_top.y
		if x < distanceToContinent then
			if  x >= (islandWidth/(-2)) then
				--
				if (x < (islandWidth/2)) and (math.abs(y) <= (islandHeight/2)) then
					--island spawn
				elseif (math.abs(y) <=  pathHeight) and x >= islandWidth/2 then
					--path
				else
					removeChunk(event)
				end
			else
				removeChunk(event)
			end
			
		end
	end   	
end


Event.register(defines.events.on_chunk_generated, chunk_modification)