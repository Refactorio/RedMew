_DEBUG = false
_CHEATS = false
_DUMP_ENV = false
local currency = 'coin'

storage.config = {
    -- adds a GUI listing the scenario features, the rules, and the details of the current map
    map_info = {
        enabled = true,
        -- The title of the map
        map_name_key = 'This Map has no name',
        -- The long description of the map, typically 1 paragraph
        map_description_key = "This section is supposed to be filled out on a per map basis.\nIf you're seeing this message, ping the admin team to get\na description added for this map (20 coin reward).",
        -- The feature list of the map
        map_extra_info_key = 'This map has no extra information',
        -- New Scenario Features, appears in the "What's new" tab
        new_info_key = 'Nothing is new. The world is at peace',
        -- Creator of the map
        map_primary_creator_key = 'The Refactorio Team',
        -- Secondary creator of the map
        map_secondary_creator_key = nil
    },
    -- map generation settings for redmew's maps (only applies to maps that use 'shapes')
    map_generation = {
        -- whether to regen decoratives
        ['regen_decoratives'] = false,
        -- the number of 'tiles' that are calculated per tick
        ['tiles_per_tick'] = 32,
        -- the entity modules to load (takes a list of requires), example included
        ['entity_modules'] = {},
        -- the terrain modules to load (takes a list of requires), example included
        ['terrain_modules'] = {}
    },
    -- redmew_surface allows a map preset to control world generation as well as map and difficulty settings
    -- the entire module can be toggled or just individual parts
    redmew_surface = {
        enabled = true,
        use_default = false,
        map_gen_settings = true,
        map_settings = true,
        difficulty = true
    },
    -- time before a player gets the auto-trusted rank, allowing them access to the deconstructions planner, nukes, etc.
    rank_system = {
        time_for_trust = 3 * 60 * 60 * 60, -- 3 hours
        everyone_is_regular = false
    },
    -- allows syncing player colors from and to the server. Disable this if you want to enforce custom colors
    -- when enabled, /color will also be synced to the player settings
    player_colors = {
        enabled = true
    },
    -- saves players' lives if they have a 'simple-entity-with-owner' in their inventory, also adds the 'simple-entity-with-owner' to the market and must therefor be loaded first
    train_saviour = {
        enabled = true
    },
    -- Adds the infinite storage chest to the market and adds a custom GUI to it. Also has to be loaded first due to adding a market item
    infinite_storage_chest = {
        enabled = false,
        cost = 100
    },
    -- Allows removing landfill using the deconstruction planner. Built-in for 2.0
    landfill_remover = {
        enabled = false,
        -- The tile that is used to replace landfill when it is removed.
        revert_tile = 'water-mud'
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
    -- enables dumping of inventories of offline players to a corpse at the player's last location
    dump_offline_inventories = {
        enabled = false,
        offline_timeout_mins = 15,   -- time after which a player logs off that their inventory is provided to the team
        startup_gear_drop_hours = 24 -- time after which players will keep at least their armor when disconnecting
    },
    -- enables players to create and prioritize tasks
    tasklist = {
        enabled = true
    },
    -- enables score and tracking thereof
    score = {
        enabled = true,
        -- the global score trackers to show
        global_to_show = {
            'satellites-launched',
            'rockets-launched',
            'aliens-killed',
            'built-by-players',
            'built-by-robots',
            'trees-cut',
            'rocks-smashed',
            'kills-by-trains',
            'coins-spent'
        }
    },
    -- adds a paint brush
    paint = {
        enabled = true,
        -- Sometimes the hidden tile information is lost, the fallback tile will be used when removing those tiles.
        fallback_hidden_tile = 'dirt-6',
        prevent_on_landfill = true
    },
    -- autofill turrets with ammo
    autofill = {
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
        },
        -- will delay the creating of the market in ticks
        delay = nil
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
            'Welcome to this map created by the RedMew team. You can join our discord at: refactorio.de/discord',
            'Click the infomation icon in the top left corner for server information and map details.'
        },
        cutscene = false,
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
                {name = 'simple-entity-with-owner', count = 2},
                {name = 'coin', count = 20000},
                {name = 'infinity-pipe', count = 10},
                {name = 'heat-interface', count = 10},
                {name = 'selection-tool', count = 1},
                {name = 'linked-chest', count = 10},
                {name = 'train-stop', count = 10},
                {name = 'rail', count = 100},
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
    death_corpse_tags = {
        enabled = true
    },
    -- adds many commands for users and admins alike
    redmew_commands = {
        enabled = true,
        whois = {
            player_data_to_show = {
                'player-distance-walked',
                'coins-earned',
                'coins-spent',
                'player-deaths',
                'player-items-crafted',
                'player-console-chats'
            }
        }
    },
    -- adds many commands for admins
    admin_commands = {
        enabled = true
    },
    -- adds commands for donators
    donator_commands = {
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
    -- adds a command to open a gui that can play sounds from a list
    radio = {
        enabled = false
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
        -- adds craftable loaders.
        loaders = true,
        -- turns on entity info aka alt-mode on first joining
        set_alt_on_create = true,
        -- prevents personal construction robots from being mined by other players
        save_bots = true,
        -- pick up item an inserter put on the ground, when the inserter is mined
        inserter_drops_pickup = true
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
        enabled = true,
        -- chance behemoth biters and spitters will double on death.
        duplicate_chance = 0.05
    },
    -- gradually informs players of features such as chat, toasts, etc.
    player_onboarding = {
        enabled = true
    },
    -- allows for large-scale biter attacks
    biter_attacks = {
        enabled = false,
        -- whether or not to send attacks on timed intervals (against a random player)
        timed_attacks = {
            enabled = true,
            -- frequency of automatic attacks (in seconds)
            attack_frequency = 40 * 60, -- 40 minutes
            -- difficulty of automatic attacks (1-easy, 3-normal, 10-hard, 40-brutal)
            attack_difficulty = 3
        },
        -- whether or not to send attacks on rocket launches
        launch_attacks = {
            enabled = true,
            -- whether to only attack on the first launch
            first_launch_only = true
        }
    },
    -- allows the (manual) saving and then (automatic) loading of players' quickbars between maps
    player_quick_bars = {
        enabled = true
    },
    -- allows the (manual) saving and then (automatic) loading of players' logistc requests between maps
    player_logistic_requests = {
        enabled = true
    },
    -- enables the redmew settings GUI
    redmew_settings = {
        enabled = true
    },
    -- when biter corpses in an area are above a threshold, remove the desired amount
    biter_corpse_remover = {
        enabled = true,
        max_queue_size = 200 -- The number of corpses to keep in the queue before removing the oldest.
    },
    turret_active_delay = {
        enabled = true,
        -- delay for turret type in ticks
        turret_types = {
            ['ammo-turret'] = 60 * 30,
            ['electric-turret'] = 60 * 15,
            ['fluid-turret'] = 60 * 20,
            ['artillery-turret'] = 60 * 10
        },
        -- reduce delay for each level of the tech
        techs = {
            ['weapon-shooting-speed'] = {{turret_type = 'ammo-turret', amount = 60 * 26 / 6}},
            ['laser-shooting-speed'] = {{turret_type = 'electric-turret', amount = 60 * 12 / 7}},
            ['refined-flammables'] = {{turret_type = 'fluid-turret', amount = 60 * 17 / 7}},
            ['artillery-shell-speed'] = {{turret_type = 'artillery-turret', amount = 60 * 2}}
        }
    },
    research_printer = {
        enabled = true,
        print_to_force = false, -- print a message to force chat when that force finishes a new research.
        print_to_discord = true, -- print a message to the discord channel when the player force finishes a new research.
        ignore_script = false -- ignore researches unlocked by commands or by code.
    },
    -- Control groups of spiders with a decon planner. Built-in for 2.0
    spidertron_group_control = {
        enabled = false
    },
    donator = {
        donator_perks = {
            enabled = true
        }
    },
    permissions = {
        enabled = true,
        presets = {
            no_blueprints = false,
            no_handcraft = false,
        },
        modes = {},
    },
    -- display chat messages on map surface too, as temporarily popups attached on top o players
    popup_chat = {
        enabled = true,
        min_lifetime = 06 * 60, --  6s
        max_lifetime = 20 * 60, -- 20s
        min_length = 40, -- messages shorter than this value will still be displayed for the min_lifetime
        max_length = 92, -- messages longer than this value will be trimmed
    },
    player_shortcuts = {
        enabled = false,
        shortcuts = {
            auto_stash = true,
            clear_corpses = true,
            battery_charge = true,
        }
    },
    train_station_teleport = {
        enabled = false,
        radius = 13,
    },
    admin_panel = {
        enabled = true,
    },
    experience = {
        enabled = false,
        -- controls the formula for calculating level up costs in stone sent to surface
        difficulty_scale = 20, -- Diggy default  20. Higher increases experience requirement climb
        first_lvl_xp = 350,    -- Diggy default 350. This sets the price for the first level.
        xp_fine_tune = 400,    -- Diggy default 400. This value is used to fine tune the overall requirement climb without affecting the speed
        cost_precision = 3,    -- Diggy default   3. This sets the precision of the required experience to level up. E.g. 1234 becomes 1200 with precision 2 and 1230 with precision 3.
        -- percentage * mining productivity level gets added to mining speed
        mining_speed_productivity_multiplier = 5,
        XP = {
            ['big-rock'] = 5,
            ['huge-rock'] = 10,
            ['rocket_launch'] = 0.05,       -- XP reward in percentage of total experience when a rocket launches (Diggy default: 0.05 which equals 5%)
            ['rocket_launch_max'] = 500000, -- Max XP reward from rocket launches (Diggy default: 500000)
            ['automation-science-pack'] = 4,
            ['logistic-science-pack'] = 8,
            ['chemical-science-pack'] = 15,
            ['military-science-pack'] = 12,
            ['production-science-pack'] = 25,
            ['utility-science-pack'] = 50,
            ['space-science-pack'] = 10,
            ['enemy_killed'] = 10,          -- Base XP for killing biters and spitters.
            ['death-penalty'] = 0.0035,     -- XP deduct in percentage of total experience when a player dies (Diggy default: 0.0035 which equals 0.35%)
            --['cave-in-penalty'] = 100     -- XP lost every cave in.
            ['infinity-research'] = 0.60    -- XP reward in percentage of the required experience from current level to next level (Diggy default: 0.60 which equals 60%)
        },
        buffs = {
            -- define new buffs here, they are handed out for each level
            -- double_level (optional): the level interval for receiving a double bonus (Diggy default: 5 which equals every 5th level)
            -- level interval (optional): the interval to receive the bonus. Default is 1
            mining_speed = { value = 20, max = 29 },
            inventory_slot = { value = 1, max = 100 },
            health_bonus = { value = 2.5, double_level = 5, max = 500 },
            character_reach = { value = 1, max = 10, level_interval = 10 },
            crafting_speed = { value = 0.1, max = 10 },
            running_speed = { value = 0.025, max = 3 },
        },
        -- add or remove a table entry to add or remove an unlockable item from the market.
        unlockables = {
            { level =   2, price =    4, name = 'wood' },
            { level =   3, price =    5, name = 'stone-wall' },
            { level =   4, price =   20, name = 'pistol' },
            { level =   4, price =    5, name = 'firearm-magazine' },
            { level =   5, price =  100, name = 'light-armor' },
            { level =   6, price =    6, name = 'small-lamp' },
            { level =   6, price =    5, name = 'raw-fish' },
            { level =   8, price =    1, name = 'stone-brick' },
            { level =  10, price =   85, name = 'shotgun' },
            { level =  10, price =    4, name = 'shotgun-shell' },
            { level =  12, price =  200, name = 'heavy-armor' },
            { level =  14, price =   25, name = 'landfill' },
            { level =  15, price =   85, name = 'submachine-gun' },
            { level =  18, price =   10, name = 'piercing-rounds-magazine' },
            { level =  18, price =    8, name = 'piercing-shotgun-shell' },
            { level =  19, price =    2, name = 'rail' },
            { level =  19, price =    1, name = 'iron-stick' },
            { level =  20, price =   50, name = 'locomotive' },
            { level =  20, price =  350, name = 'modular-armor' },
            { level =  21, price =    5, name = 'rail-signal' },
            { level =  22, price =    5, name = 'rail-chain-signal' },
            { level =  23, price =   15, name = 'train-stop' },
            { level =  24, price =   35, name = 'cargo-wagon' },
            { level =  24, price =   35, name = 'fluid-wagon' },
            { level =  26, price =  150, name = 'tank' },
            { level =  29, price =  750, name = 'power-armor' },
            { level =  30, price =   30, name = 'logistic-robot' },
            { level =  31, price =  200, name = 'personal-roboport-equipment' },
            { level =  32, price =   20, name = 'construction-robot' },
            { level =  34, price =  750, name = 'fission-reactor-equipment' },
            { level =  35, price =  150, name = 'battery-equipment' },
            { level =  38, price =  250, name = 'exoskeleton-equipment' },
            { level =  40, price =  125, name = 'energy-shield-equipment' },
            { level =  42, price =  500, name = 'personal-laser-defense-equipment' },
            { level =  44, price = 1250, name = 'power-armor-mk2' },
            { level =  46, price =  750, name = 'battery-mk2-equipment' },
            { level =  48, price =  550, name = 'combat-shotgun' },
            { level =  51, price =   25, name = 'uranium-rounds-magazine' },
            { level =  63, price =  250, name = 'rocket-launcher' },
            { level =  63, price =   40, name = 'rocket' },
            { level =  71, price =   80, name = 'explosive-rocket' },
            { level =  75, price =  800, name = 'energy-shield-mk2-equipment' },
            { level =  78, price = 1000, name = 'satellite' },
            { level = 100, price = 2500, name = 'spidertron' },
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
            ['behemoth-worm-turret'] = 7
        },
        sound = {
            path = nil,
            duration = 60 * 60,
            override_sound_type = 'ambient' -- Menu > Settings > Sounds > Music
        }
    },
    market_chest = {
        enabled = false,
        market_provides_chests = true,
        -- What market provides
        offers = {
            ['coal'] = 2,
            ['copper-ore'] = 2,
            ['iron-ore'] = 2,
            ['stone'] = 2,
            ['uranium-ore'] = 10,
        },
        -- What market requests
        requests = {
            ['coal'] = 1,
            ['copper-ore'] = 1,
            ['iron-ore'] = 1,
            ['stone'] = 1,
            ['uranium-ore'] = 5,
        },
    },
    -- adds a small display always on screen for production stats
    production_hud = {
        enabled = true,
        starting_items = { 'iron-ore', 'copper-ore', 'coal', 'stone' },
        limit = 40, -- limit of tracked items per-player
    },
    calculator = {
        enabled = true,
        technology = true,
    }
}

return storage.config
