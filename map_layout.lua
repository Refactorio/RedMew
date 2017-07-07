--[[
Hey there!

With this you can customize your world generation.
Just set the map_styles of your choice to true to make it happen.

---MewMew---

notes:

--]]

require "locale.map_layout.perlin_noise"
require "locale.map_layout.gens_neko"
perlin:load(  )



local map_styles = {
up = false,
right = false,
square = false,
circle = false,
rivers = false,
resource_rainbow = false,
red_planet = false,
red_planet_2 = false,
red_planet_2_messy_resources = false,
dagobah_swamp = false,
grey_void = false,
resource_cluster_truck = false,
perlin_01 = false,
perlin_02 = false
}

--if map_styles.red_planet == true or map_styles.red_planet_2 == true or map_styles.dagobah_swamp == true then
	wreck_item_pool = {}
	wreck_item_pool = {{name="iron-gear-wheel", count=32},{name="iron-plate", count=64},{name="rocket-control-unit", count=1} ,{name="coal", count=4},{name="rocket-launcher", count=1},{name="rocket", count=32},{name="copper-cable", count=128},{name="land-mine", count=64},{name="railgun", count=1},{name="railgun-dart", count=128},{name="fast-inserter", count=8},{name="stack-filter-inserter", count=2},{name="belt-immunity-equipment", count=1},{name="fusion-reactor-equipment", count=1},{name="electric-engine-unit", count=8},{name="exoskeleton-equipment", count=1},{name="rocket-fuel", count=10},{name="used-up-uranium-fuel-cell", count=3},{name="uranium-fuel-cell", count=2}}
--end

local function place_entities(surface, entity_list)
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

local function auto_place_entity_around_target(entity, scan_radius, mode, density, surface)
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

local function create_entitie_cluster(name, pos, amount)

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

local function create_rock_cluster(pos, amount)
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

local function create_tree_cluster(pos, amount)
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

local function find_tile_placement_spot_around_target_position(tilename, position, mode, density)
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

local function create_tile_cluster(tilename,position,amount)
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

local function on_chunk_generated(event)

	if map_styles.resource_rainbow == true then
		resource_rainbow(event)
	end

	if map_styles.perlin_01 == true then
		perlin_01(event)
	end

	if map_styles.perlin_02 == true then
		perlin_02(event)
	end

	if map_styles.rivers == true then
		rivers(event)
	end

	if map_styles.square == true then
		local size = 30
		size = size / 2
		size = round(size,0)
		local negative_size = size * -1
		local area = event.area
		local surface = event.surface
		local tiles = {}
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				local pos_x = event.area.left_top.x + x
				local pos_y = event.area.left_top.y + y
				if pos_y >= size or pos_x >= size or pos_x < negative_size or pos_y < negative_size then
					table.insert(tiles, {name = "out-of-map", position = {pos_x,pos_y}})
				end
			end
		end
		surface.set_tiles(tiles)
	end

	if map_styles.circle == true then
		local radius = 1609
		local radsquare = radius*radius
		local surface = event.surface
		local tiles = {}
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				local tile_distance_to_center = nil
				local pos_x = event.area.left_top.x + x
				local pos_y = event.area.left_top.y + y
				local a = pos_y * pos_y
				local b = pos_x * pos_x
				local tile_distance_to_center = a + b
				if tile_distance_to_center >= radsquare then
						table.insert(tiles, {name = "out-of-map", position = {pos_x,pos_y}})
				end
			end
		end
		surface.set_tiles(tiles)
	end

	if map_styles.resource_cluster_truck == true then
		resource_cluster_truck(event)
	end

	if map_styles.up == true then
		up(event)
	end

	if map_styles.right == true then
		right(event)
	end

	if map_styles.dagobah_swamp == true then
		dagobah_swamp(event)
	end

	if map_styles.red_planet == true then
		red_planet(event)
	end
	if map_styles.red_planet_2 == true then
		red_planet_2(event)
	end

	if map_styles.red_planet_2_messy_resources == true then
		red_planet_2_messy_resources(event)
	end


	if map_styles.grey_void == true then
		grey_void(event)
	end
end

function resource_rainbow(event)
	if not global.perlin_noise_seed then global.perlin_noise_seed = math.random(1000,1000000) end
	local seed = global.perlin_noise_seed
	local entities = event.surface.find_entities(event.area)
	for _, entity in pairs(entities) do
		if entity.type == "resource" and entity.name ~= "crude-oil" then
			entity.destroy()
		end
	end

	local width_modifier = 0.8

	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos_x = event.area.left_top.x + x
			local pos_y = event.area.left_top.y + y
			local noise_terrain_1 = perlin:noise(((pos_x+seed)/350),((pos_y+seed)/350),0)
			local noise_terrain_2 = perlin:noise(((pos_x+seed)/50),((pos_y+seed)/50),0)
			local noise_terrain = noise_terrain_1 + (noise_terrain_2 * 0.01)

			if noise_terrain > -0.1 * width_modifier and noise_terrain <= -0.075 * width_modifier then
				local a = pos_x
				local b = pos_y
				local c = 1
				if event.area.right_bottom.x < 0 then a = event.area.right_bottom.x * -1 end
				if event.area.right_bottom.y < 0 then b = event.area.right_bottom.y * -1 end
				if a > b	then	c = a	else c = b	end
				local resource_amount_distance_multiplicator = (((c + 1) / 75) / 75) + 1
				local noise_resource_amount_modifier = perlin:noise(((pos_x+seed)/200),((pos_y+seed)/200),0)
				local resource_amount = 1 + ((700 + (700*noise_resource_amount_modifier*0.2)) * resource_amount_distance_multiplicator)
				if event.surface.can_place_entity {name="iron-ore", position={pos_x,pos_y}} then
					event.surface.create_entity {name="iron-ore", position={pos_x,pos_y}, amount=resource_amount}
				end
			end
			if noise_terrain > -0.075 * width_modifier and noise_terrain <= -0.05 * width_modifier then
				local a = pos_x
				local b = pos_y
				local c = 1
				if event.area.right_bottom.x < 0 then a = event.area.right_bottom.x * -1 end
				if event.area.right_bottom.y < 0 then b = event.area.right_bottom.y * -1 end
				if a > b	then	c = a	else c = b	end
				local resource_amount_distance_multiplicator = (((c + 1) / 75) / 75) + 1
				local noise_resource_amount_modifier = perlin:noise(((pos_x+seed)/200),((pos_y+seed)/200),0)
				local resource_amount = 1 + ((400 + (400*noise_resource_amount_modifier*0.2)) * resource_amount_distance_multiplicator)
				if event.surface.can_place_entity {name="copper-ore", position={pos_x,pos_y}} then
					event.surface.create_entity {name="copper-ore", position={pos_x,pos_y}, amount=resource_amount}
				end
			end
			if noise_terrain > -0.05 * width_modifier and noise_terrain <= -0.04 * width_modifier then
				local a = pos_x
				local b = pos_y
				local c = 1
				if event.area.right_bottom.x < 0 then a = event.area.right_bottom.x * -1 end
				if event.area.right_bottom.y < 0 then b = event.area.right_bottom.y * -1 end
				if a > b	then	c = a	else c = b	end
				local resource_amount_distance_multiplicator = (((c + 1) / 75) / 75) + 1
				local noise_resource_amount_modifier = perlin:noise(((pos_x+seed)/200),((pos_y+seed)/200),0)
				local resource_amount = 1 + ((400 + (400*noise_resource_amount_modifier*0.2)) * resource_amount_distance_multiplicator)
				if event.surface.can_place_entity {name="stone", position={pos_x,pos_y}} then
					event.surface.create_entity {name="stone", position={pos_x,pos_y}, amount=resource_amount}
				end
			end
			if noise_terrain > -0.04 * width_modifier and noise_terrain <= -0.03 * width_modifier then
				local a = pos_x
				local b = pos_y
				local c = 1
				if event.area.right_bottom.x < 0 then a = event.area.right_bottom.x * -1 end
				if event.area.right_bottom.y < 0 then b = event.area.right_bottom.y * -1 end
				if a > b	then	c = a	else c = b	end
				local resource_amount_distance_multiplicator = (((c + 1) / 75) / 75) + 1
				local noise_resource_amount_modifier = perlin:noise(((pos_x+seed)/200),((pos_y+seed)/200),0)
				local resource_amount = 1 + ((400 + (400*noise_resource_amount_modifier*0.2)) * resource_amount_distance_multiplicator)
				if event.surface.can_place_entity {name="coal", position={pos_x,pos_y}} then
					event.surface.create_entity {name="coal", position={pos_x,pos_y}, amount=resource_amount}
				end
			end
			if noise_terrain > -0.03 * width_modifier and noise_terrain <= -0.02 * width_modifier then
				local a = pos_x
				local b = pos_y
				local c = 1
				if event.area.right_bottom.x < 0 then a = event.area.right_bottom.x * -1 end
				if event.area.right_bottom.y < 0 then b = event.area.right_bottom.y * -1 end
				if a > b	then	c = a	else c = b	end
				local resource_amount_distance_multiplicator = (((c + 1) / 75) / 75) + 1
				local noise_resource_amount_modifier = perlin:noise(((pos_x+seed)/200),((pos_y+seed)/200),0)
				local resource_amount = 1 + ((400 + (400*noise_resource_amount_modifier*0.2)) * resource_amount_distance_multiplicator)
				if event.surface.can_place_entity {name="uranium-ore", position={pos_x,pos_y}} then
					event.surface.create_entity {name="uranium-ore", position={pos_x,pos_y}, amount=resource_amount}
				end
			end
		end
	end
end

function perlin_01(event)
		local seed = global.perlin_noise_seed
		local tiles = {}
		local entities = event.surface.find_entities(event.area)
		for _, entity in pairs(entities) do
			if entity.type ~= "player" then
				entity.destroy()
			end
		end
		local entity_list = {}
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				local pos_x = event.area.left_top.x + x
				local pos_y = event.area.left_top.y + y
					local p = perlin:noise(((pos_x+seed)/10),((pos_y+seed)/10),0)
					p = round((p * 100),0) + 50
					if p < 55 then table.insert(tiles, {name = "concrete", position = {pos_x,pos_y}}) end
					if p >= 55 then table.insert(tiles, {name = "stone-path", position = {pos_x,pos_y}}) end
					if p >= 56 and p <= 80 then
						if event.surface.can_place_entity {name="stone-wall", position={pos_x,pos_y}} then
							event.surface.create_entity {name="stone-wall", position={pos_x,pos_y}}
						end
					end
					if p >= 99 and p < 100 then
						if event.surface.can_place_entity {name="accumulator", position={pos_x,pos_y}} then
							event.surface.create_entity {name="accumulator", position={pos_x,pos_y}}
						end
					end
					if p >= 102 and p < 105 then
						if event.surface.can_place_entity {name="substation", position={pos_x,pos_y}} then
							event.surface.create_entity {name="substation", position={pos_x,pos_y}}
						end
					end
					if p >= 105 and p < 111 then
						if event.surface.can_place_entity {name="solar-panel", position={pos_x,pos_y}} then
							event.surface.create_entity {name="solar-panel", position={pos_x,pos_y}}
						end
					end
					if p >= 111 then
						if event.surface.can_place_entity {name="laser-turret", position={pos_x,pos_y}} then
							event.surface.create_entity {name="laser-turret", position={pos_x,pos_y}}
						end
					end
			end
		end
		event.surface.set_tiles(tiles,true)
end

function perlin_02(event)
	if not global.perlin_noise_seed then global.perlin_noise_seed = 1000000 end
	local seed = global.perlin_noise_seed
	local tiles = {}
	local entities = event.surface.find_entities(event.area)
	for _, entity in pairs(entities) do
		if entity.type ~= "player" then
			entity.destroy()
		end
	end
	local entity_list = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos_x = event.area.left_top.x + x
			local pos_y = event.area.left_top.y + y
				local p = perlin:noise(((pos_x+seed)/150),((pos_y+seed)/150),0)
				local p2 = perlin:noise(((pos_x+seed)/45),((pos_y+seed)/45),0)
				local p3 = perlin:noise(((pos_x+seed)/10),((pos_y+seed)/10),0)
				p2 = p2 * 0.2
				p3 = p3 * 0.1
				if p + p2 < -0.2 then table.insert(tiles, {name = "water", position = {pos_x,pos_y}}) end
				if p + p2 >= -0.2 and p + p2 <= 0.5 then table.insert(tiles, {name = "grass", position = {pos_x,pos_y}}) end
				if p + p2  >= 0.5 then table.insert(tiles, {name = "red-desert-dark", position = {pos_x,pos_y}}) end

		end
	end
	event.surface.set_tiles(tiles,true)
end

function rivers(event)

			--- maybe add fish in rivers

			if not global.perlin_noise_seed then global.perlin_noise_seed = math.random(1000,1000000) end
			local seed = global.perlin_noise_seed
			local tiles = {}
			for x = 0, 31, 1 do
				for y = 0, 31, 1 do
					local pos_x = event.area.left_top.x + x
					local pos_y = event.area.left_top.y + y
					local noise_terrain_1 = perlin:noise(((pos_x+seed)/150),((pos_y+seed)/150),0)
					local noise_terrain_2 = perlin:noise(((pos_x+seed)/75),((pos_y+seed)/75),0)
					local noise_terrain_3 = perlin:noise(((pos_x+seed)/50),((pos_y+seed)/50),0)
					local noise_terrain_4 = perlin:noise(((pos_x+seed)/7),((pos_y+seed)/7),0)
					local noise_terrain = noise_terrain_1 + (noise_terrain_2 * 0.2) + (noise_terrain_3 * 0.1) + (noise_terrain_4 * 0.02)
					local tile_to_insert
					if noise_terrain > -0.03 and noise_terrain < 0.03 then
						tile_to_insert = "water-green"
						local a = pos_x + 1
						table.insert(tiles, {name = tile_to_insert, position = {a,pos_y}})
						local a = pos_y + 1
						table.insert(tiles, {name = tile_to_insert, position = {pos_x,a}})
						local a = pos_x - 1
						table.insert(tiles, {name = tile_to_insert, position = {a,pos_y}})
						local a = pos_y - 1
						table.insert(tiles, {name = tile_to_insert, position = {pos_x,a}})
						table.insert(tiles, {name = tile_to_insert, position = {pos_x,pos_y}})
					end
				end
			end
			event.surface.set_tiles(tiles,true)
end

function circle(event)
	local radius = 1609
	local radsquare = radius*radius
	local surface = event.surface
	local tiles = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local tile_distance_to_center = nil
			local pos_x = event.area.left_top.x + x
			local pos_y = event.area.left_top.y + y
			local a = pos_y * pos_y
			local b = pos_x * pos_x
			local tile_distance_to_center = a + b
			if tile_distance_to_center >= radsquare then
					table.insert(tiles, {name = "out-of-map", position = {pos_x,pos_y}})
			end
		end
	end
	surface.set_tiles(tiles)
end

function resource_cluster_truck(event)
	if not global.resource_cluster_truck then global.resource_cluster_truck = 1 end
	local entities = event.surface.find_entities(event.area)
	for _, entity in pairs(entities) do
		if entity.type == "resource" then
			entity.destroy()
		end
	end
	local pos_x = event.area.left_top.x + math.random(10, 20)
	local pos_y = event.area.left_top.y + math.random(10, 20)
	local radius = 10
	local surface = event.surface
	local tiles = {}
	local center = 15
	local ore_spawn = math.random(1,6)
	local oil_amount = math.random(10000,150000)
	local resource_amount = math.random(400,7000)
	if math.random(1,12) == 1 then resource_amount = math.random(7000,150000) end
	if global.resource_cluster_truck % 2 == 1 then
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				local tile_distance_to_center = nil
				local pos_x = event.area.left_top.x + x
				local pos_y = event.area.left_top.y + y
				center_x = event.area.left_top.x + center
				center_y = event.area.left_top.y + center
				local a = (pos_x - center_x) * (pos_x - center_x)
				local b = (pos_y - center_y) * (pos_y - center_y)
				local tile_distance_to_center = math.sqrt(a + b)
				if tile_distance_to_center < radius then

					if tile_distance_to_center <= 0 then tile_distance_to_center = tile_distance_to_center * -1 end
					tile_distance_to_center = tile_distance_to_center + 1

					local amount = resource_amount
					if tile_distance_to_center < radius / 2 then
						amount = resource_amount * 1.5
					end
					if tile_distance_to_center < radius / 3 then
						amount = resource_amount * 2
					end

					if ore_spawn == 6 then amount = oil_amount end

					if ore_spawn == 1 then
						if surface.can_place_entity {name="stone", position={x=pos_x,y=pos_y}, amount = amount} then
							surface.create_entity {name="stone", position={x=pos_x,y=pos_y}, amount = amount}
						end
					end
					if ore_spawn == 2 then
						if surface.can_place_entity {name="iron-ore", position={x=pos_x,y=pos_y}, amount = amount} then
							surface.create_entity {name="iron-ore", position={x=pos_x,y=pos_y}, amount = amount}
						end
					end
					if ore_spawn == 3 then
						if surface.can_place_entity {name="coal", position={x=pos_x,y=pos_y}, amount = amount} then
							surface.create_entity {name="coal", position={x=pos_x,y=pos_y}, amount = amount}
						end
					end
					if ore_spawn == 4 then
						if surface.can_place_entity {name="copper-ore", position={x=pos_x,y=pos_y}, amount = amount} then
							surface.create_entity {name="copper-ore", position={x=pos_x,y=pos_y}, amount = amount}
						end
					end
					if ore_spawn == 5 then
						if surface.can_place_entity {name="uranium-ore", position={x=pos_x,y=pos_y}, amount = amount} then
							surface.create_entity {name="uranium-ore", position={x=pos_x,y=pos_y}, amount = amount}
						end
					end
					if ore_spawn == 6 then
						if surface.can_place_entity {name="crude-oil", position={x=pos_x,y=pos_y}, amount = amount} then
							surface.create_entity {name="crude-oil", position={x=pos_x,y=pos_y}, amount = amount}
						end
					end
				end
			end
		end
	end
	global.resource_cluster_truck = global.resource_cluster_truck + 1
end

function up(event)
	local area = event.area
	local surface = event.surface
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

function right(event)
	local area = event.area
	local surface = event.surface
	local tiles = {}
	if event.area.left_top.x < -75 or event.area.left_top.y > 32 or event.area.left_top.y < -400 then
		for x = event.area.left_top.x, event.area.right_bottom.x do
			for y = event.area.left_top.y, event.area.right_bottom.y do
				table.insert(tiles, {name = "out-of-map", position = {x,y}})
			end
		end
		surface.set_tiles(tiles)
	end
end

function dagobah_swamp(event)
	local area = event.area
	local surface = event.surface
	local tiles = {}
	local decoratives = {}

	local entities = surface.find_entities(area)
	for _, entity in pairs(entities) do
		if entity.type == "simple-entity" or entity.type == "tree" then
			if entity.name ~= "tree-09" and entity.name ~= "tree-07" and entity.name ~= "tree-06" then --and entity.name ~= "tree-04"
				entity.destroy()
			end
		end
	end
	local forest_cluster = true
	if math.random(1,4) == 1 then forest_cluster = false end

	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos_x = event.area.left_top.x + x
			local pos_y = event.area.left_top.y + y
			local pos = {x = pos_x,y = pos_y}
			local tile = surface.get_tile(pos_x,pos_y)
			local tile_to_insert = tile
			local entity_placed = false
			if tile.name ~= "water-green" then
				table.insert(tiles, {name = "grass", position = {pos_x,pos_y}})

				local entity_list = {}
				table.insert(entity_list, {name="big-ship-wreck-1", pos={pos_x,pos_y},chance = 65000, health="random"})
				table.insert(entity_list, {name="big-ship-wreck-2", pos={pos_x,pos_y},chance = 65000, health="random"})
				table.insert(entity_list, {name="big-ship-wreck-3", pos={pos_x,pos_y},chance = 65000, health="random"})
				local b, placed_entity = place_entities(surface, entity_list)
				if b == true then
					placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
					placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
					placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
				end

				local entity_list = {}
				table.insert(entity_list, {name="tree-04", pos={pos_x,pos_y},chance = 400})
				table.insert(entity_list, {name="tree-09", pos={pos_x,pos_y},chance = 1000})
				table.insert(entity_list, {name="tree-07", pos={pos_x,pos_y},chance = 400})
				table.insert(entity_list, {name="tree-06", pos={pos_x,pos_y},chance = 150})
				table.insert(entity_list, {name="stone-rock", pos={pos_x,pos_y},chance = 400})
				table.insert(entity_list, {name="green-coral", pos={pos_x,pos_y},chance = 10000})
				table.insert(entity_list, {name="medium-ship-wreck", pos={pos_x,pos_y},chance = 25000, health="random"})
				table.insert(entity_list, {name="small-ship-wreck", pos={pos_x,pos_y},chance = 25000, health="random"})
				table.insert(entity_list, {name="car", pos={pos_x,pos_y},chance = 125000, health="low"})
				table.insert(entity_list, {name="stone-furnace", pos={pos_x,pos_y},chance = 100000, health="random", force="enemy"})
				local b, placed_entity = place_entities(surface, entity_list)

				if forest_cluster == true then
					if math.random(1,800) == 1 then create_tree_cluster(pos, 120) end
				end
			end
		end
	end
	surface.set_tiles(tiles,true)

	--check for existing chunk if you would overwrite decoratives
	local for_start_x = 0
	local for_end_x = 31
	local for_start_y = 0
	local for_end_y = 31
	local testing_pos = event.area.left_top.x - 1
	local tile = surface.get_tile(testing_pos, event.area.left_top.y)
	if tile.name then for_start_x = -1 end
	local testing_pos = event.area.left_top.y - 1
	local tile = surface.get_tile(event.area.left_top.x, testing_pos)
	if tile.name then for_start_y = -1 end
	local testing_pos = event.area.right_bottom.x
	local tile = surface.get_tile(testing_pos, event.area.right_bottom.y)
	if tile.name then for_end_x = 32 end
	local testing_pos = event.area.right_bottom.y
	local tile = surface.get_tile(event.area.right_bottom.x, testing_pos)
	if tile.name then for_end_y = 32 end

	for x = for_start_x, for_end_x, 1 do
		for y = for_start_y, for_end_y, 1 do
			local pos_x = event.area.left_top.x + x
			local pos_y = event.area.left_top.y + y
			local tile = surface.get_tile(pos_x, pos_y)
			local decal_has_been_placed = false

			if tile.name == "grass" then
				if decal_has_been_placed == false then
					local r = math.random(1,3)
					if r == 1 then
						table.insert(decoratives, {name="green-carpet-grass", position={pos_x,pos_y}, amount=1})
						decal_has_been_placed = false
					end
				end
				if decal_has_been_placed == false then
					local r = math.random(1,7)
					if r == 1 then
						table.insert(decoratives, {name="green-hairy-grass", position={pos_x,pos_y}, amount=1})
						decal_has_been_placed = false
					end
				end
				if decal_has_been_placed == false then
					local r = math.random(1,10)
					if r == 1 then
						table.insert(decoratives, {name="green-bush-mini", position={pos_x,pos_y}, amount=1})
						decal_has_been_placed = false
					end
				end
				if decal_has_been_placed == false then
					local r = math.random(1,6)
					if r == 1 then
						table.insert(decoratives, {name="green-pita", position={pos_x,pos_y}, amount=1})
						decal_has_been_placed = false
					end
				end
				if decal_has_been_placed == false then
					local r = math.random(1,12)
					if r == 1 then
						table.insert(decoratives, {name="green-small-grass", position={pos_x,pos_y}, amount=1})
						decal_has_been_placed = false
					end
				end
				if decal_has_been_placed == false then
					local r = math.random(1,25)
					if r == 1 then
						table.insert(decoratives, {name="green-asterisk", position={pos_x,pos_y}, amount=1})
						decal_has_been_placed = false
					end
				end
			end
			if tile.name == "water" or tile.name == "water-green" then

				if decal_has_been_placed == false then
					local r = math.random(1,18)
					if r == 1 then
						table.insert(decoratives, {name="green-carpet-grass", position={pos_x,pos_y}, amount=1})
						decal_has_been_placed = false
					end
				end
				if decal_has_been_placed == false then
					local r = math.random(1,950)
					if r == 1 then
						table.insert(decoratives, {name="green-small-grass", position={pos_x,pos_y}, amount=1})
						decal_has_been_placed = false
					end
				end
				if decal_has_been_placed == false then
					local r = math.random(1,150)
					if r == 1 then
						table.insert(decoratives, {name="green-bush-mini", position={pos_x,pos_y}, amount=1})
						decal_has_been_placed = false
					end
				end
			end
		end
	end
	for _,deco in pairs(decoratives) do
		surface.create_decoratives{check_collision=false, decoratives={deco}}
	end
end

function red_planet(event)

end

function red_planet_2(event)
	if not global.perlin_noise_seed then global.perlin_noise_seed = math.random(1000,1000000) end
	local surface = game.surfaces[1]
	local tiles = {}
	local decoratives = {}
	local tree_to_place = {"dry-tree","dry-hairy-tree","tree-06","tree-06","tree-01","tree-02","tree-03"}
	local entities = surface.find_entities(event.area)
	for _, entity in pairs(entities) do
		if entity.type == "simple-entity" or entity.type == "resource" or entity.type == "tree" then
			entity.destroy()
		end
	end

	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos_x = event.area.left_top.x + x
			local pos_y = event.area.left_top.y + y
			local tile = surface.get_tile(pos_x,pos_y)
			local tile_to_insert = "concrete"

			local a = pos_x
			local b = pos_y
			local c = 1
			if event.area.right_bottom.x < 0 then a = event.area.right_bottom.x * -1 end
			if event.area.right_bottom.y < 0 then b = event.area.right_bottom.y * -1 end
			if a > b	then	c = a	else c = b	end
			local resource_amount_distance_multiplicator = (((c + 1) / 75) / 75) + 1
			local resource_entity_placed = false

			local entity_list = {}
			table.insert(entity_list, {name="big-ship-wreck-1", pos={pos_x,pos_y},chance = 65000, health="random"})
			table.insert(entity_list, {name="big-ship-wreck-2", pos={pos_x,pos_y},chance = 65000, health="random"})
			table.insert(entity_list, {name="big-ship-wreck-3", pos={pos_x,pos_y},chance = 65000, health="random"})
			table.insert(entity_list, {name="medium-ship-wreck", pos={pos_x,pos_y},chance = 25000, health="medium"})
			table.insert(entity_list, {name="small-ship-wreck", pos={pos_x,pos_y},chance = 15000, health="medium"})
			table.insert(entity_list, {name="car", pos={pos_x,pos_y},chance = 150000, health="low"})
			table.insert(entity_list, {name="laser-turret", pos={pos_x,pos_y},chance = 100000, force="enemy", health="low"})
			table.insert(entity_list, {name="nuclear-reactor", pos={pos_x,pos_y},chance = 1000000, force="enemy", health="medium"})
			local b, placed_entity = place_entities(surface, entity_list)
			if b == true then
				if placed_entity.name == "big-ship-wreck-1" or placed_entity.name == "big-ship-wreck-2" or placed_entity.name == "big-ship-wreck-3" then
					placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
					placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
					placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
				end
			end

			local seed_increment_number = 10000
			local seed = global.perlin_noise_seed

			local noise_terrain_1 = perlin:noise(((pos_x+seed)/400),((pos_y+seed)/400),0)
			noise_terrain_1 = noise_terrain_1 * 100
			seed = seed + seed_increment_number
			local noise_terrain_2 = perlin:noise(((pos_x+seed)/250),((pos_y+seed)/250),0)
			noise_terrain_2 = noise_terrain_2 * 100
			seed = seed + seed_increment_number
			local noise_terrain_3 = perlin:noise(((pos_x+seed)/100),((pos_y+seed)/100),0)
			noise_terrain_3 = noise_terrain_3 * 50
			seed = seed + seed_increment_number
			local noise_terrain_4 = perlin:noise(((pos_x+seed)/20),((pos_y+seed)/20),0)
			noise_terrain_4 = noise_terrain_4 * 10
			seed = seed + seed_increment_number
			local noise_terrain_5 = perlin:noise(((pos_x+seed)/5),((pos_y+seed)/5),0)
			noise_terrain_5 = noise_terrain_5 * 4
			seed = seed + seed_increment_number
			local noise_sand = perlin:noise(((pos_x+seed)/18),((pos_y+seed)/18),0)
			noise_sand = noise_sand * 10

			--DECORATIVES
			seed = seed + seed_increment_number
			local noise_decoratives_1 = perlin:noise(((pos_x+seed)/20),((pos_y+seed)/20),0)
			noise_decoratives_1 = noise_decoratives_1
			seed = seed + seed_increment_number
			local noise_decoratives_2 = perlin:noise(((pos_x+seed)/30),((pos_y+seed)/30),0)
			noise_decoratives_2 = noise_decoratives_2
			seed = seed + seed_increment_number
			local noise_decoratives_3 = perlin:noise(((pos_x+seed)/30),((pos_y+seed)/30),0)
			noise_decoratives_3 = noise_decoratives_3


			seed = seed + seed_increment_number
			local noise_water_1 = perlin:noise(((pos_x+seed)/250),((pos_y+seed)/300),0)
			noise_water_1 = noise_water_1 * 100
			seed = seed + seed_increment_number
			local noise_water_2 = perlin:noise(((pos_x+seed)/100),((pos_y+seed)/150),0)
			noise_water_2 = noise_water_2 * 50

			--RESOURCES
			seed = seed + seed_increment_number
			local noise_resources = perlin:noise(((pos_x+seed)/100),((pos_y+seed)/100),0)
			seed = seed + seed_increment_number
			local noise_resources_2 = perlin:noise(((pos_x+seed)/40),((pos_y+seed)/40),0)
			seed = seed + seed_increment_number
			local noise_resources_3 = perlin:noise(((pos_x+seed)/20),((pos_y+seed)/20),0)
			noise_resources = noise_resources * 50 + noise_resources_2 * 20 + noise_resources_3 * 20
			noise_resources = noise_resources_2 * 100

			seed = seed + seed_increment_number
			local noise_resource_amount_modifier = perlin:noise(((pos_x+seed)/200),((pos_y+seed)/200),0)
			local resource_amount = 1 + ((400 + (400*noise_resource_amount_modifier*0.2)) * resource_amount_distance_multiplicator)
			seed = seed + seed_increment_number
			local noise_resources_iron_and_copper = perlin:noise(((pos_x+seed)/250),((pos_y+seed)/250),0)
			noise_resources_iron_and_copper = noise_resources_iron_and_copper * 100
			seed = seed + seed_increment_number
			local noise_resources_coal_and_uranium = perlin:noise(((pos_x+seed)/250),((pos_y+seed)/250),0)
			noise_resources_coal_and_uranium = noise_resources_coal_and_uranium * 100
			seed = seed + seed_increment_number
			local noise_resources_stone_and_oil = perlin:noise(((pos_x+seed)/150),((pos_y+seed)/150),0)
			noise_resources_stone_and_oil = noise_resources_stone_and_oil * 100

			seed = seed + seed_increment_number
			local noise_red_desert_rocks_1 = perlin:noise(((pos_x+seed)/20),((pos_y+seed)/20),0)
			noise_red_desert_rocks_1 = noise_red_desert_rocks_1 * 100
			seed = seed + seed_increment_number
			local noise_red_desert_rocks_2 = perlin:noise(((pos_x+seed)/10),((pos_y+seed)/10),0)
			noise_red_desert_rocks_2 = noise_red_desert_rocks_2 * 50
			seed = seed + seed_increment_number
			local noise_red_desert_rocks_3 = perlin:noise(((pos_x+seed)/5),((pos_y+seed)/5),0)
			noise_red_desert_rocks_3 = noise_red_desert_rocks_3 * 100
			seed = seed + seed_increment_number
			local noise_forest = perlin:noise(((pos_x+seed)/100),((pos_y+seed)/100),0)
			noise_forest = noise_forest * 100
			seed = seed + seed_increment_number
			local noise_forest_2 = perlin:noise(((pos_x+seed)/20),((pos_y+seed)/20),0)
			noise_forest_2 = noise_forest_2 * 20

			local terrain_smoothing = math.random(0,1)
			local place_tree_number

			if noise_terrain_1 < 8 + terrain_smoothing + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
				 tile_to_insert = "red-desert"
				if noise_water_1 + noise_water_2 + noise_sand > -10 and noise_water_1 + noise_water_2 + noise_sand < 25 and noise_terrain_1 < -52 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 + noise_terrain_5 then
					tile_to_insert = "sand"
					place_tree_number = math.random(3,#tree_to_place)
				else
					place_tree_number = math.random(1,(#tree_to_place - 3))
				end

				if noise_water_1 + noise_water_2 > 0 and noise_water_1 + noise_water_2 < 15 and noise_terrain_1 < -60 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 + noise_terrain_5 then
					tile_to_insert = "water"
					local a = pos_x + 1
					table.insert(tiles, {name = tile_to_insert, position = {a,pos_y}})
					local a = pos_y + 1
					table.insert(tiles, {name = tile_to_insert, position = {pos_x,a}})
					local a = pos_x - 1
					table.insert(tiles, {name = tile_to_insert, position = {a,pos_y}})
					local a = pos_y - 1
					table.insert(tiles, {name = tile_to_insert, position = {pos_x,a}})
					if noise_water_1 + noise_water_2 < 2 or noise_water_1 + noise_water_2 > 13 then
						if math.random(1,15) == 1 then
							table.insert(decoratives, {name="green-carpet-grass", position={pos_x,pos_y}, amount=1})
						end
						if math.random(1,15) == 1 then
							table.insert(decoratives, {name="brown-cane-cluster", position={pos_x,pos_y}, amount=1})
						end
					end
				end

				if tile_to_insert ~= "water" then
					if noise_water_1 + noise_water_2 > 16 and noise_water_1 + noise_water_2 < 25 and noise_terrain_1 < -55 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 + noise_terrain_5 then
						if math.random(1,35) == 1 then
							table.insert(decoratives, {name="brown-carpet-grass", position={pos_x,pos_y}, amount=1})
						end
					end
					if noise_water_1 + noise_water_2 > -10 and noise_water_1 + noise_water_2 < -1 and noise_terrain_1 < -55 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 + noise_terrain_5 then
						if math.random(1,35) == 1 then
							table.insert(decoratives, {name="brown-carpet-grass", position={pos_x,pos_y}, amount=1})
						end
					end
					if noise_decoratives_1 > 0.5 and noise_decoratives_1 <= 0.8 then
						if math.random(1,12) == 1 then table.insert(decoratives, {name="red-desert-bush", position={pos_x,pos_y}, amount=1}) end
					end
					if noise_decoratives_1 > 0.4 and noise_decoratives_1 <= 0.5 then
						if math.random(1,4) == 1 then table.insert(decoratives, {name="red-desert-bush", position={pos_x,pos_y}, amount=1}) end
					end
				end

				--HAPPY TREES
				if noise_terrain_1 < -30 + noise_terrain_2 + noise_terrain_3 + noise_terrain_5 + noise_forest_2 then
					if noise_forest > 0 and noise_forest <= 10 then
						if math.random(1,50) == 1 then
							if surface.can_place_entity {name=tree_to_place[place_tree_number], position={pos_x,pos_y}} then
								surface.create_entity {name=tree_to_place[place_tree_number], position={pos_x,pos_y}}
							end
						end
					end
					if noise_forest > 10 and noise_forest <= 20 then
						if math.random(1,25) == 1 then
							if surface.can_place_entity {name=tree_to_place[place_tree_number], position={pos_x,pos_y}} then
								surface.create_entity {name=tree_to_place[place_tree_number], position={pos_x,pos_y}}
							end
						end
					end
					if noise_forest > 20 then
						if math.random(1,10) == 1 then
							if surface.can_place_entity {name=tree_to_place[place_tree_number], position={pos_x,pos_y}} then
								surface.create_entity {name=tree_to_place[place_tree_number], position={pos_x,pos_y}}
							end
						end
					end
				end

				if tile_to_insert ~= "water" then
					if noise_terrain_1 < 8 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 and noise_terrain_1 > -5 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
						if math.random(1,45) == 1 then
							table.insert(decoratives, {name="red-desert-rock-medium", position={pos_x,pos_y}, amount=1})
						end
						if math.random(1,20) == 1 then
							table.insert(decoratives, {name="red-desert-rock-tiny", position={pos_x,pos_y}, amount=1})
						end
					else
						if math.random(1,375) == 1 then
							table.insert(decoratives, {name="red-desert-rock-medium", position={pos_x,pos_y}, amount=1})
						end
						if math.random(1,45) == 1 then
							table.insert(decoratives, {name="red-desert-rock-tiny", position={pos_x,pos_y}, amount=1})
						end
					end
				end
			else
				tile_to_insert = "red-desert-dark"
			end
			if resource_entity_placed == false and noise_resources_coal_and_uranium + noise_resources < -72 and noise_terrain_1 > 65 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
				if surface.can_place_entity {name="uranium-ore", position={pos_x,pos_y}} then
					surface.create_entity {name="uranium-ore", position={pos_x,pos_y}, amount=resource_amount}
					resource_entity_placed = true
				end
			end
			if resource_entity_placed == false and noise_resources_iron_and_copper + noise_resources > 72 and noise_terrain_1 > 15 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
				if surface.can_place_entity {name="iron-ore", position={pos_x,pos_y}} then
					surface.create_entity {name="iron-ore", position={pos_x,pos_y}, amount=resource_amount}
					resource_entity_placed = true
				end
			end
			if resource_entity_placed == false and noise_resources_coal_and_uranium + noise_resources > 70 and noise_terrain_1 > 15 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
				if surface.can_place_entity {name="coal", position={pos_x,pos_y}} then
					surface.create_entity {name="coal", position={pos_x,pos_y}, amount=resource_amount}
					resource_entity_placed = true
				end
			end
			if resource_entity_placed == false and noise_resources_iron_and_copper + noise_resources < -72 and noise_terrain_1 > 15 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
				if surface.can_place_entity {name="copper-ore", position={pos_x,pos_y}} then
					surface.create_entity {name="copper-ore", position={pos_x,pos_y}, amount=resource_amount}
					resource_entity_placed = true
				end
			end
			if resource_entity_placed == false and noise_resources_stone_and_oil + noise_resources > 72 and noise_terrain_1 > 15 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
				if surface.can_place_entity {name="stone", position={pos_x,pos_y}} then
					surface.create_entity {name="stone", position={pos_x,pos_y}, amount=resource_amount}
					resource_entity_placed = true
				end
			end
			if resource_entity_placed == false and noise_resources_stone_and_oil + noise_resources < -70 and noise_terrain_1 < -50 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
				if math.random(1,42) == 1 then
					if surface.can_place_entity {name="crude-oil", position={pos_x,pos_y}} then
						surface.create_entity {name="crude-oil", position={pos_x,pos_y}, amount=(resource_amount*500)}
						resource_entity_placed = true
					end
				end
			end

			if resource_entity_placed == false and noise_red_desert_rocks_1 + noise_red_desert_rocks_2 + noise_red_desert_rocks_3 > 20 and noise_red_desert_rocks_1 + noise_red_desert_rocks_2 < 60 and noise_terrain_1 > 7 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
				if math.random(1,3) == 1 then
					if math.random(1,3) == 1 then
						if surface.can_place_entity {name="red-desert-rock-huge-01", position={pos_x,pos_y}} then
							surface.create_entity {name="red-desert-rock-huge-01", position={pos_x,pos_y}}
						end
					else
						if surface.can_place_entity {name="red-desert-rock-big-01", position={pos_x,pos_y}} then
							surface.create_entity {name="red-desert-rock-big-01", position={pos_x,pos_y}}
						end
					end
				end
			end

			if noise_red_desert_rocks_1 + noise_red_desert_rocks_2 + noise_red_desert_rocks_3 + noise_terrain_4 >= 10 and noise_red_desert_rocks_1 + noise_red_desert_rocks_2 + noise_red_desert_rocks_3 < 20 and noise_terrain_1 > 7 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
				if math.random(1,5) == 1 then
					table.insert(decoratives, {name="red-desert-rock-medium", position={pos_x,pos_y}, amount=1})
				end
			else
				if tile_to_insert ~= "water" and tile_to_insert ~= "sand" then
					if math.random(1,15) == 1 then
						table.insert(decoratives, {name="red-desert-rock-small", position={pos_x,pos_y}, amount=1})
					else
						if math.random(1,8) == 1 then
							table.insert(decoratives, {name="red-desert-rock-tiny", position={pos_x,pos_y}, amount=1})
						end
					end
				end
			end
			if tile_to_insert ~= "water" then
				if noise_decoratives_2 > 0.6 then
					if math.random(1,9) == 1 then table.insert(decoratives, {name="red-asterisk", position={pos_x,pos_y}, amount=1}) end
				else
					if noise_decoratives_2 > 0.4 then
						if math.random(1,17) == 1 then table.insert(decoratives, {name="red-asterisk", position={pos_x,pos_y}, amount=1}) end
					end
				end
				if noise_decoratives_3 < -0.6 then
					if math.random(1,2) == 1 then table.insert(decoratives, {name="brown-fluff-dry", position={pos_x,pos_y}, amount=1}) end
				else
					if noise_decoratives_3 < -0.4 then
						if math.random(1,5) == 1 then table.insert(decoratives, {name="brown-fluff-dry", position={pos_x,pos_y}, amount=1}) end
					end
				end
			end
			table.insert(tiles, {name = tile_to_insert, position = {pos_x,pos_y}})
		end
	end

	surface.set_tiles(tiles,true)
	for _,deco in pairs(decoratives) do
		surface.create_decoratives{check_collision=false, decoratives={deco}}
	end
end

function red_planet_2_messy_resources(event)
	if not global.perlin_noise_seed then global.perlin_noise_seed = math.random(1000,1000000) end

	--787460
	local surface = game.surfaces[1]
	local tiles = {}
	local decoratives = {}
	local tree_to_place = {"dry-tree","dry-hairy-tree","tree-06","tree-06","tree-01","tree-02","tree-03"}
	local ore = {"iron-ore","coal","copper-ore","stone"}
	local entities = surface.find_entities(event.area)
	for _, entity in pairs(entities) do
		if entity.type == "simple-entity" or entity.type == "resource" or entity.type == "tree" then
			entity.destroy()
		end
	end

	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos_x = event.area.left_top.x + x
			local pos_y = event.area.left_top.y + y
			local tile = surface.get_tile(pos_x,pos_y)
			local tile_to_insert = "concrete"

			local a = pos_x
			local b = pos_y
			local c = 1
			if event.area.right_bottom.x < 0 then a = event.area.right_bottom.x * -1 end
			if event.area.right_bottom.y < 0 then b = event.area.right_bottom.y * -1 end
			if a > b	then	c = a	else c = b	end
			local resource_amount_distance_multiplicator = (((c + 1) / 75) / 75) + 1
			local resource_entity_placed = false

			local entity_list = {}
			table.insert(entity_list, {name="big-ship-wreck-1", pos={pos_x,pos_y},chance = 75000, health="random"})
			table.insert(entity_list, {name="big-ship-wreck-2", pos={pos_x,pos_y},chance = 75000, health="random"})
			table.insert(entity_list, {name="big-ship-wreck-3", pos={pos_x,pos_y},chance = 75000, health="random"})
			table.insert(entity_list, {name="medium-ship-wreck", pos={pos_x,pos_y},chance = 50000, health="medium"})
			table.insert(entity_list, {name="small-ship-wreck", pos={pos_x,pos_y},chance = 25000, health="medium"})
			table.insert(entity_list, {name="car", pos={pos_x,pos_y},chance = 250000, health="low"})
			table.insert(entity_list, {name="laser-turret", pos={pos_x,pos_y},chance = 250000, force="enemy", health="low"})
			table.insert(entity_list, {name="nuclear-reactor", pos={pos_x,pos_y},chance = 1000000, force="enemy", health="medium"})
			local b, placed_entity = place_entities(surface, entity_list)
			if b == true then
				if placed_entity.name == "big-ship-wreck-1" or placed_entity.name == "big-ship-wreck-2" or placed_entity.name == "big-ship-wreck-3" then
					placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
					placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
					placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
				end
			end

			local seed_increment_number = 10000
			local seed = global.perlin_noise_seed

			local noise_terrain_1 = perlin:noise(((pos_x+seed)/400),((pos_y+seed)/400),0)
			noise_terrain_1 = noise_terrain_1 * 100
			seed = seed + seed_increment_number
			local noise_terrain_2 = perlin:noise(((pos_x+seed)/250),((pos_y+seed)/250),0)
			noise_terrain_2 = noise_terrain_2 * 100
			seed = seed + seed_increment_number
			local noise_terrain_3 = perlin:noise(((pos_x+seed)/100),((pos_y+seed)/100),0)
			noise_terrain_3 = noise_terrain_3 * 50
			seed = seed + seed_increment_number
			local noise_terrain_4 = perlin:noise(((pos_x+seed)/20),((pos_y+seed)/20),0)
			noise_terrain_4 = noise_terrain_4 * 10
			seed = seed + seed_increment_number
			local noise_terrain_5 = perlin:noise(((pos_x+seed)/5),((pos_y+seed)/5),0)
			noise_terrain_5 = noise_terrain_5 * 4
			seed = seed + seed_increment_number
			local noise_sand = perlin:noise(((pos_x+seed)/18),((pos_y+seed)/18),0)
			noise_sand = noise_sand * 10

			--DECORATIVES
			seed = seed + seed_increment_number
			local noise_decoratives_1 = perlin:noise(((pos_x+seed)/20),((pos_y+seed)/20),0)
			noise_decoratives_1 = noise_decoratives_1
			seed = seed + seed_increment_number
			local noise_decoratives_2 = perlin:noise(((pos_x+seed)/30),((pos_y+seed)/30),0)
			noise_decoratives_2 = noise_decoratives_2
			seed = seed + seed_increment_number
			local noise_decoratives_3 = perlin:noise(((pos_x+seed)/30),((pos_y+seed)/30),0)
			noise_decoratives_3 = noise_decoratives_3


			seed = seed + seed_increment_number
			local noise_water_1 = perlin:noise(((pos_x+seed)/250),((pos_y+seed)/300),0)
			noise_water_1 = noise_water_1 * 100
			seed = seed + seed_increment_number
			local noise_water_2 = perlin:noise(((pos_x+seed)/100),((pos_y+seed)/150),0)
			noise_water_2 = noise_water_2 * 50

			--RESOURCES
			seed = seed + seed_increment_number
			local noise_resources = perlin:noise(((pos_x+seed)/40),((pos_y+seed)/40),0)
			seed = seed + seed_increment_number
			local noise_resources_2 = perlin:noise(((pos_x+seed)/150),((pos_y+seed)/150),0)
			seed = seed + seed_increment_number
			local noise_resources_3 = perlin:noise(((pos_x+seed)/20),((pos_y+seed)/20),0)
			seed = seed + seed_increment_number
			local noise_resources_4 = perlin:noise(((pos_x+seed)/20),((pos_y+seed)/20),0)
			noise_resources_2 = noise_resources_2 + (noise_resources_3 * 0.2)
			noise_resources = noise_resources * 100
			noise_resources_4 = noise_resources_4 * 20

			seed = seed + seed_increment_number
			local noise_resource_amount_modifier = perlin:noise(((pos_x+seed)/200),((pos_y+seed)/200),0)
			local resource_amount = 1 + ((400 + (400*noise_resource_amount_modifier*0.2)) * resource_amount_distance_multiplicator)
			seed = seed + seed_increment_number
			local noise_resources_iron_and_copper = perlin:noise(((pos_x+seed)/100),((pos_y+seed)/100),0)
			noise_resources_iron_and_copper = noise_resources_iron_and_copper * 100
			seed = seed + seed_increment_number
			local noise_resources_coal_and_uranium = perlin:noise(((pos_x+seed)/50),((pos_y+seed)/50),0)
			noise_resources_coal_and_uranium = noise_resources_coal_and_uranium * 100
			seed = seed + seed_increment_number
			local noise_resources_stone_and_oil = perlin:noise(((pos_x+seed)/150),((pos_y+seed)/150),0)
			noise_resources_stone_and_oil = noise_resources_stone_and_oil * 100

			seed = seed + seed_increment_number
			local noise_red_desert_rocks_1 = perlin:noise(((pos_x+seed)/20),((pos_y+seed)/20),0)
			noise_red_desert_rocks_1 = noise_red_desert_rocks_1 * 100
			seed = seed + seed_increment_number
			local noise_red_desert_rocks_2 = perlin:noise(((pos_x+seed)/10),((pos_y+seed)/10),0)
			noise_red_desert_rocks_2 = noise_red_desert_rocks_2 * 50
			seed = seed + seed_increment_number
			local noise_red_desert_rocks_3 = perlin:noise(((pos_x+seed)/5),((pos_y+seed)/5),0)
			noise_red_desert_rocks_3 = noise_red_desert_rocks_3 * 100
			seed = seed + seed_increment_number
			local noise_forest = perlin:noise(((pos_x+seed)/100),((pos_y+seed)/100),0)
			noise_forest = noise_forest * 100
			seed = seed + seed_increment_number
			local noise_forest_2 = perlin:noise(((pos_x+seed)/20),((pos_y+seed)/20),0)
			noise_forest_2 = noise_forest_2 * 20

			local terrain_smoothing = math.random(0,1)
			local place_tree_number

			if noise_terrain_1 < 8 + terrain_smoothing + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
				 tile_to_insert = "red-desert"
				if noise_water_1 + noise_water_2 + noise_sand > -10 and noise_water_1 + noise_water_2 + noise_sand < 25 and noise_terrain_1 < -52 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 + noise_terrain_5 then
					tile_to_insert = "sand"
					place_tree_number = math.random(3,#tree_to_place)
				else
					place_tree_number = math.random(1,(#tree_to_place - 3))
				end

				if noise_water_1 + noise_water_2 > 0 and noise_water_1 + noise_water_2 < 15 and noise_terrain_1 < -60 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 + noise_terrain_5 then
					tile_to_insert = "water"
					local a = pos_x + 1
					table.insert(tiles, {name = tile_to_insert, position = {a,pos_y}})
					local a = pos_y + 1
					table.insert(tiles, {name = tile_to_insert, position = {pos_x,a}})
					local a = pos_x - 1
					table.insert(tiles, {name = tile_to_insert, position = {a,pos_y}})
					local a = pos_y - 1
					table.insert(tiles, {name = tile_to_insert, position = {pos_x,a}})
					if noise_water_1 + noise_water_2 < 2 or noise_water_1 + noise_water_2 > 13 then
						if math.random(1,15) == 1 then
							table.insert(decoratives, {name="green-carpet-grass", position={pos_x,pos_y}, amount=1})
						end
						if math.random(1,15) == 1 then
							table.insert(decoratives, {name="brown-cane-cluster", position={pos_x,pos_y}, amount=1})
						end
					end
				end

				if tile_to_insert ~= "water" then
					if noise_water_1 + noise_water_2 > 16 and noise_water_1 + noise_water_2 < 25 and noise_terrain_1 < -55 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 + noise_terrain_5 then
						if math.random(1,35) == 1 then
							table.insert(decoratives, {name="brown-carpet-grass", position={pos_x,pos_y}, amount=1})
						end
					end
					if noise_water_1 + noise_water_2 > -10 and noise_water_1 + noise_water_2 < -1 and noise_terrain_1 < -55 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 + noise_terrain_5 then
						if math.random(1,35) == 1 then
							table.insert(decoratives, {name="brown-carpet-grass", position={pos_x,pos_y}, amount=1})
						end
					end
					if noise_decoratives_1 > 0.5 and noise_decoratives_1 <= 0.8 then
						if math.random(1,12) == 1 then table.insert(decoratives, {name="red-desert-bush", position={pos_x,pos_y}, amount=1}) end
					end
					if noise_decoratives_1 > 0.4 and noise_decoratives_1 <= 0.5 then
						if math.random(1,4) == 1 then table.insert(decoratives, {name="red-desert-bush", position={pos_x,pos_y}, amount=1}) end
					end
				end

				--HAPPY TREES
				if noise_terrain_1 < -30 + noise_terrain_2 + noise_terrain_3 + noise_terrain_5 + noise_forest_2 then
					if noise_forest > 0 and noise_forest <= 10 then
						if math.random(1,50) == 1 then
							if surface.can_place_entity {name=tree_to_place[place_tree_number], position={pos_x,pos_y}} then
								surface.create_entity {name=tree_to_place[place_tree_number], position={pos_x,pos_y}}
							end
						end
					end
					if noise_forest > 10 and noise_forest <= 20 then
						if math.random(1,25) == 1 then
							if surface.can_place_entity {name=tree_to_place[place_tree_number], position={pos_x,pos_y}} then
								surface.create_entity {name=tree_to_place[place_tree_number], position={pos_x,pos_y}}
							end
						end
					end
					if noise_forest > 20 then
						if math.random(1,10) == 1 then
							if surface.can_place_entity {name=tree_to_place[place_tree_number], position={pos_x,pos_y}} then
								surface.create_entity {name=tree_to_place[place_tree_number], position={pos_x,pos_y}}
							end
						end
					end
				end

				if tile_to_insert ~= "water" then
					if noise_terrain_1 < 8 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 and noise_terrain_1 > -5 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
						if math.random(1,45) == 1 then
							table.insert(decoratives, {name="red-desert-rock-medium", position={pos_x,pos_y}, amount=1})
						end
						if math.random(1,20) == 1 then
							table.insert(decoratives, {name="red-desert-rock-tiny", position={pos_x,pos_y}, amount=1})
						end
					else
						if math.random(1,375) == 1 then
							table.insert(decoratives, {name="red-desert-rock-medium", position={pos_x,pos_y}, amount=1})
						end
						if math.random(1,45) == 1 then
							table.insert(decoratives, {name="red-desert-rock-tiny", position={pos_x,pos_y}, amount=1})
						end
					end
				end
			else
				tile_to_insert = "red-desert-dark"
			end
			if resource_entity_placed == false and noise_resources_iron_and_copper + noise_resources > 92 and noise_terrain_1 > 15 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 + noise_resources_4 then
				if surface.can_place_entity {name="uranium-ore", position={pos_x,pos_y}} then
					surface.create_entity {name="uranium-ore", position={pos_x,pos_y}, amount=resource_amount}
					resource_entity_placed = true
				end
			end

			local a = 1
			local b = 90
			for i = 1, 32, 1 do
				if a == 5 then a = 1 end
				if resource_entity_placed == false and noise_resources_iron_and_copper + noise_resources > b and noise_terrain_1 > 15 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 + noise_resources_4 then
					if surface.can_place_entity {name=ore[a], position={pos_x,pos_y}} then
						surface.create_entity {name=ore[a], position={pos_x,pos_y}, amount=resource_amount}
						resource_entity_placed = true
					end
				end
				b = b - 2
				a = a + 1
			end

			if resource_entity_placed == false and noise_resources_stone_and_oil + noise_resources < -70 and noise_terrain_1 < -50 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
				if math.random(1,42) == 1 then
					if surface.can_place_entity {name="crude-oil", position={pos_x,pos_y}} then
						surface.create_entity {name="crude-oil", position={pos_x,pos_y}, amount=(resource_amount*500)}
						resource_entity_placed = true
					end
				end
			end

			if resource_entity_placed == false and noise_red_desert_rocks_1 + noise_red_desert_rocks_2 + noise_red_desert_rocks_3 > 20 and noise_red_desert_rocks_1 + noise_red_desert_rocks_2 < 60 and noise_terrain_1 > 7 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
				if math.random(1,3) == 1 then
					if math.random(1,3) == 1 then
						if surface.can_place_entity {name="red-desert-rock-huge-01", position={pos_x,pos_y}} then
							surface.create_entity {name="red-desert-rock-huge-01", position={pos_x,pos_y}}
						end
					else
						if surface.can_place_entity {name="red-desert-rock-big-01", position={pos_x,pos_y}} then
							surface.create_entity {name="red-desert-rock-big-01", position={pos_x,pos_y}}
						end
					end
				end
			end

			if noise_red_desert_rocks_1 + noise_red_desert_rocks_2 + noise_red_desert_rocks_3 + noise_terrain_4 >= 10 and noise_red_desert_rocks_1 + noise_red_desert_rocks_2 + noise_red_desert_rocks_3 < 20 and noise_terrain_1 > 7 + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
				if math.random(1,5) == 1 then
					table.insert(decoratives, {name="red-desert-rock-medium", position={pos_x,pos_y}, amount=1})
				end
			else
				if tile_to_insert ~= "water" and tile_to_insert ~= "sand" then
					if math.random(1,15) == 1 then
						table.insert(decoratives, {name="red-desert-rock-small", position={pos_x,pos_y}, amount=1})
					else
						if math.random(1,8) == 1 then
							table.insert(decoratives, {name="red-desert-rock-tiny", position={pos_x,pos_y}, amount=1})
						end
					end
				end
			end
			if tile_to_insert ~= "water" then
				if noise_decoratives_2 > 0.6 then
					if math.random(1,9) == 1 then table.insert(decoratives, {name="red-asterisk", position={pos_x,pos_y}, amount=1}) end
				else
					if noise_decoratives_2 > 0.4 then
						if math.random(1,17) == 1 then table.insert(decoratives, {name="red-asterisk", position={pos_x,pos_y}, amount=1}) end
					end
				end
				if noise_decoratives_3 < -0.6 then
					if math.random(1,2) == 1 then table.insert(decoratives, {name="brown-fluff-dry", position={pos_x,pos_y}, amount=1}) end
				else
					if noise_decoratives_3 < -0.4 then
						if math.random(1,5) == 1 then table.insert(decoratives, {name="brown-fluff-dry", position={pos_x,pos_y}, amount=1}) end
					end
				end
			end
			table.insert(tiles, {name = tile_to_insert, position = {pos_x,pos_y}})
		end
	end

	surface.set_tiles(tiles,true)
	for _,deco in pairs(decoratives) do
		surface.create_decoratives{check_collision=false, decoratives={deco}}
	end
end

local function grey_void(event)
	if not global.void_slime then global.void_slime = {x=0,y=0} end
	if not global.void_slime_is_alive then global.void_slime_is_alive = true end
	local area = event.area
	local surface = event.surface
	local tiles = {}
	local decoratives = {}
	local resource_tiles = {}
	local special_tiles = true

	local entities = surface.find_entities(area)
	for _, entity in pairs(entities) do
		if entity.type == "resource" then
			table.insert(resource_tiles, {name = "concrete", position = entity.position})
			special_tiles = false
		end
		if entity.type == "simple-entity" or entity.type == "tree" then
			if entity.name ~= "dry-tree" then
				entity.destroy()
			end
		end
	end

	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos_x = event.area.left_top.x + x
			local pos_y = event.area.left_top.y + y
			local pos = {x = pos_x,y = pos_y}
			local tile = surface.get_tile(pos_x,pos_y)
			local tile_to_insert = tile
			local entity_placed = false
			if tile.name ~= "lab-dark-1" then
				table.insert(tiles, {name = "lab-dark-1", position = {pos_x,pos_y}})
			end
		end
	end
	surface.set_tiles(tiles,false)
	surface.set_tiles(resource_tiles,false)

	if special_tiles == true then
		local pos_x = event.area.left_top.x + math.random(10,21)
		local pos_y = event.area.left_top.y + math.random(10,21)
		local pos = {x = pos_x,y = pos_y}
		if math.random(1,20) == 1 then create_tile_cluster("water", pos, 300) end
	end
end

Event.register(defines.events.on_chunk_generated, worldgen_onchunk)
