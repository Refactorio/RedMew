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

            -- creates clusters of ore with higher yields and frequency instead of evenly scattered ore
            -- lowers max resource max_resource_probability to 50% of the original value
            cluster_mode = true,

            -- value between 0 and 1, higher value means stronger variance between coordinates
            noise_variance = 0.04,

            -- a value between 0 and 1 that triggers the spawning of resource based on noise
            noise_resource_threshold = 0.40,

            -- raw multiplier for ore content in cluster mode
            cluster_yield_multiplier = 1.7,

            -- shows where resources are located
            display_resource_fields = false,

            -- percentage of resource added to the sum. 100 tiles means
            -- 10% more resources with a distance_richness_modifier of 10
            -- 20% more resources with a distance_richness_modifier of 5
            distance_richness_modifier = 7,

            -- defines the increased chance of spawning resources
            -- calculated_probability = resource_probability + ((distance / distance_probability_modifier) / 100)
            distance_probability_modifier = 10,

            -- increases the amount of liquids that need pumping
            liquid_value_modifiers = {
                ['crude-oil'] = 750,
            },

            -- min percentage of chance that resources will spawn after mining
            resource_probability = 0.01,

            -- max chance of spawning resources based on resource_probability + calculated distance_probability_modifier
            max_resource_probability = 0.30,
			
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
