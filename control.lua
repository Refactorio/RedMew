require "util"
require "locale/utils/event"
require "config"
require "locale/utils/utils"
require "base_data"
require "info"
require "player_list"
require "poll"
require "band"
require "fish_market"
require "train_station_names"
require "score"
require "map_layout"



function player_joined(event)
	local player = game.players[event.player_index]
		player.insert { name = "raw-fish", count = 4 }
	    player.insert { name = "iron-gear-wheel", count = 8 }		
	    player.insert { name = "iron-plate", count = 16 }
	    --player.insert { name = "pistol", count = 1 }
	    --player.insert { name = "firearm-magazine", count = 8 }
		--player.insert { name = "train-stop", count = 16 }
		--player.insert { name = "roboport", count = 16 }
		--player.insert { name = "construction-robot", count = 16 }
		--player.insert { name = "solar-panel", count = 16 }
		--player.insert { name = "substation", count = 16 }
		--player.insert { name = "logistic-chest-passive-provider", count = 16 }		
		--player.insert { name = "power-armor", count = 1 }
		player.print("Welcome to our Server. You can join our Discord at: discord.me/redmew")
		player.print("And remember.. Keep Calm And Spaghetti!")
		--game.speed=1
end

function walkabout(player_name, distance)

	if distance == nil then
		--game.print("Specify rough distance for the walkabout.")
		distance = math.random(5000, 10000)
		return
	end
	
	if distance == "close" then
		distance = math.random(3000, 7000)
	else
		if distance == "far" then
			distance = math.random(7000, 11000)
		else
			if distance == "very far" then
			distance = math.random(11000, 15000)
			else
				game.print("Walkabout failed.")
				return
			end
		end		
	end
	
	
	
	
	
	
	local x = 1
	while game.players[x] ~= nil do
		local player = game.players[x]
		if player_name == player.name then
			local repeat_attempts = 5
			local r = 1
			local surface = game.surfaces[1]
			local distance_max = distance * 1.05
			local distance_min = distance * 0.95
			distance_max = round(distance_max, 0)
			distance_min = round(distance_min, 0)
			
			--while r <= repeat_attempts do
				x = math.random(distance_min, distance_max)
				if 1 == math.random(1, 2) then
					x = x * -1				
				end
				
				y = math.random(distance_min, distance_max)
				if 1 == math.random(1, 2) then
					y = y * -1
				end
				
				if 1 == math.random(1, 2) then
					z = distance_max * -1
					x = math.random(z, distance_max)
				else
					z = distance_max * -1
					y = math.random(z, distance_max)
				end
			
				--r = r + 1
				--local tile = surface.get_tile(x,y)
				--game.print(tile.name)
				--if tile.name == "deep-water" or tile.name == "water" then					
					--if r >= repeat_attempts then
						--game.print(player_name .. " tried to go on a walkabout, but could only find water.")
						--return
					--end
				--else
					local pos = {x, y}
					player.teleport(pos)
					game.print(player_name .. " went on a walkabout, to find himself.")
					return			
				--end
			--end
		end
		x = x + 1
	end
	game.print(player_name .. " could not go on a walkabout.")
end
--function player_respawned(event)
	--local player = game.players[event.player_index]
	--player.insert { name = "pistol", count = 1 }
	--player.insert { name = "firearm-magazine", count = 10 }
--end

Event.register(defines.events.on_research_finished, function (event)
	local research = event.research
	if global.scenario.config.logistic_research_enabled then
		research.force.technologies["logistic-system"].enabled=true
	else
	    research.force.technologies["logistic-system"].enabled=false
	end
end)

Event.register(defines.events.on_player_created, player_joined)
Event.register(defines.events.on_player_respawned, player_respawned)
