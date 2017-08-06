-- author grilledham

require("grid_islands_config")

local half_island_x_distance = (ISLAND_X_DISTANCE / 2) 
local half_island_y_distance = (ISLAND_Y_DISTANCE / 2) 

function run_shape_module(event)
	local area = event.area
	local surface = event.surface
	local tiles = {}
	local entities = {}

	local top_left = area.left_top
	local x = top_left.x 
	local y = top_left.y   		
	
	for world_y = y, y + 31 do
		local world_y2 = world_y - GLOBAL_Y_SHIFT
        local local_y = ((world_y2 + half_island_y_distance) % ISLAND_Y_DISTANCE) - half_island_y_distance + 0.5 -- projects world space into local island space.

		local row_pos = math.floor(world_y2 / ISLAND_Y_DISTANCE + 0.5)
		local row_i = row_pos % PATTERN_ROWS + 1
        local row = PATTERN[row_i] or {}   

		for world_x = x, x + 31 do  
			local world_x2 = world_x - GLOBAL_X_SHIFT	
            local local_x = ((world_x2 + half_island_x_distance) % ISLAND_X_DISTANCE) - half_island_x_distance + 0.5 

			local col_pos = math.floor(world_x2 / ISLAND_X_DISTANCE + 0.5)  
            local col_i = col_pos % PATTERN_COLS + 1

			local builder
			if START_BUILDER and col_pos == 0 and row_pos == 0 then
				builder = START_BUILDER
			else
            	 builder = row[col_i] or empty_island  
			end

			local entity, amount = builder(local_x, local_y, world_x, world_y) -- should this use world_x2 and world_y2
			if entity then				
				if not (type(entity) == "boolean") then					
					table.insert(entities, {name = entity, position = {world_x, world_y}, amount = amount or 667})
				end
			elseif not PATH(local_x, local_y) then
				table.insert(tiles, {name = NOT_LAND, position = {world_x, world_y}})
			end 	
		end
	end

	surface.set_tiles(tiles, false)	

	for _, v in ipairs(entities) do	
		if surface.can_place_entity(v) then	
			surface.create_entity(v)		
		end
	end

	return true
end