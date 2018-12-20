local Module = {}

local Gui = require 'utils.gui'
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()

local button_uids = {
    ['ccw_button_name'] = Gui.uid_name(),
    ['clear_button_name'] = Gui.uid_name(),
    ['cw_button_name'] = Gui.uid_name(),
    ['left_button_name'] = Gui.uid_name(),
    ['down_button_name'] = Gui.uid_name(),
    ['right_button_name'] = Gui.uid_name(),
    ['zoom_button_name'] = Gui.uid_name(),
}

Module.button_uids = button_uids

local votes = {}
local primitives = {next_move = ""}

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
    local left = player.gui.left
    local main_frame = left[main_frame_name]

    if main_frame and main_frame.valid then
        Gui.remove_data_recursively(main_frame)
        main_frame.destroy()
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

        local upper_b_f = main_frame.add {type = 'flow', direction = 'horizontal'}
        local lower_b_f = main_frame.add {type = 'flow', direction = 'horizontal'}

        upper_b_f.add{type = 'sprite-button', name = button_uids.ccw_button_name, sprite = 'utility/hint_arrow_left'}
        upper_b_f.add{type = 'sprite-button', name = button_uids.clear_button_name, sprite = 'utility/trash_bin'}
        upper_b_f.add{type = 'sprite-button', name = button_uids.cw_button_name, sprite = 'utility/hint_arrow_right'}

        lower_b_f.add{type = 'sprite-button', name = button_uids.left_button_name, sprite = 'utility/left_arrow'}
        lower_b_f.add{type = 'sprite-button', name = button_uids.down_button_name, sprite = 'utility/speed_down'}
        lower_b_f.add{type = 'sprite-button', name = button_uids.right_button_name, sprite = 'utility/right_arrow'}
        
        main_frame.add{
            type = 'label',
            caption = 'Your vote:   ' .. (votes[player.index] or 'None')
        }
        
        main_frame.add{
            type = 'label',
            caption = 'Next move: ' .. primitives.next_move
        }

        main_frame.add{type = 'sprite-button', name = button_uids.zoom_button_name, sprite = 'utility/search_icon'}

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

Gui.on_click(main_button_name, function(event) toggle(event.player) end)

function Module.bind_button(button_uid, handler)
    Gui.on_click(button_uid, function(event)
        handler(event.player) end
    )
end

function Module.set_player_vote(player, value)
    votes[player.index] = value
    toggle(player) --TODO: Fix this
    toggle(player)
end

function Module.set_next_move(next_move) 
    primitives.next_move = next_move
    for _,p in pairs(game.players) do 
        toggle(p) --TODO: Fix this
        toggle(p)
    end
end

Event.add(defines.events.on_player_joined_game, player_joined)

return Module