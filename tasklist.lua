local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Global = require 'utils.global'
local UserGroups = require 'user_groups'
local Utils = require 'utils.utils'

local normal_color = {r = 1, g = 1, b = 1}
local focus_color = {r = 1, g = 0.55, b = 0.1}

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
local no_notify_players = {}

Global.register(
    {
        announcements = announcements,
        tasks = tasks,
        player_tasks = player_tasks,
        tasks_counter = tasks_counter,
        no_notify_announcements_players = no_notify_players
    },
    function(tbl)
        announcements = tbl.announcements
        tasks = tbl.tasks
        player_tasks = tbl.player_tasks
        tasks_counter = tbl.tasks_counter
        no_notify_players = tbl.no_notify_announcements_players
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
        local name = game.players[pi].name
        table.insert(message, name)
        table.insert(message, ', ')
    end
    table.remove(message)

    return table.concat(message)
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

local function redraw_tasks(data)
    local parent = data.tasks_content
    Gui.clear(parent)
    local volunteer_buttons = {}
    data.volunteer_buttons = volunteer_buttons

    local task_count = #tasks
    if task_count == 0 then
        parent.add {type = 'label', caption = 'There are no Tasks.'}
        return
    end

    for task_index, task in ipairs(tasks) do
        local delete_button =
            parent.add({type = 'flow'}).add {
            type = 'sprite-button',
            name = delete_task_button_name,
            sprite = 'utility/remove',
            tooltip = 'Delete task.'
        }
        apply_button_style(delete_button)
        Gui.set_data(delete_button, task_index)

        local edit_button =
            parent.add({type = 'flow'}).add {
            type = 'sprite-button',
            name = edit_task_button_name,
            sprite = 'utility/rename_icon_normal',
            tooltip = 'Edit task.'
        }
        apply_button_style(edit_button)
        Gui.set_data(edit_button, task)

        local up_button =
            parent.add({type = 'flow'}).add {
            type = 'button',
            name = move_task_up_button_name,
            caption = '▲',
            tooltip = 'Move the task up, right click moves 5 spaces, shift click moves the task to the top.'
        }
        up_button.enabled = task_index ~= 1
        apply_direction_button_style(up_button)
        Gui.set_data(up_button, task_index)
        local down_button =
            parent.add({type = 'flow'}).add {
            type = 'button',
            name = move_task_down_button_name,
            caption = '▼',
            tooltip = 'Move the task down, right click moves 5 spaces, shift click moves the task to the bottom.'
        }
        down_button.enabled = task_index ~= task_count
        apply_direction_button_style(down_button)
        Gui.set_data(down_button, task_index)

        local volunteer_button_flow = parent.add {type = 'flow'}
        --[[ local volunteer_button_flow_style = volunteer_button_flow.style
        volunteer_button_flow_style.horizontally_stretchable = true
        volunteer_button_flow_style.align = 'right' ]]
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

        volunteer_buttons[task] = volunteer_button

        local label = parent.add {type = 'label', caption = table.concat {'#', task.task_id, ' ', task.name}}
        label.style.left_padding = 4
    end
end

local function draw_main_frame(left)
    local data = {}

    local frame = left.add {type = 'frame', name = main_frame_name, direction = 'vertical'}
    Gui.set_data(frame, data)

    local announcements_header_flow = frame.add {type = 'flow'}

    local edit_announcments_button =
        announcements_header_flow.add {
        type = 'sprite-button',
        name = announcements_edit_button_name,
        sprite = 'utility/rename_icon_normal',
        tooltip = 'Edit announcments.'
    }
    local edit_announcments_button_style = edit_announcments_button.style
    edit_announcments_button_style.width = 26
    edit_announcments_button_style.height = 26

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
    announcements_textbox.word_wrap = true
    local announcements_textbox_style = announcements_textbox.style
    announcements_textbox_style.width = 400
    announcements_textbox_style.height = 100

    data.announcements_textbox = announcements_textbox
    data.announcements_updated_label = announcements_updated_label

    local tasks_header_flow = frame.add {type = 'flow'}
    local tasks_header = tasks_header_flow.add {type = 'label', caption = 'Tasks'}
    tasks_header.style.font = 'default-listbox'

    local tasks_scroll_pane = frame.add {type = 'scroll-pane', direction = 'vertical'}
    local tasks_scroll_pane_style = tasks_scroll_pane.style
    tasks_scroll_pane_style.width = 400
    tasks_scroll_pane_style.maximal_height = 250

    local tasks_content = tasks_scroll_pane.add {type = 'table', column_count = 6}
    local tasks_content_style = tasks_content.style
    tasks_content_style.horizontal_spacing = 0
    tasks_content_style.vertical_spacing = 0
    data.tasks_content = tasks_content

    redraw_tasks(data)

    frame.add {type = 'button', name = add_task_button_name, caption = 'New Task'}

    frame.add {
        type = 'checkbox',
        name = notify_checkbox_name,
        caption = 'Notify me about new annoucements or tasks',
        state = not no_notify_players[left.player_index]
    }

    frame.add {type = 'button', name = main_button_name, caption = 'Close'}
end

local function toggle(event)
    local left = event.player.gui.left
    local frame = left[main_frame_name]
    if frame and frame.valid then
        Gui.destroy(frame)
        frame = left[edit_announcements_frame_name]
        if frame and frame.valid then
            Gui.destroy(frame)
        end
        frame = left[create_task_frame_name]
        if frame and frame.valid then
            Gui.destroy(frame)
        end
    else
        draw_main_frame(left)
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

local function close_edit_announcments_frame(frame)
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

local function update_announcements(player)
    local text = announcements.edit_text

    announcements.text = text
    announcements.last_update_player = player
    announcements.last_update_time = game.tick

    local last_edit_message = get_announcements_updated_by_message()
    local update_message = 'The announcements have been updated by ' .. player.name

    for pi, p in ipairs(game.connected_players) do
        local notify = not no_notify_players[pi]

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
            draw_main_frame(left)
        end
    end
end

local function create_new_tasks(task_name, player)
    local task_id = get_task_id()
    local task = {
        task_id = task_id,
        created_by = player,
        edited_by = nil,
        tick = game.tick,
        name = task_name,
        volunteers = {}
    }

    table.insert(tasks, task)

    local message =
        table.concat {
        player.name,
        ' has create a new task #',
        task_id,
        ' - ',
        task_name
    }

    for pi, p in ipairs(game.connected_players) do
        local notify = not no_notify_players[pi]
        local left = p.gui.left
        local frame = left[main_frame_name]
        if frame and frame.valid then
            local frame_data = Gui.get_data(frame)
            redraw_tasks(frame_data)
        elseif notify then
            draw_main_frame(left)
        end

        if notify then
            p.print(message)
        end
    end
end

local function player_created(event)
    local player = game.players[event.player_index]
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

        redraw_tasks(data)
    end

    local tasks_for_player = player_tasks[player.index]
    if tasks_for_player and next(tasks_for_player) then
        for _, p in game.connected_players do
            local frame = p.gui.left[main_frame_name]
            if frame and frame.valid then
                local data = Gui.get_data(frame)
                local volunteer_buttons = data.volunteer_buttons

                for t, _ in pairs(tasks_for_player) do
                    update_volunteer_button(volunteer_buttons[t], t)
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
    local player = game.players[event.player_index]
    local left = player.gui.left

    local frame = left[edit_announcements_frame_name]
    if frame and frame.valid then
        close_edit_announcments_frame(frame)
    end
end

Event.add(defines.events.on_player_joined_game, player_created)
Event.add(defines.events.on_player_left_game, player_left)

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

        Gui.set_data(frame, data)

        local top_flow = frame.add {type = 'flow'}
        local last_edit_player_label = top_flow.add {type = 'label'}
        local editing_players_label = top_flow.add {type = 'label'}

        local textbox =
            frame.add {type = 'text-box', name = edit_announcements_textbox_name, text = announcements.edit_text}
        textbox.word_wrap = true
        local textbox_style = textbox.style
        textbox_style.width = 400
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

Gui.on_click(
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
        close_edit_announcments_frame(frame)
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
        close_edit_announcments_frame(frame)

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

        for pi, _ in pairs(task.volunteers) do
            local tasks_for_player = player_tasks[pi]
            if tasks_for_player then
                tasks_for_player[task] = nil
            end
        end

        for pi, p in ipairs(game.connected_players) do
            local notify = not no_notify_players[pi]
            local left = p.gui.left
            local frame = left[main_frame_name]
            if frame and frame.valid then
                local data = Gui.get_data(frame)
                redraw_tasks(data)
            elseif notify then
                draw_main_frame(left)
            end

            if notify then
                p.print(message)
            end
        end
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
            redraw_tasks(data)
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

        local player_index = event.player_index
        local volunteers = task.volunteers

        if volunteers[player_index] then
            volunteers[player_index] = nil

            local tasks_for_player = player_tasks[player_index]
            tasks_for_player[task] = nil
        else
            volunteers[player_index] = event.player

            local tasks_for_player = player_tasks[player_index]
            if not tasks_for_player then
                tasks_for_player = {}
                player_tasks[player_index] = tasks_for_player
            end

            tasks_for_player[task] = true
        end

        for _, p in ipairs(game.connected_players) do
            local frame = p.gui.left[main_frame_name]
            if frame and frame.valid then
                local data = Gui.get_data(frame)
                local volunteer_buttons = data.volunteer_buttons

                update_volunteer_button(volunteer_buttons[task], task)
            end
        end
    end
)

Gui.on_click(
    add_task_button_name,
    function(event)
        local player = event.player
        local left = player.gui.left
        local frame = left[create_task_frame_name]

        if frame then
            return
        end

        frame = left.add {type = 'frame', name = create_task_frame_name, caption = 'New Task', direction = 'vertical'}

        local textbox = frame.add {type = 'text-box'}
        local textbox_style = textbox.style
        textbox_style.width = 400

        local bottom_flow = frame.add {type = 'flow'}

        local close_button = bottom_flow.add {type = 'button', name = create_task_close_button_name, caption = 'Close'}
        Gui.set_data(close_button, frame)
        local clear_button = bottom_flow.add {type = 'button', name = create_task_clear_button_name, caption = 'Clear'}
        Gui.set_data(clear_button, textbox)
        bottom_flow.add({type = 'flow'}).style.horizontally_stretchable = true
        local confirm_button =
            bottom_flow.add {type = 'button', name = create_task_confirm_button_name, caption = 'Create Task'}
        Gui.set_data(confirm_button, {frame = frame, textbox = textbox})
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

        local frame = data.frame
        local textbox = data.textbox
        local task_name = textbox.text

        Gui.destroy(frame)

        create_new_tasks(task_name, event.player)
    end
)

commands.add_command(
    'task',
    '<task> - Creates a new task (Admins and regulars only).',
    function(cmd)
        local player = game.player

        if player then
            if not player.admin and not UserGroups.is_regular(player.name) then
                cant_run(cmd.name)
                return
            end
        else
            player = server_player
        end

        local task_name = cmd.parameter

        if not task_name or task_name == '' then
            player.print('Usage: /task <task>')
            return
        end

        create_new_tasks(task_name, player)
    end
)
