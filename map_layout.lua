--[[
Hey there!

With this you can customize your world generation.
Just set the map_styles of your choice to true to make it happen.

---MewMew---

notes:

--]]

require "perlin_noise"
require "shapes"
Spiral.width=6
Spiral.size=2
Spiral.build()
perlin:load(  )
if not global.perlin_noise_seed then global.perlin_noise_seed = math.random(1000,1000000) end

local map_styles = {}

map_styles = {
up = false,
right = false,
square = false,
circle = false,
red_planet = false,
dagobah_swamp = false,
grey_void = false,
resource_cluster_truck = false,
perlin_01 = false,
perlin_02 = false,
spiral = true
}

if map_styles.red_planet == true or map_styles.dagobah_swamp == true then
	wreck_item_pool = {}
	wreck_item_pool = {{name="iron-gear-wheel", count=32},{name="iron-plate", count=64},{name="rocket-control-unit", count=1} ,{name="coal", count=4},{name="rocket-launcher", count=1},{name="rocket", count=32},{name="copper-cable", count=128},{name="land-mine", count=64},{name="railgun", count=1},{name="railgun-dart", count=128},{name="fast-inserter", count=8},{name="stack-filter-inserter", count=2},{name="belt-immunity-equipment", count=1},{name="fusion-reactor-equipment", count=1},{name="electric-engine-unit", count=8},{name="exoskeleton-equipment", count=1},{name="rocket-fuel", count=10},{name="used-up-uranium-fuel-cell", count=3},{name="uranium-fuel-cell", count=2}}
end

local function removeChunk(event)
	local tiles = {}
	for x = event.area.left_top.x, event.area.right_bottom.x do
		for y = event.area.left_top.y, event.area.right_bottom.y do
			table.insert(tiles, {name = "out-of-map", position = {x,y}})
		end
	end
	event.surface.set_tiles(tiles)
end

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

	if map_styles.spiral == true then
		if Spiral.onshape({event.area.left_top.x, event.area.left_top.y}) then
			removeChunk(event)
		end
	end

	if map_styles.perlin_02 == true then
		local seed = global.perlin_noise_seed
		local surface = game.surfaces[1]
		local tiles = {}
		local void_tiles = {}
		local entities = surface.find_entities(event.area)
		for _, entity in pairs(entities) do
			if entity.type ~= "player" then
				entity.destroy()
			end
		end

		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				local pos_x = event.area.left_top.x + x
				local pos_y = event.area.left_top.y + y
				table.insert(void_tiles, {name = "concrete", position = {pos_x,pos_y}})
				local tile = surface.get_tile(pos_x,pos_y)
				local tile_to_insert = "concrete"

				--if tile.name ~= "water" and tile.name ~= "deepwater" then
					local noise_terrain_1 = perlin:noise(((pos_x+seed)/500),((pos_y+seed)/500),0)
					noise_terrain_1 = noise_terrain_1 * 100
					local noise_terrain_2 = perlin:noise(((pos_x+seed+40000)/250),((pos_y+seed+40000)/250),0)
					noise_terrain_2 = noise_terrain_2 * 50
					local noise_terrain_3 = perlin:noise(((pos_x+seed+50000)/50),((pos_y+seed+50000)/50),0)
					noise_terrain_3 = noise_terrain_3 * 50
					local noise_terrain_4 = perlin:noise(((pos_x+seed+50000)/20),((pos_y+seed+70000)/20),0)
					noise_terrain_4 = noise_terrain_4 * 10
					local noise_terrain_5 = perlin:noise(((pos_x+seed+50000)/5),((pos_y+seed+70000)/5),0)
					noise_terrain_5 = noise_terrain_5 * 10
					local noise_red_desert_rocks = perlin:noise(((pos_x+seed+100000)/10),((pos_y+seed+100000)/10),0)
					noise_red_desert_rocks = noise_red_desert_rocks * 100
					local p3 = perlin:noise(((pos_x+seed+200000)/10),((pos_y+seed+200000)/10),0)
					p3 = p3 * 100
					local noise_forest = perlin:noise(((pos_x+seed+300000)/100),((pos_y+seed+300000)/100),0)
					noise_forest = noise_forest * 100

					local terrain_smoothing = math.random(0,1)

					if noise_terrain_1 < 8 + terrain_smoothing + noise_terrain_2 + noise_terrain_3 + noise_terrain_4 then
						 tile_to_insert = "red-desert"

						if noise_terrain_1 < -75 + noise_terrain_2 + noise_terrain_5 then
							tile_to_insert = "water"
							local a = pos_x + 1
							table.insert(tiles, {name = tile_to_insert, position = {a,pos_y}})
							local a = pos_y + 1
							table.insert(tiles, {name = tile_to_insert, position = {pos_x,a}})
							local a = pos_x - 1
							table.insert(tiles, {name = tile_to_insert, position = {a,pos_y}})
							local a = pos_y - 1
							table.insert(tiles, {name = tile_to_insert, position = {pos_x,a}})
						end

						if noise_terrain_1 < -5 then
							if noise_forest > 0 and noise_forest <= 10 then
								if math.random(1,50) == 1 then
									if surface.can_place_entity {name="dry-tree", position={pos_x,pos_y}} then
										surface.create_entity {name="dry-tree", position={pos_x,pos_y}}
									end
								end
							end
							if noise_forest > 10 and noise_forest <= 20 then
								if math.random(1,25) == 1 then
									if surface.can_place_entity {name="dry-tree", position={pos_x,pos_y}} then
										surface.create_entity {name="dry-tree", position={pos_x,pos_y}}
									end
								end
							end
							if noise_forest > 20 then
								if math.random(1,10) == 1 then
									if surface.can_place_entity {name="dry-tree", position={pos_x,pos_y}} then
										surface.create_entity {name="dry-tree", position={pos_x,pos_y}}
									end
								end
							end
						end
					else
						tile_to_insert = "red-desert-dark"

						if noise_red_desert_rocks > 20 and noise_terrain_1 > -2 + terrain_smoothing + noise_terrain_2 + noise_terrain_3 then
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
				--else
				--	if tile.name == "water" then tile_to_insert = "water" end
				--	if tile.name == "deepwater" then tile_to_insert = "deepwater" end
				--end
				table.insert(tiles, {name = tile_to_insert, position = {pos_x,pos_y}})
			end
		end
		--surface.set_tiles(void_tiles,false)
		surface.set_tiles(tiles,true)
		--surface.set_tiles(tiles,true)

	end

	if map_styles.perlin_01 == true then
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

	if map_styles.up == true then
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

	if map_styles.right == true then
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

	if map_styles.dagobah_swamp == true then
		local area = event.area
		local surface = event.surface
		--local surface = game.surfaces[1]
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
											-- or tile.name == "grass-dry"
				if tile.name ~= "water" and tile.name ~= "deepwater" then
					tile_to_insert = "grass"

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

				else
					if tile.name == "water" then tile_to_insert = "water" end
					if tile.name == "deepwater" then tile_to_insert = "deepwater" end
				end
				table.insert(tiles, {name = tile_to_insert, position = {pos_x,pos_y}})
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
				if tile.name == "water" then

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

	if map_styles.red_planet == true then
		local area = event.area
		local surface = event.surface
		local tiles = {}
		local water_tiles = {}
		local decoratives = {}

		local entities = surface.find_entities(area)
		for _, entity in pairs(entities) do
			if entity.type == "tree" or entity.type == "simple-entity" then
					entity.destroy()
			end
		end
		local rock_cluster = true
		if math.random(1,3) == 1 then rock_cluster = false end

		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				local pos_x = event.area.left_top.x + x
				local pos_y = event.area.left_top.y + y
				local pos = {pos_x,pos_y}
				local tile = surface.get_tile(pos_x,pos_y)
				local entity_placed = false
											-- or tile.name == "grass-dry"
				if tile.name == "grass" or tile.name == "sand" or tile.name == "dirt" or tile.name == "grass-medium" then
					table.insert(tiles, {name = "red-desert", position = {pos_x,pos_y}})
					local entity_list = {}
					table.insert(entity_list, {name="dry-tree", pos={pos_x,pos_y},chance = 160})
					table.insert(entity_list, {name="red-desert-rock-big-01", pos={pos_x,pos_y},chance = 800})
					table.insert(entity_list, {name="red-desert-rock-huge-01", pos={pos_x,pos_y},chance = 1500})
					table.insert(entity_list, {name="stone-rock", pos={pos_x,pos_y},chance = 1300})
					table.insert(entity_list, {name="medium-ship-wreck", pos={pos_x,pos_y},chance = 15000, health="medium"})
					table.insert(entity_list, {name="small-ship-wreck", pos={pos_x,pos_y},chance = 15000, health="medium"})
					table.insert(entity_list, {name="car", pos={pos_x,pos_y},chance = 100000, health="low"})
					table.insert(entity_list, {name="nuclear-reactor", pos={pos_x,pos_y},chance = 1000000, force="enemy", health="medium"})
					local b, placed_entity = place_entities(surface, entity_list)
					if b == false then
						table.insert(entity_list, {name="big-ship-wreck-1", pos={pos_x,pos_y},chance = 75000, health="random"})
						table.insert(entity_list, {name="big-ship-wreck-2", pos={pos_x,pos_y},chance = 75000, health="random"})
						table.insert(entity_list, {name="big-ship-wreck-3", pos={pos_x,pos_y},chance = 75000, health="random"})
						local b, placed_entity = place_entities(surface, entity_list)
						if b == true then
							placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
							placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
							placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
						end
					end
				else
					if tile.name == "water" or tile.name == "water-green" then
						--table.insert(water_tiles, {name = "water-green", position = {pos_x,pos_y}})
					else
						if tile.name == "deepwater" or tile.name == "deepwater-green" then
							--table.insert(water_tiles, {name = "deepwater-green", position = {pos_x,pos_y}})
						else
							table.insert(tiles, {name = "red-desert-dark", position = {pos_x,pos_y}})
							if rock_cluster == true then
								if math.random(1,1200) == 1 then create_rock_cluster({x=pos_x,y=pos_y},math.random(15,75)) end
							end
							local entity_list = {}
							table.insert(entity_list, {name="red-desert-rock-big-01", pos={pos_x,pos_y},chance = 400})
							table.insert(entity_list, {name="red-desert-rock-huge-01", pos={pos_x,pos_y},chance = 700})
							table.insert(entity_list, {name="pipe-to-ground", pos={pos_x,pos_y},chance = 15000, force="enemy"})
							table.insert(entity_list, {name="programmable-speaker", pos={pos_x,pos_y},chance = 25000, force="enemy", health="high"})
							table.insert(entity_list, {name="laser-turret", pos={pos_x,pos_y},chance = 50000, force="enemy", health="low"})
							table.insert(entity_list, {name="tank", pos={pos_x,pos_y},chance = 500000, health="low"})
							local b, placed_entity = place_entities(surface, entity_list)
							if b == false then
								table.insert(entity_list, {name="big-ship-wreck-1", pos={pos_x,pos_y},chance = 75000, health="random"})
								table.insert(entity_list, {name="big-ship-wreck-2", pos={pos_x,pos_y},chance = 75000, health="random"})
								table.insert(entity_list, {name="big-ship-wreck-3", pos={pos_x,pos_y},chance = 75000, health="random"})
								local b, placed_entity = place_entities(surface, entity_list)
								if b == true then
									placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
									placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
									placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
								end
							end
						end
					end
				end

			end
		end
		surface.set_tiles(tiles,true)
		--surface.set_tiles(water_tiles,false)
		--surface.set_tiles(water_tiles,false)

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
				if tile.name == "red-desert" then
					if decal_has_been_placed == false then
						local r = math.random(1,21)
						if r == 1 then
							table.insert(decoratives, {name="red-desert-bush", position={pos_x,pos_y}, amount=1})
							decal_has_been_placed = true
						end
					end
					if decal_has_been_placed == false then
						local r = math.random(1,34)
						if r == 1 then
							table.insert(decoratives, {name="red-desert-rock-tiny", position={pos_x,pos_y}, amount=1})
							decal_has_been_placed = true
						end
					end
					if decal_has_been_placed == false then
						local r = math.random(1,76)
						if r == 1 then
							table.insert(decoratives, {name="red-desert-rock-medium", position={pos_x,pos_y}, amount=1})
							decal_has_been_placed = true
						end
					end
					if decal_has_been_placed == false then
						local r = math.random(1,25)
						if r == 1 then
							table.insert(decoratives, {name="red-asterisk", position={pos_x,pos_y}, amount=1})
							decal_has_been_placed = true
						end
					end
					if decal_has_been_placed == false then
						local r = math.random(1,36)
						if r == 1 then
							table.insert(decoratives, {name="brown-hairy-grass", position={pos_x,pos_y}, amount=1})
							decal_has_been_placed = true
						end
					end
					if decal_has_been_placed == false then
						local r = math.random(1,44)
						if r == 1 then
							table.insert(decoratives, {name="brown-carpet-grass", position={pos_x,pos_y}, amount=1})
							decal_has_been_placed = true
						end
					end
					if decal_has_been_placed == false then
						local r = math.random(1,227)
						if r == 1 then
							table.insert(decoratives, {name="brown-coral-mini", position={pos_x,pos_y}, amount=1})
							decal_has_been_placed = true
						end
					end
					if decal_has_been_placed == false then
						local r = math.random(1,227)
						if r == 1 then
							table.insert(decoratives, {name="orange-coral-mini", position={pos_x,pos_y}, amount=1})
							decal_has_been_placed = true
						end
					end

				end
				if tile.name == "red-desert-dark" then
					if decal_has_been_placed == false then
						local r = math.random(1,25)
						if r == 1 then
							table.insert(decoratives, {name="red-desert-bush", position={pos_x,pos_y}, amount=1})
							decal_has_been_placed = true
						end
					end
					if decal_has_been_placed == false then
						local r = math.random(1,25)
						if r == 1 then
							table.insert(decoratives, {name="red-desert-rock-medium", position={pos_x,pos_y}, amount=1})
							decal_has_been_placed = true
						end
					end
					if decal_has_been_placed == false then
						local r = math.random(1,15)
						if r == 1 then
							table.insert(decoratives, {name="red-desert-rock-small", position={pos_x,pos_y}, amount=1})
							decal_has_been_placed = true
						end
					end
					if decal_has_been_placed == false then
						local r = math.random(1,12)
						if r == 1 then
							table.insert(decoratives, {name="red-desert-rock-tiny", position={pos_x,pos_y}, amount=1})
							decal_has_been_placed = true
						end
					end
					if decal_has_been_placed == false then
						local r = math.random(1,27)
						if r == 1 then
							table.insert(decoratives, {name="red-asterisk", position={pos_x,pos_y}, amount=1})
							decal_has_been_placed = true
						end
					end
					if decal_has_been_placed == false then
						local r = math.random(1,32)
						if r == 1 then
							table.insert(decoratives, {name="brown-hairy-grass", position={pos_x,pos_y}, amount=1})
							decal_has_been_placed = true
						end
					end
					if decal_has_been_placed == false then
						local r = math.random(1,61)
						if r == 1 then
							table.insert(decoratives, {name="brown-carpet-grass", position={pos_x,pos_y}, amount=1})
							decal_has_been_placed = true
						end
					end
					--[[if decal_has_been_placed == false then
						local r = math.random(1,71)
						if r == 1 then
							table.insert(decoratives, {name="brown-cane-cluster", position={pos_x,pos_y}, amount=1})
							decal_has_been_placed = true
						end
					end
					--]]
				end
				--[[if tile.name == "grass" then
				end
				if tile.name == "grass-dry" then
				end
				if tile.name == "grass-medium" then
				end
				if tile.name == "dirt" then
				end
				if tile.name == "dirt-dark" then
				end--]]
			end
		end
		for _,deco in pairs(decoratives) do
			surface.create_decoratives{check_collision=false, decoratives={deco}}
		end
	end

	if map_styles.grey_void == true then
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
			--if math.random(1,3) == 1 then create_tile_cluster("lab-dark-2", pos, 1000) end
			--if math.random(1,700) == 1 then create_tile_cluster("lab-dark-2", pos, 300) end
		end
	end
end

local function on_tick()
	if map_styles.grey_void == true then
		if game.tick % 60 == 0 then
			if global.void_slime_is_alive == true then
				local b,x,y = create_tile_cluster("lab-dark-2",global.void_slime,1)
				global.void_slime.x = x
				global.void_slime.y = y
				if b == false then
					global.void_slime_is_alive = false
					game.print("The void slime died.")
				end
			end
		end
	end
end
--[[
function regen()
	game.surfaces[1].regenerate_decorative {"red-asterisk", "green-bush-mini", "green-carpet-grass" }
end

function reveal(var)
	local a = var
	local b = var * -1
	game.forces.player.chart(game.player.surface, {lefttop = {x = a, y = a}, rightbottom = {x = b, y = b}})
end
--]]

Event.register(defines.events.on_tick, on_tick)
Event.register(defines.events.on_chunk_generated, on_chunk_generated)
