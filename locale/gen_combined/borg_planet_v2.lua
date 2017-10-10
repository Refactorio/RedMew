--Author: MewMew
-- !! ATTENTION !!
-- Use water only in starting area as map setting!!!
require "locale.gen_shared.perlin_noise"
local Thread = require "locale.utils.Thread"

wreck_item_pool = {}
wreck_item_pool = {{name="iron-gear-wheel", count=32},{name="iron-plate", count=64},{name="rocket-control-unit", count=1},{name="rocket-fuel", count=7} ,{name="coal", count=8},{name="rocket-launcher", count=1},{name="rocket", count=32},{name="copper-cable", count=128},{name="land-mine", count=64},{name="railgun", count=1},{name="railgun-dart", count=128},{name="fast-inserter", count=8},{name="stack-filter-inserter", count=2},{name="belt-immunity-equipment", count=1},{name="fusion-reactor-equipment", count=1},{name="electric-engine-unit", count=8},{name="exoskeleton-equipment", count=1},{name="rocket-fuel", count=10},{name="used-up-uranium-fuel-cell", count=3},{name="uranium-fuel-cell", count=2},{name="power-armor", count=1},{name="modular-armor", count=1},{name="water-barrel", count=4},{name="sulfuric-acid-barrel", count=6},{name="crude-oil-barrel", count=8},{name="energy-shield-equipment", count=1},{name="explosive-rocket", count=32}}

global.perlin_noise_seed = 50000 --math.random(1000,1000000)
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

local function find_tile_placement_spot_around_target_position(tilename, position, mode, density)
	local x = position.x
	local y = position.y
	if not surface then surface = game.surfaces[1] end
	local scan_radius = 50
	if not tilename then return end
	if not mode then mode = "ball" end
	if not density then density = 1 end
	local cluster_tiles = {}
	local auto_correct = true

	local scanned_tile = surface.get_tile(x,y)
	if scanned_tile.name ~= tilename then
		table.insert(cluster_tiles, {name = tilename, position = {x,y}})
		surface.set_tiles(cluster_tiles,auto_correct)
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

function run_combined_module(event)
	local area = event.area
	local surface = event.surface

	local entities = surface.find_entities(area)
	for _, entity in pairs(entities) do
		if entity.type == "simple-entity" or entity.type == "tree" then
			if entity.name ~= "dry-tree" then
				entity.destroy()
			end
		end
	end

	for x = 0, 31, 1 do
		Thread.queue_action("run_borg", {area = event.area, surface = event.surface, x = x})
	end
end

function run_borg( params )
	local tiles = {}
	local decoratives = {}

	local area = params.area
	local surface = params.surface

	local x = params.x
	local pos_x = area.left_top.x + x

	for y = 0, 31, 1 do
		local pos_y = area.left_top.y + y
		local pos = {x = pos_x,y = pos_y}
		local tile = surface.get_tile(pos_x,pos_y)
		local tile_to_insert = "sand"
		local entity_placed = false

		local seed_increment_number = 10000
		local seed = surface.map_gen_settings.seed

		local noise_borg_defense_1 = perlin:noise(((pos_x+seed)/100),((pos_y+seed)/100),0)
		seed = seed + seed_increment_number
		local noise_borg_defense_2 = perlin:noise(((pos_x+seed)/20),((pos_y+seed)/20),0)
		seed = seed + seed_increment_number
		local noise_borg_defense = noise_borg_defense_1 + noise_borg_defense_2 * 0.15

		local noise_trees_1 = perlin:noise(((pos_x+seed)/50),((pos_y+seed)/50),0)
		seed = seed + seed_increment_number
		local noise_trees_2 = perlin:noise(((pos_x+seed)/15),((pos_y+seed)/15),0)
		seed = seed + seed_increment_number
		local noise_trees = noise_trees_1 + noise_trees_2 * 0.3

		local noise_walls_1 = perlin:noise(((pos_x+seed)/150),((pos_y+seed)/150),0)
		seed = seed + seed_increment_number
		local noise_walls_2 = perlin:noise(((pos_x+seed)/50),((pos_y+seed)/50),0)
		seed = seed + seed_increment_number
		local noise_walls_3 = perlin:noise(((pos_x+seed)/20),((pos_y+seed)/20),0)
		seed = seed + seed_increment_number
		local noise_walls = noise_walls_1 + noise_walls_2 * 0.1 + noise_walls_3 * 0.03

		if noise_borg_defense > 0.66 then
			local entity_list = {}
			table.insert(entity_list, {name="big-ship-wreck-1", pos={pos_x,pos_y},chance = 25})
			table.insert(entity_list, {name="big-ship-wreck-2", pos={pos_x,pos_y},chance = 25})
			table.insert(entity_list, {name="big-ship-wreck-3", pos={pos_x,pos_y},chance = 25})
			local b, placed_entity = place_entities(surface, entity_list)
			if b == true then
				if placed_entity.name == "big-ship-wreck-1" or placed_entity.name == "big-ship-wreck-2" or placed_entity.name == "big-ship-wreck-3" then
					placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
					placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
					placed_entity.insert(wreck_item_pool[math.random(1,#wreck_item_pool)])
				end
			end
		end

		if noise_trees > 0.17 then
			tile_to_insert = "sand-dark"
		end
		if noise_borg_defense > 0.4 then
			tile_to_insert = "concrete"
		end
		if noise_borg_defense > 0.35 and noise_borg_defense < 0.4 then
			tile_to_insert = "stone-path"
		end
		if noise_borg_defense > 0.65 and noise_borg_defense < 0.66 then
			if surface.can_place_entity {name="substation", position={pos_x,pos_y}, force="enemy"} then
				surface.create_entity {name="substation", position={pos_x,pos_y}, force="enemy"}
			end
		end
		if noise_borg_defense >= 0.54 and noise_borg_defense < 0.65 then
			if surface.can_place_entity {name="solar-panel", position={pos_x,pos_y}, force="enemy"} then
				surface.create_entity {name="solar-panel", position={pos_x,pos_y}, force="enemy"}
			end
		end
		if noise_borg_defense > 0.53 and noise_borg_defense < 0.54 then
			if surface.can_place_entity {name="substation", position={pos_x,pos_y}, force="enemy"} then
				surface.create_entity {name="substation", position={pos_x,pos_y}, force="enemy"}
			end
		end
		if noise_borg_defense >= 0.51 and noise_borg_defense < 0.53 then
			if surface.can_place_entity {name="accumulator", position={pos_x,pos_y}, force="enemy"} then
				surface.create_entity {name="accumulator", position={pos_x,pos_y}, force="enemy"}
			end
		end
		if noise_borg_defense >= 0.50 and noise_borg_defense < 0.51 then
			if surface.can_place_entity {name="substation", position={pos_x,pos_y}, force="enemy"} then
				surface.create_entity {name="substation", position={pos_x,pos_y}, force="enemy"}
			end
		end
		if noise_borg_defense >= 0.487 and noise_borg_defense < 0.50 then
			if surface.can_place_entity {name="laser-turret", position={pos_x,pos_y}, force="enemy"} then
				surface.create_entity {name="laser-turret", position={pos_x,pos_y}, force="enemy"}
			end
		end
		if noise_borg_defense >= 0.485 and noise_borg_defense < 0.487 then
			if surface.can_place_entity {name="substation", position={pos_x,pos_y}, force="enemy"} then
				surface.create_entity {name="substation", position={pos_x,pos_y}, force="enemy"}
			end
		end
		if noise_borg_defense >= 0.45 and noise_borg_defense < 0.484 then
			if surface.can_place_entity {name="stone-wall", position={pos_x,pos_y}, force="enemy"} then
				surface.create_entity {name="stone-wall", position={pos_x,pos_y}, force="enemy"}
			end
		end


		if noise_trees > 0.2 and tile_to_insert == "sand-dark" then
			if math.random(1,15) == 1 then
				if math.random(1,5) == 1 then
					if surface.can_place_entity {name="dry-hairy-tree", position={pos_x,pos_y}} then
						surface.create_entity {name="dry-hairy-tree", position={pos_x,pos_y}}
					end
				else
					if surface.can_place_entity {name="dry-tree", position={pos_x,pos_y}} then
						surface.create_entity {name="dry-tree", position={pos_x,pos_y}}
					end
				end
			end
		end

		local entity_list = {}
		table.insert(entity_list, {name="big-ship-wreck-1", pos={pos_x,pos_y},chance = 35000, health="random"})
		table.insert(entity_list, {name="big-ship-wreck-2", pos={pos_x,pos_y},chance = 45000, health="random"})
		table.insert(entity_list, {name="big-ship-wreck-3", pos={pos_x,pos_y},chance = 55000, health="random"})
		if noise_walls > -0.03 and noise_walls < 0.03 then
			table.insert(entity_list, {name="gun-turret", pos={pos_x,pos_y}, force="enemy",chance = 40})
		end
		if noise_borg_defense > 0.41 and noise_borg_defense < 0.45 then
			table.insert(entity_list, {name="gun-turret", pos={pos_x,pos_y}, force="enemy",chance = 15})
		end
		table.insert(entity_list, {name="pipe-to-ground", pos={pos_x,pos_y}, force="enemy",chance = 7500})
		if tile_to_insert ~= "stone-path" and tile_to_insert ~= "concrete" then
			table.insert(entity_list, {name="dead-dry-hairy-tree", pos={pos_x,pos_y}, force="enemy",chance = 1500})
			table.insert(entity_list, {name="dead-grey-trunk", pos={pos_x,pos_y}, force="enemy",chance = 1500})
		end
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
			if placed_entity.name == "gun-turret" then
				if math.random(1,3) == 1 then
					placed_entity.insert("piercing-rounds-magazine")
				else
					placed_entity.insert("firearm-magazine")
				end
			end
		end

		if noise_trees < -0.5 then
			if tile_to_insert == "sand-dark" or tile_to_insert == "sand" then
				if math.random(1,15) == 1 then
					if surface.can_place_entity {name="stone-rock", position={pos_x,pos_y}} then
						surface.create_entity {name="stone-rock", position={pos_x,pos_y}}
					end
				end
			end
		end

		local noise_water_1 = perlin:noise(((pos_x+seed)/200),((pos_y+seed)/200),0)
		seed = seed + seed_increment_number
		local noise_water_2 = perlin:noise(((pos_x+seed)/100),((pos_y+seed)/100),0)
		seed = seed + seed_increment_number
		local noise_water_3 = perlin:noise(((pos_x+seed)/25),((pos_y+seed)/25),0)
		seed = seed + seed_increment_number
		local noise_water_4 = perlin:noise(((pos_x+seed)/10),((pos_y+seed)/10),0)
		seed = seed + seed_increment_number
		local noise_water = noise_water_1 + noise_water_2 + noise_water_3 * 0.07 + noise_water_4 * 0.07

		local noise_water_1 = perlin:noise(((pos_x+seed)/200),((pos_y+seed)/200),0)
		seed = seed + seed_increment_number
		local noise_water_2 = perlin:noise(((pos_x+seed)/100),((pos_y+seed)/100),0)
		seed = seed + seed_increment_number
		local noise_water_3 = perlin:noise(((pos_x+seed)/25),((pos_y+seed)/25),0)
		seed = seed + seed_increment_number
		local noise_water_4 = perlin:noise(((pos_x+seed)/10),((pos_y+seed)/10),0)
		seed = seed + seed_increment_number
		local noise_water_2 = noise_water_1 + noise_water_2 + noise_water_3 * 0.07 + noise_water_4 * 0.07

		if tile_to_insert ~= "stone-path" and tile_to_insert ~= "concrete" then

			if noise_water > -0.15 and noise_water < 0.15 and noise_water_2 > 0.5 then
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

		if noise_borg_defense <= 0.45 and tile_to_insert ~= "water-green" then
			local a = -0.01
			local b = 0.01
			if noise_walls > a and noise_walls < b then
				if surface.can_place_entity {name="stone-wall", position={pos_x,pos_y}, force="enemy"} then
					surface.create_entity {name="stone-wall", position={pos_x,pos_y}, force="enemy"}
				end
			end
			if noise_walls >= a and noise_walls <= b then
					tile_to_insert = "concrete"
			end
			if noise_borg_defense < 0.40 then
				if noise_walls > b and noise_walls < b + 0.03 then
					tile_to_insert = "stone-path"
				end
				if noise_walls > a - 0.03 and noise_walls < a then
					tile_to_insert = "stone-path"
				end
			end
		end

		local noise_decoratives_1 = perlin:noise(((pos_x+seed)/50),((pos_y+seed)/50),0)
		seed = seed + seed_increment_number
		local noise_decoratives_2 = perlin:noise(((pos_x+seed)/15),((pos_y+seed)/15),0)
		seed = seed + seed_increment_number
		local noise_decoratives = noise_decoratives_1 + noise_decoratives_2 * 0.3

		if noise_decoratives > 0.3 and noise_decoratives < 0.5 then
			if tile_to_insert ~= "stone-path" and tile_to_insert ~= "concrete" and tile_to_insert ~= "water-green" then
				if math.random(1,10) == 1 then
					table.insert(decoratives, {name="red-desert-bush", position={pos_x,pos_y}, amount=1})
				end
			end
		end
		table.insert(tiles, {name = tile_to_insert, position = {pos_x,pos_y}})
	end
	surface.set_tiles(tiles,true)

	for _,deco in pairs(decoratives) do
		surface.create_decoratives{check_collision=false, decoratives={deco}}
	end
end
