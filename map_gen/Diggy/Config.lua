-- dependencies
local abs = math.abs

-- this
local Config = {
    -- a list of features to register and enable
    -- to disable a feature, change the flag
    features = {
        -- creates a starting zone
        StartingZone = {
            enabled = true,

            -- initial starting position size, higher values are not recommended
            starting_size = 8,

            -- where the market should spawn
            market_spawn_position = {x = 0, y = 3},
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

                -- unlock all research by default, only useful when testing
                unlock_all_research = true,

                -- adds additional items to the player force when starting in addition to defined in start_items above
                starting_items = {
                    {name = 'power-armor-mk2', count = 1},
                    {name = 'submachine-gun', count = 1},
                    {name = 'uranium-rounds-magazine', count = 1000},
                    {name = 'roboport', count = 2},
                    {name = 'construction-robot', count = 50},
                    {name = 'electric-energy-interface', count = 1},
                    {name = 'medium-electric-pole', count = 50},
                    {name = 'logistic-chest-storage', count = 50},
                },
            },
        },

        -- core feature
        DiggyHole = {
            enabled = true,

            -- displays a warning when a player continues digging with a full inventory
            -- primarily used for multiplayer, can be disabled without consequences
            enable_digging_warning = true,

            -- enables commands like /clear-void
            enable_debug_commands = false,

            -- initial damage per tick it damages a rock to mine, can be enhanced by robot_damage_per_mining_prod_level
            robot_initial_mining_damage = 4,

            -- damage added per level of mining productivity level research
            robot_damage_per_mining_prod_level = 1,
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
                ['rock-big'] = 2,
                ['rock-huge'] = 2.5,
                ['out-of-map'] = 1,
                ['stone-path'] = 0.03,
                ['concrete'] = 0.04,
                ['hazard-concrete'] = 0.04,
                ['refined-concrete'] = 0.06,
            },
            cracking_sounds = {
                ' R U NY O UF O O L S !',
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
            mining_coin_chance = 0.10,
            mining_coin_amount = {min = 1, max = 4},

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
            alien_coin_drop_chance = 0.30,

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

            -- location of file to find the cluster definition file
            ore_pattern = require 'map_gen.Diggy.Orepattern.Tendrils',
            --ore_pattern = require 'map_gen.Diggy.Orepattern.Clusters',

        },

        -- controls the alien spawning mechanic
        AlienSpawner = {
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
        Antigrief = {
            enabled = true,
            autojail = true,
            allowed_collapses_first_hour = 4
        },

        Experience = {
            enabled = true,
            -- controls the formula for calculating level up costs in stone sent to surface
            difficulty_scale = 16, -- Diggy default 16. Higher increases experience requirement climb
            first_lvl_xp = 400, -- Diggy default 400. This sets the price for the first level.
            xp_fine_tune = 200, -- Diggy default 200. This value is used to fine tune the overall requirement climb without affecting the speed
            cost_precision = 3, -- Diggy default 3. This sets the precision of the required experience to level up. E.g. 1234 becomes 1200 with precision 2 and 1230 with precision 3.

            -- percentage * mining productivity level gets added to mining speed
            mining_speed_productivity_multiplier = 5,

            XP = {
                ['sand-rock-big']             = 5,
                ['rock-big']                  = 5,
                ['rock-huge']                 = 10,
                ['rocket_launch']             = 0.01,     -- XP reward in percentage of total experience when a rocket launches (Diggy default: 0.01 which equals 1%)
                ['science-pack-1']            = 4,
                ['science-pack-2']            = 8,
                ['science-pack-3']            = 15,
                ['military-science-pack']     = 12,
                ['production-science-pack']   = 25,
                ['high-tech-science-pack']    = 50,
                ['space-science-pack']        = 10,
                ['enemy_killed']              = 10,       -- Base XP for killing biters and spitters.
                ['death-penalty']             = 0.002,    -- XP deduct in percentage of total experience when a player dies (Diggy default: 0.002 which equals 0.2%)
                ['cave-in-penalty']           = 100       -- XP lost every cave in.
            },

            buffs = {
                -- define new buffs here, they are handed out for each level
                mining_speed = {value = 5},
                inventory_slot = {value = 1},
                -- double_level is the level interval for receiving a double bonus (Diggy default: 5 which equals every 5th level)
                health_bonus = {value = 2.5, double_level = 5},
            },

            -- add or remove a table entry to add or remove a unlockable item from the market.
            unlockables = {
                {level = 1, price = 5, name = 'iron-axe'},
                {level = 2, price = 4, name = 'raw-wood'},
                {level = 4, price = 20, name = 'pistol'},
                {level = 4, price = 5, name = 'firearm-magazine'},
                {level = 5, price = 2, name = 'stone-brick'},
                {level = 6, price = 6, name = 'small-lamp'},
                {level = 6, price = 5, name = 'raw-fish'},
                {level = 8, price = 10, name = 'stone-wall'},
                {level = 10, price = 85, name = 'shotgun'},
                {level = 10, price = 4, name = 'shotgun-shell'},
                {level = 13, price = 25, name = 'steel-axe'},
                {level = 13, price = 50, name = 'light-armor'},
                {level = 15, price = 85, name = 'submachine-gun'},
                {level = 18, price = 10, name = 'piercing-rounds-magazine'},
                {level = 18, price = 8, name = 'piercing-shotgun-shell'},
                {level = 20, price = 50, name = 'landfill'},
                {level = 25, price = 100, name = 'heavy-armor'},
                {level = 30, price = 250, name = 'modular-armor'},
                {level = 32, price = 150, name = 'personal-roboport-equipment'},
                {level = 32, price = 20, name = 'construction-robot'},
                {level = 37, price = 750, name = 'power-armor'},
                {level = 38, price = 100, name = 'battery-equipment'},
                {level = 39, price = 750, name = 'fusion-reactor-equipment'},
                {level = 40, price = 150, name = 'energy-shield-equipment'},
                {level = 47, price = 550, name = 'combat-shotgun'},
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
