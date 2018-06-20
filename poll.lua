local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Event = require 'utils.event'
local UserGroup = require 'user_groups'

local normal_color = {r = 1, g = 1, b = 1}
local focus_color = {r = 1, g = 0.55, b = 0.1}

local polls = {}
local no_notify_players = {}
local player_poll_data = {}
local player_poll_index = {}

Global.register(
    {
        polls = polls,
        no_notify_players = no_notify_players,
        player_poll_data = player_poll_data,
        player_poll_index = player_poll_index
    },
    function(tbl)
        polls = tbl.polls
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
local poll_view_edit_name = Gui.uid_name()
local poll_view_vote_name = Gui.uid_name()

local create_poll_frame_name = Gui.uid_name()
local create_poll_label_name = Gui.uid_name()
local create_poll_question_name = Gui.uid_name()
local create_poll_answer_name = Gui.uid_name()
local create_poll_add_answer_name = Gui.uid_name()
local create_poll_delete_answer_name = Gui.uid_name()
local create_poll_close_name = Gui.uid_name()
local create_poll_clear_name = Gui.uid_name()
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

local function redraw_poll_viewer_content(data)
    local poll_viewer_content = data.poll_viewer_content
    local poll_index = data.poll_index

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
        local player = game.players[player_index]
        table.insert(tooltips[vote_index], player.name)
    end

    for i = 1, #tooltips do
        local t = tooltips[i]
        if #t == 0 then
            tooltips[i] = ''
        else
            tooltips[i] = table.concat(t, ', ')
        end
    end

    local question_label = poll_viewer_content.add {type = 'label', caption = poll.question}
    question_label.style.height = 32
    question_label.style.font_color = focus_color
    question_label.style.font = 'default-listbox'

    local grid = poll_viewer_content.add {type = 'table', column_count = 2}

    local vote_buttons = {}
    for i, a in ipairs(answers) do
        local vote_button =
            grid.add({type = 'flow'}).add {type = 'button', name = poll_view_vote_name, caption = a.voted_count}

        local tooltip = tooltips[i]
        if tooltip ~= '' then
            vote_button.tooltip = tooltip
        end

        vote_button.style.height = 24
        vote_button.style.font = 'default-small'
        vote_button.style.top_padding = 0
        vote_button.style.bottom_padding = 0
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

    poll_index = math.clamp(poll_index, 0, #polls)

    if poll_index == 0 then
        poll_index_label.caption = 'No Polls'
    else
        poll_index_label.caption = 'Poll ' .. poll_index .. ' / ' .. #polls
    end

    back_button.enabled = poll_index > 1
    forward_button.enabled = poll_index < #polls

    redraw_poll_viewer_content(data)
end

local function draw_main_frame(left, player)
    local frame = left.add {type = 'frame', name = main_frame_name, caption = 'Polls', direction = 'vertical'}

    local poll_viewer_top_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local back_button = poll_viewer_top_flow.add {type = 'button', name = poll_view_back_name, caption = '<'}
    local forward_button = poll_viewer_top_flow.add {type = 'button', name = poll_view_forward_name, caption = '>'}
    local poll_index_label = poll_viewer_top_flow.add {type = 'label'}

    local poll_viewer_content = frame.add {type = 'scroll-pane'}
    poll_viewer_content.style.maximal_height = 400
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

    local bottom_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow = bottom_flow.add {type = 'flow'}
    left_flow.style.align = 'left'
    left_flow.style.horizontally_stretchable = true

    left_flow.add {type = 'button', name = main_button_name, caption = 'Close'}

    local right_flow = bottom_flow.add {type = 'flow'}
    right_flow.style.align = 'right'

    if player.admin or UserGroup.is_regular(player.name) then
        right_flow.add {type = 'button', name = create_poll_button_name, caption = 'Create Poll'}
    end

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

local function redraw_create_poll_content(data)
    local grid = data.grid
    local answers = data.answers

    Gui.remove_data_recursivly(grid)
    grid.clear()

    grid.add {type = 'flow'}
    local question_label =
        grid.add({type = 'flow'}).add {type = 'label', name = create_poll_label_name, caption = 'Question:'}

    local question_textfield =
        grid.add({type = 'flow'}).add {type = 'textfield', name = create_poll_question_name, text = data.question}
    question_textfield.style.width = 200

    Gui.set_data(question_label, question_textfield)
    Gui.set_data(question_textfield, data)

    for count, text in ipairs(answers) do
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
        end

        local label_flow = grid.add {type = 'flow'}
        local label =
            label_flow.add {
            type = 'label',
            name = create_poll_label_name,
            caption = 'Answer #' .. count .. ':'
        }

        local textfield_flow = grid.add {type = 'flow'}

        local textfield = textfield_flow.add {type = 'textfield', name = create_poll_answer_name, text = text}
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
    if previous_data then
        question = previous_data.question
        answers = previous_data.answers
    end
    question = question or ''
    answers = answers or {'', '', ''}

    local frame =
        parent.add {type = 'frame', name = create_poll_frame_name, caption = 'New Poll', direction = 'vertical'}

    local scroll_pane = frame.add {type = 'scroll-pane', vertical_scroll_policy = 'always'}
    scroll_pane.style.maximal_height = 400
    scroll_pane.style.maximal_width = 300

    local grid = scroll_pane.add {type = 'table', column_count = 3}

    local data = {
        frame = frame,
        grid = grid,
        question = question,
        answers = answers
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

    local confirm_button = right_flow.add {type = 'button', name = create_poll_confirm_name, caption = 'Create Poll'}
    Gui.set_data(confirm_button, data)
end

local function show_new_poll(poll_index)
    for _, p in ipairs(game.connected_players) do
        if p.valid then
            local frame = p.gui.left[main_frame_name]
            if frame and frame.valid then
                local data = Gui.get_data(frame)
                data.poll_index = poll_index

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
        if a:find('%S') then
            table.insert(answers, {text = a, voted_count = 0})
        end
    end

    if #answers < 1 then
        event.player.print('Sorry, the poll needs at least one answer.')
        return
    end

    local tick = game.tick
    local duration = 3 * 60 * 60
    local poll_data = {
        question = question,
        answers = answers,
        voters = {},
        start_tick = tick,
        end_tick = tick + duration,
        created_by = event.player,
        edited_by = {}
    }

    table.insert(polls, poll_data)

    show_new_poll(#polls)

    Gui.remove_data_recursivly(frame)
    frame.destroy()
end

local function update_votes(poll_index)
    for _, p in ipairs(game.connected_players) do
        local frame = p.gui.left[main_frame_name]
        if frame and frame.valid then
            local data = Gui.get_data(frame)

            if data.poll_index == poll_index then
                redraw_poll_viewer_content(data)
            end
        end
    end
end

local function vote(event)
    local player_index = event.player_index
    local voted_button = event.element
    local button_data = Gui.get_data(voted_button)
    local vote_index = button_data.vote_index
    local data = button_data.data
    local poll_index = data.poll_index
    local poll = polls[poll_index]

    local voters = poll.voters

    local previous_vote_index = voters[player_index]
    if previous_vote_index == vote_index then
        return
    end

    local answers = poll.answers

    if previous_vote_index then
        local answer_data = answers[previous_vote_index]
        answer_data.voted_count = answer_data.voted_count - 1
    end

    local answer_data = answers[vote_index]
    answer_data.voted_count = answer_data.voted_count + 1
    voters[player_index] = vote_index

    update_votes(poll_index)
end

Event.add(defines.events.on_player_joined_game, player_joined)

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

        data.answers[data.count] = textfield.text
    end
)

Gui.on_click(
    create_poll_add_answer_name,
    function(event)
        local data = Gui.get_data(event.element)

        table.insert(data.answers, '')
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
            answers[i] = ''
        end

        redraw_create_poll_content(data)
    end
)

Gui.on_click(create_poll_confirm_name, create_poll)

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

Gui.on_click(
    poll_view_back_name,
    function(event)
        local data = Gui.get_data(event.element)
        data.poll_index = data.poll_index - 1
        update_poll_viewer(data)
    end
)

Gui.on_click(
    poll_view_forward_name,
    function(event)
        local data = Gui.get_data(event.element)
        data.poll_index = data.poll_index + 1
        update_poll_viewer(data)
    end
)

Gui.on_click(poll_view_vote_name, vote)
