local Event = require 'utils.event'
local Map = require 'map_gen.combined.tetris.shape'
local Token = require 'utils.token'
local Task = require 'utils.schedule'
local Tetrimino = require 'map_gen.combined.tetris.tetrimino'(Map)
local View = require 'map_gen.combined.tetris.view'
local Global = require 'utils.global'
local Game = require 'utils.game'
local Debug = require 'map_gen.Diggy.Debug'


local tetriminos = {}
local primitives = {
    tetri_spawn_y_position = -160, 
    winner_option_index = 0,
    mode = 1 -- 1 == normal, 2 == going down
}
local player_votes = {}
local options = {
    {
        name = 'Rotate counter clockwise',
        button_name_key = 'ccw_button_name',
        action_func_name = 'rotate',
        args = {false},
    },
    {
        name = 'Rotate counter clockwise',
        button_name_key = 'cw_button_name',
        action_func_name = 'rotate',
        args = {true},
    },
    {
        name = 'Move left',
        button_name_key = 'left_button_name',
        action_func_name = 'move',
        args = {-1, 0},
    },
    {
        name = 'Drop',
        button_name_key = 'down_button_name',
        action_func_name = 'move',
        args = {0, 0}, -- Do nothing :D
    },
    {
        name = 'Move right',
        button_name_key = 'right_button_name',
        action_func_name = 'move',
        args = {1, 0},
    },
}

Global.register(
    {
        tetriminos = tetriminos,
        primitives = primitives,
        player_votes = player_votes,
    },
    function(tbl)
        tetriminos = tbl.tetriminos
        primitives = tbl.primitives
        player_votes = tbl.player_votes
    end
)

local function calculate_winner()
    local vote_sum = {0,0,0,0,0}
    for _, vote in ipairs(player_votes) do 
        vote_sum[vote] = vote_sum[vote] + 1
    end
    
    Debug.print(serpent.line(vote_sum))

    local winners = {}
    local max = math.max(vote_sum[1], vote_sum[2], vote_sum[3], vote_sum[4], vote_sum[5])
    for candidate, n_votes in ipairs(vote_sum) do
        if max == n_votes then
            table.insert(winners, candidate)
        end
    end
    local winner_option_index = winners[math.random(#winners)]
    primitives.winner_option_index = winner_option_index
    local winner = options[winner_option_index].name
    View.set_next_move(winner)
    Debug.print("Calculated winner: " .. winner)
end

local function player_vote(player, option_index)
    Debug.print(player.name .. " voted for " .. options[option_index].name)
    player_votes[player.index] = option_index
    View.set_player_vote(player, options[option_index].name)
    calculate_winner()
end


for option_index, option in pairs(options) do 
    View.bind_button(
        View.button_uids[option.button_name_key],
        function(player)
            player_vote(player, option_index)
        end
    )
end

function spawn_new_tetrimino()
    table.insert(tetriminos, Module.new(game.surfaces.nauvis, {x = 0, y = primitives.tetri_spawn_y_position}))
end

local function tetrimino_finished(tetri)
    local final_y_position = tetri.position.y
    if final_y_position < (primitives.tetri_spawn_y_position + 160) then
        primitives.tetri_spawn_y_position = final_y_position - 176
        game.forces.player.chart(game.surfaces.nauvis, {{-192, final_y_position - 240},{160, final_y_position - 176}})
    end
    spawn_new_tetrimino()
end


chart_area = Token.register(
    function(data) 
        data.force.chart(data.surface, data.area)
    end
)

move_down = Token.register(
    function()
        for key, tetri in pairs(tetriminos) do
            if not Tetrimino.move(tetri, 0, 1) then
                tetrimino_finished(tetri) --If collided with ground fire finished event
                tetriminos[key] = nil
            end
        end
    end
)

global.pause = false
global.speed = 5
Event.on_nth_tick(61, function()

    Debug.print(debug.getinfo(2, 'S').source:match('^.+/(.+)$playing/(.+)$'))
    if #tetriminos == 0 and game.tick < 500 and game.tick > 241 then 
        game.forces.player.chart(game.surfaces.nauvis, {{-192, -304}, {160, 0}})
        spawn_new_tetrimino()
    end
    if global.pause or (game.tick % (610 / global.speed)) ~= 0 then
        return
    end

    Task.set_timeout_in_ticks(16, move_down)

    for key, tetri in pairs(tetriminos) do --Move down
        local winner = options[primitives.winner_option_index]
        --Execute voted action
        if winner then
            Tetrimino[winner.action_func_name](tetri, winner.args[1], winner.args[2])
        end
        local pos = tetri.position
        Task.set_timeout_in_ticks(10, chart_area, {
            force = game.forces.player, 
            surface = game.surfaces.nauvis, 
            area = {
                {pos.x - 32, pos.y - 32},
                {pos.x + 64, pos.y + 64}
            }
        })
    end

    primitives.winner_option_index = 0
    View.set_next_move('none')
    for player_index, _ in ipairs(player_votes) do -- reset poll
        player_votes[player_index] = nil
        local player = Game.get_player_by_index(player_index)
        View.set_player_vote(player, 'none')
    end
end)

Event.add(defines.events.on_player_left_game, function(event)
    player_votes[event.player_index] = nil
end)

return Map.get_map()