function fillVanillaConfig()
	
	config["iron-ore"] = {
		type="resource-ore",
		
		-- general spawn params
		allotment=100, -- how common resource is
		spawns_per_region={min=1, max=1}, --number of chunks
		richness=18000,        -- resource_ore has only one richness value - resource-liquid has min/max
		
		size={min=20, max=30}, -- rough radius of area, too high value can produce square shaped areas
		min_amount=500,
		
		-- resource provided at starting location
		-- probability: 1 = 100% chance to be in starting area
		--              0 = resource is not in starting area
		starting={richness=8000, size=25, probability=1},
		
		multi_resource_chance=0.20, -- absolute value
		multi_resource={
			["iron-ore"] = 2, -- ["resource_name"] = allotment
			['copper-ore'] = 4,
			["coal"] = 4,
			["stone"] = 4,
		}
	}
	
	config["copper-ore"] = {
		type="resource-ore",
		
		allotment=100,
		spawns_per_region={min=1, max=1},
		richness=16000,
		size={min=20, max=30},
		min_amount=500,

		starting={richness=6000, size=25, probability=1},
		
		multi_resource_chance=0.20,
		multi_resource={
			["iron-ore"] = 4,
			['copper-ore'] = 2,
			["coal"] = 4,
			["stone"] = 4,
		}
	}
	
	config["coal"] = {
		type="resource-ore",
		
		allotment=80,
		
		spawns_per_region={min=1, max=1},
		size={min=15, max=25},
		richness=13000,
		min_amount=500,

		starting={richness=6000, size=20, probability=1},
		
		multi_resource_chance=0.30,
		multi_resource={
			["crude-oil"] = 1,
			["iron-ore"] = 3,
			['copper-ore'] = 3,
		}
	}
	
	config["stone"] = {
		type="resource-ore",
		
		allotment=60,
		spawns_per_region={min=1, max=1},
		richness=11000,
		size={min=15, max=20},
		min_amount=250,

		starting={richness=5000, size=16, probability=1},
		
		multi_resource_chance=0.30,
		multi_resource={
			["coal"] = 4,
			["iron-ore"] = 3,
			['copper-ore'] = 3,
		}
	}
	
	config["uranium-ore"] = {
		type="resource-ore",
		
		allotment=40,
		spawns_per_region={min=1, max=1},
		richness=6000,
		size={min=10, max=15},
		min_amount=500,

		starting={richness=2000, size=10, probability=1},
	}
	
	config["crude-oil"] = {
		type="resource-liquid",
		minimum_amount=240000,
		allotment=70,
		spawns_per_region={min=1, max=2},
		richness={min=240000, max=400000}, -- richness per resource spawn
		size={min=2, max=5},
		
		starting={richness=400000, size=2, probability=1},
		
		multi_resource_chance=0.20,
		multi_resource={
			["coal"] = 4,
			["uranium-ore"] = 1,
		}
	}
end