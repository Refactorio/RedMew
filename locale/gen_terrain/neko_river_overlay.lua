
require "locale.gen_shared.perlin_noise"

local tree_to_place = {"dry-tree","dry-hairy-tree","tree-06","tree-06","tree-01","tree-02","tree-03"}

function run_terrain_module(event)
	if not global.terrain_seed_A then global.terrain_seed_A = math.random(10,10000) end
	if not global.terrain_seed_B then global.terrain_seed_B = math.random(10,10000) end

	local area = event.area
	local surface = event.surface
	local tiles = {}
	local tileswater = {}

	local entities = surface.find_entities(area)
	for _, entity in pairs(entities) do
		if (run_ores_module ~= nil and entity.type == "resource") then
			entity.destroy()
		end
	end

	local top_left = area.left_top	--make a more direct reference

	for x = top_left.x-1, top_left.x + 32 do
		for y = top_left.y-1, top_left.y + 32 do
			--local pos_x = top_left.x + x
			--local pos_y = top_left.y + y
			local tile = surface.get_tile(x,y)

			if tile.name ~= "out-of-map" then

				--local tile_to_insert = "grass-3"

				local wiggle = 50 + perlin:noise((x*0.005),(y*0.005),global.terrain_seed_A + 71) * 60
				local terrain_A = perlin:noise((x*0.005),(y*0.005),global.terrain_seed_A + 19) * wiggle	--For determining where water is
				local terrain_sqr = terrain_A * terrain_A	--we can use this again to mess with other layers as well


				if terrain_sqr < 50 then	--Main water areas
					--local deep = (terrain_sqr < 20) and true or false
					terrain_A = perlin:noise((x*0.01),(y*0.01),global.terrain_seed_A + 31) * 90 + (wiggle * -0.2)	--we only gen this when we consider placing water
					--terrain_A = simplex_2d((x*0.01),(y*0.01),global.terrain_seed_A + 31) * 90 + (wiggle * -0.2)	--we only gen this when we consider placing water

					if terrain_A * terrain_A > 40 then	--creates random bridges over the water by overlapping with another noise layer
						table.insert(tiles, {name = "water", position = {x,y}})
					end
				elseif terrain_sqr > 70 then

					if run_ores_module ~= nil then
						run_ores_module_setup()
						if x > top_left.x-1 and x < top_left.x+32 and y > top_left.y-1 and y < top_left.y+32 then
							run_ores_module_tile(surface,x,y)
						end
					end
				end


			end
		end
	end

	surface.set_tiles(tiles,true)
	--surface.set_tiles(tileswater,true)
end
