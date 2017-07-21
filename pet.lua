--[[local function on_player_joined_game(event)
	local player = game.players[event.player_index]

	if player.gui.top.pet_button == nil then
		local button = player.gui.top.add({ type = "sprite-button", name = "pet_button", sprite = "entity/small-biter" })
		button.style.minimal_height = 38
		button.style.minimal_width = 38
		button.style.top_padding = 0
		button.style.left_padding = 0
		button.style.right_padding = 0
		button.style.bottom_padding = 0
	end
end

local function show_pet_panel(player)
	local frame = player.gui.left.add { type = "frame", name = "pet-panel", direction = "vertical" }

	pet_table = frame.add { type = "table", name = "pet_panel_table", colspan = 2 }
	pet_table.add({ type = "sprite-button", name = "pet_button", sprite = "entity/small-biter" })
end
]]--
function pet(player, entity_name)
	if not player then
		player = game.connected_players[1]
	else
		player = game.players[player]
	end
	if not entity_name then
		entity_name = "small-biter"
	end
	if not global.player_pets then global.player_pets = {} end

	local surface = game.surfaces[1]

	local pos = player.position
	pos.y = pos.y - 2

	local x = 1
	x = x + #global.player_pets

	global.player_pets[x] = {}
	global.player_pets[x].entity = surface.create_entity {name=entity_name, position=pos, force="player"}
	global.player_pets[x].owner = player.index
	global.player_pets[x].id = x

end

function pet_on_120_ticks()
	for _, pets in pairs(global.player_pets) do
		local player = game.players[pets.owner]
		if pcall(function () local x = pets.entity.name end) then
			pets.entity.set_command({type=defines.command.go_to_location, destination=player.position,distraction=defines.distraction.none})
		else
			global.player_pets[pets.id] = nil
			local str = player.name .. "´s pet died ;_;"
			game.print(str)
		end
	end
end

Event.register(defines.events.on_gui_click, on_gui_click)
Event.register(defines.events.on_player_joined_game, on_player_joined_game)
