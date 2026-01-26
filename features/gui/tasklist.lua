local Color = require 'resources.color_presets'
local Command = require 'utils.command'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local math = require 'utils.math'
local Rank = require 'features.rank_system'
local Ranks = require 'resources.ranks'
local Settings = require 'utils.redmew_settings'
local Utils = require 'utils.core'

local normal_color = Color.white
local focus_color = Color.dark_orange
local label_max_length = 80

local notify_name = 'notify_task'
Settings.register(notify_name, Settings.types.boolean, true, 'tasklist.notify_caption_short')

local server_player = {
    valid = true,
    index = 0,
    name = '<server>',
    admin = true,
    print = print,
}

local init_announcements = 'There are no announcements.'
local announcements = {
    text = init_announcements,
    edit_text = init_announcements,
    editing_players = {},
    last_edit_player = nil,
    last_update_player = nil,
    last_update_time = nil,
}
local tasks = {}
local player_tasks = {}
local tasks_counter = { 0 }
local last_task_update_data = {
    player = nil,
    time = nil,
}
local no_notify_players = {}

Global.register({
    announcements = announcements,
    tasks = tasks,
    player_tasks = player_tasks,
    tasks_counter = tasks_counter,
    last_task_update_data = last_task_update_data,
    no_notify_players = no_notify_players,
}, function(tbl)
    announcements = tbl.announcements
    tasks = tbl.tasks
    player_tasks = tbl.player_tasks
    tasks_counter = tbl.tasks_counter
    last_task_update_data = tbl.last_task_update_data
    no_notify_players = tbl.no_notify_players
end)

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

local STYLES = {
    count_button = {
        height = 26,
        width = 26,
        padding = 0,
        font = 'default-small',
    },
    default_button = {
        width = 26,
        height = 26,
        padding = 2,
    },
    direction_button = {
        width = 26,
        height = 26,
        padding = 0,
        font = 'default-listbox',
    },
    textbox = {
        maximal_width = 1e6,
        maximal_height = 1e6,
        minimal_width = 450,
        minimal_height = 100,
        horizontally_stretchable = true,
    },
}

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
        'Updated by: [color=yellow][font=count-font]',
        player.name,
        '[/font][/color] \nTime: [color=yellow][font=count-font]',
        Utils.format_time(game.tick - announcements.last_update_time),
        '[/font][/color] ago',
    }
end

local function get_edit_announcements_last_player_message()
    local player = announcements.last_edit_player
    if not player then
        return ''
    end

    return 'Last edit by [color=yellow][font=count-font]' .. player.name .. '[/font][/color]'
end

local function get_editing_players_message(players)
    local message = { 'Editing players: [color=yellow][font=count-font]' }

    for pi, _ in pairs(players) do
        local name = game.get_player(pi).name
        table.insert(message, name)
        table.insert(message, '[color=white],[/color] ')
    end
    table.remove(message)
    table.insert(message, '[/font][/color]')

    return table.concat(message)
end

local function get_task_updated_by_message()
    local player = last_task_update_data.player

    if not player then
        return ''
    end

    return table.concat {
        'Updated by: [color=yellow][font=count-font]',
        player.name,
        '[/font][/color] \nTime: [color=yellow][font=count-font]',
        Utils.format_time(game.tick - last_task_update_data.time),
        '[/font][/color] ago',
    }
end

local function set_updated_by(element, caption)
    local get_updated_by
    if caption == 'Announcements' then
        get_updated_by = get_announcements_updated_by_message
    elseif caption == 'Tasks' then
        get_updated_by = get_task_updated_by_message
    end

    if not get_updated_by then
        return
    end

    local last_edit_message = get_updated_by()
    element.caption = caption .. ' ' .. (#last_edit_message == 0 and '' or ' [img=info]')
    element.tooltip = last_edit_message
end

local function get_task_label_caption(task)
    local caption = task.name
    if #caption > label_max_length then
        caption = caption:sub(1, label_max_length) .. ' [...]'
    end
    return table.concat { '#', task.task_id, ' ', caption }
end

local function get_task_label_tooltip(task, game_tick)
    local tooltip = { task.name, '\n\n', 'Created by: [color=yellow][font=count-font]', task.created_by.name, '[/font][/color]' }

    local edited_by = task.edited_by
    if edited_by then
        table.insert(tooltip, '\nEdited by [color=yellow][font=count-font]')
        for _, p in pairs(edited_by) do
            table.insert(tooltip, p.name)
            table.insert(tooltip, '[color=white],[/color] ')
        end
        table.remove(tooltip)
        table.insert(tooltip, '[/font][/color]')
    end

    table.insert(tooltip, '\nTime: [color=yellow][font=count-font]')
    table.insert(tooltip, Utils.format_time(game_tick - task.tick))
    table.insert(tooltip, '[/font][/color] ago')

    return table.concat(tooltip)
end

local function update_volunteer_button(button, task)
    local volunteers = task.volunteers

    local tooltip = { 'Volunteers: ' }
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

local function update_top_gui(player)
    local button = Gui.get_top_element(player, main_button_name)
    if button and button.valid then
        button.number = #tasks or 0
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
        parent.add { type = 'label', caption = { 'task.empty_tasks' } }
        return
    end

    local game_tick = game.tick
    local delete_button_tooltip = enabled and { 'task.delete_tooltip' } or { 'task.regular_required' }
    local edit_button_tooltip = enabled and { 'task.edit_tooltip' } or { 'task.regular_required' }
    local up_button_tooltip = enabled and { 'task.up_tooltip' } or { 'task.regular_required' }
    local down_button_tooltip = enabled and { 'task.down_tooltip' } or { 'task.regular_required' }

    for task_index, task in ipairs(tasks) do
        local buttons_flow = parent.add { type = 'frame', style = 'deep_frame_in_shallow_frame' }.add { type = 'table', column_count = 5, style = 'table' }
        Gui.set_style(buttons_flow.parent, { padding = 0, margin = 0 })
        Gui.set_style(buttons_flow, { horizontal_spacing = 0, vertical_spacing = 0, padding = 0, margin = 0 })

        local delete_button = buttons_flow.add {
            type = 'sprite-button',
            name = delete_task_button_name,
            sprite = 'utility/trash',
            tooltip = delete_button_tooltip,
            style = 'tool_button_red',
        }
        delete_button.enabled = enabled
        Gui.set_style(delete_button, STYLES.default_button)
        Gui.set_data(delete_button, task_index)

        local edit_button = buttons_flow.add {
            type = 'sprite-button',
            name = edit_task_button_name,
            sprite = 'utility/rename_icon',
            tooltip = edit_button_tooltip,
            style = 'green_button',
        }
        edit_button.enabled = enabled
        Gui.set_style(edit_button, STYLES.default_button)
        Gui.set_data(edit_button, task)

        local up_button = buttons_flow.add {
            type = 'button',
            name = move_task_up_button_name,
            caption = '▲',
            tooltip = up_button_tooltip,
        }
        up_button.enabled = enabled and task_index ~= 1
        Gui.set_style(up_button, STYLES.direction_button)
        Gui.set_data(up_button, task_index)

        local down_button = buttons_flow.add {
            type = 'button',
            name = move_task_down_button_name,
            caption = '▼',
            tooltip = down_button_tooltip,
        }
        down_button.enabled = enabled and task_index ~= task_count
        Gui.set_style(down_button, STYLES.direction_button)
        Gui.set_data(down_button, task_index)

        local volunteer_button = buttons_flow.add {
            type = 'button',
            name = volunteer_task_button_name,
        }
        Gui.set_style(volunteer_button, STYLES.count_button)
        Gui.set_data(volunteer_button, task)
        update_volunteer_button(volunteer_button, task)

        volunteer_buttons[task.task_id] = volunteer_button

        local label = parent.add {
            type = 'label',
            caption = get_task_label_caption(task),
            tooltip = get_task_label_tooltip(task, game_tick),
        }
        Gui.set_style(label, { left_padding = 4, single_line = false })

        task_labels[task_index] = label
    end
end

local function draw_main_frame(left, player)
    local enabled = Rank.equal_or_greater_than(player.name, Ranks.regular)

    local data = {}

    local edit_announcements_button_tooltip = enabled and { 'announcement.edit_tooltip' } or { 'announcement.regular_required' }
    local add_task_button_tooltip = enabled and { 'task.create_tooltip' } or { 'task.regular_required' }

    local frame = left.add { type = 'frame', name = main_frame_name, direction = 'vertical' }
    Gui.set_style(frame, { width = 470 })
    Gui.set_data(frame, data)

    local canvas = frame.add { type = 'flow', direction = 'vertical' }
    Gui.set_style(canvas, { vertical_spacing = 8 })

    do -- Announcements
        local inner = canvas.add { type = 'frame', style = 'inside_shallow_frame', direction = 'vertical' }
        local header = inner.add { type = 'frame', style = 'subheader_frame' }.add { type = 'flow', direction = 'horizontal' }

        local announcements_updated_label = header.add { type = 'label', style = 'subheader_caption_label' }
        set_updated_by(announcements_updated_label, 'Announcements')
        data.announcements_updated_label = announcements_updated_label

        Gui.add_pusher(header)

        header.add {
            type = 'sprite-button',
            name = announcements_edit_button_name,
            sprite = 'utility/rename_icon',
            tooltip = edit_announcements_button_tooltip,
            style = 'tool_button',
            enabled = enabled,
        }

        local announcements_textbox = inner.add {
            type = 'text-box',
            text = announcements.text,
        }
        announcements_textbox.read_only = true
        announcements_textbox.word_wrap = true
        Gui.set_style(announcements_textbox, STYLES.textbox)

        data.announcements_textbox = announcements_textbox
    end

    do -- Tasks
        local inner = canvas.add { type = 'frame', style = 'inside_shallow_frame', direction = 'vertical' }
        local header = inner.add { type = 'frame', style = 'subheader_frame' }.add { type = 'flow', direction = 'horizontal' }

        local tasks_updated_label = header.add { type = 'label', style = 'subheader_caption_label' }
        set_updated_by(tasks_updated_label, 'Tasks')
        data.tasks_updated_label = tasks_updated_label

        Gui.add_pusher(header)

        header.add {
            type = 'sprite-button',
            name = add_task_button_name,
            sprite = 'utility/add',
            tooltip = add_task_button_tooltip,
            style = 'tool_button',
            enabled = enabled,
        }

        local tasks_scroll_pane = inner.add { type = 'scroll-pane', direction = 'vertical' }
        Gui.set_style(tasks_scroll_pane, { width = 450, maximal_height = 250 })

        local tasks_content = tasks_scroll_pane.add { type = 'table', column_count = 2 }
        Gui.set_style(tasks_content, { horizontal_spacing = 0, vertical_spacing = 0, padding = 8 })
        data.tasks_content = tasks_content

        redraw_tasks(data, enabled)
    end

    local state = Settings.get(player.index, notify_name)
    local notify_checkbox = frame.add {
        type = 'checkbox',
        name = notify_checkbox_name,
        state = state,
        caption = { 'tasklist.notify_caption' },
        tooltip = { 'tasklist.notify_tooltip' },
    }
    data.notify_checkbox = notify_checkbox

    Gui.make_close_button(frame, main_button_name)
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
    local left = Gui.get_left_flow(player)
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
        local main_button = Gui.get_top_element(player, main_button_name)
        main_button.toggled = false
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

    local update_message = { 'announcement.updated_by', player.name }

    for _, p in ipairs(game.connected_players) do
        local notify = not no_notify_players[p.index]

        if notify then
            p.print(update_message)
        end

        local left = Gui.get_left_flow(p)
        local frame = left[main_frame_name]
        if frame and frame.valid then
            local data = Gui.get_data(frame)
            data.announcements_textbox.text = text

            set_updated_by(data.announcements_updated_label, 'Announcements')
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
        volunteers = {},
    }

    table.insert(tasks, task)

    last_task_update_data.player = player
    last_task_update_data.time = tick

    local message = table.concat {
        player.name,
        ' has create a new task #',
        task_id,
        ' - ',
        task_name,
    }

    for _, p in ipairs(game.connected_players) do
        local notify = not no_notify_players[p.index]
        local left = Gui.get_left_flow(p)
        local frame = left[main_frame_name]
        if frame and frame.valid then
            local frame_data = Gui.get_data(frame)
            set_updated_by(frame_data.tasks_updated_label, 'Tasks')

            local enabled = Rank.equal_or_greater_than(p.name, Ranks.regular)
            redraw_tasks(frame_data, enabled)
        elseif notify then
            draw_main_frame(left, p)
        end

        update_top_gui(p)

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
        frame_caption = 'Edit task #' .. previous_task.task_id
        confirm_button_name = create_task_edit_button_name
        confirm_button_caption = 'Edit task'
        text = previous_task.name
    else
        frame_caption = 'Create new task'
        confirm_button_name = create_task_confirm_button_name
        confirm_button_caption = 'Create task'
    end

    local frame = left.add { type = 'frame', name = create_task_frame_name, caption = frame_caption, direction = 'vertical', style = 'non_draggable_frame' }
    Gui.set_style(frame, { width = 470 })

    local textbox = frame.add { type = 'textfield', text = text }
    Gui.set_style(textbox, { width = 450 })

    local bottom_flow = frame.add { type = 'flow' }

    local close_button = Gui.make_close_button(bottom_flow, create_task_close_button_name)
    Gui.set_data(close_button, frame)

    local clear_button = bottom_flow.add { type = 'button', name = create_task_clear_button_name, caption = 'Clear' }
    Gui.set_data(clear_button, textbox)

    bottom_flow.add({ type = 'flow' }).style.horizontally_stretchable = true

    local confirm_button = bottom_flow.add { type = 'button', name = confirm_button_name, caption = confirm_button_caption }
    Gui.set_data(confirm_button, { frame = frame, textbox = textbox, previous_task = previous_task })
end

local function player_created(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    Gui.add_top_element(player, {
        type = 'sprite-button',
        name = main_button_name,
        sprite = 'item/repair-pack',
        tooltip = { 'tasklist.tooltip' },
        number = #tasks or 0,
        auto_toggle = true,
    })
end

local function player_joined(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local frame = Gui.get_left_element(player, main_frame_name)
    if frame and frame.valid then
        local text = announcements.edit_text

        local data = Gui.get_data(frame)

        data.announcements_textbox.text = text

        set_updated_by(data.announcements_updated_label, 'Announcements')

        local enabled = Rank.equal_or_greater_than(player.name, Ranks.regular)
        redraw_tasks(data, enabled)
    end

    local tasks_for_player = player_tasks[player.index]
    if tasks_for_player and next(tasks_for_player) then
        for _, p in ipairs(game.connected_players) do
            local main_frame = Gui.get_left_element(p, main_frame_name)
            if main_frame then
                local data = Gui.get_data(main_frame)
                local volunteer_buttons = data.volunteer_buttons

                for index, task in pairs(tasks_for_player) do
                    update_volunteer_button(volunteer_buttons[index], task)
                end
            end
        end
    end
end

local function player_left(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end
    local frame = Gui.get_left_element(player, edit_announcements_frame_name)
    if frame and frame.valid then
        close_edit_announcements_frame(frame)
    end
end

local function player_removed(event)
    announcements.editing_players[event.player_index] = nil
    player_tasks[event.player_index] = nil
    no_notify_players[event.player_index] = nil
end

local function on_tick()
    for _, p in ipairs(game.connected_players) do
        local frame = Gui.get_left_element(p, main_frame_name)

        if frame then
            local data = Gui.get_data(frame)
            set_updated_by(data.tasks_updated_label, 'Tasks')
            set_updated_by(data.announcements_updated_label, 'Announcements')

            local game_tick = game.tick
            for task_index, label in ipairs(data.task_labels) do
                label.tooltip = get_task_label_tooltip(tasks[task_index], game_tick)
            end
        end

        update_top_gui(p)
    end
end

Event.add(defines.events.on_player_created, player_created)
Event.add(defines.events.on_player_joined_game, player_joined)
Event.add(defines.events.on_player_left_game, player_left)
Event.add(defines.events.on_player_removed, player_removed)
Event.on_nth_tick(60 * 59, on_tick)

Gui.on_click(main_button_name, toggle)

Gui.on_click(announcements_edit_button_name, function(event)
    local player = event.player

    local frame = Gui.get_left_element(player, edit_announcements_frame_name)
    if frame then
        return
    end

    local data = {}

    frame = Gui.add_left_element(player, {
        type = 'frame',
        name = edit_announcements_frame_name,
        caption = 'Edit announcements',
        direction = 'vertical',
    })
    frame.style.width = 470

    Gui.set_data(frame, data)

    local top_flow = frame.add { type = 'flow' }
    local last_edit_player_label = top_flow.add { type = 'label' }
    local editing_players_label = top_flow.add { type = 'label' }

    local textbox = frame.add {
        type = 'text-box',
        name = edit_announcements_textbox_name,
        text = announcements.edit_text,
    }
    textbox.word_wrap = true
    Gui.set_style(textbox, STYLES.textbox)
    data.textbox = textbox

    local bottom_flow = frame.add { type = 'flow' }

    local close_button = Gui.make_close_button(bottom_flow, edit_close_button_name)
    local clear_button = bottom_flow.add { type = 'button', name = edit_clear_button_name, caption = 'Clear' }
    local reset_button = bottom_flow.add { type = 'button', name = edit_reset_button_name, caption = 'Reset' }
    bottom_flow.add({ type = 'flow' }).style.horizontally_stretchable = true
    local confirm_button = bottom_flow.add { type = 'button', name = edit_confirm_button_name, caption = 'Confirm' }

    Gui.set_data(close_button, frame)
    Gui.set_data(clear_button, textbox)
    Gui.set_data(reset_button, textbox)
    Gui.set_data(confirm_button, frame)

    announcements.editing_players[player.index] = {
        textbox = textbox,
        last_edit_player_label = last_edit_player_label,
        editing_players_label = editing_players_label,
    }

    local last_edit_message = get_edit_announcements_last_player_message()
    local editing_players_message = get_editing_players_message(announcements.editing_players)

    last_edit_player_label.caption = last_edit_message
    last_edit_player_label.tooltip = last_edit_message
    editing_players_label.caption = editing_players_message
    editing_players_label.tooltip = editing_players_message
end)

Gui.on_checked_state_changed(notify_checkbox_name, function(event)
    local player_index = event.player_index
    local checkbox = event.element
    local state = checkbox.state

    local no_notify
    if state then
        no_notify = nil
    else
        no_notify = true
    end

    no_notify_players[player_index] = no_notify
    Settings.set(player_index, notify_name, state)
end)

Gui.on_click(edit_close_button_name, function(event)
    local frame = Gui.get_data(event.element)
    close_edit_announcements_frame(frame)
end)

Gui.on_click(edit_clear_button_name, function(event)
    local text = ''
    local textbox = Gui.get_data(event.element)
    textbox.text = text
    update_edit_announcements_textbox(text, event.player)
end)

Gui.on_click(edit_reset_button_name, function(event)
    local text = announcements.text
    local textbox = Gui.get_data(event.element)
    textbox.text = text
    update_edit_announcements_textbox(text, event.player)
end)

Gui.on_click(edit_confirm_button_name, function(event)
    local frame = Gui.get_data(event.element)
    close_edit_announcements_frame(frame)

    local player = event.player
    update_announcements(player)
end)

Gui.on_text_changed(edit_announcements_textbox_name, function(event)
    local textbox = event.element
    local text = textbox.text

    update_edit_announcements_textbox(text, event.player)
end)

Gui.on_click(delete_task_button_name, function(event)
    local task_index = Gui.get_data(event.element)

    local task = table.remove(tasks, task_index)

    local message = table.concat {
        event.player.name,
        ' has deleted task #',
        task.task_id,
        ' - ',
        task.name,
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
        local left = Gui.get_left_flow(p)
        local frame = left[main_frame_name]
        if frame and frame.valid then
            local data = Gui.get_data(frame)
            local enabled = Rank.equal_or_greater_than(p.name, Ranks.regular)
            redraw_tasks(data, enabled)
        elseif notify then
            draw_main_frame(left, p)
        end

        update_top_gui(p)

        if notify then
            p.print(message)
        end
    end
end)

Gui.on_click(edit_task_button_name, function(event)
    local previous_task = Gui.get_data(event.element)
    local left = Gui.get_left_flow(event.player)
    local frame = left[create_task_frame_name]

    if frame then
        Gui.destroy(frame)
    end

    draw_create_task_frame(left, previous_task)
end)

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
        local frame = Gui.get_left_element(p, main_frame_name)
        if frame and frame.valid then
            local data = Gui.get_data(frame)
            local enabled = Rank.equal_or_greater_than(p.name, Ranks.regular)
            redraw_tasks(data, enabled)
        end
    end
end

Gui.on_click(move_task_up_button_name, function(event)
    do_direction(event, -1)
end)

Gui.on_click(move_task_down_button_name, function(event)
    do_direction(event, 1)
end)

Gui.on_click(volunteer_task_button_name, function(event)
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
        local frame = Gui.get_left_element(p, main_frame_name)
        if frame and frame.valid then
            local data = Gui.get_data(frame)
            local volunteer_buttons = data.volunteer_buttons

            update_volunteer_button(volunteer_buttons[task_id], task)
        end
    end
end)

Gui.on_click(add_task_button_name, function(event)
    local left = Gui.get_left_flow(event.player)
    local frame = left[create_task_frame_name]

    if frame then
        Gui.destroy(frame)
    end

    draw_create_task_frame(left)
end)

Gui.on_click(create_task_close_button_name, function(event)
    local frame = Gui.get_data(event.element)
    Gui.destroy(frame)
end)

Gui.on_click(create_task_clear_button_name, function(event)
    local textbox = Gui.get_data(event.element)
    textbox.text = ''
end)

Gui.on_click(create_task_confirm_button_name, function(event)
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
end)

Gui.on_click(create_task_edit_button_name, function(event)
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

    local message = table.concat {
        event.player.name,
        ' has edited task #',
        task.task_id,
        ' - ',
        name,
    }

    for _, p in ipairs(game.connected_players) do
        local notify = not no_notify_players[p.index]
        local left = Gui.get_left_flow(p)
        local main_frame = left[main_frame_name]

        if main_frame then
            local main_frame_data = Gui.get_data(main_frame)

            set_updated_by(main_frame_data.tasks_updated_label, 'Tasks')
            local enabled = Rank.equal_or_greater_than(p.name, Ranks.regular)
            redraw_tasks(main_frame_data, enabled)
        elseif notify then
            draw_main_frame(left, p)
        end

        if notify then
            p.print(message)
        end
    end
end)

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Event.add(Settings.events.on_setting_set, function(event)
    if event.setting_name ~= notify_name then
        return
    end

    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player or not player.valid then
        return
    end

    local state = event.new_value
    local no_notify
    if state then
        no_notify = nil
    else
        no_notify = true
    end

    no_notify_players[player_index] = no_notify

    local frame = Gui.get_left_element(player, main_frame_name)
    if not frame then
        return
    end

    local data = Gui.get_data(frame)
    local checkbox = data.notify_checkbox

    checkbox.state = state
end)

Command.add('task', {
    description = { 'command_description.task' },
    arguments = { 'task' },
    required_rank = Ranks.regular,
    allowed_by_server = true,
    log_command = true,
    capture_excess_arguments = true,
}, function(args, player)
    create_new_tasks(args.task, player or server_player)
end)
