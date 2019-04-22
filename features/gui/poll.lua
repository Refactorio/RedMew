local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Event = require 'utils.event'
local Rank = require 'features.rank_system'
local Game = require 'utils.game'
local math = require 'utils.math'
local Server = require 'features.server'
local Command = require 'utils.command'
-- local Color = require 'resources.color_presets' -- commented to avoid lint error (secondary to desync risk)
local Ranks = require 'resources.ranks'

local insert = table.insert

local default_poll_duration = 300 * 60 -- in ticks
local duration_max = 3600 -- in seconds
local duration_step = 15 -- in seconds

local duration_slider_max = duration_max / duration_step
local tick_duration_step = duration_step * 60
local inv_tick_duration_step = 1 / tick_duration_step

-- local normal_color = Color.white -- commented to avoid lint error (secondary to desync risk)
-- local focus_color = Color.dark_orange -- commented to avoid lint error (secondary to desync risk)

local polls = {}
local polls_counter = {0}
local no_notify_players = {}
local player_poll_index = {}
local player_create_poll_data = {}

Global.register(
    {
        polls = polls,
        polls_counter = polls_counter,
        no_notify_players = no_notify_players,
        player_poll_index = player_poll_index,
        player_create_poll_data = player_create_poll_data
    },
    function(tbl)
        polls = tbl.polls
        polls_counter = tbl.polls_counter
        no_notify_players = tbl.no_notify_players
        player_poll_index = tbl.player_poll_index
        player_create_poll_data = tbl.player_create_poll_data
    end
)

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local create_poll_button_name = Gui.uid_name()
local notify_checkbox_name = Gui.uid_name()

local poll_view_back_name = Gui.uid_name()
local poll_view_forward_name = Gui.uid_name()
local poll_view_vote_name = Gui.uid_name()
local poll_view_edit_name = Gui.uid_name()

local create_poll_frame_name = Gui.uid_name()
local create_poll_duration_name = Gui.uid_name()
local create_poll_label_name = Gui.uid_name()
local create_poll_question_name = Gui.uid_name()
local create_poll_answer_name = Gui.uid_name()
local create_poll_add_answer_name = Gui.uid_name()
local create_poll_delete_answer_name = Gui.uid_name()
local create_poll_close_name = Gui.uid_name()
local create_poll_clear_name = Gui.uid_name()
local create_poll_edit_name = Gui.uid_name()
local create_poll_confirm_name = Gui.uid_name()
local create_poll_delete_name = Gui.uid_name()

local function poll_id()
    local count = polls_counter[1] + 1
    polls_counter[1] = count
    return count
end

local function apply_direction_button_style(button)
    local button_style = button.style
    button_style.width = 24
    button_style.height = 24
    button_style.top_padding = 0
    button_style.bottom_padding = 0
    button_style.left_padding = 0
    button_style.right_padding = 0
    button_style.font = 'default-listbox'
end

local function apply_button_style(button)
    local button_style = button.style
    button_style.font = 'default-semibold'
    button_style.height = 26
    button_style.minimal_width = 26
    button_style.top_padding = 0
    button_style.bottom_padding = 0
    button_style.left_padding = 2
    button_style.right_padding = 2
end

local function do_remaining_time(poll, remaining_time_label)
    local end_tick = poll.end_tick
    if end_tick == -1 then
        remaining_time_label.caption = 'Endless Poll.'
        return true
    end

    local ticks = end_tick - game.tick
    if ticks < 0 then
        remaining_time_label.caption = 'Poll Finished.'
        return false
    else
        local time = math.ceil(ticks / 60)
        remaining_time_label.caption = 'Remaining Time: ' .. time
        return true
    end
end

local function send_poll_result_to_discord(poll)
    local result = {'Poll #', poll.id}

    local created_by_player = poll.created_by
    if created_by_player and created_by_player.valid then
        insert(result, ' Created by ')
        insert(result, created_by_player.name)
    end

    local edited_by_players = poll.edited_by
    if next(edited_by_players) then
        insert(result, ' Edited by ')
        for pi, _ in pairs(edited_by_players) do
            local p = game.players[pi]
            if p and p.valid then
                insert(result, p.name)
                insert(result, ', ')
            end
        end
        table.remove(result)
    end

    insert(result, '\\n**Question: ')
    insert(result, poll.question)
    insert(result, '**\\n')

    local answers = poll.answers
    local answers_count = #answers
    for i, a in pairs(answers) do
        insert(result, '[')
        insert(result, a.voted_count)
        insert(result, '] - ')
        insert(result, a.text)
        if i ~= answers_count then
            insert(result, '\\n')
        end
    end

    local message = table.concat(result)
    Server.to_discord_embed(message)
end

local function redraw_poll_viewer_content(data)
    local poll_viewer_content = data.poll_viewer_content
    local remaining_time_label = data.remaining_time_label
    local poll_index = data.poll_index
    local player = poll_viewer_content.gui.player

    data.vote_buttons = nil
    Gui.remove_data_recursively(poll_viewer_content)
    poll_viewer_content.clear()

    local poll = polls[poll_index]
    if not poll then
        return
    end

    local answers = poll.answers
    local voters = poll.voters

    local tooltips = {}
    for _, a in pairs(answers) do
        tooltips[a] = {}
    end

    for player_index, answer in pairs(voters) do
        local p = Game.get_player_by_index(player_index)
        insert(tooltips[answer], p.name)
    end

    for a, t in pairs(tooltips) do
        if #t == 0 then
            tooltips[a] = ''
        else
            tooltips[a] = table.concat(t, ', ')
        end
    end

    local created_by_player = poll.created_by
    local created_by_text
    if created_by_player and created_by_player.valid then
        created_by_text = ' Created by ' .. created_by_player.name
    else
        created_by_text = ''
    end

    local top_flow = poll_viewer_content.add {type = 'flow', direction = 'vertical'}
    top_flow.add {type = 'label', caption = table.concat {'Poll #', poll.id, created_by_text}}

    local edited_by_players = poll.edited_by
    if next(edited_by_players) then
        local edit_names = {'Edited by '}
        for pi, _ in pairs(edited_by_players) do
            local p = Game.get_player_by_index(pi)
            if p and p.valid then
                insert(edit_names, p.name)
                insert(edit_names, ', ')
            end
        end

        table.remove(edit_names)
        local edit_text = table.concat(edit_names)

        local top_flow_label = top_flow.add {type = 'label', caption = edit_text, tooltip = edit_text}
        top_flow_label.style.single_line = false
        top_flow_label.style.horizontally_stretchable = false
    end

    local poll_enabled = do_remaining_time(poll, remaining_time_label)

    local question_flow = poll_viewer_content.add {type = 'table', column_count = 2}

    if Rank.equal_or_greater_than(player.name, Ranks.regular) then
        local edit_button =
            question_flow.add {
            type = 'sprite-button',
            name = poll_view_edit_name,
            sprite = 'utility/rename_icon_normal',
            tooltip = 'Edit Poll.'
        }

        local edit_button_style = edit_button.style
        edit_button_style.width = 26
        edit_button_style.height = 26
    end

    local question_label = question_flow.add {type = 'label', caption = poll.question}
    question_label.style.height = 32
    -- question_label.style.font_color = focus_color -- commented to avoid desync risk
    question_label.style.font = 'default-listbox'

    local grid = poll_viewer_content.add {type = 'table', column_count = 2}

    -- local answer = voters[player.index] -- commented to avoid lint error (secondary to desync risk)
    local vote_buttons = {}
    for i, a in pairs(answers) do
        local vote_button_flow = grid.add {type = 'flow'}
        local vote_button =
            vote_button_flow.add {
            type = 'button',
            name = poll_view_vote_name,
            caption = a.voted_count,
            enabled = poll_enabled
        }

        local tooltip = tooltips[a]
        if tooltip ~= '' then
            vote_button.tooltip = tooltip
        end

        local vote_button_style = vote_button.style
        vote_button_style.height = 24
        vote_button_style.width = 26
        vote_button_style.font = 'default-small'
        vote_button_style.top_padding = 0
        vote_button_style.bottom_padding = 0
        vote_button_style.left_padding = 0
        vote_button_style.right_padding = 0

        -- if answer == a then -- block commented to avoid desync risk
        --     vote_button_style.font_color = focus_color
        --     vote_button_style.disabled_font_color = focus_color
        -- end

        Gui.set_data(vote_button, {answer = a, data = data})
        vote_buttons[i] = vote_button

        local label = grid.add {type = 'label', caption = a.text}
        label.style.height = 24
    end

    data.vote_buttons = vote_buttons
end

local function update_poll_viewer(data)
    local back_button = data.back_button
    local forward_button = data.forward_button
    local poll_index_label = data.poll_index_label
    local poll_index = data.poll_index

    if #polls == 0 then
        poll_index = 0
    else
        poll_index = math.clamp(poll_index, 1, #polls)
    end

    data.poll_index = poll_index

    if poll_index == 0 then
        poll_index_label.caption = 'No Polls'
    else
        poll_index_label.caption = table.concat {'Poll ', poll_index, ' / ', #polls}
    end

    back_button.enabled = poll_index > 1
    forward_button.enabled = poll_index < #polls

    redraw_poll_viewer_content(data)
end

local function draw_main_frame(left, player)
    local frame = left.add {type = 'frame', name = main_frame_name, caption = 'Polls', direction = 'vertical'}
    frame.style.maximal_width = 320

    local poll_viewer_top_flow = frame.add {type = 'table', column_count = 5}
    poll_viewer_top_flow.style.horizontal_spacing = 0

    local back_button = poll_viewer_top_flow.add {type = 'button', name = poll_view_back_name, caption = '◀'}
    apply_direction_button_style(back_button)

    local forward_button = poll_viewer_top_flow.add {type = 'button', name = poll_view_forward_name, caption = '▶'}
    apply_direction_button_style(forward_button)

    local poll_index_label = poll_viewer_top_flow.add {type = 'label'}
    poll_index_label.style.left_padding = 8

    local spacer = poll_viewer_top_flow.add {type = 'flow'}
    spacer.style.horizontally_stretchable = true

    local remaining_time_label = poll_viewer_top_flow.add {type = 'label'}

    local poll_viewer_content = frame.add {type = 'scroll-pane'}
    poll_viewer_content.style.maximal_height = 250
    poll_viewer_content.style.width = 300

    local poll_index = player_poll_index[player.index] or #polls

    local data = {
        back_button = back_button,
        forward_button = forward_button,
        poll_index_label = poll_index_label,
        poll_viewer_content = poll_viewer_content,
        remaining_time_label = remaining_time_label,
        poll_index = poll_index
    }

    Gui.set_data(frame, data)
    Gui.set_data(back_button, data)
    Gui.set_data(forward_button, data)

    update_poll_viewer(data)

    frame.add {
        type = 'checkbox',
        name = notify_checkbox_name,
        caption = 'Notify me about polls.',
        state = not no_notify_players[player.index],
        tooltip = 'Receive a message when new polls are created and popup the poll.'
    }

    local bottom_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow = bottom_flow.add {type = 'flow'}
    left_flow.style.horizontal_align  = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add {type = 'button', name = main_button_name, caption = 'Close'}
    apply_button_style(close_button)

    local right_flow = bottom_flow.add {type = 'flow'}
    right_flow.style.horizontal_align  = 'right'

    if Rank.equal_or_greater_than(player.name, Ranks.regular) then
        local create_poll_button =
            right_flow.add {type = 'button', name = create_poll_button_name, caption = 'Create Poll'}
        apply_button_style(create_poll_button)
    else
        local create_poll_button =
            right_flow.add {
            type = 'button',
            caption = 'Create Poll',
            enabled = false,
            tooltip = 'Sorry, you need to be a regular to create polls.'
        }
        apply_button_style(create_poll_button)
    end
end

local function remove_create_poll_frame(create_poll_frame, player_index)
    local data = Gui.get_data(create_poll_frame)

    data.edit_mode = nil
    player_create_poll_data[player_index] = data

    Gui.remove_data_recursively(create_poll_frame)
    create_poll_frame.destroy()
end

local function remove_main_frame(main_frame, left, player)
    local player_index = player.index
    local data = Gui.get_data(main_frame)
    player_poll_index[player_index] = data.poll_index

    Gui.remove_data_recursively(main_frame)
    main_frame.destroy()

    local create_poll_frame = left[create_poll_frame_name]
    if create_poll_frame and create_poll_frame.valid then
        remove_create_poll_frame(create_poll_frame, player_index)
    end
end

local function toggle(event)
    local left = event.player.gui.left
    local main_frame = left[main_frame_name]

    if main_frame then
        remove_main_frame(main_frame, left, event.player)
    else
        draw_main_frame(left, event.player)
    end
end

local function update_duration(slider)
    local slider_data = Gui.get_data(slider)
    local label = slider_data.duration_label
    local value = slider.slider_value

    value = math.floor(value)

    slider_data.data.duration = value * tick_duration_step

    if value == 0 then
        label.caption = 'Endless Poll.'
    else
        label.caption = value * duration_step .. ' seconds.'
    end
end

local function redraw_create_poll_content(data)
    local grid = data.grid
    local answers = data.answers

    Gui.remove_data_recursively(grid)
    grid.clear()

    grid.add {type = 'flow'}
    grid.add {
        type = 'label',
        caption = 'Duration:',
        tooltip = 'Pro tip: Use mouse wheel or arrow keys for more fine control.'
    }

    local duration_flow = grid.add {type = 'flow', direction = 'horizontal'}
    local duration_slider =
        duration_flow.add {
        type = 'slider',
        name = create_poll_duration_name,
        minimum_value = 0,
        maximum_value = duration_slider_max,
        value = math.floor(data.duration * inv_tick_duration_step)
    }
    duration_slider.style.width = 100

    data.duration_slider = duration_slider

    local duration_label = duration_flow.add {type = 'label'}

    Gui.set_data(duration_slider, {duration_label = duration_label, data = data})

    update_duration(duration_slider)

    grid.add {type = 'flow'}
    local question_label =
        grid.add({type = 'flow'}).add {type = 'label', name = create_poll_label_name, caption = 'Question:'}

    local question_textfield =
        grid.add({type = 'flow'}).add {type = 'textfield', name = create_poll_question_name, text = data.question}
    question_textfield.style.width = 175

    Gui.set_data(question_label, question_textfield)
    Gui.set_data(question_textfield, data)

    local edit_mode = data.edit_mode
    for count, answer in pairs(answers) do
        local delete_flow = grid.add {type = 'flow'}

        local delete_button
        if edit_mode or count ~= 1 then
            delete_button =
                delete_flow.add {
                type = 'sprite-button',
                name = create_poll_delete_answer_name,
                sprite = 'utility/remove',
                tooltip = 'Delete answer field.'
            }
            delete_button.style.height = 26
            delete_button.style.width = 26
        else
            delete_flow.style.height = 26
            delete_flow.style.width = 26
        end

        local label_flow = grid.add {type = 'flow'}
        local label =
            label_flow.add {
            type = 'label',
            name = create_poll_label_name,
            caption = table.concat {'Answer #', count, ':'}
        }

        local textfield_flow = grid.add {type = 'flow'}

        local textfield = textfield_flow.add {type = 'textfield', name = create_poll_answer_name, text = answer.text}
        textfield.style.width = 175
        Gui.set_data(textfield, {answers = answers, count = count})

        if delete_button then
            Gui.set_data(delete_button, {data = data, count = count})
        end

        Gui.set_data(label, textfield)
    end
end

local function draw_create_poll_frame(parent, player, previous_data)
    previous_data = previous_data or player_create_poll_data[player.index]

    local edit_mode
    local question
    local answers
    local duration
    local title_text
    local confirm_text
    local confirm_name
    if previous_data then
        edit_mode = previous_data.edit_mode

        question = previous_data.question

        answers = {}
        for i, a in pairs(previous_data.answers) do
            answers[i] = {text = a.text, source = a}
        end

        duration = previous_data.duration
    else
        question = ''
        answers = {{text = ''}, {text = ''}, {text = ''}}
        duration = default_poll_duration
    end

    if edit_mode then
        title_text = 'Edit Poll #' .. previous_data.id
        confirm_text = 'Edit Poll'
        confirm_name = create_poll_edit_name
    else
        title_text = 'New Poll'
        confirm_text = 'Create Poll'
        confirm_name = create_poll_confirm_name
    end

    local frame =
        parent.add {type = 'frame', name = create_poll_frame_name, caption = title_text, direction = 'vertical'}
    frame.style.maximal_width = 320

    local scroll_pane = frame.add {type = 'scroll-pane', vertical_scroll_policy = 'always'}
    scroll_pane.style.maximal_height = 250
    scroll_pane.style.maximal_width = 300

    local grid = scroll_pane.add {type = 'table', column_count = 3}

    local data = {
        frame = frame,
        grid = grid,
        question = question,
        answers = answers,
        duration = duration,
        previous_data = previous_data,
        edit_mode = edit_mode
    }

    Gui.set_data(frame, data)

    redraw_create_poll_content(data)

    local add_answer_button =
        scroll_pane.add {
        type = 'button',
        name = create_poll_add_answer_name,
        caption = 'Add Answer'
    }
    apply_button_style(add_answer_button)
    Gui.set_data(add_answer_button, data)

    local bottom_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow = bottom_flow.add {type = 'flow'}
    left_flow.style.horizontal_align  = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add {type = 'button', name = create_poll_close_name, caption = 'Close'}
    apply_button_style(close_button)
    Gui.set_data(close_button, frame)

    local clear_button = left_flow.add {type = 'button', name = create_poll_clear_name, caption = 'Clear'}
    apply_button_style(clear_button)
    Gui.set_data(clear_button, data)

    local right_flow = bottom_flow.add {type = 'flow'}
    right_flow.style.horizontal_align  = 'right'

    if edit_mode then
        local delete_button = right_flow.add {type = 'button', name = create_poll_delete_name, caption = 'Delete'}
        apply_button_style(delete_button)
        Gui.set_data(delete_button, data)
    end

    local confirm_button = right_flow.add {type = 'button', name = confirm_name, caption = confirm_text}
    apply_button_style(confirm_button)
    Gui.set_data(confirm_button, data)
end

local function show_new_poll(poll_data)
    local message =
        table.concat {poll_data.created_by.name, ' has created a new Poll #', poll_data.id, ': ', poll_data.question}

    for _, p in pairs(game.connected_players) do
        local left = p.gui.left
        local frame = left[main_frame_name]
        if no_notify_players[p.index] then
            if frame and frame.valid then
                local data = Gui.get_data(frame)
                update_poll_viewer(data)
            end
        else
            p.print(message)

            if frame and frame.valid then
                local data = Gui.get_data(frame)
                data.poll_index = #polls
                update_poll_viewer(data)
            else
                player_poll_index[p.index] = nil
                draw_main_frame(left, p)
            end
        end
    end
end

local function create_poll(event)
    local player = event.player
    local data = Gui.get_data(event.element)

    local frame = data.frame
    local question = data.question

    if not question:find('%S') then
        event.player.print('Sorry, the poll needs a question.')
        return
    end

    local answers = {}
    for _, a in pairs(data.answers) do
        local text = a.text
        if text:find('%S') then
            local index = #answers + 1
            answers[index] = {text = text, index = index, voted_count = 0}
        end
    end

    if #answers < 1 then
        player.print('Sorry, the poll needs at least one answer.')
        return
    end

    player_create_poll_data[player.index] = nil

    local tick = game.tick
    local duration = data.duration
    local end_tick

    if duration == 0 then
        end_tick = -1
    else
        end_tick = tick + duration
    end

    local poll_data = {
        id = poll_id(),
        question = question,
        answers = answers,
        voters = {},
        start_tick = tick,
        end_tick = end_tick,
        duration = duration,
        created_by = event.player,
        edited_by = {}
    }

    insert(polls, poll_data)

    show_new_poll(poll_data)
    send_poll_result_to_discord(poll_data)

    Gui.remove_data_recursively(frame)
    frame.destroy()
end

local function update_vote(voters, answer, direction)
    local count = answer.voted_count + direction
    answer.voted_count = count

    local tooltip = {}
    for pi, a in pairs(voters) do
        if a == answer then
            local player = Game.get_player_by_index(pi)
            insert(tooltip, player.name)
        end
    end

    return tostring(count), table.concat(tooltip, ', ')
end

local function vote(event)
    local player_index = event.player_index
    local voted_button = event.element
    local button_data = Gui.get_data(voted_button)
    local answer = button_data.answer

    local poll_index = button_data.data.poll_index
    local poll = polls[poll_index]

    local voters = poll.voters

    local previous_vote_answer = voters[player_index]
    if previous_vote_answer == answer then
        return
    end

    local vote_index = answer.index

    voters[player_index] = answer

    local previous_vote_button_count
    local previous_vote_button_tooltip
    local previous_vote_index
    if previous_vote_answer then
        previous_vote_button_count, previous_vote_button_tooltip = update_vote(voters, previous_vote_answer, -1)
        previous_vote_index = previous_vote_answer.index
    end

    local vote_button_count, vote_button_tooltip = update_vote(voters, answer, 1)

    for _, p in pairs(game.connected_players) do
        local frame = p.gui.left[main_frame_name]
        if frame and frame.valid then
            local data = Gui.get_data(frame)

            if data.poll_index == poll_index then
                local vote_buttons = data.vote_buttons
                if previous_vote_answer then
                    local vote_button = vote_buttons[previous_vote_index]
                    vote_button.caption = previous_vote_button_count
                    vote_button.tooltip = previous_vote_button_tooltip

                    -- if p.index == player_index then
                        -- local vote_button_style = vote_button.style -- block commented to avoid desync risk
                        -- vote_button_style.font_color = normal_color
                        -- vote_button_style.disabled_font_color = normal_color
                    -- end
                end

                local vote_button = vote_buttons[vote_index]
                vote_button.caption = vote_button_count
                vote_button.tooltip = vote_button_tooltip

                -- if p.index == player_index then -- block commented to avoid desync risk
                --     local vote_button_style = vote_button.style
                --     vote_button_style.font_color = focus_color
                --     vote_button_style.disabled_font_color = focus_color
                -- end
            end
        end
    end
end

local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    local gui = player.gui
    if gui.top[main_button_name] ~= nil then
        local frame = gui.left[main_frame_name]
        if frame and frame.valid then
            local data = Gui.get_data(frame)
            update_poll_viewer(data)
        end
    else
        gui.top.add {type = 'sprite-button', name = main_button_name, sprite = 'item/programmable-speaker'}
    end
end

local function tick()
    for _, p in pairs(game.connected_players) do
        local frame = p.gui.left[main_frame_name]
        if frame and frame.valid then
            local data = Gui.get_data(frame)
            local poll = polls[data.poll_index]
            if poll then
                local poll_enabled = do_remaining_time(poll, data.remaining_time_label)

                if not poll_enabled then
                    for _, v in pairs(data.vote_buttons) do
                        v.enabled = poll_enabled
                    end
                end
            end
        end
    end
end

Event.add(defines.events.on_player_joined_game, player_joined)
Event.on_nth_tick(60, tick)

Gui.on_click(main_button_name, toggle)

Gui.on_click(
    create_poll_button_name,
    function(event)
        local player = event.player
        local left = player.gui.left
        local frame = left[create_poll_frame_name]
        if frame and frame.valid then
            remove_create_poll_frame(frame, player.index)
        else
            draw_create_poll_frame(left, player)
        end
    end
)

Gui.on_click(
    poll_view_edit_name,
    function(event)
        local player = event.player
        local left = player.gui.left
        local frame = left[create_poll_frame_name]

        if frame and frame.valid then
            Gui.remove_data_recursively(frame)
            frame.destroy()
        end

        local main_frame = left[main_frame_name]
        local frame_data = Gui.get_data(main_frame)
        local poll = polls[frame_data.poll_index]

        poll.edit_mode = true
        draw_create_poll_frame(left, player, poll)
    end
)

Gui.on_value_changed(
    create_poll_duration_name,
    function(event)
        update_duration(event.element)
    end
)

Gui.on_click(
    create_poll_delete_answer_name,
    function(event)
        local button_data = Gui.get_data(event.element)
        local data = button_data.data

        table.remove(data.answers, button_data.count)
        redraw_create_poll_content(data)
    end
)

Gui.on_click(
    create_poll_label_name,
    function(event)
        local textfield = Gui.get_data(event.element)
        textfield.focus()
    end
)

Gui.on_text_changed(
    create_poll_question_name,
    function(event)
        local textfield = event.element
        local data = Gui.get_data(textfield)

        data.question = textfield.text
    end
)

Gui.on_text_changed(
    create_poll_answer_name,
    function(event)
        local textfield = event.element
        local data = Gui.get_data(textfield)

        data.answers[data.count].text = textfield.text
    end
)

Gui.on_click(
    create_poll_add_answer_name,
    function(event)
        local data = Gui.get_data(event.element)

        insert(data.answers, {text = ''})
        redraw_create_poll_content(data)
    end
)

Gui.on_click(
    create_poll_close_name,
    function(event)
        local frame = Gui.get_data(event.element)
        remove_create_poll_frame(frame, event.player_index)
    end
)

Gui.on_click(
    create_poll_clear_name,
    function(event)
        local data = Gui.get_data(event.element)

        local slider = data.duration_slider
        slider.slider_value = math.floor(default_poll_duration * inv_tick_duration_step)
        update_duration(slider)

        data.question = ''

        local answers = data.answers
        for i = 1, #answers do
            answers[i].text = ''
        end

        redraw_create_poll_content(data)
    end
)

Gui.on_click(create_poll_confirm_name, create_poll)

Gui.on_click(
    create_poll_delete_name,
    function(event)
        local player = event.player
        local data = Gui.get_data(event.element)
        local frame = data.frame
        local poll = data.previous_data

        Gui.remove_data_recursively(frame)
        frame.destroy()

        player_create_poll_data[player.index] = nil

        local removed_index
        for i, p in pairs(polls) do
            if p == poll then
                table.remove(polls, i)
                removed_index = i
                break
            end
        end

        if not removed_index then
            return
        end

        local message = table.concat {player.name, ' has deleted Poll #', poll.id, ': ', poll.question}

        for _, p in pairs(game.connected_players) do
            if not no_notify_players[p.index] then
                p.print(message)
            end

            local main_frame = p.gui.left[main_frame_name]
            if main_frame and main_frame.valid then
                local main_frame_data = Gui.get_data(main_frame)
                local poll_index = main_frame_data.poll_index

                if removed_index < poll_index then
                    main_frame_data.poll_index = poll_index - 1
                end

                update_poll_viewer(main_frame_data)
            end
        end
    end
)

Gui.on_click(
    create_poll_edit_name,
    function(event)
        local player = event.player
        local data = Gui.get_data(event.element)
        local frame = data.frame
        local poll = data.previous_data

        local new_question = data.question
        if not new_question:find('%S') then
            player.print('Sorry, the poll needs a question.')
            return
        end

        local new_answer_set = {}
        local new_answers = {}
        for _, a in pairs(data.answers) do
            if a.text:find('%S') then
                local source = a.source
                local index = #new_answers + 1
                if source then
                    new_answer_set[source] = a
                    source.text = a.text
                    source.index = index
                    new_answers[index] = source
                else
                    new_answers[index] = {text = a.text, index = index, voted_count = 0}
                end
            end
        end

        if not next(new_answers) then
            player.print('Sorry, the poll needs at least one answer.')
            return
        end

        Gui.remove_data_recursively(frame)
        frame.destroy()

        local player_index = player.index

        player_create_poll_data[player_index] = nil

        local old_answers = poll.answers
        local voters = poll.voters
        for _, a in pairs(old_answers) do
            if not new_answer_set[a] then
                for pi, a2 in pairs(voters) do
                    if a == a2 then
                        voters[pi] = nil
                    end
                end
            end
        end

        poll.question = new_question
        poll.answers = new_answers
        poll.edited_by[player_index] = true

        local start_tick = game.tick
        local duration = data.duration
        local end_tick

        if duration == 0 then
            end_tick = -1
        else
            end_tick = start_tick + duration
        end

        poll.start_tick = start_tick
        poll.end_tick = end_tick
        poll.duration = duration

        local poll_index
        for i, p in pairs(polls) do
            if poll == p then
                poll_index = i
                break
            end
        end

        if not poll_index then
            insert(polls, poll)
            poll_index = #polls
        end

        local message = table.concat {player.name, ' has edited Poll #', poll.id, ': ', poll.question}

        for _, p in pairs(game.connected_players) do
            local main_frame = p.gui.left[main_frame_name]

            if no_notify_players[p.index] then
                if main_frame and main_frame.valid then
                    local main_frame_data = Gui.get_data(main_frame)
                    update_poll_viewer(main_frame_data)
                end
            else
                p.print(message)
                if main_frame and main_frame.valid then
                    local main_frame_data = Gui.get_data(main_frame)
                    main_frame_data.poll_index = poll_index
                    update_poll_viewer(main_frame_data)
                else
                    draw_main_frame(p.gui.left, p)
                end
            end
        end
    end
)

Gui.on_checked_state_changed(
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

local function do_direction(event, sign)
    local count
    if event.shift then
        count = #polls
    else
        local button = event.button
        if button == defines.mouse_button_type.right then
            count = 5
        else
            count = 1
        end
    end

    count = count * sign

    local data = Gui.get_data(event.element)
    data.poll_index = data.poll_index + count
    update_poll_viewer(data)
end

Gui.on_click(
    poll_view_back_name,
    function(event)
        do_direction(event, -1)
    end
)

Gui.on_click(
    poll_view_forward_name,
    function(event)
        do_direction(event, 1)
    end
)

Gui.on_click(poll_view_vote_name, vote)

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

local Class = {}

function Class.validate(data)
    if type(data) ~= 'table' then
        return false, 'argument must be of type table'
    end

    local question = data.question
    if type(question) ~= 'string' or question == '' then
        return false, 'field question must be a non empty string.'
    end

    local answers = data.answers
    if type(answers) ~= 'table' then
        return false, 'answers field must be an array.'
    end

    if #answers == 0 then
        return false, 'answer array must contain at least one entry.'
    end

    for _, a in pairs(answers) do
        if type(a) ~= 'string' or a == '' then
            return false, 'answers must be a non empty string.'
        end
    end

    local duration = data.duration
    local duration_type = type(duration)
    if duration_type == 'number' then
        if duration < 0 then
            return false, 'duration cannot be negative, set duration to 0 for endless poll.'
        end
    elseif duration_type ~= 'nil' then
        return false, 'duration must be of type number or nil'
    end

    return true
end

function Class.poll(data)
    local suc, error = Class.validate(data)
    if not suc then
        return false, error
    end

    local answers = {}
    for index, a in pairs(data.answers) do
        if a ~= '' then
            insert(answers, {text = a, index = index, voted_count = 0})
        end
    end

    local duration = data.duration
    if duration then
        duration = duration * 60
    else
        duration = default_poll_duration
    end

    local start_tick = game.tick
    local end_tick
    if duration == 0 then
        end_tick = -1
    else
        end_tick = start_tick + duration
    end

    local id = poll_id()

    local poll_data = {
        id = id,
        question = data.question,
        answers = answers,
        voters = {},
        start_tick = start_tick,
        end_tick = end_tick,
        duration = duration,
        created_by = game.player or {name = '<server>', valid = true},
        edited_by = {}
    }

    insert(polls, poll_data)

    show_new_poll(poll_data)
    send_poll_result_to_discord(poll_data)

    return true, id
end

function Class.poll_result(id)
    if type(id) ~= 'number' then
        return 'poll-id must be a number'
    end

    for _, poll_data in pairs(polls) do
        if poll_data.id == id then
            local result = {'Question: ', poll_data.question, ' Answers: '}
            local answers = poll_data.answers
            local answers_count = #answers
            for i, a in pairs(answers) do
                insert(result, '( [')
                insert(result, a.voted_count)
                insert(result, '] - ')
                insert(result, a.text)
                insert(result, ' )')
                if i ~= answers_count then
                    insert(result, ', ')
                end
            end

            return table.concat(result)
        end
    end

    return table.concat {'poll #', id, ' not found'}
end

local function poll_command(args)
    local param = args.poll
    param = 'return ' .. param

    local func, error = loadstring(param)
    if not func then
        Game.player_print(error)
        return
    end

    local suc, result = Class.poll(func())
    if not suc then
        Game.player_print(result)
    else
        Game.player_print(table.concat {'Poll #', result, ' successfully created.'})
    end
end

local function poll_result_command(args)
    local id = tonumber(args.poll)
    local result = Class.poll_result(id)
    Game.player_print(result)
end

function Class.send_poll_result_to_discord(id)
    if type(id) ~= 'number' then
        Server.to_discord_embed('poll-id must be a number')
        return
    end

    for _, poll_data in pairs(polls) do
        if poll_data.id == id then
            send_poll_result_to_discord(poll_data)
            return
        end
    end

    local message = table.concat {'poll #', id, ' not found'}
    Server.to_discord_embed(message)
end

Command.add(
    'poll',
    {
        description = {'command_description.poll'},
        arguments = {'poll'},
        required_rank = Ranks.regular,
        allowed_by_server = true,
        custom_help_text = {'command_custom_help.poll'},
        log_command = true,
        capture_excess_arguments = true
    },
    poll_command
)

Command.add(
    'poll-result',
    {
        description = {'command_description.poll_result'},
        arguments = {'poll'},
        allowed_by_server = true
    },
    poll_result_command
)

return Class
