_DEBUG = false
_CHEATS = false

global.config = {
    -- The title of the map
    map_name_key = 'This Map has no name',

    -- The long description of the map, typically 1 paragraph
    map_description_key = "By default this section is blank as it's supposed to be filled out on a per map basis. (If you're seeing this message, ping the admin team to get a description added for this map)",

    -- The feature list of the map
    map_extra_info_key = 'This map has no extra information',

    -- New Scenario Features, appears in the "What's new" tab
    new_info_key = 'Nothing is new. The world is at peace',

    -- Adds a command to scale UPS and movement speed. Use with caution
    -- as it might break scenarios that modify movement speed
    performance = {
        enabled = true,
    },
  
    -- adds a player list icon and keeps track of data.
    player_list = {
        enabled = true,
        show_coin_column = true,
    },

    -- enables the poll system
    poll = {
        enabled = true,
    },

    -- enables players to create and join tags
    tag_group = {
        enabled = true,
    },

    -- enables players to create and prioritize tasks
    tasklist = {
        enabled = true,
    },

    -- enables the blueprint helper
    blueprint_helper = {
        enabled = true,
    },

    -- enables score and tracking thereof
    score = {
        enabled = true,
    },

    -- adds a paint brush
    paint = {
        enabled = true,
    },

    -- adds a fish market
    fish_market = {
        enabled = true,
        market_item = 'coin',
    },

    -- automatically marks mines for deconstruction when they are depleted
    -- currently not working with mods
    auto_deconstruct = {
        enabled = true,
    },

    -- adds anti-nuke griefing
    nuke_control = {
        enabled = true,
        enable_autokick = true,
        enable_autoban = true,

        -- how long a player must be on the server to be allowed to use the nuke
        nuke_min_time_hours = 3,
    },

    -- adds a meltdown feature, requiring precise management
    reactor_meltdown = {
        enabled = true,
        -- when enabled, controls whether it's on by default. State can be controlled with the /meltdown command.
        on_by_default = false,
    },

    -- adds hodor responses to messages
    hodor = {
        enabled = true,
    },

    -- enable RedMew auto respond messages
    auto_respond = {
        enabled = true,
    },

    -- enable the mentioning system, which notifies a player when their name is mentioned
    mentions = {
        enabled = true,
    },

    player_create = {
        enabled = true,

        -- items automatically inserted into the player inventory
        starting_items = {
            {name = 'iron-gear-wheel', count = 8},
            {name = 'iron-plate', count = 16},
        },

        -- opens the scenario popup when the player joins
        show_info_at_start = true,

        -- prints messages when the player joins
        join_messages = {
            'Welcome to this map created by the RedMew team. You can join our discord at: redmew.com/discord',
            'Click the question mark in the top left corner for server information and map details.',
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
                {name = 'steel-axe', count = 10},
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
            },
        },
    },

    -- spawns more units when one dies
    hail_hydra = {
        enabled = false,

        -- any non-rounded number will turn into a chance to spawn an additional alien
        -- example: 2.5 would spawn 2 for sure and 50% chance to spawn one additionally
        hydras = {
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
}

return global.config
