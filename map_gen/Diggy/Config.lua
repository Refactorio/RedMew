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
        -- creates a starting zone
        StartingZone = {
            enabled = true,

            -- initial starting position size, higher values are not recommended
            starting_size = 8,
        },
        
        -- controls the Daylight (Default diggy: enabled = true)
        NightTime = {
            enabled = true, -- true = No Daylight, false = Day/night circle (Solar panels work)
        },

        -- controls setting up the players
        SetupPlayer = {
            enabled = true,
            starting_items = {
                {name = 'iron-axe', count = 1},
                {name = 'stone-wall', count = 10},
            },
            cheats = {
                manual_mining_speed_modifier = 1000,
                character_inventory_slots_bonus = 1000,
                character_running_speed_modifier = 2,
                starting_items = {
                    {name = 'modular-armor', count = 1},
                    {name = 'submachine-gun', count = 1},
                    {name = 'uranium-rounds-magazine', count = 200},
                },
            },
        },

        -- core feature
        DiggyHole = {
            enabled = true,

            -- enables commands like /clear-void
            enable_debug_commands = false,
        },

        -- adds the ability to collapse caves
        DiggyCaveCollapse = {
            enabled = true,

            -- adds per tile what the current stress is
            enable_stress_grid = false,

            -- shows the mask on spawn
            enable_mask_debug = false,

            -- enables commands like /test-tile-support-range
            enable_debug_commands = false,

            --the size of the mask used
            mask_size = 9,

            --how much the mask will effect tiles in the different rings of the mask
            mask_relative_ring_weights = {2, 3, 4},

            -- delay in seconds before the cave collapses
            collapse_delay = 2.5,

            -- the threshold that will be applied to all neighbors on a collapse via a mask
            collapse_threshold_total_strength = 16,

            support_beam_entities = {
                ['market'] = 9,
                ['stone-wall'] = 3,
                ['sand-rock-big'] = 2,
                ['out-of-map'] = 1,
                ['stone-path'] = 0.03,
                ['concrete'] = 0.04,
                ['hazard-concrete'] = 0.04,
                ['refined-concrete'] = 0.06,
            },
            cracking_sounds = {
              'CRACK',
              'KRRRR',
              'R U N',
            }
        },

        -- Adds the ability to drop coins and track how many are sent into space
        ArtefactHunting = {
            enabled = true,

            -- value between 0 and 1, higher value means stronger variance between coordinates
            noise_variance = 0.75,

            -- minimum noise value to spawn a treasure chest, works best with a very high noise variance,
            -- otherwise you risk spawning a lot of chests together
            treasure_chest_noise_threshold = 0.69,

            -- minimum distance from spawn where a chest can spawn
            minimal_treasure_chest_distance = 25,

            -- chances to receive a coin when mining
            mining_artefact_chance = 0.10,
            mining_artefact_amount = {min = 1, max = 4},

            -- lets you set the coin modifiers for aliens
            -- the modifier value increases the upper random limit that biters can drop
            alien_coin_modifiers = {
                ['small-biter'] = 1,
                ['small-spitter'] = 1,
                ['medium-biter'] = 2,
                ['medium-spitter'] = 2,
                ['big-biter'] = 4,
                ['big-spitter'] = 4,
                ['behemoth-biter'] = 6,
                ['behemoth-spitter'] = 6,
            },

            -- shows the chest locations, only use when debugging
            display_chest_locations = false,

            treasure_chest_raffle = {
                ['coin'] = {chance = 1.00, min = 20, max = 255},
                ['steel-axe'] = {chance = 0.55, min = 1, max = 2},
                ['stone'] = {chance = 0.50, min = 25, max = 75},
                ['copper-ore'] = {chance = 0.25, min = 30, max = 60},
                ['copper-plate'] = {chance = 0.10, min = 12, max = 25},
                ['iron-ore'] = {chance = 0.20, min = 10, max = 55},
                ['iron-plate'] = {chance = 0.10, min = 5, max = 25},
                ['steel-plate'] = {chance = 0.05, min = 3, max = 14},
                ['steel-furnace'] = {chance = 0.02, min = 1, max = 1},
                ['steam-engine'] = {chance = 0.02, min = 1, max = 1},
                ['coal'] = {chance = 0.40, min = 30, max = 55},
                ['concrete'] = {chance = 0.14, min = 10, max = 50},
                ['stone-brick'] = {chance = 0.14, min = 25, max = 75},
                ['stone-wall'] = {chance = 0.50, min = 1, max = 3},
            }
        },

        -- replaces the chunks with void
        RefreshMap = {
            enabled = true,
        },

        -- automatically opens areas
        SimpleRoomGenerator = {
            enabled = true,

            -- value between 0 and 1, higher value means stronger variance between coordinates
            noise_variance = 0.066,

            -- shows where rooms are located
            display_room_locations = false,

            -- minimum distance and noise range required for water to spawn
            room_noise_minimum_distance = 9,
            room_noise_ranges = {
                {name = 'water', min = 0.54, max = 1},
                {name = 'dirt', min = 0.39, max = 0.53},
            },
        },

        -- responsible for resource spawning
        ScatteredResources = {
            enabled = true,
            
            -- ==============
            -- Debug settings
            -- ==============
            
            -- shows the ore locations, only use when debugging (cluster mode)
            display_resource_fields = false,
            
            -- shows the ore locations, only use when debugging (compound_cluster_mode)
            display_compound_ore_locations = false,
            
            -- ===========================================================
            -- These settings affects both scattered_mode and cluster_mode
            -- ===========================================================
            
            -- percentage of resource added to the sum. 100 tiles means
            -- 10% more resources with a distance_richness_modifier of 10
            -- 20% more resources with a distance_richness_modifier of 5
            distance_richness_modifier = 7,
            
            -- increases the amount of liquids that need pumping
            liquid_value_modifiers = {
                ['crude-oil'] = 750,
            },

            -- weights per resource of spawning 
            resource_weights = {
                ['coal']        = 160,
                ['copper-ore']  = 215,
                ['iron-ore']    = 389,
                ['stone']       = 212,
                ['uranium-ore'] =  21,
                ['crude-oil']   =   3,
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
            
            -- defines the weights of which resource_richness_value to spawn
            resource_richness_weights = {
                ['scarce']     = 440,
                ['low']        = 350,
                ['sufficient'] = 164,
                ['good']       =  30,
                ['plenty']     =  10,
                ['jackpot']    =   6,
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
            
            -- =======================
            -- Scattered mode settings
            -- =======================
            
            -- creates scattered ore (single tiles) at random locations
            scattered_mode = true,
            
            -- defines the increased chance of spawning resources
            -- calculated_probability = resource_probability + ((distance / distance_probability_modifier) / 100)
            distance_probability_modifier = 10,
            
            -- min percentage of chance that resources will spawn after mining
            resource_probability = 0.01,

            -- max chance of spawning resources based on resource_probability + calculated distance_probability_modifier
            max_resource_probability = 0.30,
            
            -- =====================
            -- Cluster mode settings
            -- =====================

            -- creates clusters of ore with higher yields and frequency instead of evenly scattered ore
            -- lowers max resource max_resource_probability to 50% of the original value
            cluster_mode = true,

            -- value between -1 and 1, higher value means stronger variance between coordinates
            -- (this means smaller, more frequent ore patches)
            noise_variance = 0.04,

            -- a value between 0 and 1 that triggers the spawning of resource based on noise
            -- (lower values have larger patches, 0 means ~50% of the map is ore)
            noise_resource_threshold = 0.40,

            -- raw multiplier for ore content in cluster mode
            cluster_yield_multiplier = 1.7,
            
            -- ==============================
            -- Compound cluster mode settings
            -- ==============================
            
            -- creates compound clusters of ores defined by a layered ore-gen
            compound_cluster_mode = false,
            
            -- defines the weights of which resource_richness_value range to spawn
            compound_cluster_richness_weights = {
                ['scarce']     = 440,
                ['low']        = 350,
                ['sufficient'] = 164,
                ['good']       =  30,
                ['plenty']     =  10,
                ['jackpot']    =   6,
            },

            -- defines the min and max range of base quantity for ores to spawn
            compound_cluster_richness_values = {
                ['scarce']     = {1, 200},
                ['low']        = {201, 400},
                ['sufficient'] = {401, 750},
                ['good']       = {751, 1200},
                ['plenty']     = {1201, 2000},
                ['jackpot']    = {2001, 5000},
            },
            
            -- in compound cluster mode, final ore quantities are generated by the following procedure:
            --   iterate through each cluster checking the following conditions
            --     if the distance < min_distance, check the next cluster
            --     if the noise value < threshold, check the next cluster
            --     a resource_type is generated based on the values of weights
            --     if resource_type is 'skip', check the next cluster
            --     if an entry in distances exists for the given resource_type
            --       if distance < distances[resource_type], check the next cluster
            --     a range of values is selected from richness_values based on richness_weights
            --     base_amount = a random value from within the selected range of values
            --     amount is adjusted by 1 + 0.01*(distance / distance_richness)
            --       this means every distance_richness tiles, the quantity increases by 1%
            --     if the resource_type has an entry in the type_scalar
            --       then the amount is multiplied by the scalar
            --     the resource is then generated and no further clusters are checked
            
            -- increases the amount of ore by flat multiplication to initial amount
            -- highly suggested to use for fluids so their yield is reasonable
            compound_cluster_type_scalar = {
                ['crude-oil'] = 750,
            },
            
            -- defines all ore patches to be generated. Add as many clusters as 
            -- needed. Clusters listed first have a higher placement priority over
            -- the latter clusters
            compound_clusters = {
            
                {variance=0.04,
                    threshold=0.40,
                    yield=1.7,
                    min_distance=30,
                    distance_richness=7,
                    noise="perlin",
                    weights = {
                        ['coal']        = 160,
                        ['copper-ore']  = 215,
                        ['iron-ore']    = 389,
                        ['stone']       = 212,
                        ['uranium-ore'] =  21,
                        ['crude-oil']   =   3,
                    },
                    distances = {
                        ['coal']        = 16,
                        ['copper-ore']  = 18,
                        ['iron-ore']    = 18,
                        ['stone']       = 15,
                        ['uranium-ore'] = 86,
                        ['crude-oil']   = 57,
                    }, },
                    
            --  {    variance=0.04,
            --      threshold=0.40,
            --      yield=1.7,
            --      min_distance=18,
            --      distance_richness=7,
            --      noise="perlin",
            --      weights = {
            --          ['copper-ore']  = 1,
            --          ['iron-ore']    = 2,
			--          ['skip']        = 2,
            --      },
            --      distances = {
            --      }, },
            
                },
            
        },

        -- controls the alien spawning mechanic
        AlienSpawner = {
            enabled = true,

            -- minimum distance from spawn before aliens can spawn
            alien_minimum_distance = 40,

            -- chance of spawning aliens when mining
            alien_probability = 0.07,
        },

        -- controls the market and buffs
        MarketExchange = {
            enabled = true,

            -- percentage * mining productivity level gets added to mining speed
            mining_speed_productivity_multiplier = 5,

            -- market config
            market_spawn_position = {x = 0, y = 3},
            stone_to_surface_amount = 50,
            currency_item = 'stone',

            -- locations where chests will be automatically cleared from currency_item
            void_chest_tiles = {
                {x = -1, y = 5}, {x = 0, y = 5}, {x = 1, y = 5},
            },

            -- every x ticks it will clear y currency_item
            void_chest_frequency = 307,

            unlockables = {
                {stone = 50, type = 'buff', prototype = {name = 'mining_speed', value = 10}},
                {stone = 50, type = 'buff', prototype = {name = 'inventory_slot', value = 3}},
                {stone = 50, type = 'buff', prototype = {name = 'stone_automation', value = 10}},
                {stone = 50, type = 'market', prototype = {price = 25, name = 'raw-wood'}},
                {stone = 50, type = 'market', prototype = {price = 50, name = 'raw-fish'}},
                {stone = 50, type = 'market', prototype = {price = 175, name = 'steel-axe'}},

                {stone = 250, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 250, type = 'buff', prototype = {name = 'inventory_slot', value = 2}},
                {stone = 250, type = 'buff', prototype = {name = 'stone_automation', value = 5}},
                {stone = 250, type = 'market', prototype = {price = 50, name = 'small-lamp'}},
                {stone = 250, type = 'market', prototype = {price = 25, name = 'stone-brick'}},
                {stone = 250, type = 'market', prototype = {price = 125, name = 'stone-wall'}},

                {stone = 450, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 450, type = 'buff', prototype = {name = 'inventory_slot', value = 2}},
                {stone = 450, type = 'buff', prototype = {name = 'stone_automation', value = 5}},
                {stone = 450, type = 'market', prototype = {price = 850, name = 'submachine-gun'}},
                {stone = 450, type = 'market', prototype = {price = 850, name = 'shotgun'}},
                {stone = 450, type = 'market', prototype = {price = 50, name = 'firearm-magazine'}},
                {stone = 450, type = 'market', prototype = {price = 50, name = 'shotgun-shell'}},
                {stone = 450, type = 'market', prototype = {price = 500, name = 'light-armor'}},

                {stone = 750, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 750, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 750, type = 'buff', prototype = {name = 'stone_automation', value = 5}},

                {stone = 1250, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 1250, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 1250, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 1750, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 1750, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 1750, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 2500, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 2500, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 2500, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 4000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 4000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 4000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 6500, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 6500, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 6500, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 8000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 8000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 8000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 10000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 10000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 10000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 10000, type = 'market', prototype = {price = 750, name = 'heavy-armor'}},

                {stone = 15000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 15000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 25000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 25000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 25000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 35000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 35000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 35000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 35000, type = 'market', prototype = {price = 100, name = 'piercing-rounds-magazine'}},
                {stone = 35000, type = 'market', prototype = {price = 100, name = 'piercing-shotgun-shell'}},
                {stone = 35000, type = 'market', prototype = {price = 1500, name = 'modular-armor'}},

                {stone = 50000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 50000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 50000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 75000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 75000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 75000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 100000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 100000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 100000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 100000, type = 'market', prototype = {price = 1000, name = 'landfill'}},

                {stone = 125000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 125000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 125000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 150000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 150000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 150000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 175000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 175000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 175000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 200000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 200000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 200000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 225000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 225000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 225000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 250000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 250000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 250000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 275000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 275000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 275000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 300000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 300000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 300000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 350000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 350000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 350000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 400000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 400000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 400000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 500000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 500000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 500000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 600000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 600000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 600000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 700000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 700000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 700000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},

                {stone = 800000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 800000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
                {stone = 800000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 800000, type = 'market', prototype = {price = 250, name = 'uranium-rounds-magazine'}},
                {stone = 800000, type = 'market', prototype = {price = 1000, name = 'combat-shotgun'}},

                {stone = 900000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 900000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 900000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 1000000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 1000000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 1000000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 1250000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 1250000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 1250000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 1500000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 1500000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 1500000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 1750000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 1750000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 1750000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 2000000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 2000000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 2000000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 2500000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 2500000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 2500000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 3000000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 3000000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 3000000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 3500000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 3500000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 3500000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 4000000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 4000000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 4000000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 4500000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 4500000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 4500000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 5000000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 5000000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 5000000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 6000000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 6000000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 6000000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 7000000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 7000000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 7000000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 8000000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 8000000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 8000000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 9000000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 9000000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 9000000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},

                {stone = 10000000, type = 'buff', prototype = {name = 'mining_speed', value = 5}},
                {stone = 10000000, type = 'buff', prototype = {name = 'stone_automation', value = 2}},
                {stone = 10000000, type = 'buff', prototype = {name = 'inventory_slot', value = 1}},
            },
        },
    },
}

return Config
