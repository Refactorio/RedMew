local Event = require "utils.event"

Event.add(defines.events.on_player_died, function (event)
	local player = event.player_index
	if game.players[player].name ~= nil then
		print("PLAYER$die," .. player .. "," .. game.players[player].name .. "," .. game.players[player].force.name)
	end
end)

Event.add(defines.events.on_player_respawned, function (event)
	local player = event.player_index
	if game.players[player].name ~= nil then
		print("PLAYER$respawn," .. player .. "," .. game.players[player].name .. "," .. game.players[player].force.name)
	end
end)

Event.add(defines.events.on_player_joined_game, function (event)
	local player = event.player_index
	if game.players[player].name ~= nil then
		print("PLAYER$join," .. player .. "," .. game.players[player].name .. "," .. game.players[player].force.name)
	end
end)

Event.add(defines.events.on_player_left_game, function (event)
	local player = event.player_index
	if game.players[player].name ~= nil then
		print("PLAYER$leave," .. player .. "," .. game.players[player].name .. "," .. game.players[player].force.name)
	end
end)

function heartbeat()
	--Do nothing, this is just so managepgm can call something as a heartbeat without any errors occurring
end

function playerQuery()
	if #game.connected_players == 0 then
		print("output$pquery$none")
	else
		local response = "output&pquery$"
		for _,player in pairs(game.connected_players) do
			local playerdata = player.name .. "-" .. player.force.name
			response = response .. playerdata .. ","
		end
		print(response:sub(1,#str-1))
	end
end