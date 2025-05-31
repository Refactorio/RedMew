-- dependencies
local ScenarioInfo = require 'features.gui.info'
local abs = math.abs

local config = {
    scenario_name = 'diggy',
    -- a list of features to register and enable
    -- to disable a feature, change the flag
    features = {
        -- creates a starting zone
        starting_zone = {
            enabled = true,
            load = function() return require('map_gen.maps.diggy.feature.starting_zone') end,
            -- initial starting position size, higher values are not recommended
            starting_size = 8,
            -- where the market should spawn
            market_spawn_position = {x = 0, y = 3}
        },
        -- controls the Daylight (Default diggy: enabled = true)
        night_time = {
            enabled = true, -- true = No Daylight, false = Day/night circle (Solar panels work)
            load = function() return require('map_gen.maps.diggy.feature.night_time') end
        },
        -- controls setting up the players
        setup_player = {
            enabled = true,
            load = function() return require('map_gen.maps.diggy.feature.setup_player') end,
            starting_items = {
                {name = 'stone-wall', count = 12},
                {name = 'iron-gear-wheel', count = 8},
                {name = 'iron-plate', count = 16},
                {name = 'pistol', count = 1},
                {name = 'firearm-magazine', count = 32},
                {name = 'burner-mining-drill', count = 3},
                {name = 'stone-furnace', count = 5},
            },

            -- 0.01 bonus equals 1% in game. This value is recommended to be tweaked for single player
            initial_mining_speed_bonus = 1,

            -- applied when _CHEATS is set to true and _DEBUG is NOT true.
            -- see config.lua -> config.player_create.cheats for available options
            cheats = {
                enabled = true,
                -- Sets the manual mining speed for the player force. A value of 1 = 100% faster. Setting it
                -- to 0.5 would make it 50% faster than the base speed.
                manual_mining_speed_modifier = 1000,
                -- increase the amount of inventory slots for the player force
                character_inventory_slots_bonus = 0,
                -- increases the run speed of all characters for the player force
                character_running_speed_modifier = 2,
                -- a flat health bonus to the player force
                character_health_bonus = 1000000,
                -- starts with a fully slotted power armor mk2
                start_with_power_armor = true,
                -- adds additional items to the player force when starting in addition to defined in start_items above
                starting_items = {}
            }
        },
        -- controls the introduction cutscene
        cutscene = {
            enabled = false,
            load = function() return require('map_gen.maps.diggy.feature.cutscene') end
        },
        -- core feature
        diggy_hole = {
            enabled = true,
            load = function() return require('map_gen.maps.diggy.feature.diggy_hole') end,
            -- delay in ticks between robot mining rock and rock being marked again for deconstruction
            robot_mining_delay = 6,
            -- This value is multiplied with robot_mining_delay to determine mining damage applied.  Can be enhanced by robot_damage_per_mining_prod_level
            robot_per_tick_damage = 4,
            -- damage added per level of mining productivity level research
            robot_damage_per_mining_prod_level = 1,

            -- turn this setting on if you want to bring back landfill research, default is off due to griefing
            allow_landfill_research = true,
        },
        -- adds the ability to collapse caves
        diggy_cave_collapse = {
            enabled = true,
            load = function() return require('map_gen.maps.diggy.feature.diggy_cave_collapse') end,
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
                ['nuclear-reactor'] = 4,
                ['stone-wall'] = 3,
                ['big-rock'] = 2,
                ['huge-rock'] = 2.5,
                ['out-of-map'] = 1,
                ['stone-path'] = 0.03,
                ['concrete'] = 0.04,
                ['hazard-concrete'] = 0.04,
                ['refined-concrete'] = 0.06,
                ['refined-hazard-concrete'] = 0.06
            },
            cracking_sounds = {
                {'diggy.cracking_sound_1'},
                {'diggy.cracking_sound_2'}
            }
        },
        -- Adds the ability to drop coins and track how many are sent into space
        coin_gathering = {
            enabled = true,
            load = function() return require('map_gen.maps.diggy.feature.coin_gathering') end,
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
                ['behemoth-spitter'] = 7
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
                ['efficiency-module'] = {chance = 0.03, min = 1, max = 2},
                ['efficiency-module-2'] = {chance = 0.01, min = 1, max = 2},
                ['productivity-module'] = {chance = 0.03, min = 1, max = 2},
                ['productivity-module-2'] = {chance = 0.01, min = 1, max = 2},
                ['speed-module'] = {chance = 0.03, min = 1, max = 2},
                ['speed-module-2'] = {chance = 0.01, min = 1, max = 2},
                ['small-lamp'] = {chance = 0.05, min = 1, max = 5}
            }
        },
        -- replaces the chunks with void
        refresh_map = {
            enabled = true,
            load = function() return require('map_gen.maps.diggy.feature.refresh_map') end
        },
        -- automatically opens areas
        simple_room_generator = {
            enabled = true,
            load = function() return require('map_gen.maps.diggy.feature.simple_room_generator') end,
            -- value between 0 and 1, higher value means stronger variance between coordinates
            noise_variance = 0.066,
            -- shows where rooms are located
            display_room_locations = false,
            -- minimum distance and noise range required for water to spawn
            room_noise_minimum_distance = 9,
            room_noise_ranges = {
                {name = 'water', min = 0.54, max = 1},
                {name = 'dirt', min = 0.37, max = 0.54}
            }
        },
        -- responsible for resource spawning
        scattered_resources = {
            enabled = true,
            load = function() return require('map_gen.maps.diggy.feature.scattered_resources') end,
            -- determines how distance is measured
            distance = function(x, y)
                return abs(x) + abs(y)
            end,
            --distance = function (x, y) return math.sqrt(x * x + y * y) end,

            -- defines the weights of which resource_richness_value to spawn
            resource_richness_weights = {
                ['scarce'] = 440,
                ['low'] = 350,
                ['sufficient'] = 164,
                ['good'] = 30,
                ['plenty'] = 10,
                ['jackpot'] = 6
            },
            -- defines the min and max range of ores to spawn
            resource_richness_values = {
                ['scarce'] = {1, 200},
                ['low'] = {201, 400},
                ['sufficient'] = {401, 750},
                ['good'] = {751, 1200},
                ['plenty'] = {1201, 2000},
                ['jackpot'] = {2001, 5000}
            },
            -- increases the amount of resources by flat multiplication to initial amount
            -- highly suggested to use for fluids so their yield is reasonable
            resource_type_scalar = {
                ['crude-oil'] = 1500,
                ['uranium-ore'] = 1.25
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
                ['coal'] = 160,
                ['copper-ore'] = 215,
                ['iron-ore'] = 389,
                ['stone'] = 212,
                ['uranium-ore'] = 21,
                ['crude-oil'] = 3
            },
            -- minimum distance from the spawn point required before it spawns
            scattered_minimum_resource_distance = {
                ['coal'] = 16,
                ['copper-ore'] = 18,
                ['iron-ore'] = 18,
                ['stone'] = 15,
                ['uranium-ore'] = 86,
                ['crude-oil'] = 57
            },
            -- ==============================
            -- Compound cluster mode settings
            -- ==============================

            -- creates compound clusters of ores defined by a layered ore-gen
            cluster_mode = true,
            -- spawns tendrils of ore with roughly 80% purity
            ore_pattern = require 'map_gen.maps.diggy.orepattern.tendrils_impure'

            -- spawns some smaller dedicated and bigger mixed tendrils
            --ore_pattern = require 'map_gen.maps.diggy.orepattern.tendrils',

            -- spawns clusters of ore similar to vanilla, but mixed
            --ore_pattern = require 'map_gen.maps.diggy.orepattern.clusters',
        },
        -- controls the alien spawning mechanic
        alien_spawner = {
            enabled = true,
            load = function() return require('map_gen.maps.diggy.feature.alien_spawner') end,

            -- minimum distance from spawn before aliens can spawn
            alien_minimum_distance = 40,

            -- chance of spawning aliens when mining from 0 to 1
            alien_probability = 0.05,

            -- each tile of void removed increases alien evolution by
            evolution_per_void_removed = 0.0000024,

            -- initial evolution percentage, recommended to set to 0 for non-multiplayer setups
            initial_evolution = 10,

            -- evolution over time value, leave nil to use vanilla settings
            evolution_over_time_factor = 0.000006,

            -- spawns the following units when they die. To disable, remove the contents
            -- any non-rounded number will turn into a chance to spawn an additional alien
            -- example: 2.5 would spawn 2 for sure and 50% chance to spawn one additionally
            hail_hydra = {
                -- spitters
                ['small-spitter'] = {['small-worm-turret'] = {min = 0.1, max = 0.8}},
                ['medium-spitter'] = {['medium-worm-turret'] = {min = 0.1, max = 0.8}},
                ['big-spitter'] = {['big-worm-turret'] = {min = 0.1, max = 0.8}},
                ['behemoth-spitter'] = {['behemoth-worm-turret'] = {min = 0.2, max = 0.8}},
                -- biters
                ['medium-biter'] = {['small-biter'] = {min = 0.6, max = 1.5}},
                ['big-biter'] = {['medium-biter'] = {min = 0.6, max = 1.5}},
                ['behemoth-biter'] = {['big-biter'] = {min = 0.6, max = 2}},
                -- worms
                ['small-worm-turret'] = {['small-biter'] = {min = 1, max = 2.5}},
                ['medium-worm-turret'] = {
                    ['small-biter'] = {min = 1, max = 2.5},
                    ['medium-biter'] = {min = 0.3, max = 1.5}
                },
                ['big-worm-turret'] = {
                    ['small-biter'] = {min = 1, max = 2.5},
                    ['medium-biter'] = {min = 0.7, max = 1.5},
                    ['big-biter'] = {min = 0.7, max = 2}
                },
                ['behemoth-worm-turret'] = {
                    ['small-biter'] = {min = 1.5, max = 3},
                    ['medium-biter'] = {min = 1.2, max = 2},
                    ['big-biter'] = {min = 1, max = 2},
                    ['behemoth-biter'] = {min = 0.7, max = 1.2}
                }
            }
        },
        --Tracks players causing collapses
        antigrief = {
            enabled = true,
            load = function() return require('map_gen.maps.diggy.feature.antigrief') end,
            autojail = true,
            allowed_collapses_first_hour = 4
        },
        weapon_balance = {
            enabled = true,
            load = function() return require('map_gen.maps.diggy.feature.weapon_balance') end
        },
        flaming_pumpjack = {
            enabled = true,
            load = function() return require('map_gen.maps.diggy.feature.flaming_pumpjack') end,
        },
        shelob = {
            enabled = true,
            load = function() return require('map_gen.maps.diggy.feature.shelob') end,
        },
    }
}

ScenarioInfo.set_map_name('Diggy')
ScenarioInfo.set_map_description('Dig your way through!')

local diggy = require 'map_gen.maps.diggy.scenario'
return diggy.register(config)
