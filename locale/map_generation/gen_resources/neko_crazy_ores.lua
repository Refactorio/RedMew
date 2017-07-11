if ores_module then return end
ores_module = true

local random_ores = {"iron-ore","coal","copper-ore","stone","uranium-ore"}
local random_dense = {1.15,0.8,1,0.9, 0.5}	--ore density reference

function run_ores_module(event)
	--game.print("gen crazy ores")
	if not global.ores_seed_A then global.ores_seed_A = math.random(10,10000) end
	if not global.ores_seed_B then global.ores_seed_B = math.random(10,10000) end
	
	local area = event.area 
	local surface = event.surface
	local tiles = {}

	
	local entities = surface.find_entities(area)
	for _, entity in pairs(entities) do						
		if entity.type == "resource" then
			entity.destroy()
		end			
	end
		
	top_left = area.left_top	--make a more direct reference
	
	local distance_bonus = 200 + math.sqrt(top_left.x*top_left.x + top_left.y*top_left.y) * 0.2
	
	for x = area.left_top.x, area.right_bottom.x do
		for y = area.left_top.y, area.right_bottom.y do                     
				--table.insert(tiles, {name = "out-of-map", position = {x,y}}) 

			local wiggle = 100 + perlin:noise((x*0.005),(y*0.005),global.ores_seed_A + 41) * 60
			local Ores_A = perlin:noise((x*0.01),(y*0.01),global.ores_seed_B + 57) * wiggle
			
			
			if Ores_A > 35 then	--we place ores
				local Ores_B = perlin:noise((x*0.02),(y*0.02),global.ores_seed_B + 13) * wiggle	
				local a = 5
			--	
				if Ores_A < 76 then a = math.floor(Ores_A*0.75 + Ores_B*0.5) % 4 + 1 end	--if its not super high we place normal ores
			--	
				local res_amount = distance_bonus
				res_amount = math.floor(res_amount * random_dense[a])
			--	
				if surface.can_place_entity {name=random_ores[a], position={x,y}} then	
					surface.create_entity {name=random_ores[a], position={x,y}, amount=res_amount}
				end	
			elseif Ores_A < -60 then
				if math.random(1,200) == 1 and surface.can_place_entity {name="crude-oil", position={x,y}} then	
					surface.create_entity {name="crude-oil", position={x,y}, amount = math.random(20000,60000) +distance_bonus* 2000 }
				end
			end
				
		end
	end
	
end