_DUMP_ENV = true
local market_item = 'coin'

global.config = {
    map_info = {
        -- The title of the map
        map_name_key = 'This Map has no name',
        -- The long description of the map, typically 1 paragraph
        map_description_key = "This section is supposed to be filled out on a per map basis. If you're seeing this message, ping the admin team to get a description added for this map. A 20 coin bonus is available to the first person to point this out.",
        -- The feature list of the map
        map_extra_info_key = 'This map has no extra information',
        -- New Scenario Features, appears in the "What's new" tab
        new_info_key = 'Nothing is new. The world is at peace',
    },

    -- settings for when a player joins the server for the first time
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
    -- grants reward coins for certain actions
    player_rewards = {
        enabled = true,
        -- the token to use for rewards
        token = market_item,
        -- rewards players for looking through the info tabs
        info_player_reward = true,
    },
}

return global.config
