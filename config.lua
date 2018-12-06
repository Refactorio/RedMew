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
}

return global.config
