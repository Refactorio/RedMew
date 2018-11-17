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
            
            -- determines how distance is measured
            distance = function (x, y) return math.abs(x) + math.abs(y) end, 
            --distance = function (x, y) return math.sqrt(x * x + y * y) end,
            
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
            
            -- increases the amount of resources by flat multiplication to initial amount
            -- highly suggested to use for fluids so their yield is reasonable
            resource_type_scalar = {
                ['crude-oil'] = 1500,
                ['uranium-ore'] = 1.25,
            },
            
            -- ==============
            -- Debug settings
            -- ==============
            
            -- shows the ore locations, only use when debugging (compound_cluster_mode)
            display_ore_clusters = false,
            
            -- =======================
            -- Scattered mode settings
            -- =======================
            
            -- creates scattered ore (single tiles) at random locations
            scattered_mode = false,
            
            -- defines the increased chance of spawning resources
            -- calculated_probability = resource_probability + ((distance / scattered_distance_probability_modifier) / 100)
            -- this means the chance increases by 1% every DISTANCE tiles up to the max_probability
            scattered_distance_probability_modifier = 10,
            
            -- min percentage of chance that resources will spawn after mining
            scattered_min_probability = 0.01,

            -- max chance of spawning resources based on resource_probability + calculated scattered_distance_probability_modifier
            scattered_max_probability = 0.10,
            
            -- percentage of resource added to the sum. 100 tiles means
            -- 10% more resources with a distance_richness_modifier of 10
            -- 20% more resources with a distance_richness_modifier of 5
            scattered_distance_richness_modifier = 7,
            
            -- multiplies probability only if cluster mode is enabled
            scattered_cluster_probability_multiplier = 0.5,
            
            -- multiplies yield only if cluster mode is enabled
            scattered_cluster_yield_multiplier = 1.7,
            
            -- weights per resource of spawning 
            scattered_resource_weights = {
                ['coal']        = 160,
                ['copper-ore']  = 215,
                ['iron-ore']    = 389,
                ['stone']       = 212,
                ['uranium-ore'] =  21,
                ['crude-oil']   =   3,
            },

            -- minimum distance from the spawn point required before it spawns
            scattered_minimum_resource_distance = {
                ['coal']        = 16,
                ['copper-ore']  = 18,
                ['iron-ore']    = 18,
                ['stone']       = 15,
                ['uranium-ore'] = 86,
                ['crude-oil']   = 57,
            },
            
            -- ==============================
            -- Compound cluster mode settings
            -- ==============================
            
            -- creates compound clusters of ores defined by a layered ore-gen
            cluster_mode = true,
            
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
            --     amount is multiplied by cluster yield
            --     amount is multiplied by 1 + 0.01*(distance / distance_richness)
            --       this means every distance_richness tiles, the quantity increases by 1%
            --     if the resource_type has an entry in the type_scalar
            --       then the amount is multiplied by the scalar
            --     the resource is then generated and no further clusters are checked
            
            
            -- defines all ore patches to be generated. Add as many clusters as 
            -- needed. Clusters listed first have a higher placement priority over
            -- the latter clusters
            --
            -- noise types:
            --   cluster: same as vanilla factorio generation
            --   skip: skips this cluster
            --   connected_tendril: long ribbons of ore
            --   fragmented_tendril: long ribbons of ore that occur when inside another
            --       region of ribbons
            --
            -- noise source types and configurations
            --   perlin: same as vanilla factorio generation
            --     variance: increase to make patches closer together and smaller
            --         note that this is the inverse of the cluster_mode variance
            --     threshold: increase to shrink size of patches
            --   simplex: similar to perlin
            --   zero: does nothing with this source
            --   one: adds the weight directly to the noise calculation
            clusters = {
                -- start the next line with 3 dashes to enable default single cluster mode
                --   or with 2 dashes to disable it
                
                --[[ Single clusters
                {
                    yield=1.0,
                    min_distance=30,
                    distance_richness=7,
                    noise_settings = {
                        type = "cluster",
                        threshold = 0.40,
                        sources = {
                            {variance=25, weight = 1, offset = 000, type="perlin"},
                        }
                    },
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
                --]]
                
                -- start the next line with 3 dashes to enable default tendril mode
                --   or with 2 dashes to disable it
                
                ---[[ Tendril clusters
                { -- tendril default large
                    yield=1.5,
                    min_distance=30,
                    distance_richness=7,
                    color={r=255/255, g=0/255, b=255/255},
                    noise_settings = {
                        type = "connected_tendril",
                        threshold = 0.05,   
                        sources = {
                            {variance=350*2, weight = 1.000, offset = 000, type="simplex"},
                            {variance=200*2, weight = 0.350, offset = 150, type="simplex"},
                            {variance=050*2, weight = 0.050, offset = 300, type="simplex"},
                            {variance=020*2, weight = 0.015, offset = 450, type="simplex"},
                        }
                    },
                    weights = {
                        ['coal']        = 160,
                        ['copper-ore']  = 215,
                        ['iron-ore']    = 389,
                        ['stone']       = 212,
                        ['uranium-ore'] =  21,
                    },
                    distances = {
                        ['coal']        = 16,
                        ['copper-ore']  = 18,
                        ['iron-ore']    = 18,
                        ['stone']       = 15,
                        ['uranium-ore'] = 86,
                    }, },
                { -- tendril default small
                    yield=1.0,
                    min_distance=30,
                    distance_richness=7,
                    color={r=255/255, g=255/255, b=0/255},
                    noise_settings = {
                        type = "connected_tendril",
                        threshold = 0.05,
                        sources = {
                            {variance=120, weight = 1.000, offset = 000, type="simplex"},
                            {variance=060, weight = 0.300, offset = 150, type="simplex"},
                            {variance=040, weight = 0.200, offset = 300, type="simplex"},
                            {variance=020, weight = 0.090, offset = 450, type="simplex"},
                        }
                    },
                    weights = {
                        ['coal']        = 160,
                        ['copper-ore']  = 215,
                        ['iron-ore']    = 389,
                        ['stone']       = 212,
                        ['uranium-ore'] =  21,
                    },
                    distances = {
                        ['coal']        = 16,
                        ['copper-ore']  = 18,
                        ['iron-ore']    = 18,
                        ['stone']       = 15,
                        ['uranium-ore'] = 86,
                    },
                },
                { -- tendril default fragments coal
                    yield=0.25,
                    min_distance=30,
                    distance_richness=7,
                    color={r=0/255, g=0/255, b=0/255},
                    noise_settings = {
                        type = "fragmented_tendril",
                        threshold = 0.05,
                        discriminator_threshold = 0.4,
                        sources = {
                            {variance=050, weight = 1.000, offset = 600, type="simplex"},
                            {variance=030, weight = 0.500, offset = 750, type="simplex"},
                            {variance=020, weight = 0.250, offset = 900, type="simplex"},
                            {variance=010, weight = 0.100, offset =1050, type="simplex"},
                        },
                        discriminator = {
                            {variance=120, weight = 1.000, offset = 000, type="simplex"},
                            {variance=060, weight = 0.300, offset = 150, type="simplex"},
                            {variance=040, weight = 0.200, offset = 300, type="simplex"},
                            {variance=020, weight = 0.090, offset = 450, type="simplex"},
                        },
                    },
                    weights = {
                        ['coal']        = 1,
                    },
                    distances = {
                        ['coal']        = 16,
                    },
                },
                { -- tendril default fragments iron
                    yield=0.25,
                    min_distance=30,
                    distance_richness=7,
                    color={r=0/255, g=140/255, b=255/255},
                    noise_settings = {
                        type = "fragmented_tendril",
                        threshold = 0.05,
                        discriminator_threshold = 0.4,
                        sources = {
                            {variance=050, weight = 1.000, offset = 600, type="simplex"},
                            {variance=030, weight = 0.500, offset = 750, type="simplex"},
                            {variance=020, weight = 0.250, offset = 900, type="simplex"},
                            {variance=010, weight = 0.100, offset =1050, type="simplex"},
                        },
                        discriminator = {
                            {variance=120, weight = 1.000, offset = 000, type="simplex"},
                            {variance=060, weight = 0.300, offset = 150, type="simplex"},
                            {variance=040, weight = 0.200, offset = 300, type="simplex"},
                            {variance=020, weight = 0.090, offset = 450, type="simplex"},
                        },
                    },
                    weights = {
                        ['iron-ore']    = 389,
                    },
                    distances = {
                        ['coal']        = 16,
                        ['iron-ore']    = 18,
                    },
                },
                { -- tendril default fragments copper
                    yield=0.25,
                    min_distance=30,
                    distance_richness=7,
                    color={r=255/255, g=55/255, b=0/255},
                    noise_settings = {
                        type = "fragmented_tendril",
                        threshold = 0.05,
                        discriminator_threshold = 0.4,
                        sources = {
                            {variance=050, weight = 1.000, offset = 600, type="simplex"},
                            {variance=030, weight = 0.500, offset = 750, type="simplex"},
                            {variance=020, weight = 0.250, offset = 900, type="simplex"},
                            {variance=010, weight = 0.100, offset =1050, type="simplex"},
                        },
                        discriminator = {
                            {variance=120, weight = 1.000, offset = 000, type="simplex"},
                            {variance=060, weight = 0.300, offset = 150, type="simplex"},
                            {variance=040, weight = 0.200, offset = 300, type="simplex"},
                            {variance=020, weight = 0.090, offset = 450, type="simplex"},
                        },
                    },
                    weights = {
                        ['copper-ore']  = 215,
                    },
                    distances = {
                        ['copper-ore']  = 18,
                    },
                },
                { -- tendril default fragments stone
                    yield=0.25,
                    min_distance=30,
                    distance_richness=7,
                    color={r=100/255, g=100/255, b=100/255},
                    noise_settings = {
                        type = "fragmented_tendril",
                        threshold = 0.05,
                        discriminator_threshold = 0.4,
                        sources = {
                            {variance=050, weight = 1.000, offset = 600, type="simplex"},
                            {variance=030, weight = 0.500, offset = 750, type="simplex"},
                            {variance=020, weight = 0.250, offset = 900, type="simplex"},
                            {variance=010, weight = 0.100, offset =1050, type="simplex"},
                        },
                        discriminator = {
                            {variance=120, weight = 1.000, offset = 000, type="simplex"},
                            {variance=060, weight = 0.300, offset = 150, type="simplex"},
                            {variance=040, weight = 0.200, offset = 300, type="simplex"},
                            {variance=020, weight = 0.090, offset = 450, type="simplex"},
                        },
                    },
                    weights = {
                        ['stone']       = 1,
                    },
                    distances = {
                        ['stone']       = 15,
                    },
                },
                { -- crude oil
                    yield=1.7,
                    min_distance=57,
                    distance_richness=7,
                    color={r=0/255, g=255/255, b=255/255},
                    noise_settings = {
                        type = "cluster",
                        threshold = 0.40,
                        sources = {
                            {variance=25, weight = 1, offset = 000, type="perlin"},
                        },
                    },
                    weights = {
                        ['skip']        = 997,
                        ['crude-oil']   =   3,
                    },
                    distances = {
                        ['crude-oil']   = 57,
                    },
                },
                --]]
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

            -- add or remove a table entry to add or remove a unlockable item from the mall.
            -- format: {unlock_at_level, price, prototype_name},
            unlockables = require('map_gen.Diggy.FormatMarketItems').initalize_unlockables(
                {
                    {level = 1, price = 50, name = 'raw-fish'},
                    {level = 1, price = 50, name = 'steel-axe'},
                    {level = 1, price = 20, name = 'raw-wood'},
                    {level = 2, price = 50, name = 'small-lamp'},
                    {level = 2, price = 25, name = 'stone-brick'},
                    {level = 2, price = 125, name = 'stone-wall'},
                    {level = 3, price = 850, name = 'submachine-gun'},
                    {level = 3, price = 850, name = 'shotgun'},
                    {level = 3, price = 50, name = 'firearm-magazine'},
                    {level = 3, price = 50, name = 'shotgun-shell'},
                    {level = 3, price = 500, name = 'light-armor'},
                    {level = 11, price = 750, name = 'heavy-armor'},
                    {level = 13, price = 100, name = 'piercing-rounds-magazine'},
                    {level = 13, price = 100, name = 'piercing-shotgun-shell'},
                    {level = 13, price = 1500, name = 'modular-armor'},
                    {level = 16, price = 1000, name = 'landfill'},
                    {level = 30, price = 250, name = 'uranium-rounds-magazine'},
                    {level = 30, price = 1000, name = 'combat-shotgun'},
                }
            ),

            buffs = { --Define new buffs here
                {prototype = {name = 'mining_speed', value = 5}},
                {prototype = {name = 'inventory_slot', value = 1}},
                {prototype = {name = 'stone_automation', value = 3}},
            },

            -- controls the formula for calculating level up costs in stone sent to surface
            difficulity_scale = 25, -- Diggy default 25. Higher increases difficulity, lower decreases (Only affects the stone requirement/cost to level up) (Only integers has been tested succesful)
            start_stone = 50, -- Diggy default 50. This sets the price for the first level.
            cost_precision = 2, -- Diggy default 2. This sets the precision of the stone requirements to level up. E.g. 1234 becomes 1200 with precision 2 and 1230 with precision 3.
        },
    },
}

return Config