local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Event = require 'utils.event'
local UserGroup = require 'user_groups'

local default_poll_duration = 300 * 60
local duration_step = 5
local tick_duration_step = duration_step * 60
local inv_tick_duration_step = 1 / tick_duration_step

local normal_color = {r = 1, g = 1, b = 1}
local focus_color = {r = 1, g = 0.55, b = 0.1}

local polls = {}
local polls_counter = {0}
local no_notify_players = {}
local player_poll_data = {}
local player_poll_index = {}

Global.register(
    {
        polls = polls,
        polls_counter = polls_counter,
        no_notify_players = no_notify_players,
        player_poll_data = player_poll_data,
        player_poll_index = player_poll_index
    },
    function(tbl)
        polls = tbl.polls
        polls_counter = tbl.polls_counter
        no_notify_players = tbl.no_notify_players
        player_poll_data = tbl.player_poll_data
        player_poll_index = tbl.player_poll_index
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

local function redraw_poll_viewer_content(data)
    local poll_viewer_content = data.poll_viewer_content
    local poll_index = data.poll_index
    local player = poll_viewer_content.gui.player

    data.remaining_time_label = nil
    data.vote_buttons = nil
    Gui.remove_data_recursivly(poll_viewer_content)
    poll_viewer_content.clear()

    local poll = polls[poll_index]
    if not poll then
        return
    end

    local answers = poll.answers
    local voters = poll.voters

    local tooltips = {}
    for i = 1, #answers do
        tooltips[i] = {}
    end

    for player_index, vote_index in pairs(voters) do
        local p = game.players[player_index]
        table.insert(tooltips[vote_index], p.name)
    end

    for i = 1, #tooltips do
        local t = tooltips[i]
        if #t == 0 then
            tooltips[i] = ''
        else
            tooltips[i] = table.concat(t, ', ')
        end
    end

    local created_by_player = poll.created_by
    local created_by_text
    if created_by_player and created_by_player.valid then
        created_by_text = ' Created by ' .. created_by_player.name
    else
        created_by_text = ''
    end

    local top_flow = poll_viewer_content.add {type = 'flow', direction = 'horizontal'}
    top_flow.add {type = 'label', caption = 'Poll #' .. poll.id .. created_by_text}

    local remaining_time_label = poll_viewer_content.add {type = 'label'}
    data.remaining_time_label = remaining_time_label

    local poll_enabled = do_remaining_time(poll, remaining_time_label)

    local question_flow = poll_viewer_content.add {type = 'table', column_count = 2}

    if player.admin or UserGroup.is_regular(player.name) then
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
    question_label.style.font_color = focus_color
    question_label.style.font = 'default-listbox'

    local grid = poll_viewer_content.add {type = 'table', column_count = 2}

    local voted_index = voters[player.index]
    local vote_buttons = {}
    for i, a in ipairs(answers) do
        local vote_button =
            grid.add({type = 'flow'}).add {
            type = 'button',
            name = poll_view_vote_name,
            caption = a.voted_count,
            enabled = poll_enabled
        }

        local tooltip = tooltips[i]
        if tooltip ~= '' then
            vote_button.tooltip = tooltip
        end

        vote_button.style.height = 24
        vote_button.style.font = 'default-small'
        vote_button.style.top_padding = 0
        vote_button.style.bottom_padding = 0

        if voted_index == i then
            vote_button.style.font_color = focus_color
        end

        Gui.set_data(vote_button, {vote_index = i, data = data})
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
        poll_index_label.caption = 'Poll ' .. poll_index .. ' / ' .. #polls
    end

    back_button.enabled = poll_index > 1
    forward_button.enabled = poll_index < #polls

    redraw_poll_viewer_content(data)
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

local function draw_main_frame(left, player)
    local frame = left.add {type = 'frame', name = main_frame_name, caption = 'Polls', direction = 'vertical'}

    local poll_viewer_top_flow = frame.add {type = 'table', column_count = 3}
    poll_viewer_top_flow.style.horizontal_spacing = 0

    local back_button = poll_viewer_top_flow.add {type = 'button', name = poll_view_back_name, caption = '◀'}
    apply_direction_button_style(back_button)

    local forward_button = poll_viewer_top_flow.add {type = 'button', name = poll_view_forward_name, caption = '▶'}
    apply_direction_button_style(forward_button)

    local poll_index_label = poll_viewer_top_flow.add {type = 'label'}
    poll_index_label.style.left_padding = 8

    local poll_viewer_content = frame.add {type = 'scroll-pane'}
    poll_viewer_content.style.maximal_height = 250
    poll_viewer_content.style.width = 300

    local poll_index = player_poll_index[player.index] or #polls

    local data = {
        back_button = back_button,
        forward_button = forward_button,
        poll_index_label = poll_index_label,
        poll_viewer_content = poll_viewer_content,
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
    left_flow.style.align = 'left'
    left_flow.style.horizontally_stretchable = true

    left_flow.add {type = 'button', name = main_button_name, caption = 'Close'}

    local right_flow = bottom_flow.add {type = 'flow'}
    right_flow.style.align = 'right'

    if player.admin or UserGroup.is_regular(player.name) then
        right_flow.add {type = 'button', name = create_poll_button_name, caption = 'Create Poll'}
    else
        right_flow.add {
            type = 'button',
            caption = 'Create Poll',
            enabled = false,
            tooltip = 'Sorry, you need to be a regular to create polls.'
        }
    end
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

    Gui.remove_data_recursivly(grid)
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
        maximum_value = 720,
        value = math.floor(data.duration * inv_tick_duration_step)
    }
    duration_slider.style.width = 100

    local duration_label = duration_flow.add {type = 'label'}

    Gui.set_data(duration_slider, {duration_label = duration_label, data = data})

    update_duration(duration_slider)

    grid.add {type = 'flow'}
    local question_label =
        grid.add({type = 'flow'}).add {type = 'label', name = create_poll_label_name, caption = 'Question:'}

    local question_textfield =
        grid.add({type = 'flow'}).add {type = 'textfield', name = create_poll_question_name, text = data.question}
    question_textfield.style.width = 180

    Gui.set_data(question_label, question_textfield)
    Gui.set_data(question_textfield, data)

    for count, answer in ipairs(answers) do
        local delete_flow = grid.add {type = 'flow'}

        local delete_button
        if count ~= 1 then
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
            caption = 'Answer #' .. count .. ':'
        }

        local textfield_flow = grid.add {type = 'flow'}

        local textfield = textfield_flow.add {type = 'textfield', name = create_poll_answer_name, text = answer.text}
        textfield.style.width = 200
        Gui.set_data(textfield, {answers = answers, count = count})

        if delete_button then
            Gui.set_data(delete_button, {data = data, count = count})
        end

        Gui.set_data(label, textfield)
    end
end

local function draw_create_poll_frame(parent, previous_data)
    local question
    local answers
    local duration
    local title_text
    local confirm_text
    local confirm_name
    if previous_data then
        question = previous_data.question

        answers = {}
        for i, a in ipairs(previous_data.answers) do
            answers[i] = {text = a.text, source = a}
        end

        duration = previous_data.duration

        title_text = 'Edit Poll'
        confirm_text = 'Edit Poll'
        confirm_name = create_poll_edit_name
    else
        question = ''
        answers = {{text = ''}, {text = ''}, {text = ''}}
        duration = default_poll_duration

        title_text = 'New Poll'
        confirm_text = 'Create Poll'
        confirm_name = create_poll_confirm_name
    end

    local frame =
        parent.add {type = 'frame', name = create_poll_frame_name, caption = title_text, direction = 'vertical'}

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
        previous_data = previous_data
    }

    redraw_create_poll_content(data)

    local add_answer_button =
        scroll_pane.add {type = 'button', name = create_poll_add_answer_name, caption = 'Add Answer'}
    Gui.set_data(add_answer_button, data)

    local bottom_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow = bottom_flow.add {type = 'flow'}
    left_flow.style.align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add {type = 'button', name = create_poll_close_name, caption = 'Close'}
    Gui.set_data(close_button, frame)

    local clear_button = left_flow.add {type = 'button', name = create_poll_clear_name, caption = 'Clear'}
    Gui.set_data(clear_button, data)

    local right_flow = bottom_flow.add {type = 'flow'}
    right_flow.style.align = 'right'

    if previous_data then
        local delete_button = right_flow.add {type = 'button', name = create_poll_delete_name, caption = 'Delete'}
        Gui.set_data(delete_button, data)
    end

    local confirm_button = right_flow.add {type = 'button', name = confirm_name, caption = confirm_text}
    Gui.set_data(confirm_button, data)
end

local function show_new_poll(poll_data)
    for _, p in ipairs(game.connected_players) do
        local left = p.gui.left
        local frame = left[main_frame_name]
        if not no_notify_players[p.index] then
            p.print(
                poll_data.created_by.name .. ' has created a new Poll #' .. poll_data.id .. ': ' .. poll_data.question
            )

            if frame and frame.valid then
                local data = Gui.get_data(frame)
                data.poll_index = #polls
                update_poll_viewer(data)
            else
                draw_main_frame(left, p)
            end
        else
            if frame and frame.valid then
                local data = Gui.get_data(frame)
                update_poll_viewer(data)
            end
        end
    end
end

local function create_poll(event)
    local data = Gui.get_data(event.element)

    local frame = data.frame
    local question = data.question

    if not question:find('%S') then
        event.player.print('Sorry, the poll needs a question.')
        return
    end

    local answers = {}
    for _, a in ipairs(data.answers) do
        local text = a.text
        if text:find('%S') then
            table.insert(answers, {text = text, voted_count = 0})
        end
    end

    if #answers < 1 then
        event.player.print('Sorry, the poll needs at least one answer.')
        return
    end

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

    table.insert(polls, poll_data)

    show_new_poll(poll_data)

    Gui.remove_data_recursivly(frame)
    frame.destroy()
end

local function update_vote(answers, voters, vote_index, direction)
    local answer_data = answers[vote_index]
    local count = answer_data.voted_count + direction
    answer_data.voted_count = count

    local tooltip = {}
    for pi, vi in pairs(voters) do
        if vi == vote_index then
            local player = game.players[pi]
            table.insert(tooltip, player.name)
        end
    end

    return tostring(count), table.concat(tooltip, ', ')
end

local function vote(event)
    local player_index = event.player_index
    local voted_button = event.element
    local button_data = Gui.get_data(voted_button)
    local vote_index = button_data.vote_index
    local poll_index = button_data.data.poll_index
    local poll = polls[poll_index]

    local voters = poll.voters

    local previous_vote_index = voters[player_index]
    if previous_vote_index == vote_index then
        return
    end

    voters[player_index] = vote_index

    local answers = poll.answers

    local previous_vote_button_count
    local previous_vote_button_tooltip
    if previous_vote_index then
        previous_vote_button_count, previous_vote_button_tooltip = update_vote(answers, voters, previous_vote_index, -1)
    end

    local vote_button_count, vote_button_tooltip = update_vote(answers, voters, vote_index, 1)

    for _, p in ipairs(game.connected_players) do
        local frame = p.gui.left[main_frame_name]
        if frame and frame.valid then
            local data = Gui.get_data(frame)

            if data.poll_index == poll_index then
                local vote_buttons = data.vote_buttons
                if previous_vote_index then
                    local vote_button = vote_buttons[previous_vote_index]
                    vote_button.caption = previous_vote_button_count
                    vote_button.tooltip = previous_vote_button_tooltip
                    vote_button.style.font_color = normal_color
                end

                local vote_button = vote_buttons[vote_index]
                vote_button.caption = vote_button_count
                vote_button.tooltip = vote_button_tooltip
                vote_button.style.font_color = focus_color
            end
        end
    end
end

local function player_joined(event)
    local player = game.players[event.player_index]
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
    for _, p in ipairs(game.connected_players) do
        local frame = p.gui.left[main_frame_name]
        if frame and frame.valid then
            local data = Gui.get_data(frame)
            local poll = polls[data.poll_index]
            if poll then
                local poll_enabled = do_remaining_time(poll, data.remaining_time_label)

                if not poll_enabled then
                    for _, v in ipairs(data.vote_buttons) do
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
        local left = event.player.gui.left
        local frame = left[create_poll_frame_name]
        if frame and frame.valid then
            Gui.remove_data_recursivly(frame)
            frame.destroy()
        else
            draw_create_poll_frame(left)
        end
    end
)

Gui.on_click(
    poll_view_edit_name,
    function(event)
        local left = event.player.gui.left
        local frame = left[create_poll_frame_name]

        if frame and frame.valid then
            Gui.remove_data_recursivly(frame)
            frame.destroy()
        end

        local main_frame = left[main_frame_name]
        local frame_data = Gui.get_data(main_frame)
        local poll = polls[frame_data.poll_index]

        draw_create_poll_frame(left, poll)
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

        table.insert(data.answers, {text = ''})
        redraw_create_poll_content(data)
    end
)

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
    create_poll_clear_name,
    function(event)
        local data = Gui.get_data(event.element)

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
        local data = Gui.get_data(event.element)
        local frame = data.frame
        local poll = data.previous_data

        Gui.remove_data_recursivly(frame)
        frame.destroy()

        local removed_index
        for i, p in ipairs(polls) do
            if p == poll then
                table.remove(polls, i)
                removed_index = i
                break
            end
        end

        if not removed_index then
            return
        end

        local message = event.player.name .. ' has deleted Poll #' .. poll.id .. ': ' .. poll.question

        for _, p in ipairs(game.connected_players) do
            if not no_notify_players[p.index] then
                p.print(message)
            end

            local main_frame = p.gui.left[main_frame_name]
            if main_frame and main_frame.valid then
                local main_frame_data = Gui.get_data(main_frame)
                local poll_index = main_frame_data.poll_index

                if removed_index >= poll_index then
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
        for i, a in ipairs(data.answers) do
            if a.text:find('%S') then
                new_answer_set[a.source] = i
            end
        end

        if not next(new_answer_set) then
            player.print('Sorry, the poll needs at least one answer.')
            return
        end

        poll.question = new_question

        Gui.remove_data_recursivly(frame)
        frame.destroy()

        local deleted_answers = {}
        for i, a in ipairs(poll.answers) do
            if not new_answer_set[a] then
                deleted_answers[i] = true
            end
        end

        local offset = 0

        local old_answers = poll.answers
        local new_answers = {}
        for i, a in ipairs(data.answers) do
            local text = a.text
            if text:find('%S') then
                table.insert(new_answers, a.source)
            else
            end
        end

        poll.edited_by[event.player_index] = true
        local message = event.player.name .. ' has edited Poll #' .. poll.id .. ': ' .. poll.question

        for _, p in ipairs(game.connected_players) do
            if not no_notify_players[p.index] then
                p.print(message)
            end

            local main_frame = p.gui.left[main_frame_name]
            if main_frame and main_frame.valid then
                local main_frame_data = Gui.get_data(main_frame)
                update_poll_viewer(main_frame_data)
            end
        end
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

local function do_direction(event, sign)
    local count
    if event.shift then
        count = 1000000
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

--[[ function poll()
    local duration = 60 * 60
    local poll_data = {
        id = poll_id(),
        question = 'question',
        answers = {{text = 'a1', voted_count = 0}, {text = 'a2', voted_count = 0}, {text = 'a3', voted_count = 0}},
        voters = {},
        start_tick = game.tick,
        end_tick = game.tick + duration,
        duration = duration,
        created_by = game.player,
        edited_by = {}
    }

    table.insert(polls, poll_data)

    show_new_poll(poll_data)
end ]]
