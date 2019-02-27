-- dependencies
local abs = math.abs

-- this
local Config = {
    -- a list of features to register and enable
    -- to disable a feature, change the flag
    features = {
        -- creates a starting zone
        starting_zone = {
            enabled = true,

            -- initial starting position size, higher values are not recommended
            starting_size = 8,

            -- where the market should spawn
            market_spawn_position = {x = 0, y = 3},
        },

        -- controls the Daylight (Default diggy: enabled = true)
        night_time = {
            enabled = true, -- true = No Daylight, false = Day/night circle (Solar panels work)
        },

        -- controls setting up the players
        setup_player = {
            enabled = true,
            starting_items = {
                {name = 'stone-wall', count = 12},
                {name = 'iron-gear-wheel', count = 8},
                {name = 'iron-plate', count = 16},
            },

            -- applied when cheat_mode is set to true. It's recommended to tweak this to your needs
            -- when playing with cheats on (recommended for single player or LAN with limited players)
            cheats = {
                -- Sets the manual mining speed for the player force. A value of 1 = 100% faster. Setting it
                -- to 0.5 would make it 50% faster than the base speed.
                manual_mining_speed_modifier = 1000,

                -- increase the amount of inventory slots for the player force
                character_inventory_slots_bonus = 0,

                -- increases the run speed of all characters for the player force
                character_running_speed_modifier = 2,

                -- a flat health bonus to the player force
                character_health_bonus = 1000000,

                -- adds additional items to the player force when starting in addition to defined in start_items above
                starting_items = {
                },
            },
        },

        -- core feature
        diggy_hole = {
            enabled = true,

            -- initial damage per tick it damages a rock to mine, can be enhanced by robot_damage_per_mining_prod_level
            robot_initial_mining_damage = 4,

            -- damage added per level of mining productivity level research
            robot_damage_per_mining_prod_level = 1,
        },

        -- adds the ability to collapse caves
        diggy_cave_collapse = {
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
                ['market'] = 9,
                ['stone-wall'] = 3,
                ['sand-rock-big'] = 2,
                ['rock-big'] = 2,
                ['rock-huge'] = 2.5,
                ['out-of-map'] = 1,
                ['stone-path'] = 0.03,
                ['concrete'] = 0.04,
                ['hazard-concrete'] = 0.04,
                ['refined-concrete'] = 0.06,
                ['refined-hazard-concrete'] = 0.06,
            },
            cracking_sounds = {
                'R U N,  Y O U   F O O L S !',
            }
        },

        -- Adds the ability to drop coins and track how many are sent into space
        coin_gathering = {
            enabled = true,

            -- value between 0 and 1, higher value means stronger variance between coordinates
            noise_variance = 0.75,

            -- minimum noise value to spawn a treasure chest, works best with a very high noise variance,
            -- otherwise you risk spawning a lot of chests together
            treasure_chest_noise_threshold = 0.69,

            -- minimum distance from spawn where a chest can spawn
            minimal_treasure_chest_distance = 25,

            -- chances to receive a coin when mining
            mining_coin_chance = 0.15,
            mining_coin_amount = {min = 1, max = 5},

            -- lets you set the coin modifiers for aliens
            -- the modifier value increases the upper random limit that biters can drop
            alien_coin_modifiers = {
                ['small-biter'] = 2,
                ['small-spitter'] = 2,
                ['small-worm-turret'] = 2,
                ['medium-biter'] = 3,
                ['medium-spitter'] = 3,
                ['medium-worm-turret'] = 3,
                ['big-biter'] = 5,
                ['big-spitter'] = 5,
                ['big-worm-turret'] = 5,
                ['behemoth-biter'] = 7,
                ['behemoth-spitter'] = 7,
            },

            -- chance of aliens dropping coins between 0 and 1, where 1 is 100%
            alien_coin_drop_chance = 0.28,

            -- shows the chest locations, only use when debugging
            display_chest_locations = false,

            treasure_chest_raffle = {
                ['coin'] = {chance = 1.00, min = 20, max = 255},
                ['stone'] = {chance = 0.20, min = 15, max = 40},
                ['copper-ore'] = {chance = 0.25, min = 30, max = 60},
                ['copper-plate'] = {chance = 0.10, min = 12, max = 25},
                ['iron-ore'] = {chance = 0.20, min = 10, max = 55},
                ['iron-plate'] = {chance = 0.10, min = 5, max = 25},
                ['steel-plate'] = {chance = 0.05, min = 3, max = 14},
                ['steel-furnace'] = {chance = 0.03, min = 1, max = 2},
                ['steam-engine'] = {chance = 0.03, min = 1, max = 2},
                ['coal'] = {chance = 0.30, min = 30, max = 55},
                ['concrete'] = {chance = 0.14, min = 10, max = 50},
                ['stone-brick'] = {chance = 0.14, min = 25, max = 75},
                ['stone-wall'] = {chance = 0.50, min = 1, max = 5},
                ['transport-belt'] = {chance = 0.10, min = 1, max = 5},
                ['fast-transport-belt'] = {chance = 0.07, min = 2, max = 7},
                ['express-transport-belt'] = {chance = 0.04, min = 4, max = 9},
                ['rail'] = {chance = 0.20, min = 7, max = 15},
                ['rail-signal'] = {chance = 0.05, min = 3, max = 8},
                ['rail-chain-signal'] = {chance = 0.05, min = 3, max = 8},
                ['firearm-magazine'] = {chance = 0.25, min = 35, max = 120},
                ['piercing-rounds-magazine'] = {chance = 0.10, min = 15, max = 35},
                ['gun-turret'] = {chance = 0.3, min = 1, max = 2},
                ['beacon'] = {chance = 0.01, min = 1, max = 2},
                ['effectivity-module'] = {chance = 0.03, min = 1, max = 2},
                ['effectivity-module-2'] = {chance = 0.01, min = 1, max = 2},
                ['productivity-module'] = {chance = 0.03, min = 1, max = 2},
                ['productivity-module-2'] = {chance = 0.01, min = 1, max = 2},
                ['speed-module'] = {chance = 0.03, min = 1, max = 2},
                ['speed-module-2'] = {chance = 0.01, min = 1, max = 2},
                ['small-lamp'] = {chance = 0.05, min = 1, max = 5},
            }
        },

        -- replaces the chunks with void
        refresh_map = {
            enabled = true,
        },

        -- automatically opens areas
        simple_room_generator = {
            enabled = true,

            -- value between 0 and 1, higher value means stronger variance between coordinates
            noise_variance = 0.066,

            -- shows where rooms are located
            display_room_locations = false,

            -- minimum distance and noise range required for water to spawn
            room_noise_minimum_distance = 9,
            room_noise_ranges = {
                {name = 'water', min = 0.84, max = 0.96},
                {name = 'water', min = 0.73, max = 0.81},
                {name = 'water', min = 0.54, max = 0.7},
                {name = 'dirt', min = 0.46, max = 0.53},
                {name = 'dirt', min = 0.37, max = 0.45},
            },
        },

        -- responsible for resource spawning
        scattered_resources = {
            enabled = true,

            -- determines how distance is measured
            distance = function (x, y) return abs(x) + abs(y) end,
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

            -- spawns tendrils of ore with roughly 80% purity
            ore_pattern = require 'map_gen.maps.diggy.orepattern.tendrils_impure',

            -- spawns some smaller dedicated and bigger mixed tendrils
            --ore_pattern = require 'map_gen.maps.diggy.orepattern.tendrils',

            -- spawns clusters of ore similar to vanilla, but mixed
            --ore_pattern = require 'map_gen.maps.diggy.orepattern.clusters',

        },

        -- controls the alien spawning mechanic
        alien_spawner = {
            enabled = true,

            -- minimum distance from spawn before aliens can spawn
            alien_minimum_distance = 40,

            -- chance of spawning aliens when mining
            alien_probability = 0.05,

            -- spawns the following units when they die. To disable, remove the contents
            -- any non-rounded number will turn into a chance to spawn an additional alien
            -- example: 2.5 would spawn 2 for sure and 50% chance to spawn one additionally
            hail_hydra = {
                -- spitters
                ['small-spitter'] = {['small-worm-turret'] = 0.2},
                ['medium-spitter'] = {['medium-worm-turret'] = 0.2},
                ['big-spitter'] = {['big-worm-turret'] = 0.2},
                ['behemoth-spitter'] = {['big-worm-turret'] = 0.4},

                -- biters
                ['medium-biter'] = {['small-biter'] = 1.2},
                ['big-biter'] = {['medium-biter'] = 1.2},
                ['behemoth-biter'] = {['big-biter'] = 1.2},

                -- worms
                ['small-worm-turret'] = {['small-biter'] = 2.5},
                ['medium-worm-turret'] = {['small-biter'] = 2.5, ['medium-biter'] = 0.6},
                ['big-worm-turret'] = {['small-biter'] = 3.8, ['medium-biter'] = 1.3, ['big-biter'] = 1.1},
            },
        },

        --Tracks players causing collapses
        antigrief = {
            enabled = true,
            autojail = true,
            allowed_collapses_first_hour = 4,
        },

        experience = {
            enabled = true,
            -- controls the formula for calculating level up costs in stone sent to surface
            difficulty_scale = 20, -- Diggy default 15. Higher increases experience requirement climb
            first_lvl_xp = 350, -- Diggy default 350. This sets the price for the first level.
            xp_fine_tune = 400, -- Diggy default 200. This value is used to fine tune the overall requirement climb without affecting the speed
            cost_precision = 3, -- Diggy default 3. This sets the precision of the required experience to level up. E.g. 1234 becomes 1200 with precision 2 and 1230 with precision 3.

            -- percentage * mining productivity level gets added to mining speed
            mining_speed_productivity_multiplier = 5,

            XP = {
                ['sand-rock-big']             = 5,
                ['rock-big']                  = 5,
                ['rock-huge']                 = 10,
                ['rocket_launch']             = 0.01,      -- XP reward in percentage of total experience when a rocket launches (Diggy default: 0.01 which equals 1%)
                ['automation-science-pack']            = 4,
                ['logistic-science-pack']            = 8,
                ['chemical-science-pack']            = 15,
                ['military-science-pack']     = 12,
                ['production-science-pack']   = 25,
                ['utility-science-pack']    = 50,
                ['space-science-pack']        = 10,
                ['enemy_killed']              = 10,        -- Base XP for killing biters and spitters.
                ['death-penalty']             = 0.0035,    -- XP deduct in percentage of total experience when a player dies (Diggy default: 0.0035 which equals 0.35%)
                --['cave-in-penalty']         = 100        -- XP lost every cave in.
                ['infinity-research']         = 0.60       -- XP reward in percentage of the required experience from current level to next level (Diggy default: 0.60 which equals 60%)
            },

            buffs = {
                -- define new buffs here, they are handed out for each level
                mining_speed = {value = 5, max = 100},
                inventory_slot = {value = 1, max = 100},
                -- double_level is the level interval for receiving a double bonus (Diggy default: 5 which equals every 5th level)
                health_bonus = {value = 2.5, double_level = 5, max = 500},
            },

            -- add or remove a table entry to add or remove a unlockable item from the market.
            unlockables = {
                {level = 2, price = 4, name = 'wood'},
                {level = 3, price = 5, name = 'stone-wall'},
                {level = 4, price = 20, name = 'pistol'},
                {level = 4, price = 5, name = 'firearm-magazine'},
                {level = 5, price = 100, name = 'light-armor'},
                {level = 6, price = 6, name = 'small-lamp'},
                {level = 6, price = 5, name = 'raw-fish'},
                {level = 8, price = 1, name = 'stone-brick'},
                {level = 10, price = 85, name = 'shotgun'},
                {level = 10, price = 4, name = 'shotgun-shell'},
                {level = 12, price = 200, name = 'heavy-armor'},
                {level = 14, price = 35, name = 'landfill'},
                {level = 15, price = 85, name = 'submachine-gun'},
                {level = 18, price = 10, name = 'piercing-rounds-magazine'},
                {level = 18, price = 8, name = 'piercing-shotgun-shell'},
                {level = 19, price = 2, name = 'rail'},
                {level = 20, price = 50, name = 'locomotive'},
                {level = 20, price = 350, name = 'modular-armor'},
                {level = 21, price = 5, name = 'rail-signal'},
                {level = 22, price = 5, name = 'rail-chain-signal'},
                {level = 23, price = 15, name = 'train-stop'},
                {level = 24, price = 35, name = 'cargo-wagon'},
                {level = 24, price = 35, name = 'fluid-wagon'},
                {level = 29, price = 750, name = 'power-armor'},
                {level = 30, price = 30, name = 'logistic-robot'},
                {level = 31, price = 200, name = 'personal-roboport-equipment'},
                {level = 32, price = 20, name = 'construction-robot'},
                {level = 34, price = 750, name = 'fusion-reactor-equipment'},
                {level = 35, price = 150, name = 'battery-equipment'},
                {level = 38, price = 250, name = 'exoskeleton-equipment'},
                {level = 40, price = 125, name = 'energy-shield-equipment'},
                {level = 42, price = 500, name = 'personal-laser-defense-equipment'},
                {level = 44, price = 1250, name = 'power-armor-mk2'},
                {level = 46, price = 750, name = 'battery-mk2-equipment'},
                {level = 48, price = 550, name = 'combat-shotgun'},
                {level = 51, price = 25, name = 'uranium-rounds-magazine'},
                {level = 63, price = 250, name = 'rocket-launcher'},
                {level = 63, price = 40, name = 'rocket'},
                {level = 71, price = 80, name = 'explosive-rocket'},
                {level = 78, price = 1000, name = 'satellite'},
                {level = 100, price = 1, name = 'iron-stick'},
            },
            -- modifies the experience per alien type, higher is more xp
            alien_experience_modifiers = {
                ['small-biter'] = 2,
                ['small-spitter'] = 2,
                ['small-worm-turret'] = 2,
                ['medium-biter'] = 3,
                ['medium-spitter'] = 3,
                ['medium-worm-turret'] = 3,
                ['big-biter'] = 5,
                ['big-spitter'] = 5,
                ['big-worm-turret'] = 5,
                ['behemoth-biter'] = 7,
                ['behemoth-spitter'] = 7,
            },
        },
    },
}

return Config
