require "locale.gen_shared.perlin_noise"

if ores_module then return end
ores_module = true

local random_ores = {"iron-ore","coal","copper-ore","stone","uranium-ore"}
local random_dense = {1.15,0.8,1,0.9, 0.5}	--ore density reference

function run_ores_module_setup()
	if not global.ores_seed_A then global.ores_seed_A = math.random(10,10000) end
	if not global.ores_seed_B then global.ores_seed_B = math.random(10,10000) end
end

--generate ores for entire chunk
function run_ores_module(event)
	--game.print("gen crazy ores")
	run_ores_module_setup()
	--if not global.ores_seed_A then global.ores_seed_A = math.random(10,10000) end
	--if not global.ores_seed_B then global.ores_seed_B = math.random(10,10000) end

	local area = event.area
	local surface = event.surface
	local tiles = {}


	local entities = surface.find_entities(area)
	for _, entity in pairs(entities) do
		if entity.type == "resource" then
			entity.destroy()
		end
	end

	local top_left = area.left_top	--make a more direct reference

	local distance_bonus = 200 + math.sqrt(top_left.x*top_left.x + top_left.y*top_left.y) * 0.2

	for x = top_left.x, top_left.x + 31 do
		for y = top_left.y, top_left.y + 31 do
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
					surface.create_entity {name="crude-oil", position={x,y}, amount = math.random(5000,20000) +math.floor(distance_bonus)* 1500 }
				end
			end

		end
	end

end

--used when terrain modual passes to it, can save extra calculations
function run_ores_module_tile(surface,x,y)

	distance_bonus = 200 + math.sqrt(x*x + y*y) * 0.2

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
		--if surface.can_place_entity {name=random_ores[a], position={x,y}} then
			--We assume it can be places because terrain gen told us to.
			surface.create_entity {name=random_ores[a], position={x,y}, amount=res_amount}
		--end
	elseif Ores_A < -60 then
		if math.random(1,200) == 1 then
			surface.create_entity {name="crude-oil", position={x,y}, amount = math.random(5000,20000) +math.floor(distance_bonus)* 1500 }
		end
	end

end
