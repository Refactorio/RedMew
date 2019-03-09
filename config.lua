_DEBUG = false
_CHEATS = false
_DUMP_ENV = false
local currency = 'coin'

global.config = {
    -- adds a GUI listing the scenario features, the rules, and the details of the current map
    map_info = {
        enabled = true,
        -- The title of the map
        map_name_key = 'This Map has no name',
        -- The long description of the map, typically 1 paragraph
        map_description_key = "This section is supposed to be filled out on a per map basis.\nIf you're seeing this message, ping the admin team to get a description\nadded for this map. 20 coins is rewarded to the first person that points this out.",
        -- The feature list of the map
        map_extra_info_key = 'This map has no extra information',
        -- New Scenario Features, appears in the "What's new" tab
        new_info_key = 'Nothing is new. The world is at peace'
    },
    -- map generation settings for redmew's maps (only applies to maps that use 'shapes')
    map_generation = {
        -- whether to regen decoratives
        ['regen_decoratives'] = false,
        -- the number of 'tiles' that are calculated per tick
        ['tiles_per_tick'] = 32,
        -- the entity modules to load (takes a list of requires), example included
        ['entity_modules'] = {
            --function() return require('map_gen.entities.fluffy_rainbows') end
        },
        -- the terrain modules to load (takes a list of requires), example included
        ['terrain_modules'] = {
            --function() return require('map_gen.terrain.tris_chunk_grid') end
        },
    },
    -- redmew_surface allows a map preset to control world generation as well as map and difficulty settings
    -- the entire module can be toggled or just individual parts
    redmew_surface = {
        enabled = true,
        map_gen_settings = true,
        map_settings = true,
        difficulty = true
    },
    -- time before a player gets the auto-trusted rank, allowing them access to the deconstructions planner, nukes, etc.
    rank_system = {
        time_for_trust = 3 * 60 * 60 * 60, -- 3 hours
        everyone_is_regular = false
    },
    -- saves players' lives if they have a small-plane in their inventory, also adds the small-plane to the market and must therefor be loaded first
    train_saviour = {
        enabled = true
    },
    -- Adds the infinite storage chest to the market and adds a custom GUI to it. Also has to be loaded first due to adding a market item
    infinite_storage_chest = {
        enabled = false,
        cost = 100
    },
    -- adds a command to scale UPS and movement speed. Use with caution as it might break scenarios that modify movement speed
    performance = {
        enabled = true
    },
    -- adds a player list icon and keeps track of data.
    player_list = {
        enabled = true,
        show_coin_column = true
    },
    -- enables the poll system
    poll = {
        enabled = true
    },
    -- enables players to create and join tags
    tag_group = {
        enabled = true
    },
    -- enables players to create and prioritize tasks
    tasklist = {
        enabled = true
    },
    -- enables the blueprint helper
    blueprint_helper = {
        enabled = true
    },
    -- enables score and tracking thereof
    score = {
        enabled = true
    },
    -- adds a paint brush
    paint = {
        enabled = true
    },
    -- adds a market
    market = {
        enabled = true,
        -- will create a standard market on game startup
        create_standard_market = true,
        -- the coordinates at which the standard market will be created
        standard_market_location = {x = 0, y = -5},
        currency = currency,
        -- defines the chance that killing an entity will drop coins and the min and max it can drop upon death
        entity_drop_amount = {
            ['biter-spawner'] = {low = 5, high = 15, chance = 1},
            ['spitter-spawner'] = {low = 5, high = 15, chance = 1},
            ['small-worm-turret'] = {low = 2, high = 8, chance = 1},
            ['medium-worm-turret'] = {low = 5, high = 15, chance = 1},
            ['big-worm-turret'] = {low = 10, high = 20, chance = 1},
            -- default is 0, no chance of coins dropping from biters/spitters
            ['small-biter'] = {low = 1, high = 5, chance = 0},
            ['small-spitter'] = {low = 1, high = 2, chance = 0},
            ['medium-spitter'] = {low = 1, high = 3, chance = 0},
            ['big-spitter'] = {low = 1, high = 3, chance = 0},
            ['behemoth-spitter'] = {low = 1, high = 10, chance = 0},
            ['medium-biter'] = {low = 1, high = 3, chance = 0},
            ['big-biter'] = {low = 1, high = 5, chance = 0},
            ['behemoth-biter'] = {low = 1, high = 10, chance = 0}
        }
    },
    -- adds anti-nuke griefing
    nuke_control = {
        enabled = true,
        enable_autokick = true,
        enable_autoban = true,
        -- how long a player must be on the server to be allowed to use the nuke
        nuke_min_time_hours = 3
    },
    -- adds a meltdown feature, requiring precise management
    reactor_meltdown = {
        enabled = true,
        -- when enabled, controls whether it's on by default. State can be controlled with the /meltdown command.
        on_by_default = false
    },
    -- adds hodor responses to messages
    hodor = {
        enabled = true
    },
    -- enable RedMew auto respond messages
    auto_respond = {
        enabled = true
    },
    -- enable the mentioning system, which notifies a player when their name is mentioned
    mentions = {
        enabled = true
    },
    -- settings for when a player joins the server for the first time
    player_create = {
        enabled = true,
        -- items automatically inserted into the player inventory
        starting_items = {
            {name = 'iron-gear-wheel', count = 8},
            {name = 'iron-plate', count = 16}
        },
        -- opens the scenario popup when the player joins
        show_info_at_start = true,
        -- prints messages when the player joins
        join_messages = {
            'Welcome to this map created by the RedMew team. You can join our discord at: redmew.com/discord',
            'Click the question mark in the top left corner for server information and map details.'
        },
        -- format is a table: {{message, weight}, {message, weight}}, where a higher weight has more chance to be shown
        random_join_message_set = require 'resources.join_messages',
        -- applied when cheat_mode is set to true
        cheats = {
            -- Sets the manual mining speed for the player force. A value of 1 = 100% faster. Setting it
            -- to 0.5 would make it 50% faster than the base speed.
            manual_mining_speed_modifier = 1000,
            -- increase the amount of inventory slots for the player force
            character_inventory_slots_bonus = 0,
            -- increases the run speed of all characters for the player force
            character_running_speed_modifier = 5,
            -- a flat health bonus to the player force
            character_health_bonus = 1000000,
            -- starts with a fully slotted power armor mk2
            start_with_power_armor = true,
            -- adds additional items to the player when _CHEATS is true
            starting_items = {
                {name = 'submachine-gun', count = 1},
                {name = 'uranium-rounds-magazine', count = 200},
                {name = 'construction-robot', count = 250},
                {name = 'electric-energy-interface', count = 50},
                {name = 'substation', count = 50},
                {name = 'roboport', count = 10},
                {name = 'infinity-chest', count = 10},
                {name = 'small-plane', count = 2},
                {name = 'coin', count = 20000},
                {name = 'rocket-part', count = 2},
                {name = 'computer', count = 2},
                {name = 'infinity-pipe', count = 10},
                {name = 'heat-interface', count = 10},
                {name = 'compilatron-chest', count = 5},
                {name = 'compilatron-chest', count = 5},
                {name = 'escape-pod-assembler', count = 5},
                {name = 'escape-pod-lab', count = 10},
                {name = 'escape-pod-power', count = 5},
                {name = 'pollution', count = 5},
                {name = 'selection-tool', count = 1}
            }
        }
    },
    -- spawns more units when one dies
    hail_hydra = {
        enabled = false,
        -- enables difficulty scaling with number of online players
        -- if enabled you can disable it for individual spawns by setting {locked = true}
        online_player_scale_enabled = true,
        -- the number of players required for regular values.
        -- less online players than this number decreases the spawn chances
        -- more online players than this number increases the spawn chances
        -- the spawn chance is increased or decreased with 0.01 * (#connected_players - online_player_scale)
        online_player_scale = 20,
        -- any non-rounded number will turn into a chance to spawn an additional alien
        -- example: 2.5 would spawn 2 for sure and 50% chance to spawn one additionally
        -- min defines the lowest chance, max defines the max chance at evolution 1.
        -- trigger defines when the chance is active
        -- setting max to less than min or nil will ignore set the max = min
        -- Hail Hydra scales between min and max with a custom formula.
        -- Key values shown in evolution = (percentage of max):
        -- | 0.25 evolution = 10% | 0.50 evolution = 29% | 0.60 evolution = 45% | 0.75 evolution = 58% |
        -- | 0.80 evolution = 65% | 0.90 evolution = 81% | 1.00 evolution = 100% |
        -- eg. {min = 0.2, max = 2, trigger = 0.3} means that after evolution 0.3 this hydra spawns with a chance of at least 0.2
        -- and at evolution = 1.00 it spawns with a chance of 2.
        -- At evolution 0.60 it would spawn with a chance of min + max * (percentage of max) = 1.1
        -- Example of all available options (only min is required):
        -- ['behemoth-biter'] = {min = 0.1, max = 0.5, trigger = 0.90, locked = true}}
        hydras = {
            -- spitters
            ['small-spitter'] = {['small-worm-turret'] = {min = 0.2, max = 1}},
            ['medium-spitter'] = {['medium-worm-turret'] = {min = 0.2, max = 1}},
            ['big-spitter'] = {['big-worm-turret'] = {min = 0.2, max = 1}},
            ['behemoth-spitter'] = {['behemoth-worm-turret'] = {min = 0.2, max = 1}},
            -- biters
            ['medium-biter'] = {['small-biter'] = {min = 1, max = 2}},
            ['big-biter'] = {['medium-biter'] = {min = 1, max = 2}},
            ['behemoth-biter'] = {['big-biter'] = {min = 1, max = 2}},
            -- worms
            ['small-worm-turret'] = {['small-biter'] = {min = 1.5, max = 2.5}},
            ['medium-worm-turret'] = {['small-biter'] = {min = 2.5, max = 3.5}, ['medium-biter'] = {min = 1.0, max = 2}},
            ['big-worm-turret'] = {
                ['small-biter'] = {min = 2.5, max = 4},
                ['medium-biter'] = {min = 1.5, max = 2.2},
                ['big-biter'] = {min = 0.7, max = 1.5}
            },
            ['behemoth-worm-turret'] = {
                ['small-biter'] = {min = 4, max = 5.2},
                ['medium-biter'] = {min = 2.5, max = 3.8},
                ['big-biter'] = {min = 1.2, max = 2.4},
                ['behemoth-biter'] = {min = 0.8, max = -1}
            }
        }
    },
    -- grants reward coins for certain actions
    player_rewards = {
        enabled = true,
        -- the token to use for rewards
        token = currency,
        -- rewards players for looking through the info tabs
        info_player_reward = true
    },
    -- makes manual stuff cumbersome
    lazy_bastard = {
        enabled = false
    },
    -- automatically marks miners for deconstruction when they are depleted (currently compatible with hard mods that add miners)
    autodeconstruct = {
        enabled = true
    },
    -- when a player dies, leaves a map marker until the corpse expires or is looted
    corpse_util = {
        enabled = true
    },
    -- adds many commands for users and admins alike
    redmew_commands = {
        enabled = true
    },
    -- adds many commands for admins
    admin_commands = {
        enabled = true
    },
    -- adds commands for donators
    donator_commands = {
        enabled = true
    },
    player_colors = {
        enabled = true
    },
    -- adds a command to generate a popup dialog box for players to see, useful for important announcements
    popup = {
        enabled = true
    },
    -- adds a command to open a gui that creates rich text
    rich_text_gui = {
        enabled = true
    },
    -- adds a camera to watch another player
    camera = {
        enabled = true
    },
    -- adds small quality of life tweaks for multiplayer play
    redmew_qol = {
        enabled = true,
        -- restricts placed chests to 1 square of inventory
        restrict_chest = false,
        -- gives entities with backer names a chance to be named after a player or redmew regular
        backer_name = true,
        -- gives locos placed a random color
        random_train_color = true,
        -- gives players entity ghosts (from destruction like biter attacks) before the required research is complete
        ghosts_before_research = true,
        -- adds craftable loaders.
        loaders = true,
        -- turns on entity info aka alt-mode on first joining
        set_alt_on_create = true,
        -- prevents personal construction robots from being mined by other players
        save_bots = true,
        -- enable research_queue
        research_queue = true
    },
    -- adds a useless button with the biter percentage
    evolution_progress = {
        enabled = true
    },
    -- sets the day/night cycle or a fixed light level. use_day_night_cycle and use_fixed_brightness are mutually exclusive
    day_night = {
        -- enables/disables the module
        enabled = false,
        -- for info on day/night cycles see https://github.com/Refactorio/RedMew/wiki/Day-Night-cycle
        use_day_night_cycle = false,
        day_night_cycle = {
            ticks_per_day = 25000,
            dusk = 0.25,
            evening = 0.45,
            morning = 0.55,
            dawn = 0.75
        },
        -- brightness is a number between 0.15 and 1
        use_fixed_brightness = false,
        fixed_brightness = 0.5
    },
    -- enables a command which allows for an end-game event
    apocalypse = {
        enabled = true
    },
    -- gradually informs players of features such as chat, toasts, etc.
    player_onboarding = {
        enabled = true
    }
}

return global.config
