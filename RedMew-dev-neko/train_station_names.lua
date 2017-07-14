local function player_built_entity(event)

	if event.created_entity.name == "train-stop" then
		local y = math.random(1,3)
		if y == 1 then			
		else
			local total_players = #game.players
			local x = math.random(1,total_players)
			local player = game.players[x]
			event.created_entity.backer_name = player.name
		end
	end
	
end

Event.register(defines.events.on_built_entity, player_built_entity)
Event.register(defines.events.on_robot_built_entity, player_built_entity)
