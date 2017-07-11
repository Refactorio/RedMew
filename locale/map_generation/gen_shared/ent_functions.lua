--allows any gen to access these functions

function place_entities(surface, entity_list)
	local directions = {defines.direction.north, defines.direction.east, defines.direction.south, defines.direction.west}	
	for _, entity in pairs(entity_list) do		
		local r = math.random(1,entity.chance)		
		if r == 1 then
			if not entity.force then entity.force = "player" end
			local r = math.random(1,4)			
			if surface.can_place_entity {name=entity.name, position=entity.pos, direction=directions[r], force=entity.force} then														
				local e = surface.create_entity {name=entity.name, position=entity.pos, direction=directions[r], force=entity.force}
				if entity.health then
					if entity.health == "low" then e.health = ((e.health / 1000) * math.random(33,330)) end
					if entity.health == "medium" then e.health = ((e.health / 1000) * math.random(333,666)) end
					if entity.health == "high" then e.health = ((e.health / 1000) * math.random(666,999)) end
					if entity.health == "random" then e.health = ((e.health / 1000) * math.random(1,1000)) end
				end
				return true, e
			end			
		end		
	end
	return false
end

function auto_place_entity_around_target(entity, scan_radius, mode, density, surface)
	local x = entity.pos.x
	local y = entity.pos.y
	if not surface then surface = game.surfaces[1] end
	if not scan_radius then scan_radius = 6 end
	if not entity then return end
	if not mode then mode = "ball" end
	if not density then density = 1 end
	
	if surface.can_place_entity {name=entity.name, position={x,y}} then														
		local e = surface.create_entity {name=entity.name, position={x,y}}
		return true, e
	end
	
	local i = 2
	local r = 1		
	
	if mode == "ball" then
		if math.random(1,2) == 1 then 
			density = density * -1
		end
		r = math.random(1,4)
	end
	if mode == "line" then
		density = 1
		r = math.random(1,4)
	end
	if mode == "line_down" then
		density = density * -1
		r = math.random(1,4)
	end
	if mode == "line_up" then
		density = 1
		r = math.random(1,4)
	end
	if mode == "block" then
		r = 1
		density = 1
	end	
	
	if r == 1 then
		--start placing at -1,-1
		while i <= scan_radius do
			y = y - density						
			x = x - density				
			for a = 1, i, 1 do				
				if surface.can_place_entity {name=entity.name, position={x,y}} then														
					local e = surface.create_entity {name=entity.name, position={x,y}}
					return true, e
				end
				x = x + density
			end		
			for a = 1, i, 1 do				
				if surface.can_place_entity {name=entity.name, position={x,y}} then														
					local e = surface.create_entity {name=entity.name, position={x,y}}
					return true, e
				end
				y = y + density
			end		
			for a = 1, i, 1 do				
				if surface.can_place_entity {name=entity.name, position={x,y}} then														
					local e = surface.create_entity {name=entity.name, position={x,y}}
					return true, e
				end
				x = x - density
			end		
			for a = 1, i, 1 do				
				if surface.can_place_entity {name=entity.name, position={x,y}} then														
					local e = surface.create_entity {name=entity.name, position={x,y}}
					return true, e
				end
				y = y - density
			end			
			i = i + 2
		end
	end
		
	if r == 2 then
		--start placing at 0,-1
		while i <= scan_radius do
			y = y - density						
			x = x - density
			for a = 1, i, 1 do
				x = x + density
				if surface.can_place_entity {name=entity.name, position={x,y}} then														
					local e = surface.create_entity {name=entity.name, position={x,y}}
					return true, e
				end
			end		
			for a = 1, i, 1 do
				y = y + density
				if surface.can_place_entity {name=entity.name, position={x,y}} then														
					local e = surface.create_entity {name=entity.name, position={x,y}}
					return true, e
				end
			end		
			for a = 1, i, 1 do
				x = x - density
				if surface.can_place_entity {name=entity.name, position={x,y}} then														
					local e = surface.create_entity {name=entity.name, position={x,y}}
					return true, e
				end
			end		
			for a = 1, i, 1 do
				y = y - density
				if surface.can_place_entity {name=entity.name, position={x,y}} then														
					local e = surface.create_entity {name=entity.name, position={x,y}}
					return true, e
				end
			end		
			i = i + 2
		end
	end
	
	if r == 3 then
		--start placing at 1,-1
		while i <= scan_radius do
			y = y - density						
			x = x + density								
			for a = 1, i, 1 do				
				if surface.can_place_entity {name=entity.name, position={x,y}} then														
					local e = surface.create_entity {name=entity.name, position={x,y}}
					return true, e
				end
				y = y + density
			end		
			for a = 1, i, 1 do				
				if surface.can_place_entity {name=entity.name, position={x,y}} then														
					local e = surface.create_entity {name=entity.name, position={x,y}}
					return true, e
				end
				x = x - density
			end		
			for a = 1, i, 1 do				
				if surface.can_place_entity {name=entity.name, position={x,y}} then														
					local e = surface.create_entity {name=entity.name, position={x,y}}
					return true, e
				end
				y = y - density
			end
			for a = 1, i, 1 do				
				if surface.can_place_entity {name=entity.name, position={x,y}} then														
					local e = surface.create_entity {name=entity.name, position={x,y}}
					return true, e
				end
				x = x + density
			end				
			i = i + 2
		end
	end
	
	if r == 4 then
		--start placing at 1,0
		while i <= scan_radius do
			y = y - density
			x = x + density				
			for a = 1, i, 1 do
				y = y + density
				if surface.can_place_entity {name=entity.name, position={x,y}} then														
					local e = surface.create_entity {name=entity.name, position={x,y}}
					return true, e
				end
			end		
			for a = 1, i, 1 do
				x = x - density
				if surface.can_place_entity {name=entity.name, position={x,y}} then														
					local e = surface.create_entity {name=entity.name, position={x,y}}
					return true, e
				end
			end		
			for a = 1, i, 1 do
				y = y - density
				if surface.can_place_entity {name=entity.name, position={x,y}} then														
					local e = surface.create_entity {name=entity.name, position={x,y}}
					return true, e
				end
			end
			for a = 1, i, 1 do
				x = x + density
				if surface.can_place_entity {name=entity.name, position={x,y}} then														
					local e = surface.create_entity {name=entity.name, position={x,y}}
					return true, e
				end
			end			
			i = i + 2
		end
	end
		
	return false
end

function create_entitie_cluster(name, pos, amount)
	
	local surface = game.surfaces[1]		
	local entity = {}	
	entity.pos = pos
	entity.name = name
	local mode = "ball"
	
	for i = 1, amount, 1 do
		local b, e = auto_place_entity_around_target(entity, 30, mode)
		if b == true then
			if 1 == math.random(1,40) then
				entity.pos = e.position
			end	
			if e.type == "resource" then
				e.amount = math.random(500,1500)
			end						
		end
	end	
	return b, e
end

function create_rock_cluster(pos, amount)
	if not pos then return false end
	if amount == nil then amount = 7 end
	local scan_radius = amount * 2
	local mode = "line_down"
	if math.random(1,2) == 1 then mode = "line_up" end
	local entity = {}
	entity.pos = pos		
	for i = 1, amount, 1 do
		if 1 == math.random(1,3) then
			entity.name = "red-desert-rock-huge-01"
		else
			entity.name = "red-desert-rock-big-01"
		end	
		local b, e = auto_place_entity_around_target(entity, scan_radius, mode)
		if b == true then
			if 1 ~= math.random(1,20) then
				entity.pos = e.position
			end			
		end
	end	
	return b, e
end

function create_tree_cluster(pos, amount)
	if not pos then return false end
	if amount == nil then amount = 7 end
	local scan_radius = amount * 2
	--local mode = "line_down"	
	--if math.random(1,2) == 1 then mode = "line_up" end
	local mode = "ball"
	local entity = {}
	entity.pos = pos		
	for i = 1, amount, 1 do
		entity.name = "tree-06"
		local density = 2
		if 1 == math.random(1,20) then entity.name = "tree-07" end	
		if 1 == math.random(1,70) then entity.name = "tree-09" end
		if 1 == math.random(1,10) then entity.name = "tree-04" end
		if 1 == math.random(1,9) then density = 1 end
		if 1 == math.random(1,3) then density = 3 end
		if 1 == math.random(1,3) then density = 4 end
		
		local b, e = auto_place_entity_around_target(entity, scan_radius, mode, density)
		if b == true then
			if 1 == math.random(1,3) then
				entity.pos = e.position
			end			
		end
	end	
	return b, e
end

function find_tile_placement_spot_around_target_position(tilename, position, mode, density)
	local x = position.x
	local y = position.y
	if not surface then surface = game.surfaces[1] end
	local scan_radius = 50
	if not tilename then return end
	if not mode then mode = "ball" end
	if not density then density = 1 end
	local cluster_tiles = {}
	local auto_correct = false
	
	local scanned_tile = surface.get_tile(x,y)
	if scanned_tile.name ~= tilename then
		table.insert(cluster_tiles, {name = tilename, position = {x,y}})
		surface.set_tiles(cluster_tiles,false)
		return true, x, y
	end
	
	local i = 2
	local r = 1		
	
	if mode == "ball" then
		if math.random(1,2) == 1 then 
			density = density * -1
		end
		r = math.random(1,4)
	end
	if mode == "line" then
		density = 1
		r = math.random(1,4)
	end
	if mode == "line_down" then
		density = density * -1
		r = math.random(1,4)
	end
	if mode == "line_up" then
		density = 1
		r = math.random(1,4)
	end
	if mode == "block" then
		r = 1
		density = 1
	end	
	
	if r == 1 then
		--start placing at -1,-1
		while i <= scan_radius do
			y = y - density						
			x = x - density				
			for a = 1, i, 1 do				
				local scanned_tile = surface.get_tile(x,y)				
				if scanned_tile.name ~= tilename then	
					table.insert(cluster_tiles, {name = tilename, position = {x,y}})
					surface.set_tiles(cluster_tiles,auto_correct)
					return true, x, y
				end
				x = x + density
			end		
			for a = 1, i, 1 do				
				local scanned_tile = surface.get_tile(x,y)
				if scanned_tile.name ~= tilename then	
					table.insert(cluster_tiles, {name = tilename, position = {x,y}})
					surface.set_tiles(cluster_tiles,auto_correct)
					return true, x, y
				end
				y = y + density
			end		
			for a = 1, i, 1 do				
				local scanned_tile = surface.get_tile(x,y)
				if scanned_tile.name ~= tilename then	
					table.insert(cluster_tiles, {name = tilename, position = {x,y}})
					surface.set_tiles(cluster_tiles,auto_correct)
					return true, x, y
				end
				x = x - density
			end		
			for a = 1, i, 1 do				
				local scanned_tile = surface.get_tile(x,y)
				if scanned_tile.name ~= tilename then	
					table.insert(cluster_tiles, {name = tilename, position = {x,y}})
					surface.set_tiles(cluster_tiles,auto_correct)
					return true, x, y
				end
				y = y - density
			end			
			i = i + 2
		end
	end
		
	if r == 2 then
		--start placing at 0,-1
		while i <= scan_radius do
			y = y - density						
			x = x - density
			for a = 1, i, 1 do
				x = x + density
				local scanned_tile = surface.get_tile(x,y)
				if scanned_tile.name ~= tilename then	
					table.insert(cluster_tiles, {name = tilename, position = {x,y}})
					surface.set_tiles(cluster_tiles,auto_correct)
					return true, x, y
				end
			end		
			for a = 1, i, 1 do
				y = y + density
				local scanned_tile = surface.get_tile(x,y)
				if scanned_tile.name ~= tilename then	
					table.insert(cluster_tiles, {name = tilename, position = {x,y}})
					surface.set_tiles(cluster_tiles,auto_correct)
					return true, x, y
				end
			end		
			for a = 1, i, 1 do
				x = x - density
				local scanned_tile = surface.get_tile(x,y)
				if scanned_tile.name ~= tilename then	
					table.insert(cluster_tiles, {name = tilename, position = {x,y}})
					surface.set_tiles(cluster_tiles,auto_correct)
					return true, x, y
				end
			end		
			for a = 1, i, 1 do
				y = y - density
				local scanned_tile = surface.get_tile(x,y)
				if scanned_tile.name ~= tilename then	
					table.insert(cluster_tiles, {name = tilename, position = {x,y}})
					surface.set_tiles(cluster_tiles,auto_correct)
					return true, x, y
				end
			end		
			i = i + 2
		end
	end
	
	if r == 3 then
		--start placing at 1,-1
		while i <= scan_radius do
			y = y - density						
			x = x + density								
			for a = 1, i, 1 do				
				local scanned_tile = surface.get_tile(x,y)
				if scanned_tile.name ~= tilename then	
					table.insert(cluster_tiles, {name = tilename, position = {x,y}})
					surface.set_tiles(cluster_tiles,auto_correct)
					return true, x, y
				end
				y = y + density
			end		
			for a = 1, i, 1 do				
				local scanned_tile = surface.get_tile(x,y)
				if scanned_tile.name ~= tilename then	
					table.insert(cluster_tiles, {name = tilename, position = {x,y}})
					surface.set_tiles(cluster_tiles,auto_correct)
					return true, x, y
				end
				x = x - density
			end		
			for a = 1, i, 1 do				
				local scanned_tile = surface.get_tile(x,y)
				if scanned_tile.name ~= tilename then	
					table.insert(cluster_tiles, {name = tilename, position = {x,y}})
					surface.set_tiles(cluster_tiles,auto_correct)
					return true, x, y
				end
				y = y - density
			end
			for a = 1, i, 1 do				
				local scanned_tile = surface.get_tile(x,y)
				if scanned_tile.name ~= tilename then	
					table.insert(cluster_tiles, {name = tilename, position = {x,y}})
					surface.set_tiles(cluster_tiles,auto_correct)
					return true, x, y
				end
				x = x + density
			end				
			i = i + 2
		end
	end
	
	if r == 4 then
		--start placing at 1,0
		while i <= scan_radius do
			y = y - density
			x = x + density				
			for a = 1, i, 1 do
				y = y + density
				local scanned_tile = surface.get_tile(x,y)
				if scanned_tile.name ~= tilename then	
					table.insert(cluster_tiles, {name = tilename, position = {x,y}})
					surface.set_tiles(cluster_tiles,auto_correct)
					return true, x, y
				end
			end		
			for a = 1, i, 1 do
				x = x - density
				local scanned_tile = surface.get_tile(x,y)
				if scanned_tile.name ~= tilename then	
					table.insert(cluster_tiles, {name = tilename, position = {x,y}})
					surface.set_tiles(cluster_tiles,auto_correct)
					return true, x, y
				end
			end		
			for a = 1, i, 1 do
				y = y - density
				local scanned_tile = surface.get_tile(x,y)
				if scanned_tile.name ~= tilename then	
					table.insert(cluster_tiles, {name = tilename, position = {x,y}})
					surface.set_tiles(cluster_tiles,auto_correct)
					return true, x, y
				end
			end
			for a = 1, i, 1 do
				x = x + density
				local scanned_tile = surface.get_tile(x,y)
				if scanned_tile.name ~= tilename then	
					table.insert(cluster_tiles, {name = tilename, position = {x,y}})
					surface.set_tiles(cluster_tiles,auto_correct)
					return true, x, y
				end
			end			
			i = i + 2
		end
	end	
	return false
end

function create_tile_cluster(tilename,position,amount)
	local mode = "ball"
	local cluster_tiles = {}
	local surface = game.surfaces[1]
	local pos = position
	local x = pos.x
	local y = pos.y
	for i = 1, amount, 1 do
		local b,x,y = find_tile_placement_spot_around_target_position(tilename, pos, mode)
		if b == true then						
			if 1 == math.random(1,2) then
				pos.x = x
				pos.y = y
			end			
		end
		if b == false then return false,x,y end
		if i >= amount then return true,x,y end
	end		
end