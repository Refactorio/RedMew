function fillEnemies()
	
	config["enemy-base"] = {
		type="entity",
		force="enemy",
		clear_range = {6, 6},
		
		spawns_per_region={min=2,max=4},
		size={min=2,max=4},
		size_per_region_factor=0.4,
		richness=1,
		
		absolute_probability=rso_settings["rso-enemy-chance"], -- chance to spawn in region
		probability_distance_factor=1.15, -- relative increase per region
		max_probability_distance_factor=3.0, -- absolute value
		
		along_resource_probability=0.20, -- chance to spawn in resource chunk anyway, absolute value. Can happen once per resource.
		
		sub_spawn_probability=0.3,     -- chance for this entity to spawn anything from sub_spawns table, absolute value
		sub_spawn_size={min=1, max=2}, -- in same chunk
		sub_spawn_distance_factor=1.04,
		sub_spawn_max_distance_factor=3,
		sub_spawns={
			["small-worm-turret"]={
				min_distance=2,
				allotment=200,
				allotment_distance_factor=0.8,
				clear_range = {2, 2},
			},
			["medium-worm-turret"]={
				min_distance=4,
				allotment=100,
				allotment_distance_factor=1.1,
				clear_range = {2, 2},
			},
			["big-worm-turret"]={
				min_distance=6,
				allotment=100,
				allotment_distance_factor=1.2,
				clear_range = {2, 2},
			}
		}
	}
	
end