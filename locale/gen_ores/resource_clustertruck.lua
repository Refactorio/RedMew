--Author: MewMew

require "locale.gen_shared.perlin_noise"

function run_combined_module(event)
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
