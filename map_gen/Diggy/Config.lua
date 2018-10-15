-- dependencies

-- this
local Config = {
    -- enable debug mode, shows extra messages
    debug = false,

    -- allow cheats. Example: by default the player will have X mining speed
    cheats = false,

    -- a list of features to register and enable
    -- to disable a feature, change the flag
    features = {
        StartingZone = {
            enabled = true,

            -- initial starting position size, values higher than 30 might break
            starting_size = 8,
        },
        SetupPlayer = {
            enabled = true,
            starting_items = {
                {name = 'iron-axe', count = 1},
                {name = 'stone-wall', count = 10},
            },
            cheats = {
                manual_mining_speed_modifier = 1000,
            },
        },
        DiggyHole = {
            enabled = true,
        },
        DiggyCaveCollapse = {
            enabled = true,

            -- adds per tile what the current stress is
            enable_stress_grid = false,

            -- shows the mask on spawn
            enable_mask_debug = false,

            --the size of the mask used
            mask_size = 9,

            --how much the mask will effect tiles in the different rings of the mask
            mask_relative_ring_weights = {2, 3, 4},

            -- delay in seconds before the cave collapses
            collapse_delay = 2.5,

            -- the threshold that will be applied to all neighbors on a collapse via a mask
            collapse_threshold_total_strength = 16,

            support_beam_entities = {
                ['market'] = 10,
                ['stone-wall'] = 3.3,
                ['sand-rock-big'] = 2.2,
                ['out-of-map'] = 1.1,
                ['stone-brick'] = 0.055,
                ['stone-path'] = 0.055,
                ['concrete'] = 0.33,
                ['hazard-concrete-left'] = 0.33,
                ['hazard-concrete-right'] = 0.33,
                ['refined-concrete'] = 0.77,
                ['refined-hazard-concrete-left'] = 0.77,
                ['refined-hazard-concrete-right'] = 0.77,
            },
            cracking_sounds = {
              'CRACK',
              'KRRRR',
            }
        },
        RefreshMap = {
            enabled = true,
        },
        SimpleRoomGenerator = {
            enabled = true,

            -- value between 0 and 1, higher value means stronger variance between coordinates
            noise_variance = 0.066,

            -- adds per tile what the current noise is
            enable_noise_grid = false,

            -- minimum distance and noise range required for water to spawn
            room_noise_minimum_distance = 9,
            room_noise_ranges = {
                {name = 'water', min = 0.54, max = 1},
                {name = 'dirt', min = 0.39, max = 0.53},
            },
        },
        ScatteredResources = {
            enabled = true,

            -- percentage of resource added to the sum. 100 tiles means
            -- 10% more resources with a distance_richness_modifier of 10
            -- 20% more resources with a distance_richness_modifier of 5
            distance_richness_modifier = 5,

            -- defines the increased chance of spawning resources
            -- calculated_probability = resource_probability + ((distance / distance_probability_modifier) / 100)
            distance_probability_modifier = 2,

            -- increases the amount of oil * oil_value_modifier
            oil_value_modifier = 650,

            -- percentage of chance that resources will spawn after mining
            resource_probability = 0.15,

            -- max chance of spawning resources based on resource_probability + calculated distance_probability_modifier
            max_resource_probability = 0.45,

            -- chances per resource of spawning, sum must be 1.00
            resource_chances = {
                ['coal']        = 0.21,
                ['copper-ore']  = 0.30,
                ['iron-ore']    = 0.26,
                ['stone']       = 0.20,
                ['uranium-ore'] = 0.02,
                ['crude-oil']   = 0.01,
            },

            -- minimum distance from the spawn point required before it spawns
            minimum_resource_distance = {
                ['coal']        = 16,
                ['copper-ore']  = 18,
                ['iron-ore']    = 18,
                ['stone']       = 15,
                ['uranium-ore'] = 86,
                ['crude-oil']   = 57,
            },

            -- defines the chance of which resource_richness_value to spawn, sum must be 1.00
            resource_richness_probability = {
                ['scarce']     = 0.40,
                ['low']        = 0.28,
                ['sufficient'] = 0.16,
                ['good']       = 0.10,
                ['plenty']     = 0.04,
                ['jackpot']    = 0.02,
            },

            -- defines the min and max range of ores to spawn
            resource_richness_values = {
                ['scarce']     = {1, 200},
                ['low']        = {201, 400},
                ['sufficient'] = {401, 750},
                ['good']       = {751, 1200},
                ['plenty']     = {1201, 2000},
                ['jackpot']    = {2001, 5000},
            },
        },
        AlienSpawner = {
            enabled = false,

            -- minimum distance from spawn before aliens can spawn
            alien_minimum_distance = 35,

            -- chance of spawning aliens when mining
            alien_probability = 0.07,
        },
        MarketExchange = {
            enabled = true,

            -- percentage * mining productivity level gets added to mining speed
            mining_speed_productivity_multiplier = 10,

            -- market config
            market_spawn_position = {x = 0, y = 4},
            stone_to_surface_amount = 50,
            currency_item = 'stone',

            unlockables = {
                {stone = 50, type = 'buff', prototype = {name = 'mining_speed', value = 10}},
                {stone = 50, type = 'buff', prototype = {name = 'inventory_slot', value = 3}},
                {stone = 50, type = 'market', prototype = {price = 50, name = 'raw-fish'}},
                {stone = 50, type = 'market', prototype = {price = 175, name = 'steel-axe'}},

                {stone = 250, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 250, type = 'buff', prototype = {name = 'inventory_slot', value = 2}},
                {stone = 250, type = 'market', prototype = {price = 50, name = 'small-electric-pole'}},
                {stone = 250, type = 'market', prototype = {price = 50, name = 'small-lamp'}},
                {stone = 250, type = 'market', prototype = {price = 25, name = 'stone-brick'}},
                {stone = 250, type = 'market', prototype = {price = 125, name = 'stone-wall'}},

                {stone = 450, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 450, type = 'buff', prototype = {name = 'inventory_slot', value = 2}},
                {stone = 450, type = 'market', prototype = {price = 850, name = 'submachine-gun'}},
                {stone = 450, type = 'market', prototype = {price = 50, name = 'firearm-magazine'}},
                {stone = 450, type = 'market', prototype = {price = 500, name = 'light-armor'}},

                {stone = 750, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 750, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 1250, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 1250, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 1750, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 1750, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 2500, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 2500, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 4000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 4000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 6500, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 6500, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 8000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 8000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 10000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 10000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 10000, type = 'market', prototype = {price = 750, name = 'heavy-armor'}},

                {stone = 15000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
                {stone = 15000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 25000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
                {stone = 25000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 35000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
                {stone = 35000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 35000, type = 'market', prototype = {price = 100, name = 'piercing-rounds-magazine'}},
                {stone = 35000, type = 'market', prototype = {price = 1500, name = 'modular-armor'}},

                {stone = 50000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
                {stone = 50000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 75000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
                {stone = 75000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 100000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
                {stone = 100000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 125000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
                {stone = 150000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
                {stone = 175000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
                {stone = 200000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
                {stone = 225000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
                {stone = 250000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
                {stone = 275000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
                {stone = 300000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
                {stone = 350000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
                {stone = 400000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
                {stone = 500000, type = 'buff', prototype = {name = 'mining_speed', value = 2}},
            },
        },
    },
}

return Config
