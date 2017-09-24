----------------------------------------------------------------------------------------------------------------------------------------
-- Create last lists for your Factory Workers
-- based on MewMew's Poll
----------------------------------------------------------------------------------------------------------------------------------------

local function create_tasklist_gui(event)
	local player = game.players[event.player_index]

	if player.gui.top.tasklist == nil then
		local button = player.gui.top.add { name = "tasklist", type = "sprite-button", sprite = "item/blueprint" }
		button.style.font = "default-bold"
		button.style.minimal_height = 38
		button.style.minimal_width = 38
		button.style.top_padding = 2
		button.style.left_padding = 4
		button.style.right_padding = 4
		button.style.bottom_padding = 2
	end
end

local function tasklist_show(player)

	player.gui.left.direction = "horizontal"
	local frame = player.gui.left.add { type = "frame", name = "tasklist-panel", direction = "vertical" }

	frame.add { type = "table", name = "tasklist_panel_table", colspan = 1 }

	local tasklist_panel_table = frame.tasklist_panel_table

	tasklist_panel_table.add { type = "label", caption = "Task List:", single_line = false, name = "tasklist_title"}
	local tasklist_label = tasklist_panel_table["tasklist_title"]
	tasklist_label.style.maximal_width = 208
	tasklist_label.style.minimal_width = 208
	tasklist_label.style.maximal_height = 165
	tasklist_label.style.font = "default"

	local y = 1
	local counter = 0
	while (y < 6) do

		if not (global.tasklist_items[y] == "") then
			counter = counter + 1

			local z = tostring(y)

			tasklist_panel_table.add { type = "label", caption = counter .. ". " .. global.tasklist_items[y], single_line = false, name = "tasklist_item_label_" .. z}
			local tasklist_label = tasklist_panel_table["tasklist_item_label_" .. z]
			tasklist_label.style.maximal_width = 208
			tasklist_label.style.minimal_width = 208
			tasklist_label.style.maximal_height = 165
			tasklist_label.style.font = "default"
		end
		y = y + 1
	end

	if global.tasklist_author ~= nil then
		tasklist_panel_table.add { type = "label", caption = "-- created by: " .. global.tasklist_author, single_line = false, name = "tasklist_author"}
		local tasklist_label = tasklist_panel_table["tasklist_author"]
		tasklist_label.style.maximal_width = 208
		tasklist_label.style.minimal_width = 208
		tasklist_label.style.maximal_height = 165
		tasklist_label.style.font = "default"
	end


	frame.add { type = "table", name = "tasklist_panel_button_table", colspan = 3 }
	local tasklist_panel_button_table = frame.tasklist_panel_button_table

	global.tasklist_panel_creation_time[player.index] = game.tick

	if is_regular( player.name ) or is_mod( player.name ) or player.admin then
	   tasklist_panel_button_table.add { type = "button", caption = "New Tasks", name = "new_tasklist_assembler_button" }
	end

	tasklist_panel_button_table.add { type = "button", caption = "Hide", name = "tasklist_hide_button" }

	tasklist_panel_button_table.tasklist_hide_button.style.minimal_width = 70
	tasklist_panel_button_table.new_tasklist_assembler_button.style.font = "default-bold"
	tasklist_panel_button_table.new_tasklist_assembler_button.style.minimal_height = 38
	tasklist_panel_button_table.tasklist_hide_button.style.font = "default-bold"
	tasklist_panel_button_table.tasklist_hide_button.style.minimal_height = 38
	-- tasklist_panel_button_table.add { type = "checkbox", caption = "Show Tasklist", state = global.autoshow_tasklist_for_player[player.name], name = "auto_show_tasklist_checkbox"	}
end

local function tasklist(player)
	local frame = player.gui.left["tasklist-assembler"]
	frame = frame.table_tasklist_assembler

	global.tasklist_items = {"","","","",""}
	global.tasklist_items[1] = frame.textfield_task_1.text
	global.tasklist_items[2] = frame.textfield_task_2.text
	global.tasklist_items[3] = frame.textfield_task_3.text
	global.tasklist_items[4] = frame.textfield_task_4.text
	global.tasklist_items[5] = frame.textfield_task_5.text
	if (global.tasklist_items[5] .. global.tasklist_items[4] .. global.tasklist_items[3] .. global.tasklist_items[2] .. global.tasklist_items[1] == "") then
		return
	end

	global.tasklist_author = player.name

	local msg = player.name
	msg = msg .. " has created an updated tasklist!"

	local frame = player.gui.left["tasklist-assembler"]
	frame.destroy()

	local x = 1

	while (game.players[x] ~= nil) do

		local player = game.players[x]

		local frame = player.gui.left["tasklist-panel"]

		if (frame) then
				frame.destroy()
		end

		if (global.autoshow_tasklist_for_player[player.name] == true) then
			tasklist_show(player)
		end

		player.print(msg)

		x = x + 1
	end
end


local function tasklist_refresh()

	local x = 1

	while (game.players[x] ~= nil) do

		local player = game.players[x]

		if (player.gui.left["tasklist-panel"]) then
			local frame = player.gui.left["tasklist-panel"]
			frame = frame.tasklist_panel_table
		end
		x = x + 1
	end

end

local function tasklist_assembler(player)
	local frame = player.gui.left.add { type = "frame", name = "tasklist-assembler", caption = "" }
	local frame_table = frame.add { type = "table", name = "table_tasklist_assembler", colspan = 2 }
	frame_table.add { type = "label", caption = "Task #1:" }
	frame_table.add { type = "textfield", name = "textfield_task_1", text = global.tasklist_items[1],  }
	frame_table["textfield_task_1"].style.minimal_width = 450
	frame_table["textfield_task_1"].style.maximal_width = 450
	frame_table.add { type = "label", caption = "Task #2:" }
	frame_table.add { type = "textfield", name = "textfield_task_2", text = global.tasklist_items[2] }
	frame_table["textfield_task_2"].style.minimal_width = 450
	frame_table["textfield_task_2"].style.maximal_width = 450
	frame_table.add { type = "label", caption = "Task #3:" }
	frame_table.add { type = "textfield", name = "textfield_task_3", text = global.tasklist_items[3] }
	frame_table["textfield_task_3"].style.minimal_width = 450
	frame_table["textfield_task_3"].style.maximal_width = 450
	frame_table.add { type = "label", caption = "Task #4:" }
	frame_table.add { type = "textfield", name = "textfield_task_4", text = global.tasklist_items[4] }
	frame_table["textfield_task_4"].style.minimal_width = 450
	frame_table["textfield_task_4"].style.maximal_width = 450
	frame_table.add { type = "label", caption = "Task #5:" }
	frame_table.add { type = "textfield", name = "textfield_task_5", text = global.tasklist_items[5] }
	frame_table["textfield_task_5"].style.minimal_width = 450
	frame_table["textfield_task_5"].style.maximal_width = 450
	frame_table.add { type = "label", caption = "" }
	frame_table.add { type = "button", name = "create_new_tasklist_button", caption = "Publish" }

end

function tasklist_sync_for_new_joining_player(event)
	if not global.tasklist_items then global.tasklist_items = {"","","","",""} end
	if not global.autoshow_tasklist_for_player then global.autoshow_tasklist_for_player = {} end
	if not global.tasklist_duration_in_seconds then global.tasklist_duration_in_seconds = 99 end
	if not global.tasklist_panel_creation_time then global.tasklist_panel_creation_time = {} end

	local player = game.players[event.player_index]

	global.autoshow_tasklist_for_player[player.name] = true

	local frame = player.gui.left["tasklist-panel"]
	if (frame == nil) then
		tasklist_show(player)
	end

end

local function on_gui_click(event)
	if not (event and event.element and event.element.valid) then return end
		local player = game.players[event.element.player_index]
		local name = event.element.name

		if (name == "tasklist") then
			local frame = player.gui.left["tasklist-panel"]
			if (frame) then
				frame.destroy()
			else
				tasklist_show(player)
			end

			local frame = player.gui.left["tasklist-assembler"]
			if (frame) then
				frame.destroy()
			end
		end

		if (name == "new_tasklist_assembler_button") then
			local frame = player.gui.left["tasklist-assembler"]
			if (frame) then
				frame.destroy()
			else
				tasklist_assembler(player)
			end
		end

		if (name == "create_new_tasklist_button") then
				tasklist(player)
		end

		if (name == "tasklist_hide_button") then
			local frame = player.gui.left["tasklist-panel"]
			if (frame) then
				frame.destroy()
			end
			local frame = player.gui.left["tasklist-assembler"]
			if (frame) then
				frame.destroy()
			end
		end

		if (name == "auto_show_tasklist_checkbox") then
			global.autoshow_tasklist_for_player[player.name] = event.element.state
		end
end


Event.register(defines.events.on_gui_click, on_gui_click)
Event.register(defines.events.on_player_joined_game, create_tasklist_gui)
Event.register(defines.events.on_player_joined_game, tasklist_sync_for_new_joining_player)
