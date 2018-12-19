local Event = require 'utils.event'
local Map = require 'map_gen.combined.tetris.shape'
local Token = require 'utils.token'
local Task = require 'utils.schedule'
local Tetrimino = require 'map_gen.combined.tetris.tetrimino'(Map)
local View = require 'map_gen.combined.tetris.view'
local Global = require 'utils.global'

local tetriminos = {}
local primitives = {tetri_spawn_y_position = -160}
local player_votes = {}

Global.register(
    {
        tetriminos = tetriminos,
        primitives = primitives,
        player_votes = player_votes,
        winner_index = winner_index,
    },
    function(tbl)
        tetriminos = tbl.tetriminos
        primitives = tbl.primitives
        player_votes = tbl.player_votes
        winner_index = tbl.winner_index
    end
)

local function calculate_winner()
    local vote_sum = {0,0,0,0}
    for _, vote in ipairs(player_votes) do 
        vote_sum[vote] = vote_sum[vote] + 1
    end
    
    local winners = {}
    local max = math.max(vote_sum[1], vote_sum[2], vote_sum[3], vote_sum[4])
    for candidate, n_votes in ipairs(vote_sum) do
        if max == n_votes then
            table.insert(winners, candidate)
        end
    end
    winner_index = winners[math.random(#winners)]
    if winner_index == 1 then 
        View.set_next_move("Rotate counter clockwise")
    elseif winner_index == 2 then 
        View.set_next_move("Rotate clockwise")
    elseif winner_index == 3 then 
        View.set_next_move("Move left")
    elseif winner_index == 4 then 
        View.set_next_move('Move right')
    end
end

View.bind_button(View.button_uids.ccw_button_name, function(player)
    player_votes[player.index] = 1
    View.set_player_vote(player, 'Rotate counter clockwise')
    calculate_winner()
end)
View.bind_button(View.button_uids.cw_button_name, function(player)
    player_votes[player.index] = 2
    View.set_player_vote(player, 'Rotate clockwise')
    calculate_winner()
end)
View.bind_button(View.button_uids.left_button_name, function(player)
    player_votes[player.index] = 3
    View.set_player_vote(player, 'Move left')
    calculate_winner()
end)
View.bind_button(View.button_uids.right_button_name, function(player)
    player_votes[player.index] = 4
    View.set_player_vote(player, 'Move right')
    calculate_winner()
end)

function spawn_new_tetrimino()
    table.insert(tetriminos, Module.new(game.surfaces.nauvis, {x = 0, y = primitives.tetri_spawn_y_position}))
    primitives.tetri_spawn_y_position = primitives.tetri_spawn_y_position - 16
end

local function tetrimino_finished(tetri)
    spawn_new_tetrimino()
end


tick = Token.register(
    function()
        for key, tetri in pairs(tetriminos) do 
            if not Tetrimino.move(tetri, 0, 1) then 
                tetrimino_finished(tetri)
                tetriminos[key] = nil
            end
        end
    end
)


Event.on_nth_tick(121, function()
    if #tetriminos == 0 then 
        spawn_new_tetrimino()
    end
    Task.set_timeout_in_ticks(16, tick)

    for key, tetri in pairs(tetriminos) do 
        if winner_index == 1 then 
            Tetrimino.rotate(tetri)
        elseif winner_index == 2 then 
            Tetrimino.rotate(tetri, true)
        elseif winner_index == 3 then 
            Tetrimino.move(tetri, -1, 0)
        elseif winner_index == 4 then 
            Tetrimino.move(tetri, 1, 0)
        end
    end
end)

Event.add(defines.events.on_player_left_game, function(event)
    player_votes[event.player_index] = nil
end)


return Map.get_map()