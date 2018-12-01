_DEBUG = false
_CHEATS = false
MARKET_ITEM = 'coin'

global.config = {
    -- The title of the map
    map_name_key = 'This Map has no name',

    -- The long description of the map, typically 1 paragraph
    map_description_key = "By default this section is blank as it's supposed to be filled out on a per map basis. (If you're seeing this message, ping the admin team to get a description added for this map)",

    -- The feature list of the map
    map_extra_info_key = 'This map has no extra information',

    -- New Scenario Features, appears in the "What's new" tab
    new_info_key = 'Nothing is new. The world is at peace',

    player_list = {
        enable_coin_col = true,
    },
    paint = {
        enable = true,
    },
    fish_market = {
        enable = true,
    },
    nuke_control = {
        enable_autokick = true,
        enable_autoban = true,

        -- how long a player must be on the server to be allowed to use the nuke
        nuke_min_time_hours = 3,
    },
    hodor = true,
    auto_respond = true,
    mentions = true,
}
