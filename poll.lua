----------------------------------------------------------------------------------------------------------------------------------------
-- Create Polls for your Factory Workers
-- by MewMew -- with some help from RedLabel, Klonan, Morcup, BrainClot
----------------------------------------------------------------------------------------------------------------------------------------

local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Event = require 'utils.event'

local polls = {}
local no_notify_players = {}

Global.register(
    {polls = polls, no_notify_players = no_notify_players},
    function(tbl)
        polls = tbl.polls
        no_notify_players = tbl.no_notify_players
    end
)

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local create_poll_button_name = Gui.uid_name()
local notify_checkbox_name = Gui.uid_name()

local create_poll_frame_name = Gui.uid_name()
local create_poll_label_name = Gui.uid_name()
local create_poll_textfield_name = Gui.uid_name()
local create_poll_close_name = Gui.uid_name()
local create_poll_confirm_name = Gui.uid_name()

local function player_joined(event)
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    if player.gui.top[main_button_name] ~= nil then
        return
    end

    player.gui.top.add {type = 'sprite-button', name = main_button_name, sprite = 'item/programmable-speaker'}
end

local function draw_main_frame(left, player)
    local frame = left.add {type = 'frame', name = main_frame_name, caption = 'Polls'}

    local bottom_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow = bottom_flow.add {type = 'flow'}
    left_flow.style.align = 'left'
    left_flow.style.horizontally_stretchable = true

    left_flow.add {type = 'button', name = main_button_name, caption = 'Close'}

    local right_flow = bottom_flow.add {type = 'flow'}
    right_flow.style.align = 'right'

    right_flow.add {type = 'button', name = create_poll_button_name, caption = 'Create Poll'}

    right_flow.add {
        type = 'checkbox',
        name = notify_checkbox_name,
        caption = 'Show Polls',
        state = not no_notify_players[player.index],
        tooltip = 'Notify me when new polls are created'
    }
end

local function toggle(event)
    local left = event.player.gui.left
    local main_frame = left[main_frame_name]

    if main_frame then
        Gui.remove_data_recursivly(main_frame)
        main_frame.destroy()

        local create_poll_frame = left[create_poll_frame_name]
        if create_poll_frame and create_poll_frame.valid then
            Gui.remove_data_recursivly(create_poll_frame)
            create_poll_frame.destroy()
        end
    else
        draw_main_frame(left, event.player)
    end
end

local function draw_create_poll_frame(event)
    local left = event.player.gui.left

    local frame = left.add {type = 'frame', name = create_poll_frame_name, caption = 'New Poll', direction = 'vertical'}

    local scroll_pane = frame.add {type = 'scroll-pane', direction = 'vertical', vertical_scroll_policy = 'always'}
    scroll_pane.style.maximal_height = 500
    scroll_pane.style.maximal_width = 400

    local list = scroll_pane.add {type = 'flow', direction = 'vertical'}
    list.style.horizontally_stretchable = true

    local question_flow = list.add {type = 'flow', direction = 'horizontal'}
    question_flow.add {type = 'label', name = create_poll_label_name, caption = 'Question'}
    local textfield = question_flow.add {type = 'textfield', name = create_poll_textfield_name}
    textfield.style.width = 600

    local bottom_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow = bottom_flow.add {type = 'flow'}
    left_flow.style.align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add {type = 'button', name = create_poll_close_name, caption = 'Close'}
    Gui.set_data(close_button, frame)

    local right_flow = bottom_flow.add {type = 'flow'}
    right_flow.style.align = 'right'

    right_flow.add {type = 'button', name = create_poll_confirm_name, caption = 'Create Poll'}
end

Event.add(defines.events.on_player_joined_game, player_joined)

Gui.on_click(main_button_name, toggle)

Gui.on_click(create_poll_button_name, draw_create_poll_frame)

Gui.on_click(
    create_poll_close_name,
    function(event)
        local element = event.element
        local frame = Gui.get_data(element)

        Gui.remove_data_recursivly(frame)
        frame.destroy()
    end
)

Gui.on_click(
    notify_checkbox_name,
    function(event)
        local player_index = event.player_index
        local checkbox = event.element

        local new_state
        if checkbox.state then
            new_state = nil
        else
            new_state = true
        end

        no_notify_players[player_index] = new_state
    end
)

--[[ local function create_poll_gui(event)
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

	local frame = player.gui.left.add { type = "frame", name = "poll-panel", direction = "vertical" }

	frame.add { type = "table", name = "poll_panel_table", column_count = 2 }

	local poll_panel_table = frame.poll_panel_table

	if not (global.poll_question == "") then

		local str = "Poll #" .. global.score_total_polls_created .. ":"
		if global.score_total_polls_created > 1 then
			local x = game.tick
			x = ((x / 60) / 60) / 60
			x = global.score_total_polls_created / x
			x = math.round(x)
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
		end
		y = y + 1
	end

	frame.add { type = "table", name = "poll_panel_button_table", column_count = 3 }
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

	while game.players[x] do

		local player = game.players[x]

		local frame = player.gui.left["poll-panel"]

		if (frame) then
				frame.destroy()
		end

		if global.autoshow_polls_for_player[player.name] then
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
	local frame_table = frame.add { type = "table", name = "table_poll_assembler", column_count = 2 }
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
			global.autoshow_polls_for_player[player.name] = not global.autoshow_polls_for_player[player.name]			
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

function on_second()
	for _, player in pairs(game.connected_players) do
		if global.poll_panel_creation_time then
			if global.poll_panel_creation_time[player.index] then
				local frame = player.gui.left["poll-panel"]
				if frame then
					local y = (game.tick - global.poll_panel_creation_time[player.index]) / 60
					local y = global.poll_duration_in_seconds - y
					y = math.round(y)
					if y <= 0 then
						frame.destroy()
						global.poll_panel_creation_time[player.index] = nil
					else
						y = "Hide (" .. y
						y = y .. ")"
						frame.poll_panel_button_table.poll_hide_button.caption = y
					end
				end
			end
		end
	end
end

Event.on_nth_tick(61, on_second)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_joined_game, create_poll_gui)
Event.add(defines.events.on_player_joined_game, poll_sync_for_new_joining_player)
 ]]
