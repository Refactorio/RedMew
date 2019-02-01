local Module = {}

local Gui = require 'utils.gui'
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()

local uids = {
    ['ccw_button'] = Gui.uid_name(),
    ['noop_button'] = Gui.uid_name(),
    ['cw_button'] = Gui.uid_name(),
    ['left_button'] = Gui.uid_name(),
    ['down_button'] = Gui.uid_name(),
    ['right_button'] = Gui.uid_name(),
    ['pause_button'] = Gui.uid_name(),
    ['points_label'] = Gui.uid_name()
}

local button_pretty_names = {
    [uids.ccw_button] = 'Rotate counter clockwise',
    [uids.noop_button] = 'Do nothing',
    [uids.cw_button] = 'Rotate clockwise',
    [uids.left_button] = 'Move left',
    [uids.down_button] = 'Move down',
    [uids.right_button] = 'Move right',
    [uids.pause_button] = 'Pause'
}

local sprites = {
    [uids.ccw_button] = 'utility/reset',
    [uids.noop_button] = 'utility/clear',
    [uids.cw_button] = 'utility/reset',
    [uids.left_button] = 'utility/left_arrow',
    [uids.down_button] = 'utility/speed_down',
    [uids.right_button] = 'utility/right_arrow',
    [uids.pause_button] = 'utility/pause'
}

Module.button_enum = uids
Module.pretty_names = button_pretty_names

local primitives = {
    buttons_enabled = false,
    points = 0,
    progress = 0,
    last_move = nil
}
local vote_players = {
    [uids.ccw_button] = {},
    [uids.noop_button] = {},
    [uids.cw_button] = {},
    [uids.left_button] = {},
    [uids.down_button] = {},
    [uids.right_button] = {},
    [uids.pause_button] = {}
}
local vote_numbers = {
    [uids.ccw_button] = 0,
    [uids.noop_button] = 0,
    [uids.cw_button] = 0,
    [uids.left_button] = 0,
    [uids.down_button] = 0,
    [uids.right_button] = 0,
    [uids.pause_button] = 0
}
Global.register(
    {
        primitives = primitives,
        vote_players = vote_players,
        vote_numbers = vote_numbers
    },
    function(tbl)
        primitives = tbl.primitives
        vote_players = tbl.vote_players
        vote_numbers = tbl.vote_numbers
    end
)

local function button_tooltip(button_id)
    local tooltip = ''
    local non_zero = false
    local players = vote_players[button_id]
    if not players then
        return button_pretty_names[button_id]
    end
    for _, p_name in pairs(vote_players[button_id]) do
        non_zero = true
        tooltip = string.format('%s, %s', p_name, tooltip) --If you have a better solution please tell me. Lol.
    end
    if non_zero then
        return string.format('%s: %s', button_pretty_names[button_id], tooltip:sub(1, -3))
    end
    return button_pretty_names[button_id]
end

local function button_enabled(button_id, player_id)
    return (not vote_players[button_id]) or primitives.buttons_enabled and (not vote_players[button_id][player_id])
end

local function add_sprite_button(element, player, name)
    return element.add {
        type = 'sprite-button',
        name = name,
        enabled = button_enabled(name, player.index),
        tooltip = button_tooltip(name),
        number = vote_numbers[name],
        sprite = sprites[name]
    }
end

local function toggle(player)
    if not player then
        return
    end
    local left = player.gui.left
    local main_frame = left[main_frame_name]

    if main_frame and main_frame.valid then
        Gui.destroy(main_frame)
    else
        main_frame =
            left.add {
            type = 'frame',
            name = main_frame_name,
            direction = 'vertical',
            caption = 'Tetris'
        }
        main_frame.style.width = 250
        main_frame.add {
            type = 'label',
            caption = 'Vote on the next move!'
        }

        local upper_b_f = main_frame.add {type = 'flow', direction = 'horizontal'}
        local lower_b_f = main_frame.add {type = 'flow', direction = 'horizontal'}

        local vote_buttons = {
            [uids.ccw_button] = add_sprite_button(upper_b_f, player, uids.ccw_button),
            [uids.noop_button] = add_sprite_button(upper_b_f, player, uids.noop_button),
            [uids.cw_button] = add_sprite_button(upper_b_f, player, uids.cw_button),
            [uids.left_button] = add_sprite_button(lower_b_f, player, uids.left_button),
            [uids.down_button] = add_sprite_button(lower_b_f, player, uids.down_button),
            [uids.right_button] = add_sprite_button(lower_b_f, player, uids.right_button),
            [uids.pause_button] = add_sprite_button(main_frame, player, uids.pause_button)
        }

        local progress_bar = main_frame.add {type = 'progressbar', value = primitives.progress}

        local points_f = main_frame.add {type = 'flow', direction = 'horizontal'}
        points_f.add {
            type = 'label',
            caption = 'Points: '
        }

        local points =
            points_f.add {
            type = 'label',
            caption = primitives.points
        }
        main_frame.add {
            type = 'label',
            caption = 'Last move:'
        }

        local last_move_tooltip = 'Do nothing'
        local last_move_sprite = nil
        local last_move_button = primitives.last_move
        if last_move_button then
            last_move_tooltip = button_pretty_names[last_move_button]
            last_move_sprite = sprites[last_move_button]
        end
        main_frame.add {
            type = 'sprite-button',
            enabled = false,
            tooltip = last_move_tooltip,
            sprite = last_move_sprite
        }

        local data = {
            vote_buttons = vote_buttons,
            points = points,
            progress_bar = progress_bar
        }
        Gui.set_data(main_frame, data)
    end
end

local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)

    if player.gui.top[main_button_name] ~= nil then
        return
    end

    player.gui.top.add {name = main_button_name, type = 'sprite-button', sprite = 'utility/force_editor_icon'}
    toggle(Game.get_player_by_index(event.player_index))
end

Gui.on_click(
    main_button_name,
    function(event)
        toggle(event.player)
    end
)

function Module.bind_button(button_uid, handler)
    Gui.on_click(
        button_uid,
        function(event)
            handler(event.player)
        end
    )
end

--- Sets the total game points to the given number
-- @param points number
function Module.set_points(points)
    primitives.points = points
    for _, player in pairs(game.players) do
        local mf = player.gui.left[main_frame_name]
        if mf then
            local data = Gui.get_data(mf)
            if data then
                data['points'].caption = points
            end
        end
    end
end

--- Sets the number displayed next to a button
-- @param button_id string the buttons uid
-- @param number number then number that will be displayed
function Module.set_vote_number(button_id, number)
    vote_numbers[button_id] = number
end

--- Adds a players name to the tooltip of a button and (if applicable) removes the name from another button
-- @description Also disabled the selected button an (if applicable) enables the second
-- @param player LuaPlayer
-- @param vote_button_id string the uid of the button that the players name will be added to
-- @param[opt] old_vote_button_id string the uid of the button that the players name will be removed from
function Module.set_player_vote(player, vote_button_id, old_vote_button_id)
    local mf = player.gui.left[main_frame_name]
    if mf then
        local vote_buttons = Gui.get_data(mf).vote_buttons
        if vote_button_id then
            vote_buttons[vote_button_id].enabled = false
            vote_players[vote_button_id][player.index] = player.name
        end

        if old_vote_button_id then
            vote_buttons[old_vote_button_id].enabled = true
            vote_players[old_vote_button_id][player.index] = nil
        end
    end
    for _, p in pairs(game.players) do
        toggle(p)
        toggle(p)
    end
end

--- enables or disables the vote buttons
-- @param enable boolean true if the vote buttons should be enabled, false if not
function Module.enable_vote_buttons(enable)
    primitives.buttons_enabled = enable
    for _, player in pairs(game.players) do
        local mf = player.gui.left[main_frame_name]
        if mf then
            local data = Gui.get_data(mf)
            if data then
                local buttons = data.vote_buttons
                for _, button in pairs(buttons) do
                    button.enabled = button_enabled(button.name, player.index)
                end
            end
        end
    end
end

--- Sets the last move
-- @param button_id string the button id of the last move
function Module.set_last_move(button_id)
    primitives.last_move = button_id
end

--- Resets all poll buttons back to default
function Module.reset_poll_buttons()
    for key, _ in pairs(vote_players) do
        vote_players[key] = {}
        vote_numbers[key] = 0
    end
    for _, player in pairs(game.players) do
        toggle(player)
        toggle(player)
    end
end

--- Sets progressbar denoting the time left until the current vote is finished
-- @param progress number between 0 and 1
function Module.set_progress(progress)
    primitives.progress = progress
    for _, player in pairs(game.players) do
        local mf = player.gui.left[main_frame_name]
        if mf then
            local data = Gui.get_data(mf)
            if data then
                data.progress_bar.value = progress
            end
        end
    end
end

Event.add(defines.events.on_player_joined_game, player_joined)

return Module
