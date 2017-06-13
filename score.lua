if not global.score_rockets_launched then global.score_rockets_launched = 0 end

local function create_score_gui(event)
	local player = game.players[event.player_index]
	
	if player.gui.top.score == nil then
		local button = player.gui.top.add({ type = "sprite-button", name = "score", sprite = "item/rocket-silo" })		
		button.style.minimal_height = 38
		button.style.minimal_width = 38
		button.style.top_padding = 2
		button.style.left_padding = 4
		button.style.right_padding = 4
		button.style.bottom_padding = 2
	end
end

function refresh_score()
	local x = 1
	while (game.players[x] ~= nil) do 
		local player = game.players[x]
		local frame = player.gui.top["score_panel"]	
	
		if (frame) then			
				frame.score_table.label_rockets_launched.caption = "Rockets launched: " .. global.score_rockets_launched
				frame.score_table.label_biters_killed.caption = "Biters liberated: " .. global.score_biter_total_kills		
--				frame.score_table.label_score_polls_created.caption = "Polls created: " .. global.score_total_polls_created
		end
		x = x + 1
	end
end

local function score_show(player)

	local rocket_score_value_string = tostring(global.score_rockets_launched)

	local frame = player.gui.top.add { type = "frame", name = "score_panel" }
		
	local score_table = frame.add { type = "table", colspan = 5, name = "score_table" }
	local label = score_table.add { type = "label", caption = "", name = "label_rockets_launched" }	
	label.style.font = "default-bold"			
	label.style.font_color = { r=0.98, g=0.66, b=0.22}
	label.style.top_padding = 2
	label.style.left_padding = 4
	label.style.right_padding = 4
	
	score_table.add { type = "label", caption = "|"}	
		
	local label = score_table.add { type = "label", caption = "", name = "label_biters_killed" }	
	label.style.font = "default-bold"			
	label.style.font_color = { r=0.98, g=0.11, b=0.11}
	label.style.top_padding = 2
	label.style.left_padding = 4
	label.style.right_padding = 4
--[[	
	if global.score_total_polls_created then
		score_table.add { type = "label", caption = "|"}	
		
		local label = score_table.add { type = "label", caption = "", name = "label_score_polls_created" }	
		label.style.font = "default-bold"			
		label.style.font_color = { r=0.80, g=0.80, b=0.80}
		label.style.top_padding = 2
		label.style.left_padding = 4
		label.style.right_padding = 4
	end
--]]	
	refresh_score()
end


local function on_gui_click(event)
	if not (event and event.element and event.element.valid) then return end
	
	local player = game.players[event.element.player_index]
	local name = event.element.name	
	local frame = player.gui.top["score_panel"]	
	
	if (name == "score") and (frame == nil) then
				score_show(player)
	else
		if (name == "score") then
			frame.destroy()
		end
	end
		
end

local function rocket_launched(event)
	global.score_rockets_launched = global.score_rockets_launched + 1
	game.print ("A rocket has been launched!")	
	refresh_score()
end



Event.register(defines.events.on_entity_died, refresh_score)
Event.register(defines.events.on_gui_click, on_gui_click)
Event.register(defines.events.on_player_joined_game, create_score_gui)
Event.register(defines.events.on_rocket_launched, rocket_launched)