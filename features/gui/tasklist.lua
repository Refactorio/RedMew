local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Rank = require 'features.rank_system'
local Utils = require 'utils.core'
local Game = require 'utils.game'
local math = require 'utils.math'
local Command = require 'utils.command'
local Color = require 'resources.color_presets'
local Ranks = require 'resources.ranks'

local normal_color = Color.white
local focus_color = Color.dark_orange

local server_player = {
    valid = true,
    index = 0,
    name = '<server>',
    admin = true,
    print = print
}

local init_announcements = 'There are no announcements.'
local announcements = {
    text = init_announcements,
    edit_text = init_announcements,
    editing_players = {},
    last_edit_player = nil,
    last_update_player = nil,
    last_update_time = nil
}
local tasks = {}
local player_tasks = {}
local tasks_counter = {0}
local last_task_update_data = {
    player = nil,
    time = nil
}
local no_notify_players = {}

Global.register(
    {
        announcements = announcements,
        tasks = tasks,
        player_tasks = player_tasks,
        tasks_counter = tasks_counter,
        last_task_update_data = last_task_update_data,
        no_notify_players = no_notify_players
    },
    function(tbl)
        announcements = tbl.announcements
        tasks = tbl.tasks
        player_tasks = tbl.player_tasks
        tasks_counter = tbl.tasks_counter
        last_task_update_data = tbl.last_task_update_data
        no_notify_players = tbl.no_notify_players
    end
)

local main_frame_name = Gui.uid_name()
local main_button_name = Gui.uid_name()
local announcements_edit_button_name = Gui.uid_name()
local add_task_button_name = Gui.uid_name()
local edit_task_button_name = Gui.uid_name()
local delete_task_button_name = Gui.uid_name()
local move_task_up_button_name = Gui.uid_name()
local move_task_down_button_name = Gui.uid_name()
local volunteer_task_button_name = Gui.uid_name()
local notify_checkbox_name = Gui.uid_name()

local edit_announcements_frame_name = Gui.uid_name()
local edit_announcements_textbox_name = Gui.uid_name()
local edit_close_button_name = Gui.uid_name()
local edit_clear_button_name = Gui.uid_name()
local edit_reset_button_name = Gui.uid_name()
local edit_confirm_button_name = Gui.uid_name()

local create_task_frame_name = Gui.uid_name()
local create_task_close_button_name = Gui.uid_name()
local create_task_clear_button_name = Gui.uid_name()
local create_task_confirm_button_name = Gui.uid_name()
local create_task_edit_button_name = Gui.uid_name()

local function get_task_id()
    local count = tasks_counter[1] + 1
    tasks_counter[1] = count
    return count
end

local function get_announcements_updated_by_message()
    local player = announcements.last_update_player

    if not player then
        return ''
    end

    return table.concat {
        'Updated by ',
        player.name,
        ' (',
        Utils.format_time(game.tick - announcements.last_update_time),
        ' ago).'
    }
end

local function get_edit_announcements_last_player_message()
    local player = announcements.last_edit_player
    if not player then
        return ''
    end

    return 'Last edit by ' .. player.name
end

local function get_editing_players_message(players)
    local message = {'Editing players: '}

    for pi, _ in pairs(players) do
        local name = Game.get_player_by_index(pi).name
        table.insert(message, name)
        table.insert(message, ', ')
    end
    table.remove(message)

    return table.concat(message)
end

local function get_task_updated_by_message()
    local player = last_task_update_data.player

    if not player then
        return ''
    end

    return table.concat {
        'Updated by ',
        player.name,
        ' (',
        Utils.format_time(game.tick - last_task_update_data.time),
        ' ago).'
    }
end

local function get_task_label_tooltip(task, game_tick)
    local tooltip = {'Created by ', task.created_by.name}

    local edited_by = task.edited_by
    if edited_by then
        table.insert(tooltip, ' Edited by ')
        for _, p in pairs(edited_by) do
            table.insert(tooltip, p.name)
            table.insert(tooltip, ', ')
        end
        table.remove(tooltip)
    end

    table.insert(tooltip, ' (')
    table.insert(tooltip, Utils.format_time(game_tick - task.tick))
    table.insert(tooltip, ' ago)')

    return table.concat(tooltip)
end

local function apply_direction_button_style(button)
    local button_style = button.style
    button_style.width = 26
    button_style.height = 26
    button_style.top_padding = 0
    button_style.bottom_padding = 0
    button_style.left_padding = 0
    button_style.right_padding = 0
    button_style.font = 'default-listbox'
end

local function apply_button_style(button)
    local style = button.style
    style.width = 26
    style.height = 26
end

local function update_volunteer_button(button, task)
    local volunteers = task.volunteers

    local tooltip = {'Volunteers: '}
    local count = 0

    for _, p in pairs(volunteers) do
        if p.connected then
            table.insert(tooltip, p.name)
            table.insert(tooltip, ', ')
            count = count + 1
        end
    end
    table.remove(tooltip)

    button.caption = count
    if count == 0 then
        button.tooltip = 'No volunteers'
    else
        button.tooltip = table.concat(tooltip)
    end

    if volunteers[button.player_index] then
        button.style.font_color = focus_color
    else
        button.style.font_color = normal_color
    end
end

local function redraw_tasks(data, enabled)
    local parent = data.tasks_content
    Gui.clear(parent)

    local volunteer_buttons = {}
    local task_labels = {}
    data.volunteer_buttons = volunteer_buttons
    data.task_labels = task_labels

    local task_count = #tasks
    if task_count == 0 then
        parent.add {type = 'label', caption = 'There are no Tasks.'}
        return
    end

    local delete_button_tooltip
    local edit_button_tooltip
    local up_button_tooltip
    local down_button_tooltip
    if enabled then
        delete_button_tooltip = 'Delete task.'
        edit_button_tooltip = 'Edit task.'
        up_button_tooltip = 'Move the task up, right click moves 5 spaces, shift click moves the task to the top.'
        down_button_tooltip = 'Move the task down, right click moves 5 spaces, shift click moves the task to the bottom.'
    else
        delete_button_tooltip = 'Sorry, you have to be a regular to delete tasks.'
        edit_button_tooltip = 'Sorry, you have to be a regular to edit tasks.'
        up_button_tooltip = 'Sorry, you have to be a regualr to move tasks.'
        down_button_tooltip = 'Sorry, you have to be a regualr to move tasks.'
    end

    local game_tick = game.tick

    for task_index, task in ipairs(tasks) do
        local delete_button =
            parent.add({type = 'flow'}).add {
            type = 'sprite-button',
            name = delete_task_button_name,
            sprite = 'utility/remove',
            tooltip = delete_button_tooltip
        }
        delete_button.enabled = enabled
        apply_button_style(delete_button)
        Gui.set_data(delete_button, task_index)

        local edit_button =
            parent.add({type = 'flow'}).add {
            type = 'sprite-button',
            name = edit_task_button_name,
            sprite = 'utility/rename_icon_normal',
            tooltip = edit_button_tooltip
        }
        edit_button.enabled = enabled
        apply_button_style(edit_button)
        Gui.set_data(edit_button, task)

        local up_button =
            parent.add({type = 'flow'}).add {
            type = 'button',
            name = move_task_up_button_name,
            caption = '▲',
            tooltip = up_button_tooltip
        }
        up_button.enabled = enabled and task_index ~= 1
        apply_direction_button_style(up_button)
        Gui.set_data(up_button, task_index)
        local down_button =
            parent.add({type = 'flow'}).add {
            type = 'button',
            name = move_task_down_button_name,
            caption = '▼',
            tooltip = down_button_tooltip
        }
        down_button.enabled = enabled and task_index ~= task_count
        apply_direction_button_style(down_button)
        Gui.set_data(down_button, task_index)

        local volunteer_button_flow = parent.add {type = 'flow'}
        local volunteer_button = volunteer_button_flow.add {type = 'button', name = volunteer_task_button_name}
        local volunteer_button_style = volunteer_button.style
        volunteer_button_style.font = 'default-small'
        volunteer_button_style.height = 26
        volunteer_button_style.width = 26
        volunteer_button_style.top_padding = 0
        volunteer_button_style.bottom_padding = 0
        volunteer_button_style.left_padding = 0
        volunteer_button_style.right_padding = 0
        Gui.set_data(volunteer_button, task)
        update_volunteer_button(volunteer_button, task)

        volunteer_buttons[task.task_id] = volunteer_button

        local label =
            parent.add {
            type = 'label',
            caption = table.concat {'#', task.task_id, ' ', task.name},
            tooltip = get_task_label_tooltip(task, game_tick)
        }
        label.style.left_padding = 4

        task_labels[task_index] = label
    end
end

local function draw_main_frame(left, player)
    local enabled = Rank.equal_or_greater_than(player.name, Ranks.regular)

    local data = {}

    local edit_announcements_button_tooltip
    local add_task_button_tooltip
    if enabled then
        edit_announcements_button_tooltip = 'Edit announcements.'
        add_task_button_tooltip = 'Create a new task.'
    else
        edit_announcements_button_tooltip = 'Sorry, you need to be a regular to edit announcements.'
        add_task_button_tooltip = 'Sorry, you need to be a regular to create a new tasks.'
    end

    local frame = left.add {type = 'frame', name = main_frame_name, direction = 'vertical'}
    Gui.set_data(frame, data)

    local announcements_header_flow = frame.add {type = 'flow'}

    local edit_announcements_button =
        announcements_header_flow.add {
        type = 'sprite-button',
        name = announcements_edit_button_name,
        sprite = 'utility/rename_icon_normal',
        tooltip = edit_announcements_button_tooltip
    }
    edit_announcements_button.enabled = enabled
    apply_button_style(edit_announcements_button)

    local announcements_header = announcements_header_flow.add {type = 'label', caption = 'Announcements'}
    announcements_header.style.font = 'default-listbox'

    local last_edit_message = get_announcements_updated_by_message()
    local announcements_updated_label =
        announcements_header_flow.add {
        type = 'label',
        caption = last_edit_message,
        tooltip = last_edit_message
    }

    local announcements_textbox = frame.add {type = 'text-box', text = announcements.text}
    announcements_textbox.read_only = true
    --announcements_textbox.word_wrap = true
    local announcements_textbox_style = announcements_textbox.style
    announcements_textbox_style.width = 450
    announcements_textbox_style.height = 100

    data.announcements_textbox = announcements_textbox
    data.announcements_updated_label = announcements_updated_label

    local tasks_header_flow = frame.add {type = 'flow'}

    local add_task_button =
        tasks_header_flow.add {
        type = 'sprite-button',
        name = add_task_button_name,
        sprite = 'utility/add',
        tooltip = add_task_button_tooltip
    }
    add_task_button.enabled = enabled
    apply_button_style(add_task_button)

    local tasks_header = tasks_header_flow.add {type = 'label', caption = 'Tasks'}
    tasks_header.style.font = 'default-listbox'

    local last_task_updated_message = get_task_updated_by_message()
    local tasks_updated_label =
        tasks_header_flow.add {
        type = 'label',
        caption = last_task_updated_message,
        tooltip = last_task_updated_message
    }
    data.tasks_updated_label = tasks_updated_label

    local tasks_scroll_pane = frame.add {type = 'scroll-pane', direction = 'vertical'}
    local tasks_scroll_pane_style = tasks_scroll_pane.style
    tasks_scroll_pane_style.width = 450
    tasks_scroll_pane_style.maximal_height = 250

    local tasks_content = tasks_scroll_pane.add {type = 'table', column_count = 6}
    local tasks_content_style = tasks_content.style
    tasks_content_style.horizontal_spacing = 0
    tasks_content_style.vertical_spacing = 0
    data.tasks_content = tasks_content

    redraw_tasks(data, enabled)

    frame.add {
        type = 'checkbox',
        name = notify_checkbox_name,
        caption = 'Notify me about new announcements or tasks',
        state = not no_notify_players[left.player_index]
    }

    frame.add {type = 'button', name = main_button_name, caption = 'Close'}
end

local function close_edit_announcements_frame(frame)
    local editing_players = announcements.editing_players
    editing_players[frame.player_index] = nil
    Gui.destroy(frame)

    if not next(editing_players) then
        return
    end

    local editing_players_message = get_editing_players_message(editing_players)

    for _, data in pairs(editing_players) do
        local editing_players_label = data.editing_players_label
        editing_players_label.caption = editing_players_message
        editing_players_label.tooltip = editing_players_message
    end
end

local function toggle(event)
    local player = event.player
    local left = player.gui.left
    local frame = left[main_frame_name]
    if frame and frame.valid then
        Gui.destroy(frame)
        frame = left[edit_announcements_frame_name]
        if frame and frame.valid then
            close_edit_announcements_frame(frame)
        end
        frame = left[create_task_frame_name]
        if frame and frame.valid then
            Gui.destroy(frame)
        end
    else
        draw_main_frame(left, player)
    end
end

local function update_edit_announcements_textbox(text, player)
    local player_index = player.index
    announcements.edit_text = text
    announcements.last_edit_player = player
    local editing_players = announcements.editing_players

    local last_edit_message = get_edit_announcements_last_player_message()
    local editing_players_message = get_editing_players_message(editing_players)

    for pi, data in pairs(editing_players) do
        if pi ~= player_index then
            data.textbox.text = text
        end

        local last_edit_label = data.last_edit_player_label
        last_edit_label.caption = last_edit_message
        last_edit_label.tooltip = last_edit_message

        local editing_players_label = data.editing_players_label
        editing_players_label.caption = editing_players_message
        editing_players_label.tooltip = editing_players_message
    end
end

local function update_announcements(player)
    local text = announcements.edit_text

    announcements.text = text
    announcements.last_update_player = player
    announcements.last_update_time = game.tick

    local last_edit_message = get_announcements_updated_by_message()
    local update_message = 'The announcements have been updated by ' .. player.name

    for _, p in ipairs(game.connected_players) do
        local notify = not no_notify_players[p.index]

        if notify then
            p.print(update_message)
        end

        local left = p.gui.left
        local frame = left[main_frame_name]
        if frame and frame.valid then
            local data = Gui.get_data(frame)
            data.announcements_textbox.text = text

            local label = data.announcements_updated_label
            label.caption = last_edit_message
            label.tooltip = last_edit_message
        elseif notify then
            draw_main_frame(left, p)
        end
    end
end

local function create_new_tasks(task_name, player)
    local task_id = get_task_id()
    local tick = game.tick
    local task = {
        task_id = task_id,
        created_by = player,
        edited_by = nil,
        tick = tick,
        name = task_name,
        volunteers = {}
    }

    table.insert(tasks, task)

    last_task_update_data.player = player
    last_task_update_data.time = tick

    local update_message = get_task_updated_by_message()

    local message =
        table.concat {
        player.name,
        ' has create a new task #',
        task_id,
        ' - ',
        task_name
    }

    for _, p in ipairs(game.connected_players) do
        local notify = not no_notify_players[p.index]
        local left = p.gui.left
        local frame = left[main_frame_name]
        if frame and frame.valid then
            local frame_data = Gui.get_data(frame)
            frame_data.tasks_updated_label.caption = update_message

            local enabled = Rank.equal_or_greater_than(p.name, Ranks.regular)
            redraw_tasks(frame_data, enabled)
        elseif notify then
            draw_main_frame(left, p)
        end

        if notify then
            p.print(message)
        end
    end
end

local function draw_create_task_frame(left, previous_task)
    local frame_caption
    local confirm_button_name
    local confirm_button_caption
    local text

    if previous_task then
        frame_caption = 'Edit Task #' .. previous_task.task_id
        confirm_button_name = create_task_edit_button_name
        confirm_button_caption = 'Edit Task'
        text = previous_task.name
    else
        frame_caption = 'Create New Task'
        confirm_button_name = create_task_confirm_button_name
        confirm_button_caption = 'Create Task'
    end

    local frame = left.add {type = 'frame', name = create_task_frame_name, caption = frame_caption, direction = 'vertical'}
    frame.style.width = 470

    local textbox = frame.add {type = 'textfield', text = text}
    local textbox_style = textbox.style
    textbox_style.width = 450

    local bottom_flow = frame.add {type = 'flow'}

    local close_button = bottom_flow.add {type = 'button', name = create_task_close_button_name, caption = 'Close'}
    Gui.set_data(close_button, frame)
    local clear_button = bottom_flow.add {type = 'button', name = create_task_clear_button_name, caption = 'Clear'}
    Gui.set_data(clear_button, textbox)
    bottom_flow.add({type = 'flow'}).style.horizontally_stretchable = true
    local confirm_button = bottom_flow.add {type = 'button', name = confirm_button_name, caption = confirm_button_caption}
    Gui.set_data(confirm_button, {frame = frame, textbox = textbox, previous_task = previous_task})
end

local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    local gui = player.gui

    local frame = gui.left[main_frame_name]
    if frame and frame.valid then
        local text = announcements.edit_text
        local last_edit_message = get_announcements_updated_by_message()

        local data = Gui.get_data(frame)

        data.announcements_textbox.text = text

        local label = data.announcements_updated_label
        label.caption = last_edit_message
        label.tooltip = last_edit_message

        local enabled = Rank.equal_or_greater_than(player.name, Ranks.regular)
        redraw_tasks(data, enabled)
    end

    local tasks_for_player = player_tasks[player.index]
    if tasks_for_player and next(tasks_for_player) then
        for _, p in ipairs(game.connected_players) do
            local main_frame = p.gui.left[main_frame_name]
            if main_frame then
                local data = Gui.get_data(main_frame)
                local volunteer_buttons = data.volunteer_buttons

                for index, task in pairs(tasks_for_player) do
                    update_volunteer_button(volunteer_buttons[index], task)
                end
            end
        end
    end

    local top = gui.top
    if not top[main_button_name] then
        top.add {type = 'sprite-button', name = main_button_name, sprite = 'item/repair-pack'}
    end
end

local function player_left(event)
    local player = Game.get_player_by_index(event.player_index)
    local left = player.gui.left

    local frame = left[edit_announcements_frame_name]
    if frame and frame.valid then
        close_edit_announcements_frame(frame)
    end
end

local function on_tick()
    for _, p in ipairs(game.connected_players) do
        local left = p.gui.left
        local frame = left[main_frame_name]

        if frame then
            local data = Gui.get_data(frame)
            data.tasks_updated_label.caption = get_task_updated_by_message()
            data.announcements_updated_label.caption = get_announcements_updated_by_message()

            local game_tick = game.tick
            for task_index, label in ipairs(data.task_labels) do
                label.tooltip = get_task_label_tooltip(tasks[task_index], game_tick)
            end
        end
    end
end

Event.add(defines.events.on_player_joined_game, player_joined)
Event.add(defines.events.on_player_left_game, player_left)
Event.on_nth_tick(3600, on_tick)

Gui.on_click(main_button_name, toggle)

Gui.on_click(
    announcements_edit_button_name,
    function(event)
        local player = event.player
        local left = player.gui.left

        local frame = left[edit_announcements_frame_name]
        if frame then
            return
        end

        local data = {}

        frame =
            left.add {
            type = 'frame',
            name = edit_announcements_frame_name,
            caption = 'Edit Announcements',
            direction = 'vertical'
        }
        frame.style.width = 470

        Gui.set_data(frame, data)

        local top_flow = frame.add {type = 'flow'}
        local last_edit_player_label = top_flow.add {type = 'label'}
        local editing_players_label = top_flow.add {type = 'label'}

        local textbox = frame.add {type = 'text-box', name = edit_announcements_textbox_name, text = announcements.edit_text}
        --textbox.word_wrap = true
        local textbox_style = textbox.style
        textbox_style.width = 450
        textbox_style.height = 100

        data.textbox = textbox

        local bottom_flow = frame.add {type = 'flow'}

        local close_button = bottom_flow.add {type = 'button', name = edit_close_button_name, caption = 'Close'}
        local clear_button = bottom_flow.add {type = 'button', name = edit_clear_button_name, caption = 'Clear'}
        local reset_button = bottom_flow.add {type = 'button', name = edit_reset_button_name, caption = 'Reset'}
        bottom_flow.add({type = 'flow'}).style.horizontally_stretchable = true
        local confirm_button = bottom_flow.add {type = 'button', name = edit_confirm_button_name, caption = 'Confirm'}

        Gui.set_data(close_button, frame)
        Gui.set_data(clear_button, textbox)
        Gui.set_data(reset_button, textbox)
        Gui.set_data(confirm_button, frame)

        announcements.editing_players[player.index] = {
            textbox = textbox,
            last_edit_player_label = last_edit_player_label,
            editing_players_label = editing_players_label
        }

        local last_edit_message = get_edit_announcements_last_player_message()
        local editing_players_message = get_editing_players_message(announcements.editing_players)

        last_edit_player_label.caption = last_edit_message
        last_edit_player_label.tooltip = last_edit_message
        editing_players_label.caption = editing_players_message
        editing_players_label.tooltip = editing_players_message
    end
)

Gui.on_checked_state_changed(
    notify_checkbox_name,
    function(event)
        local checkbox = event.element
        local player_index = event.player_index
        if checkbox.state then
            no_notify_players[player_index] = nil
        else
            no_notify_players[player_index] = true
        end
    end
)

Gui.on_click(
    edit_close_button_name,
    function(event)
        local frame = Gui.get_data(event.element)
        close_edit_announcements_frame(frame)
    end
)

Gui.on_click(
    edit_clear_button_name,
    function(event)
        local text = ''
        local textbox = Gui.get_data(event.element)
        textbox.text = text
        update_edit_announcements_textbox(text, event.player)
    end
)

Gui.on_click(
    edit_reset_button_name,
    function(event)
        local text = announcements.text
        local textbox = Gui.get_data(event.element)
        textbox.text = text
        update_edit_announcements_textbox(text, event.player)
    end
)

Gui.on_click(
    edit_confirm_button_name,
    function(event)
        local frame = Gui.get_data(event.element)
        close_edit_announcements_frame(frame)

        local player = event.player
        update_announcements(player)
    end
)

Gui.on_text_changed(
    edit_announcements_textbox_name,
    function(event)
        local textbox = event.element
        local text = textbox.text

        update_edit_announcements_textbox(text, event.player)
    end
)

Gui.on_click(
    delete_task_button_name,
    function(event)
        local task_index = Gui.get_data(event.element)

        local task = table.remove(tasks, task_index)

        local message =
            table.concat {
            event.player.name,
            ' has deleted task #',
            task.task_id,
            ' - ',
            task.name
        }

        local task_id = task.task_id
        for pi, _ in pairs(task.volunteers) do
            local tasks_for_player = player_tasks[pi]
            if tasks_for_player then
                tasks_for_player[task_id] = nil
            end
        end

        for _, p in ipairs(game.connected_players) do
            local notify = not no_notify_players[p.index]
            local left = p.gui.left
            local frame = left[main_frame_name]
            if frame and frame.valid then
                local data = Gui.get_data(frame)
                local enabled = Rank.equal_or_greater_than(p.name, Ranks.regular)
                redraw_tasks(data, enabled)
            elseif notify then
                draw_main_frame(left, p)
            end

            if notify then
                p.print(message)
            end
        end
    end
)

Gui.on_click(
    edit_task_button_name,
    function(event)
        local previous_task = Gui.get_data(event.element)
        local left = event.player.gui.left
        local frame = left[create_task_frame_name]

        if frame then
            Gui.destroy(frame)
        end

        draw_create_task_frame(left, previous_task)
    end
)

local function do_direction(event, sign)
    local count
    if event.shift then
        count = #tasks
    else
        local button = event.button
        if button == defines.mouse_button_type.right then
            count = 5
        else
            count = 1
        end
    end

    count = count * sign

    local old_index = Gui.get_data(event.element)

    local new_index = old_index + count
    new_index = math.clamp(new_index, 1, #tasks)

    local task = table.remove(tasks, old_index)
    table.insert(tasks, new_index, task)

    for _, p in ipairs(game.connected_players) do
        local frame = p.gui.left[main_frame_name]
        if frame and frame.valid then
            local data = Gui.get_data(frame)
            local enabled = Rank.equal_or_greater_than(p.name, Ranks.regular)
            redraw_tasks(data, enabled)
        end
    end
end

Gui.on_click(
    move_task_up_button_name,
    function(event)
        do_direction(event, -1)
    end
)

Gui.on_click(
    move_task_down_button_name,
    function(event)
        do_direction(event, 1)
    end
)

Gui.on_click(
    volunteer_task_button_name,
    function(event)
        local button = event.element
        local task = Gui.get_data(button)
        local task_id = task.task_id

        local player_index = event.player_index
        local volunteers = task.volunteers

        if volunteers[player_index] then
            volunteers[player_index] = nil

            local tasks_for_player = player_tasks[player_index]
            tasks_for_player[task_id] = nil
        else
            volunteers[player_index] = event.player

            local tasks_for_player = player_tasks[player_index]
            if not tasks_for_player then
                tasks_for_player = {}
                player_tasks[player_index] = tasks_for_player
            end

            tasks_for_player[task_id] = task
        end

        for _, p in ipairs(game.connected_players) do
            local frame = p.gui.left[main_frame_name]
            if frame and frame.valid then
                local data = Gui.get_data(frame)
                local volunteer_buttons = data.volunteer_buttons

                update_volunteer_button(volunteer_buttons[task_id], task)
            end
        end
    end
)

Gui.on_click(
    add_task_button_name,
    function(event)
        local left = event.player.gui.left
        local frame = left[create_task_frame_name]

        if frame then
            Gui.destroy(frame)
        end

        draw_create_task_frame(left)
    end
)

Gui.on_click(
    create_task_close_button_name,
    function(event)
        local frame = Gui.get_data(event.element)
        Gui.destroy(frame)
    end
)

Gui.on_click(
    create_task_clear_button_name,
    function(event)
        local textbox = Gui.get_data(event.element)
        textbox.text = ''
    end
)

Gui.on_click(
    create_task_confirm_button_name,
    function(event)
        local data = Gui.get_data(event.element)

        local player = event.player
        local textbox = data.textbox
        local task_name = textbox.text

        if task_name == '' then
            player.print('Sorry, tasks cannot be empty.')
            return
        end

        local frame = data.frame

        Gui.destroy(frame)

        create_new_tasks(task_name, player)
    end
)

Gui.on_click(
    create_task_edit_button_name,
    function(event)
        local data = Gui.get_data(event.element)

        local player = event.player
        local textbox = data.textbox
        local name = textbox.text

        if name == '' then
            player.print('Sorry, tasks cannot be empty.')
            return
        end

        local frame = data.frame
        local task = data.previous_task

        Gui.destroy(frame)

        if task.name == name then
            return
        end

        local tick = game.tick

        task.name = name
        local edited_by = task.edited_by
        if not edited_by then
            edited_by = {}
            task.edited_by = edited_by
        end
        edited_by[player.index] = player
        task.tick = tick

        last_task_update_data.player = player
        last_task_update_data.time = tick

        local task_index
        for i, t in ipairs(tasks) do
            if task == t then
                task_index = i
                break
            end
        end

        if not task_index then
            table.insert(tasks, task)
        end

        local message =
            table.concat {
            event.player.name,
            ' has edited task #',
            task.task_id,
            ' - ',
            name
        }

        local update_message = get_task_updated_by_message()

        for _, p in ipairs(game.connected_players) do
            local notify = not no_notify_players[p.index]
            local left = p.gui.left
            local main_frame = left[main_frame_name]

            if main_frame then
                local main_frame_data = Gui.get_data(main_frame)

                main_frame_data.tasks_updated_label.caption = update_message
                local enabled = Rank.equal_or_greater_than(p.name, Ranks.regular)
                redraw_tasks(main_frame_data, enabled)
            elseif notify then
                draw_main_frame(left, p)
            end

            if notify then
                p.print(message)
            end
        end
    end
)

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Command.add(
    'task',
    {
        description = {'command_description.task'},
        arguments = {'task'},
        required_rank = Ranks.regular,
        allowed_by_server = true,
        log_command = true,
        capture_excess_arguments = true,
    },
    function(args, player)
        create_new_tasks(args.task, player or server_player)
    end
)
