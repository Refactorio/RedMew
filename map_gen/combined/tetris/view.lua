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
    ['vote_label_name'] = Gui.uid_name(),
    ['next_move_label'] = Gui.uid_name(),
    ['points_label'] = Gui.uid_name(),
}

Module.uids = uids

local votes = {}
local primitives = {next_move = '', points = 0}

Global.register(
    {
        votes = votes,
        primitives = primitives,
    },
    function(tbl)
        votes = tbl.votes
        primitives = tbl.primitives
    end
)

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

        local vote_buttons = {}
        table.insert(vote_buttons, upper_b_f.add{type = 'sprite-button', name = uids.ccw_button, sprite = 'utility/hint_arrow_left'})
        table.insert(vote_buttons, upper_b_f.add{type = 'sprite-button', name = uids.clear_button, sprite = 'utility/trash_bin'})
        table.insert(vote_buttons, upper_b_f.add{type = 'sprite-button', name = uids.cw_button, sprite = 'utility/hint_arrow_right'})

        table.insert(vote_buttons, lower_b_f.add{type = 'sprite-button', name = uids.left_button, sprite = 'utility/left_arrow'})
        table.insert(vote_buttons, lower_b_f.add{type = 'sprite-button', name = uids.down_button, sprite = 'utility/speed_down'})
        table.insert(vote_buttons, lower_b_f.add{type = 'sprite-button', name = uids.right_button, sprite = 'utility/right_arrow'})
  
        local vote_f = main_frame.add{type = 'flow', direction = 'horizontal'}
        vote_f.add{
            type = 'label',
            caption = 'Your vote:   '
        }
        local vote = vote_f.add {
            type = 'label',
            caption = (votes[player.index] or 'None')
        }
    
        local move_f = main_frame.add {type = 'flow', direction = 'horizontal'}
        move_f.add{
            type = 'label',
            caption = 'Next move: '
        }
        local move = move_f.add {
            type = 'label',
            caption = primitives.next_move
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
            vote = vote,
            move = move,
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

function Module.set_player_vote(player, value)
    votes[player.index] = value
    local mf = player.gui.left[main_frame_name]
    if mf then
        local data = Gui.get_data(mf)
        if data then
            data['vote'].caption = value
        end
    end
end

function Module.set_next_move(next_move)
    primitives.next_move = next_move
    for _,player in pairs(game.players) do
        local mf = player.gui.left[main_frame_name]
        if mf then     
            local data = Gui.get_data(mf)
            if data then
                data['move'].caption = next_move
            end
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