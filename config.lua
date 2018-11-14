_DEBUG = false
MARKET_ITEM = 'coin'

global.scenario = {}
global.scenario.variables = {}
global.scenario.variables.player_positions = {}
global.player_walk_distances = {}
global.scenario.variables.player_deaths = {}
global.scenario.config = {}
global.scenario.config.player_list = {}
global.scenario.config.player_list.enable_coin_col = true
global.scenario.config.paint = {}
global.scenario.config.paint.enable = true
global.scenario.config.fish_market = {}
global.scenario.config.fish_market.enable = true
global.scenario.config.nuke_control = {}
global.scenario.config.nuke_control.enable_autokick = true
global.scenario.config.nuke_control.enable_autoban = true
global.scenario.custom_functions = {}
global.scenario.config.nuke_control.nuke_min_time_hours = 3 --how long a player must be on the server to be allowed to use the nuke
global.scenario.config.admin_check = true --auto-promote admins into their role
global.newline = '\n'
newline = '\n'

-- The title of the map
global.scenario.config.map_name_key = 'This Map has no name'
-- The long description of the map, typically 1 paragraph
global.scenario.config.map_description_key = "By default this section is blank as it's supposed to be filled out on a per map basis. (If you're seeing this message, ping the admin team to get a description added for this map)"
-- The feature list of the map
global.scenario.config.map_extra_info_key = 'This map has no extra infomation'
-- New Scenario Features, appears in the "What's new" tab
global.scenario.config.new_info_key = 'Nothing is new. The world is at peace'
