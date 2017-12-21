require "util"
require "locale/utils/event"
require "config"
require "locale/utils/utils"
require "locale/utils/list_utils"
require "base_data"
require "user_groups"
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
require "autodeconstruct"
require "corpse_util"
require "reactor_meltdown"

local function player_joined(event)
	local player = game.players[event.player_index]
	player.insert { name = "raw-fish", count = 4 }
	player.insert { name = "iron-gear-wheel", count = 8 }
	player.insert { name = "iron-plate", count = 16 }
	player.print("Welcome to our Server. You can join our Discord at: redmew.com/discord")
	player.print("And remember.. Keep Calm And Spaghetti!")
end

function walkabout(player_name, distance)
	game.player.print("This command moved to /walkabout.")
end

local hodor_messages = {{"Hodor.", 16}, {"Hodor?", 16},{"Hodor!", 16}, {"Hodor! Hodor! Hodor! Hodor!", 4}, {"Hodor :(",4}, {"Hodor :)",4}, {"HOOOODOOOR!", 4}, {"( ͡° ͜ʖ ͡°)",1}, {"☉ ‿ ⚆",1}}
local message_weight_sum = 0
for _,w in pairs(hodor_messages) do
message_weight_sum = message_weight_sum + w[2]
end

function hodor(event)
	local message = event.message:lower()
	if message:match("hodor") then
		local index = math.random(1, message_weight_sum)
		local message_weight_sum = 0
		for _,m in pairs(hodor_messages) do
			message_weight_sum = message_weight_sum + m[2]
			if message_weight_sum >= index then
				game.print("Hodor: " .. m[1])
				return
			end
		end
	end
	if message:match("discord") then
		if game.player then
			game.player.print("Did you ask about our discord server?")
			game.player.print("You can find it here: redmew/discord")
		end
	end
end

Event.register(defines.events.on_player_created, player_joined)
Event.register(defines.events.on_console_chat, hodor)
