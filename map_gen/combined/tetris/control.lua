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
local states = {
    normal = 1,
    drop = 2,
    pause = 3,
}
primitives = {
    tetri_spawn_y_position = -160,
    winner_option_index = 0,
    state = states.normal
}
local player_votes = {}
local options = {
    {
        name = 'Rotate counter clockwise',
        button_name_key = 'ccw_button_name',
        action_func_name = 'rotate',
        args = {false},
        transition = 1,
    },{
        name = 'Rotate counter clockwise',
        button_name_key = 'cw_button_name',
        action_func_name = 'rotate',
        args = {true},
        transition = 1,
    },{
        name = 'Move left',
        button_name_key = 'left_button_name',
        action_func_name = 'move',
        args = {-1, 0},
        transition = 1,
    },{
        name = 'Drop',
        button_name_key = 'down_button_name',
        transition = 2,
    },{
        name = 'Move right',
        button_name_key = 'right_button_name',
        action_func_name = 'move',
        args = {1, 0},
        transition = 1,
    },
}

local player_zoom = {}
Global.register(
    {
        tetriminos = tetriminos,
        primitives = primitives,
        player_votes = player_votes,
        player_zoom = player_zoom,
    },
    function(tbl)
        tetriminos = tbl.tetriminos
        primitives = tbl.primitives
        player_votes = tbl.player_votes
        player_zoom = tbl.player_zoom
    end
)

local function calculate_winner()
    if primitives.state == states.drop then
        return --Halt vote if in drop mode
    end
    local vote_sum = {0,0,0,0,0}
    for _, vote in ipairs(player_votes) do
        vote_sum[vote] = vote_sum[vote] + 1
    end

    local winners = {}
    local max = math.max(vote_sum[1], vote_sum[2], vote_sum[3], vote_sum[4], vote_sum[5])
    if max == 0 then
        Debug.print('No votes')
        View.set_next_move('None')
        return
    end
    for candidate, n_votes in ipairs(vote_sum) do
        if max == n_votes then
            table.insert(winners, candidate)
        end
    end
    local winner_option_index = winners[math.random(#winners)]
    primitives.winner_option_index = winner_option_index
    local winner = options[winner_option_index].name
    View.set_next_move(winner)
    Debug.print('Calculated winner: ' .. winner)
end

local function player_vote(player, option_index)
    player_votes[player.index] = option_index
    local vote_name = 'None'
    if option_index then
        vote_name =  options[option_index].name
    end
    Debug.print(player.name .. ' voted for ' .. vote_name)
    View.set_player_vote(player, vote_name)
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
View.bind_button(
    View.button_uids.clear_button_name,
    function(player)
        player_vote(player, nil) -- Clear player vote
    end
)

View.bind_button(
    View.button_uids.zoom_button_name,
    function(player)
        local zoom = player_zoom[player.index] or 1
        if zoom == 1 then
            zoom = 0.13
        else
            zoom = 1
        end
        player.zoom = zoom
        player_zoom[player.index] = zoom
    end
)

local function spawn_new_tetrimino()
    table.insert(tetriminos, Tetrimino.new(game.surfaces.nauvis, {x = 0, y = primitives.tetri_spawn_y_position}))
end

local function row_full(tetri)
    local bottom = tetri:bottom_position()

    local y = tetri.position.y + 16 * bottom - 14
    for x = -178, 162, 16 do
        local tile = tetri.surface.get_tile(x, y)
        if tile.valid and tile.name == 'water' then
            return false
        end
    end
    return true
end

local function tetrimino_finished(tetri)
    local final_y_position = tetri.position.y
    if final_y_position < (primitives.tetri_spawn_y_position + 160) then
        primitives.tetri_spawn_y_position = final_y_position - 176
        game.forces.player.chart(tetri.surface, {{-192, final_y_position - 240},{160, final_y_position - 176}})
    end

    if primitives.state == states.drop then
        View.set_next_move('None')
    end
    primitives.state = states.normal
    Debug.print('state ' .. primitives.state)

    Debug.print('Row full: ' .. tostring(row_full(tetri)))

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
            if not tetri:move(0, 1) then
                tetrimino_finished(tetri) --If collided with ground fire finished event
                tetriminos[key] = nil
            end
        end
    end
)

global.speed = 2

spawn_new_tetrimino_token = Token.register(spawn_new_tetrimino)
Event.on_init(function()
    game.forces.player.chart(game.surfaces.nauvis, {{-192, -304}, {160, 0}})
    Task.set_timeout_in_ticks(300, spawn_new_tetrimino_token)
end)
Event.on_nth_tick(61, function()
    if
        primitives.state == states.pause or
        (
            (game.tick % (610 / global.speed)) ~= 0 and
            primitives.state == states.normal
        )
    then
        return
    end

    Task.set_timeout_in_ticks(16, move_down)

    if primitives.state == states.drop then
        return
    end

    for key, tetri in pairs(tetriminos) do --Execute voted action
        local winner = options[primitives.winner_option_index]
        --Execute voted action
        if winner then
            local action = tetri[winner.action_func_name]
            if action then
                action(tetri, winner.args[1], winner.args[2])
            end
            primitives.state = winner.transition --Change system state
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
    if primitives.state == states.normal then --Keep showing 'none if dropping'
        View.set_next_move('None')
    end
    for player_index, _ in ipairs(player_votes) do -- reset poll
        player_votes[player_index] = nil
        local player = Game.get_player_by_index(player_index)
        View.set_player_vote(player, 'None')
    end
end)

Event.add(defines.events.on_player_left_game, function(event)
    player_votes[event.player_index] = nil
end)

Event.add(defines.events.on_player_created, function(event)
    local player = Game.get_player_by_index(event.player_index)
    player.teleport{8,8}
end)
return Map.get_map()