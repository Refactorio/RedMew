local Module = {}

local Gui = require 'utils.gui'
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()

local uids = {
    ['ccw_button'] = Gui.uid_name(),
    ['clear_button'] = Gui.uid_name(),
    ['cw_button'] = Gui.uid_name(),
    ['left_button'] = Gui.uid_name(),
    ['down_button'] = Gui.uid_name(),
    ['right_button'] = Gui.uid_name(),
    ['zoom_button'] = Gui.uid_name(),
    ['points_label'] = Gui.uid_name(),
}

local button_pretty_names = {
    ['ccw_button'] = 'Rotate counter clockwise',
    ['cw_button'] = 'Rotate clockwise',
    ['left_button'] = 'Move left',
    ['down_button'] = 'Move down',
    ['right_button'] = 'Move right',
}
Module.uids = uids

local primitives = {points = 0}
local vote_players = {
    ccw_button = {},
    cw_button = {},
    left_button = {},
    down_button = {},
    right_button = {},
}
local vote_numbers = {
    ccw_button = 0,
    cw_button = 0,
    left_button = 0,
    down_button = 0,
    right_button = 0,
}
Global.register(
    {
        primitives = primitives,
        vote_players = vote_players,
        vote_numbers = vote_numbers,
    },
    function(tbl)
        primitives = tbl.primitives
        vote_players = tbl.vote_players
        vote_numbers = tbl.vote_numbers
    end
)

local function button_tooltip(button_key)
    local n = 0
    local tooltip = ''
    local names = {}
    local non_zero = false
    for p_name, _ in pairs(vote_players[button_key]) do
        non_zero = true
        tooltip = string.format('%s, %s', p_name, tooltip) --If you have a better solution please tell me. Lol.
    end
    if non_zero then
        return string.format('%s: %s', button_pretty_names[button_key], tooltip:sub(1, -3))
    end
    return button_pretty_names[button_key]
end

local function toggle(player)
    if not player then return end
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
            caption = 'Tetris',
        }
        main_frame.style.width = 250
        main_frame.add {
            type = 'label',
            caption = 'Vote on the next move!'
        }

        local upper_b_f = main_frame.add{type = 'flow', direction = 'horizontal'}
        local lower_b_f = main_frame.add{type = 'flow', direction = 'horizontal'}

        local vote_buttons = {
            [uids.ccw_button] = upper_b_f.add{type = 'sprite-button', tooltip = button_tooltip('cw_button'), number = vote_numbers.ccw_button, name = uids.ccw_button, sprite = 'utility/reset'},
            [uids.clear_button] = upper_b_f.add{type = 'sprite-button', name = uids.clear_button._n, sprite = 'utility/trash_bin'},
            [uids.cw_button] = upper_b_f.add{type = 'sprite-button', tooltip = button_tooltip('cw_button'), number = vote_numbers.cw_button, name = uids.cw_button, sprite = 'utility/reset'},

            [uids.left_button] = lower_b_f.add{type = 'sprite-button', tooltip = button_tooltip('left_button'), number = vote_numbers.left_button,  name = uids.left_button, sprite = 'utility/left_arrow'},
            [uids.down_button] = lower_b_f.add{type = 'sprite-button', tooltip = button_tooltip('down_button'), number = vote_numbers.down_button, name = uids.down_button, sprite = 'utility/speed_down'},
            [uids.right_button] = lower_b_f.add{type = 'sprite-button', tooltip = button_tooltip('right_button'), number = vote_numbers.right_button, name = uids.right_button, sprite = 'utility/right_arrow'},
        }

        main_frame.add{type = 'sprite-button', name = uids.zoom_button, sprite = 'utility/search_icon'}

        local points_f = main_frame.add{type = 'flow', direction = 'horizontal'}
        points_f.add{
            type = 'label',
            caption = 'Points: ',
        }

        local points = points_f.add {
            type = 'label',
            caption = primitives.points,
        }

        local data = {
            vote_buttons = vote_buttons,
            points = points,
        }
        Gui.set_data(main_frame, data)
    end
end

local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)

    if player.gui.top[main_button_name] ~= nil then
        return
    end

    player.gui.top.add{name = main_button_name, type = 'sprite-button', sprite = 'utility/force_editor_icon'}
    toggle(Game.get_player_by_index(event.player_index))
end

Gui.on_click(main_button_name, function(event) toggle(event.player) end)

function Module.bind_button(button_uid, handler)
    Gui.on_click(button_uid, function(event)
        handler(event.player) end
    )
end

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

local function change_vote_button(data, player_name, button_key, change, set)
    local element = data.vote_buttons[uids[button_key]]
    local number = vote_numbers[button_key] + change
    vote_numbers[button_key] = number
    element.number = number
    vote_players[button_key][player_name] = set
    element.tooltip = button_tooltip(button_key)
end

function Module.set_player_vote(player, value, vote_button_key, old_vote_button_key)
    local mf = player.gui.left[main_frame_name]
    if mf then
        local data = Gui.get_data(mf)

        if vote_button_key then
            change_vote_button(data, player.name, vote_button_key, 1, true)
        end

        if old_vote_button_key then
            change_vote_button(data, player.name, old_vote_button_key, -1)
        end
    end
end

function Module.disable_vote_buttons()
    for _,player in pairs(game.players) do
        local mf = player.gui.left[main_frame_name]
        if mf then
            local data = Gui.get_data(mf)
            if data then
                local buttons = data.vote_buttons
                for _, button in pairs(buttons) do
                    button.enabled = false
                end
            end
        end
    end
end
disable = Module.disable

Event.add(defines.events.on_player_joined_game, player_joined)

return Module