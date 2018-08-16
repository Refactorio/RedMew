local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Global = require 'utils.global'
local UserGroups = require 'user_groups'
local Utils = require 'utils.utils'

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

local no_notify_players = {}

Global.register(
    {
        announcements = announcements,
        tasks = tasks,
        no_notify_announcements_players = no_notify_players
    },
    function(tbl)
        announcements = tbl.announcements
        tasks = tbl.tasks
        no_notify_players = tbl.no_notify_announcements_players
    end
)

local main_frame_name = Gui.uid_name()
local main_button_name = Gui.uid_name()
local announcements_edit_button_name = Gui.uid_name()
local notify_checkbox_name = Gui.uid_name()

local edit_announcements_frame_name = Gui.uid_name()
local edit_announcements_textbox_name = Gui.uid_name()
local edit_close_button_name = Gui.uid_name()
local edit_clear_button_name = Gui.uid_name()
local edit_reset_button_name = Gui.uid_name()
local edit_confirm_button_name = Gui.uid_name()

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

local function draw_main_frame(left)
    local data = {}

    local frame = left.add {type = 'frame', name = main_frame_name, caption = 'Tasks', direction = 'vertical'}
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
    announcements_textbox_style.width = 500
    announcements_textbox_style.height = 100

    data.announcements_textbox = announcements_textbox
    data.announcements_updated_label = announcements_updated_label

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
    else
        draw_main_frame(left)
    end
end

local function update_edit_announcements_textbox(text, player)
    announcements.edit_text = text
    announcements.last_edit_player = player
    local editing_players = announcements.editing_players

    local last_edit_message = get_edit_announcements_last_player_message()
    local editing_players_message = get_editing_players_message(editing_players)

    for _, data in pairs(editing_players) do
        data.textbox.text = text

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
        textbox_style.width = 500
        textbox_style.height = 100

        data.textbox = textbox

        local bottom_flow = frame.add {type = 'flow'}

        local close_button = bottom_flow.add {type = 'button', name = edit_close_button_name, caption = 'Close'}
        bottom_flow.add {type = 'button', name = edit_clear_button_name, caption = 'Clear'}
        bottom_flow.add {type = 'button', name = edit_reset_button_name, caption = 'Reset'}
        bottom_flow.add({type = 'flow'}).style.horizontally_stretchable = true
        local confirm_button = bottom_flow.add {type = 'button', name = edit_confirm_button_name, caption = 'Confirm'}

        Gui.set_data(close_button, frame)
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
        update_edit_announcements_textbox('', event.player)
    end
)

Gui.on_click(
    edit_reset_button_name,
    function(event)
        update_edit_announcements_textbox(announcements.text, event.player)
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
