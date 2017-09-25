require "util"
require "locale/utils/event"
require "config"
require "locale/utils/utils"
require "locale/utils/list_utils"
require "base_data"
require "user_groups"
require "chatlog"
require "info"
require "player_list"
require "poll"
require "band"
require "fish_market"
require "train_station_names"
require "score"
require "map_layout"
require "nuke_control"
require "walk_distance"
require "on_tick"
require "follow"
require "wells"
require "custom_commands"
require "tasklist"

local function player_joined(event)
	local player = game.players[event.player_index]
		player.insert { name = "raw-fish", count = 4 }
	  player.insert { name = "iron-gear-wheel", count = 8 }
	  player.insert { name = "iron-plate", count = 16 }
		player.print("Welcome to our Server. You can join our Discord at: discord.me/redmew")
		player.print("And remember.. Keep Calm And Spaghetti!")
end

function walkabout(player_name, distance)
		game.player.print("This command moved to /walkabout.")
end

Event.register(defines.events.on_player_created, player_joined)
