local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Global = require 'utils.global'
local Debug = require 'utils.debug'
local Map = require 'map_gen.maps.tetris.shape'
local Tetrimino = require 'map_gen.maps.tetris.tetrimino'(Map)
local View = require 'map_gen.maps.tetris.view'
local InfinityChest = require 'features.infinite_storage_chest'
local states = require 'map_gen.maps.tetris.states'
local StateMachine = require 'utils.state_machine'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local tetriminos = {}
local primitives = {
    tetri_spawn_y_position = -160,
    winner_option_index = 0,
    state = states.voting,
    next_vote_finished = 305,
    points = 0,
    down_substate = 0
}
local player_votes = {}
local options = {
    {
        button = View.button_enum.ccw_button,
        action_func_name = 'rotate',
        args = {false},
        transition = states.moving
    },
    {
        button = View.button_enum.noop_button,
        action_func_name = 'noop',
        args = {},
        transition = states.moving
    },
    {
        button = View.button_enum.cw_button,
        action_func_name = 'rotate',
        args = {true},
        transition = states.moving
    },
    {
        button = View.button_enum.left_button,
        action_func_name = 'move',
        args = {-1, 0},
        transition = states.moving
    },
    {
        button = View.button_enum.down_button,
        transition = states.down
    },
    {
        button = View.button_enum.right_button,
        action_func_name = 'move',
        args = {1, 0},
        transition = states.moving
    },
    {
        button = View.button_enum.pause_button,
        action_func_name = 'noop',
        args = {},
        transition = states.pause
    }
}

local machine = StateMachine.new(states.voting)

local player_zoom = {}
local player_force = nil
local play_surface = nil
Global.register(
    {
        tetriminos = tetriminos,
        primitives = primitives,
        player_votes = player_votes,
        player_zoom = player_zoom,
        machine = machine
    },
    function(tbl)
        tetriminos = tbl.tetriminos
        primitives = tbl.primitives
        player_votes = tbl.player_votes
        player_zoom = tbl.player_zoom
        machine = tbl.machine
    end
)

local point_table = {1, 3, 5, 9}
local tetris_tick_duration = 61
global.vote_delay = 10

-- Use redmew_surface to give us a waterworld and a spawn location
RS.set_spawn_position({x = 8, y = 8})
RS.set_map_gen_settings({MGSP.waterworld})

local function calculate_winner()
    if StateMachine.in_state(machine, states.down) then --TODO: Fix
        return --Halt vote if in down mode
    end
    Debug.print('calculating winner')
    local vote_sum = {0, 0, 0, 0, 0, 0, 0}
    for _, vote in pairs(player_votes) do
        vote_sum[vote] = vote_sum[vote] + 1
    end

    local winners = {}
    local max = math.max(vote_sum[1], vote_sum[2], vote_sum[3], vote_sum[4], vote_sum[5], vote_sum[6], vote_sum[7])
    for candidate, n_votes in pairs(vote_sum) do
        if max == n_votes then
            table.insert(winners, candidate)
        end
        View.set_vote_number(options[candidate].button, n_votes)
    end
    local winner_option_index = 0
    if max > 0 then
        winner_option_index = winners[math.random(#winners)]
    end
    primitives.winner_option_index = winner_option_index
    if _DEBUG and (winner_option_index > 0) then
        Debug.print('Calculated winner: ' .. View.pretty_names[options[winner_option_index].button])
    end
end

local function player_vote(player, option_index)
    local old_vote = player_votes[player.index]
    if old_vote == option_index then
        return
    end
    local vote_button = nil
    local old_vote_button = nil

    if option_index then
        vote_button = options[option_index].button
    end

    if old_vote then
        old_vote_button = options[old_vote].button
    end

    player_votes[player.index] = option_index

    if _DEBUG then
        Debug.print(string.format('%s voted for %s', player.name, View.pretty_names[vote_button]))
    end
    StateMachine.transition(machine, states.voting)

    calculate_winner()

    View.set_player_vote(player, vote_button, old_vote_button)
end

for option_index, option in pairs(options) do
    View.bind_button(
        option.button,
        function(player)
            player_vote(player, option_index)
        end
    )
end

local function spawn_new_tetrimino()
    table.insert(tetriminos, Tetrimino.new(play_surface, {x = 0, y = primitives.tetri_spawn_y_position}))
end

local function collect_full_row_resources(tetri)
    local active_qchunks = Tetrimino.active_qchunks(tetri)
    local storage = {}

    local full_rows = {}
    local rows = {}
    local position = tetri.position
    local tetri_y = position.y
    local surface = tetri.surface
    local get_tile = surface.get_tile
    local find_entities_filtered = surface.find_entities_filtered
    for _, qchunk in pairs(active_qchunks) do
        local q_y = qchunk.y
        if not rows[q_y] then
            rows[q_y] = true
            local y = tetri_y + 16 * q_y - 14
            local row_full = true
            for x = -178, 178, 16 do
                local tile = get_tile(x, y)
                if tile.valid and tile.name == 'water' then
                    row_full = false
                    break
                end
            end

            if row_full then
                table.insert(full_rows, q_y)
                for _, patch in pairs(find_entities_filtered {type = 'resource', area = {{-178, y}, {162, y + 12}}}) do
                    local subtotal = storage[patch.name] or 0
                    storage[patch.name] = subtotal + patch.amount
                    patch.destroy()
                end
            end
        end
    end

    if #full_rows > 0 then
        local points = point_table[#full_rows]
        for resource, amount in pairs(storage) do
            storage[resource] = amount * points
            if resource == 'crude-oil' then
                storage[resource] = nil
                if #full_rows == 1 then
                    return
                end
            end
        end

        local x = position.x + active_qchunks[1].x * 16 - 9
        local y = tetri_y + active_qchunks[1].y * 16 - 9
        local chest = InfinityChest.create_chest(tetri.surface, {x, y}, storage)
        chest.minable = false
        chest.destructible = false

        primitives.points = primitives.points + points * 100
        View.set_points(primitives.points)
    end
end

local function tetrimino_finished(tetri)
    local final_y_position = tetri.position.y
    if final_y_position < (primitives.tetri_spawn_y_position + 352) then
        primitives.tetri_spawn_y_position = final_y_position - 256
        player_force.chart(tetri.surface, {{-192, final_y_position - 352}, {160, final_y_position - 176}})
    end

    StateMachine.transition(machine, states.voting)

    collect_full_row_resources(tetri)

    spawn_new_tetrimino()
end

local chart_area =
    Token.register(
    function(data)
        data.force.chart(data.surface, data.area)
    end
)

local switch_state =
    Token.register(
    function(data)
        StateMachine.transition(machine, data.state)
    end
)

local move_down =
    Token.register(
    function()
        for key, tetri in pairs(tetriminos) do
            if not Tetrimino.move(tetri, 0, 1) then
                tetrimino_finished(tetri) --If collided with ground fire finished event
                tetriminos[key] = nil
            end

            local pos = tetri.position
            Task.set_timeout_in_ticks(
                10,
                chart_area,
                {
                    force = player_force,
                    surface = play_surface,
                    area = {
                        {pos.x - 32, pos.y - 32},
                        {pos.x + 64, pos.y + 64}
                    }
                }
            )
        end
    end
)

local function execute_vote_tick()
    if game.tick < primitives.next_vote_finished then
        return
    end

    local winner = options[primitives.winner_option_index]
    if winner then
        StateMachine.transition(machine, winner.transition)
        View.set_last_move(winner.button)
    else
        View.set_last_move(nil)
        StateMachine.transition(machine, states.moving)
    end

    primitives.winner_option_index = 0
    for player_index, _ in pairs(player_votes) do -- reset poll
        player_votes[player_index] = nil
    end
    View.reset_poll_buttons()
end

local function execute_winner_action()
    for key, tetri in pairs(tetriminos) do --Execute voted action
        local winner = options[primitives.winner_option_index]
        --Execute voted action
        if winner then
            local action = Tetrimino[winner.action_func_name]
            if action then
                action(tetri, winner.args[1], winner.args[2])
            end
        end
    end

    Task.set_timeout_in_ticks(16, move_down)
    Task.set_timeout_in_ticks(26, switch_state, {state = states.voting})
end

local spawn_new_tetrimino_token = Token.register(spawn_new_tetrimino)
Event.on_init(
    function()
        player_force = game.forces.player
        play_surface = RS.get_surface()
        player_force.chart(play_surface, {{-192, -432}, {160, 0}})
        Task.set_timeout_in_ticks(30 * tetris_tick_duration - 15, spawn_new_tetrimino_token)
        View.enable_vote_buttons(true)
    end
)

Event.add(
    defines.events.on_tick,
    function()
        if StateMachine.in_state(machine, states.voting) then
            local progress = (primitives.next_vote_finished - game.tick + 1) / global.vote_delay / tetris_tick_duration
            if progress >= 0 and progress <= 1 then
                View.set_progress(progress)
            end
        end
    end
)

local function execute_down_tick()
    local down_state = primitives.down_substate

    if down_state > 3 then
        primitives.down_substate = 0
        StateMachine.transition(machine, states.voting)
        return
    end

    primitives.down_substate = down_state + 1

    Task.set_timeout_in_ticks(16, move_down)
end

StateMachine.register_state_tick_callback(machine, states.voting, execute_vote_tick)

StateMachine.register_state_tick_callback(machine, states.down, execute_down_tick)

StateMachine.register_transition_callback(
    machine,
    states.voting,
    states.pause,
    function()
        View.enable_vote_buttons(true)
        game.print('Pausing...')
    end
)

StateMachine.register_transition_callback(
    machine,
    states.pause,
    states.voting,
    function()
        primitives.next_vote_finished = global.vote_delay * tetris_tick_duration + game.tick
        game.print('Resuming...')
    end
)

StateMachine.register_transition_callback(
    machine,
    states.moving,
    states.voting,
    function()
        View.enable_vote_buttons(true)
    end
)

StateMachine.register_transition_callback(
    machine,
    states.down,
    states.voting,
    function()
        View.enable_vote_buttons(true)
    end
)

StateMachine.register_transition_callback(
    machine,
    states.voting,
    states.down,
    function()
        primitives.next_vote_finished = (3 + global.vote_delay) * tetris_tick_duration + game.tick
        View.enable_vote_buttons(false)
    end
)

StateMachine.register_transition_callback(
    machine,
    states.voting,
    states.moving,
    function()
        View.enable_vote_buttons(false)
        primitives.next_vote_finished = global.vote_delay * tetris_tick_duration + game.tick
        execute_winner_action()
    end
)

Event.on_nth_tick(
    tetris_tick_duration,
    function()
        StateMachine.machine_tick(machine)
    end
)

Event.add(
    defines.events.on_player_left_game,
    function(event)
        player_votes[event.player_index] = nil
    end
)

return Map.get_map()
