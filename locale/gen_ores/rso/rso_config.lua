
debug_enabled = true
config_log_enabled = false
debug_items_enabled = false

--region_size = 7	-- alternative mean to control how further away resources would be, default - 256 tiles or 8 chunks
				-- each region is region_size*region_size chunks
				-- each chunk is 32*32 tiles

starting_area_size = 1         	-- starting area in regions, safe from random nonsense

--multi_resource_active = true			-- moved to settings
multi_resource_richness_factor = 0.60 	-- any additional resource is multiplied by this value times resources-1
multi_resource_size_factor = 0.90
multi_resource_chance_diminish = 0.6	-- diminishing effect factor on multi_resource_chance

min_amount=250 					-- default value for minimum amount of resource in single pile

-- mode is no longer used by generation process - it autodetects endless resources
-- endless_resource_mode = false   -- if true, the size of each resource is modified by the following modifier. Use with the endless resources mod.
endless_resource_mode_sizeModifier = 0.80

biter_ratio_segment=1      --the ratio components determining how many biters to spitters will be spawned
spitter_ratio_segment=1    --eg. 1 and 1 -> equal number of biters and spitters,  10 and 1 -> 10 times as many biters to spitters

useEnemiesInPeaceMod = false -- additional override for peace mod detection - when set to true it will spawn enemies normally, needs to have enemies enabled in peace mod

useStraightWorldMod = false -- enables Straight World mod - actual mod code copied into RSO to make it compatible

-- special modification of straight world mod for platforms (thanks to Dreadicon)
useStraightWorldPlatforms = true -- enables Straight World behavior but only for platforms
straightWorldPlatformsThreshold = 0.25 -- determines how blocky/organic platforms are on a scale of 0 to 1: lower is more blocky.

ignoreMapGenSettings = false -- stops the default behaviour of reading map gen settings

useResourceCollisionDetection = true	-- enables avoidace calculations to reduce ores overlaping of each other
resourceCollisionDetectionRatio = 0.999 -- threshold to exit placement early
resourceCollisionDetectionRatioFallback = 0.75 	-- at least this much of ore field needs to be placable to spawn it
resourceCollisionFieldSkip = true		-- determines if ore field should be skipped completely if placement based on ratio failed
