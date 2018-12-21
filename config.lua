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
