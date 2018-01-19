--Author: MewMew

require "map_genshared.perlin_noise"

function run_combined_module(event)
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
