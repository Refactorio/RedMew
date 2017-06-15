if not global.map_layout_name then global.map_layout_name = "" end

local islandWidth = 512
local islandHeight = 512
local distanceToContinent = 10000
local pathHeight = 32

local function removeChunk(event) 
	local tiles = {}
	for x = event.area.left_top.x, event.area.right_bottom.x do
		for y = event.area.left_top.y, event.area.right_bottom.y do                     
			table.insert(tiles, {name = "out-of-map", position = {x,y}})            
		end
	end
	event.surface.set_tiles(tiles)
end

local function generateIslandChunk(event)

end
 
local function generatePathChunk(event)
	local tiles = {}
	for x = event.area.left_top.x, event.area.right_bottom.x do
		for y = event.area.left_top.y, event.area.right_bottom.y do                     
			table.insert(tiles, {name = "grass", position = {x,y}})
		end
	end
	event.surface.set_tiles(tiles)
end
	
local function chunk_modification(event)	
	if global.map_layout_name == "Up" then
		if event.area.left_top.y > 50 or event.area.left_top.x > 96 or event.area.left_top.x < -128 then
			removeChunk(event)
		end
	end   
	
	
	if global.map_layout_name == "HolyLand" then
		local x = event.area.left_top.x
		local y = event.area.left_top.y
		if x < distanceToContinent then
			if  x >= (islandWidth/(-2)) then
				--
				if (x < (islandWidth/2)) and (math.abs(y) <= (islandHeight/2)) then
					generateIslandChunk(event)
				elseif (math.abs(y) <=  pathHeight/2) and x >= islandWidth/2 then
					generatePathChunk(event)
				else
					removeChunk(event)
				end
			else
				removeChunk(event)
			end
			
		end
	end   	
end

local function removeResourcesFromArea(cArea)
	for _,v in pairs(game.surfaces.nauvis.find_entities_filtered{area=cArea}) do
		v.destroy() 
	end
end

local function on_tick(event)
	if (event.tick % 300) == 0 then
		removeResourcesFromArea({left_top = {islandWidth/2, 0}, right_bottom = {islandWidth/2 + distanceToContinent, pathHeight}})
	end
end

Event.register(defines.events.on_chunk_generated, chunk_modification)
Event.register(defines.events.on_tick, on_tick)