local Gui = require 'utils.gui'
local Utils = require 'utils.core'
local Game = require 'utils.game'
local Global = require 'utils.global'
local Command = require 'utils.command'
local Popup = require 'features.gui.popup'
local Color = require 'resources.color_presets'

local format = string.format

local report_frame_name = Gui.uid_name()
local report_close_button_name = Gui.uid_name()
local report_tab_button_name = Gui.uid_name()
local jail_offender_button_name = Gui.uid_name()
local report_body_name = Gui.uid_name()
local jail_name = 'Jail'
local default_group = 'Default'
local prefix = '------------------NOTICE-------------------'
local prefix_e = '--------------------------------------------'

local Module = {}

-- Global registered locals
local report_data = {}
local jail_data = {}

Global.register(
    {
        report_data = report_data,
        jail_data = jail_data
    },
    function(tbl)
        report_data = tbl.report_data
        jail_data = tbl.jail_data
    end
)

local function report_command(args, player)
    local reported_player_name = args.player
    local reported_player = game.players[reported_player_name]

    if not reported_player then
        Game.player_print(reported_player_name .. ' does not exist.')
        return nil
    end

    Module.report(player, reported_player, args.message)
    Game.player_print('Your report has been sent.')
end

local function draw_report(parent, report_id)
    local report = report_data[report_id]
    if report_id == 0 or not report then
        parent.add {type = 'label', caption = 'No reports yet.'}
        return
    end

    local reported_player_name = Game.get_player_by_index(report.reported_player_index).name
    local reporting_player_name = '<script>'
    if report.reporting_player_index then
        reporting_player_name = Game.get_player_by_index(report.reporting_player_index).name
    end
    local time = Utils.format_time(report.tick)
    local time_ago = Utils.format_time(game.tick - report.tick)

    local message = report.message
    Gui.clear(parent)

    local permission_group = game.permissions.get_group(jail_name)
    local jail_offender_button_caption = (Game.get_player_by_index(report.reported_player_index).permission_group == permission_group) and 'Unjail ' .. reported_player_name or 'Jail ' .. reported_player_name

    parent.add {type = 'label', caption = 'Offender: ' .. reported_player_name}
    local msg_label_pane = parent.add {type = 'scroll-pane', vertical_scroll_policy = 'auto-and-reserve-space', horizontal_scroll_policy = 'never'}
    msg_label_pane.style.maximal_height = 400
    local msg_label = msg_label_pane.add {type = 'label', caption = 'Message: ' .. message}
    local jail_offender_button = parent.add {type = 'button', name = jail_offender_button_name, caption = jail_offender_button_caption}
    jail_offender_button.style.height = 24
    jail_offender_button.style.font = 'default-small'
    jail_offender_button.style.top_padding = 0
    jail_offender_button.style.bottom_padding = 0
    jail_offender_button.style.left_padding = 0
    jail_offender_button.style.right_padding = 0
    msg_label.style.single_line = false
    msg_label.style.maximal_width = 680
    parent.add {type = 'label', caption = string.format('Time: %s (%s ago)', time, time_ago)}
    parent.add {type = 'label', caption = 'Reported by: ' .. reporting_player_name}
end

Module.show_reports =
    function(player)
    local reports = report_data

    local center = player.gui.center

    local report_frame = center[report_frame_name]
    if report_frame and report_frame.valid then
        Gui.destroy(report_frame)
    end

    report_frame =
        center.add {
        type = 'frame',
        name = report_frame_name,
        direction = 'vertical',
        caption = 'User reports'
    }
    report_frame.style.maximal_width = 700
    player.opened = report_frame

    if #reports > 1 then
        local scroll_pane = report_frame.add {type = 'scroll-pane', horizontal_scroll_policy = 'auto-and-reserve-space', vertical_scroll_policy = 'never'}
        local tab_flow = scroll_pane.add {type = 'flow'}
        for k, report in pairs(reports) do
            local button_cell = tab_flow.add {type = 'flow', caption = 'reportuid' .. k}
            button_cell.add {
                type = 'button',
                name = report_tab_button_name,
                caption = Game.get_player_by_index(report.reported_player_index).name
            }
        end
    end
    local report_body = report_frame.add {type = 'scroll-pane', name = report_body_name, horizontal_scroll_policy = 'never', vertical_scroll_policy = 'never'}
    report_frame.add {type = 'button', name = report_close_button_name, caption = 'Close'}

    draw_report(report_body, #reports)
end

function Module.report(reporting_player, reported_player, message)
    local player_index
    if reporting_player then
        player_index = reporting_player.index
        reporting_player.print('Your report has been sent.')
    end
    table.insert(report_data, {reporting_player_index = player_index, reported_player_index = reported_player.index, message = message, tick = game.tick})

    local notified = false
    for _, p in pairs(game.players) do
        if p.admin and p.connected then
            p.play_sound {path = 'utility/tutorial_notice', volume_modifier = 1}
            Module.show_reports(p)
            if p.afk_time < 3600 then
                notified = true
            end
        end
    end
    if not notified then
        for _, p in pairs(game.players) do
            if p.admin then
                Module.show_reports(p)
            end
        end
    end
end

--- Places a target in jail
-- @param target_player <LuaPlayer> the target to jail
-- @param player <LuaPlayer|nil> the admin as LuaPlayer or server as nil
function Module.jail(target_player, player)
    local print
    if player then
        print = player.print
    else
        player = {name = 'server'}
        print = log
    end

    if not target_player then
        print('Unknown player.')
        return
    end

    local target_name = target_player.name
    local permissions = game.permissions

    -- Check if the permission group exists, if it doesn't, create it.
    local permission_group = permissions.get_group(jail_name)
    if not permission_group then
        permission_group = permissions.create_group(jail_name)

        -- Set all permissions to disabled
        for action_name, _ in pairs(defines.input_action) do
            permission_group.set_allows_action(defines.input_action[action_name], false)
        end
    end

    local former_permission_group = target_player.permission_group
    if former_permission_group == permission_group then
        print(format('Player %s is already in jail.', target_name))
        return
    end

    -- Enable writing to console to allow a person to speak, and allow them to edit permission group so that an admin can unjail themselves
    permission_group.set_allows_action(defines.input_action.write_to_console, true)
    permission_group.set_allows_action(defines.input_action.edit_permission_group, true)

    -- Add player to jail group
    permission_group.add_player(target_player)

    -- If in vehicle, kick them out and set the speed to 0.
    local vehicle = target_player.vehicle
    if vehicle then
        local train = vehicle.train
        -- Trains can't have their speed set via ent.speed and instead need ent.train.speed
        if train then
            train.speed = 0
        else
            vehicle.speed = 0
        end
        target_player.driving = false
    end

    -- If a player is shooting when they're jailed they can't stop shooting, so we change their shooting state
    if target_player.shooting_state.state ~= 0 then
        target_player.shooting_state.state = {state = defines.shooting.not_shooting, position = {0, 0}}
    end

    -- Stop player walking while jailed
    if target_player.walking_state.walking == true then
        target_player.walking_state = {walking = false, direction = defines.direction.north}
    end

    -- Check they're in jail
    if target_player.permission_group == permission_group then
        -- Let admin know it worked, let target know what's going on.
        target_player.clear_console()
        Popup.player(target_player, 'You have been jailed.\nRespond to queries from the mod team.')
        Utils.print_admins(format('%s has been jailed by %s', target_name, player.name))
        Utils.log_command(Utils.get_actor(), 'jail', target_name)

        local character = target_player.character
        local former_char_dest
        if character and character.valid then
            former_char_dest = character.destructible
            character.destructible = false
        end

        jail_data[target_player.index] = {
            name = target_name,
            perm_group = former_permission_group,
            char_dest = former_char_dest,
            color = target_player.color,
            chat_color = target_player.chat_color
        }

        target_player.color = Color.white
        target_player.chat_color = Color.white
    else
        -- Let admin know it didn't work.
        print(format('Something went wrong in the jailing of %s. You can still change their group via /permissions.', target_name))
    end
end

--- Removes a target from jail
-- @param target_player <LuaPlayer> the target to unjail
-- @param player <LuaPlayer|nil> the admin as LuaPlayer or server as nil
function Module.unjail(target_player, player)
    local print
    if player then
        print = player.print
    else
        player = {name = 'server'}
        print = log
    end

    if not target_player then
        print('Unknown player.')
        return
    end

    local target_name = target_player.name
    local target_index = target_player.index
    local target_jail_data = jail_data[target_index]

    local permissions = game.permissions
    local jail_permission_group = permissions.get_group(jail_name)
    if (not jail_permission_group) or target_player.permission_group ~= jail_permission_group or not target_jail_data then
        Game.player_print(format('%s is already not in Jail.', target_name))
        return
    end

    -- Check if the player's former permission group exists, if it doesn't, create it.
    local permission_group = target_jail_data.perm_group or permissions.get_group(default_group)
    if not permission_group then
        permission_group = permissions.create_group(default_group)
    end

    -- Move player
    permission_group.add_player(target_player)
    -- Set player to a non-shooting state (solves a niche case where players jailed while shooting will be locked into a shooting state)
    target_player.shooting_state.state = 0

    -- Restore player's state from stored data
    local character = target_player.character
    if character and character.valid then
        character.destructible = target_jail_data.char_dest
    end
    target_player.color = target_jail_data.color
    target_player.chat_color = target_jail_data.chat_color
    jail_data[target_index] = nil

    -- Check that it worked
    if target_player.permission_group == permission_group then
        -- Let admin know it worked, let target know what's going on.
        Game.player_print(target_name .. ' has been returned to the default group. They have been advised of this.')
        target_player.print(prefix)
        target_player.print('Your ability to perform actions has been restored', Color.light_green)
        target_player.print(prefix_e)
        Utils.print_admins(format('%s has been released from jail by %s', target_name, player.name))
        Utils.log_command(Utils.get_actor(), 'unjail', target_name)
    else
        -- Let admin know it didn't work.
        Game.player_print(format('Something went wrong in the unjailing of %s. You can still change their group via /permissions and inform them.', target_name))
    end
end

Gui.on_custom_close(
    report_frame_name,
    function(event)
        Gui.destroy(event.element)
    end
)

Gui.on_click(
    report_close_button_name,
    function(event)
        Gui.destroy(event.element.parent)
    end
)

Gui.on_click(
    jail_offender_button_name,
    function(event)
        local target_name = string.sub(event.element.caption, 6)
        local target = game.players[target_name]
        if target then
            Module.jail(target, event.player)
        else
            target_name = string.sub(event.element.caption, 8)
            target = game.players[target_name]
            if target then
                Module.unjail(target, event.player)
            end
        end
        Module.show_reports(event.player)
        Module.show_reports(event.player) -- Double toggle, first destroy then draw.
    end
)

Gui.on_click(
    report_tab_button_name,
    function(event)
        local center = event.player.gui.center
        local report_frame = center[report_frame_name]
        local report_uid_str = string.sub(event.element.parent.caption, 10)
        local report_uid = tonumber(report_uid_str)
        draw_report(report_frame[report_body_name], report_uid)
    end
)

local reporting_popup_name = Gui.uid_name()
local reporting_cancel_button_name = Gui.uid_name()
local reporting_submit_button_name = Gui.uid_name()
local reporting_input_name = Gui.uid_name()

Module.spawn_reporting_popup =
    function(player, reported_player)
    local center = player.gui.center

    local reporting_popup = center[reporting_popup_name]
    if reporting_popup and reporting_popup.valid then
        Gui.destroy(reporting_popup)
    end
    reporting_popup =
        center.add {
        type = 'frame',
        name = reporting_popup_name,
        direction = 'vertical',
        caption = 'Report player ' .. reported_player.name
    }
    Gui.set_data(reporting_popup, {reported_player_index = reported_player.index})

    reporting_popup.style.maximal_width = 500
    player.opened = reporting_popup
    reporting_popup.add {
        type = 'label',
        caption = 'Report message:'
    }
    local input = reporting_popup.add {type = 'text-box', name = reporting_input_name}
    input.style.width = 400
    input.style.height = 85
    local button_flow = reporting_popup.add {type = 'flow'}
    button_flow.add {type = 'button', name = reporting_submit_button_name, caption = 'Submit'}
    button_flow.add {type = 'button', name = reporting_cancel_button_name, caption = 'Cancel'}
end

Gui.on_custom_close(
    reporting_popup_name,
    function(event)
        Gui.destroy(event.element)
    end
)

Gui.on_click(
    reporting_cancel_button_name,
    function(event)
        local frame = event.element.parent.parent
        Gui.destroy(frame)
    end
)

Gui.on_click(
    reporting_submit_button_name,
    function(event)
        local frame = event.element.parent.parent
        local msg = frame[reporting_input_name].text
        local data = Gui.get_data(frame)
        local reported_player_index = data['reported_player_index']
        local print = event.player.print

        Gui.destroy(frame)
        Module.report(event.player, Game.get_player_by_index(reported_player_index), msg)
        print(prefix)
        print('You have successfully reported: ' .. Game.get_player_by_index(reported_player_index).name)
        print(prefix_e)
    end
)

Command.add(
    'report',
    {
        description = {'command_description.report'},
        arguments = {'player', 'message'},
        capture_excess_arguments = true
    },
    report_command
)

return Module
