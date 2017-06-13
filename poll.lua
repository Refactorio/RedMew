----------------------------------------------------------------------------------------------------------------------------------------
-- Create Polls for your Factory Workers                                
-- by MewMew -- with some help from RedLabel, Klonan, Morcup, BrainClot   
----------------------------------------------------------------------------------------------------------------------------------------

local function create_poll_gui(event)
	local player = game.players[event.player_index]
	
	if player.gui.top.poll == nil then
		local button = player.gui.top.add { name = "poll", type = "sprite-button", sprite = "item/programmable-speaker" }
		button.style.font = "default-bold"
		button.style.minimal_height = 38
		button.style.minimal_width = 38
		button.style.top_padding = 2
		button.style.left_padding = 4
		button.style.right_padding = 4
		button.style.bottom_padding = 2
	end
end

local function poll_show(player)
	
	player.gui.left.direction = "horizontal"	
	local frame = player.gui.left.add { type = "frame", name = "poll-panel", direction = "vertical" }	

	frame.add { type = "table", name = "poll_panel_table", colspan = 2 }
	
	local poll_panel_table = frame.poll_panel_table
	
	if not (global.poll_question == "") then
		
		local str = "Poll #" .. global.score_total_polls_created .. ":"
		if global.score_total_polls_created > 1 then
			local x = game.tick
			x = ((x / 60) / 60) / 60
			x = global.score_total_polls_created / x 
			x = round(x, 0)
			str = str .. "                   (Polls/hour: "
			str = str .. x
			str = str .. ")"
		end
		
		poll_panel_table.add { type = "label", caption = str, single_line = false, name = "poll_number_label" }
		poll_panel_table.poll_number_label.style.font_color = { r=0.75, g=0.75, b=0.75}
		poll_panel_table.add { type = "label"}	
		--poll_panel_table.add { caption = "----------------------------", type = "label" }
		--poll_panel_table.add { type = "label" }			
		poll_panel_table.add { type = "label", caption = global.poll_question, single_line = false, name = "question_label" }
		poll_panel_table.question_label.style.maximal_width = 208
		poll_panel_table.question_label.style.maximal_height = 170
		poll_panel_table.question_label.style.font = "default-bold"
		poll_panel_table.question_label.style.font_color = { r=0.98, g=0.66, b=0.22}
		poll_panel_table.add { type = "label" }
	end
	
	local y = 1
	while (y < 4) do

		if not (global.poll_answers[y] == "") then		
		
			local z = tostring(y)
			
			poll_panel_table.add { type = "label", caption = global.poll_answers[y], single_line = false, name = "answer_label_" .. z }
			local answer_label = poll_panel_table["answer_label_" .. z]
			answer_label.style.maximal_width = 208
			answer_label.style.minimal_width = 208
			answer_label.style.maximal_height = 165
			answer_label.style.font = "default"
			
			local answerbutton = poll_panel_table.add  { type = "button", caption = global.poll_button_votes[y], name = "answer_button_" .. z }	
			answerbutton.style.font = "default-listbox"
		end
		y = y + 1
	end
	
	frame.add { type = "table", name = "poll_panel_button_table", colspan = 3 }
	local poll_panel_button_table = frame.poll_panel_button_table
	poll_panel_button_table.add { type = "button", caption = "New Poll", name = "new_poll_assembler_button" }
	

	
	global.poll_panel_creation_time[player.index] = game.tick
	
	local str = "Hide (" .. global.poll_duration_in_seconds
	str = str .. ")"
	
	
	poll_panel_button_table.add { type = "button", caption = str, name = "poll_hide_button" }
	
	poll_panel_button_table.poll_hide_button.style.minimal_width = 70		
	poll_panel_button_table.new_poll_assembler_button.style.font = "default-bold"
	poll_panel_button_table.new_poll_assembler_button.style.minimal_height = 38
	poll_panel_button_table.poll_hide_button.style.font = "default-bold"		
	poll_panel_button_table.poll_hide_button.style.minimal_height = 38		
	poll_panel_button_table.add { type = "checkbox", caption = "Show Polls", state = global.autoshow_polls_for_player[player.name], name = "auto_show_polls_checkbox"	}						
end

local function poll(player)
	
	local frame = player.gui.left["poll-assembler"]
	frame = frame.table_poll_assembler
	
	global.poll_question = ""
	global.poll_question = frame.textfield_question.text
	if (global.poll_question == "") then
		return
	end
	
	
	global.poll_answers = {"","",""}
	global.poll_answers[1] = frame.textfield_answer_1.text
	global.poll_answers[2] = frame.textfield_answer_2.text
	global.poll_answers[3] = frame.textfield_answer_3.text
	if (global.poll_answers[3] .. global.poll_answers[2] .. global.poll_answers[1] == "") then
		return
	end
	
	local msg = player.name
	msg = msg .. " has created a new Poll!"
	
	global.score_total_polls_created = global.score_total_polls_created + 1
	
	local frame = player.gui.left["poll-assembler"]
	frame.destroy()
	
	global.poll_voted = nil		
	global.poll_voted  = {}
	global.poll_button_votes = {0,0,0}
	
	local x = 1
	
	while (game.players[x] ~= nil) do
	
		local player = game.players[x]
		
		local frame = player.gui.left["poll-panel"]	
	
		if (frame) then
				frame.destroy()
		end
		
		if (global.autoshow_polls_for_player[player.name] == true) then
			poll_show(player)
		end
		
		player.print(msg)
		
		x = x + 1
	end
	
	
	---------------------
	-- data for score.lua
	---------------------
	--global.score_total_polls_created = global.score_total_polls_created + 1
	--refresh_score()
	
end


local function poll_refresh()
	
	local x = 1
	
	while (game.players[x] ~= nil) do
	
		local player = game.players[x]
		
		if (player.gui.left["poll-panel"]) then		
			local frame = player.gui.left["poll-panel"]
			frame = frame.poll_panel_table
		
				if not (frame.answer_button_1 == nil) then		
					frame.answer_button_1.caption = global.poll_button_votes[1]
				end
				if not (frame.answer_button_2 == nil) then		
					frame.answer_button_2.caption = global.poll_button_votes[2]
				end
				if not (frame.answer_button_3 == nil) then		
					frame.answer_button_3.caption = global.poll_button_votes[3]
				end										
		end
		x = x + 1
	end
		
end

local function poll_assembler(player)				
	local frame = player.gui.left.add { type = "frame", name = "poll-assembler", caption = "" }	
	local frame_table = frame.add { type = "table", name = "table_poll_assembler", colspan = 2 }
	frame_table.add { type = "label", caption = "Question:" }
	frame_table.add { type = "textfield", name = "textfield_question", text = "" }
	frame_table.add { type = "label", caption = "Answer #1:" }
	frame_table.add { type = "textfield", name = "textfield_answer_1", text = "" }
	frame_table.add { type = "label", caption = "Answer #2:" }
	frame_table.add { type = "textfield", name = "textfield_answer_2", text = "" }
	frame_table.add { type = "label", caption = "Answer #3:" }
	frame_table.add { type = "textfield", name = "textfield_answer_3", text = "" }
	frame_table.add { type = "label", caption = "" }
	frame_table.add { type = "button", name = "create_new_poll_button", caption = "Create" }

end

function poll_sync_for_new_joining_player(event)

	if not global.poll_voted then global.poll_voted = {} end
	if not global.poll_question then global.poll_question = "" end
	if not global.poll_answers then global.poll_answers = {"","",""} end
	if not global.poll_button_votes then global.poll_button_votes = {0,0,0} end
	if not global.poll_voted then global.poll_voted = {} end
	if not global.autoshow_polls_for_player then global.autoshow_polls_for_player = {} end
	if not global.poll_duration_in_seconds then global.poll_duration_in_seconds = 99 end
	if not global.poll_panel_creation_time then global.poll_panel_creation_time = {} end
	if not global.score_total_polls_created then global.score_total_polls_created = 0 end
		
	local player = game.players[event.player_index]	
	
	global.autoshow_polls_for_player[player.name] = true
	
	local frame = player.gui.left["poll-panel"]	
	if (frame == nil) then
			if not (global.poll_question == "") then
				poll_show(player)
			end
	end	
	
end

local function on_gui_click(event)
	if not (event and event.element and event.element.valid) then return end
		local player = game.players[event.element.player_index]
		local name = event.element.name
		
		if (name == "poll") then
			local frame = player.gui.left["poll-panel"]
			if (frame) then
				frame.destroy()
			else
				poll_show(player)
			end
			
			local frame = player.gui.left["poll-assembler"]
			if (frame) then
				frame.destroy()
			end
		end
		
		if (name == "new_poll_assembler_button") then
			local frame = player.gui.left["poll-assembler"]
			if (frame) then
				frame.destroy()
			else
				poll_assembler(player)
			end
		end
		
		if (name == "create_new_poll_button") then			
				poll(player)
		end
		
		if (name == "poll_hide_button") then
			local frame = player.gui.left["poll-panel"]
			if (frame) then
				frame.destroy()
			end
			local frame = player.gui.left["poll-assembler"]
			if (frame) then
				frame.destroy()
			end
		end
		
		if (name == "auto_show_polls_checkbox") then
			global.autoshow_polls_for_player[player.name] = event.element.state 		
		end		
						
		if global.poll_voted[event.player_index] == nil then		
			
			if(name == "answer_button_1") then
				global.poll_button_votes[1] = global.poll_button_votes[1] + 1
				global.poll_voted[event.player_index] = player.name
				poll_refresh()
			end
				
			if(name == "answer_button_2") then
				global.poll_button_votes[2] = global.poll_button_votes[2] + 1
				global.poll_voted[event.player_index] = player.name
				poll_refresh()
			end
				
			if(name == "answer_button_3") then
				global.poll_button_votes[3] = global.poll_button_votes[3] + 1
				global.poll_voted[event.player_index] = player.name
				poll_refresh()
			end
			
		end					
end

local function poll_timeout()	
	if game.tick % 60 == 0 then
		local x = 1
		while game.players[x] ~= nil do				
			local player = game.players[x]
			if global.poll_panel_creation_time[player.index] then
				local frame = player.gui.left["poll-panel"]
				if frame then				
					local y = (game.tick - global.poll_panel_creation_time[player.index]) / 60
					local y = global.poll_duration_in_seconds - y
					y = round(y, 0)
					if y == 0 then
						frame.destroy()
						global.poll_panel_creation_time[player.index] = nil
					else
						y = "Hide (" .. y
						y = y .. ")"
						frame.poll_panel_button_table.poll_hide_button.caption = y
					end
				end
			end
			x = x + 1
		end
	end	
end

Event.register(defines.events.on_tick, poll_timeout)
Event.register(defines.events.on_gui_click, on_gui_click)
Event.register(defines.events.on_player_joined_game, create_poll_gui)
Event.register(defines.events.on_player_joined_game, poll_sync_for_new_joining_player)