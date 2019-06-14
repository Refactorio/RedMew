local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Global = require 'utils.global'
local Command = require 'utils.command'
local Debug = require 'utils.debug'
local Gui = require 'utils.gui'

local set_timeout_in_ticks = Task.set_timeout_in_ticks
local debug_print = Debug.print

local skip_btn_name = Gui.uid_name()
local backward_btn_name = Gui.uid_name()
local forward_btn_name = Gui.uid_name()

local Public = {}
local handler

local cutscene_functions = {}
local running_cutscenes = {}
local replay = {
    identifier = nil,
    final_transition_time = nil
}
Global.register(
    {
        cutscene_functions = cutscene_functions,
        running_cutscenes = running_cutscenes,
        replay = replay
    },
    function(tbl)
        cutscene_functions = tbl.cutscene_functions
        running_cutscenes = tbl.running_cutscenes
        replay = tbl.replay
    end
)

local function valid(entity)
    return entity and entity.valid
end

local function waypoint_still_active(tick, player_index)
    local running_cutscene = running_cutscenes[player_index]
    tick = tick or -1
    if tick == -1 then
        debug_print('Tick was nil', 5)
    end
    if not running_cutscene or tick < running_cutscene.start_tick then
        return false
    end
    return true
end

local toggle_gui_delayed =
    Token.register(
    function(params)
        local player = params.player
        if not waypoint_still_active(params.tick, player.index) then
            debug_print('Cutscene is no longer active. Skipping toggle_gui')
            return
        end
        local event = {player = player}
        local clear = params.clear
        if clear == 'left' then
            player.gui.left.clear()
        elseif clear == 'top' then
            player.gui.top.clear()
        elseif clear == 'center' then
            player.gui.center.clear()
        end
        params.gui.toggle(event)
    end
)

function Public.toggle_gui(tick, player, gui, initial_delay, clear)
    --[[if type(gui) == 'table' then
        debug_print('Provided GUI is invalid.')
        return
    end]]
    set_timeout_in_ticks(initial_delay, toggle_gui_delayed, {tick = tick, player = player, gui = gui, clear = clear})
end

local play_sound_delayed =
    Token.register(
    function(params)
        local player = params.player
        if not waypoint_still_active(params.tick, player.index) then
            debug_print('Cutscene is no longer active. Skipping play_sound')
            return
        end
        player.play_sound {path = params.path}
    end
)

function Public.play_sound(tick, player, path, times, delay, initial_delay)
    if not game.is_valid_sound_path(path) then
        debug_print('Provided SoundPath is invalid. Try opening /radio and browse for a valid path')
        return
    end

    if not waypoint_still_active(tick, player.index) then
        debug_print('Cutscene is no longer active. Skipping play_sound')
        return
    end

    times = times or 1
    if times == 1 and not delay and initial_delay then
        delay = initial_delay
    end
    if times > 1 or delay then
        delay = delay or 20
        initial_delay = initial_delay or 0
        for i = 1, times, 1 do
            set_timeout_in_ticks(initial_delay + delay * i, play_sound_delayed, {tick = tick, player = player, path = path})
        end
    else
        player.play_sound {path = path}
    end
end

local remove_renderings =
    Token.register(
    function(renderings)
        for _, v in pairs(renderings) do
            if rendering.is_valid(v) then
                rendering.destroy(v)
                debug_print('Deleted rendering with id: ' .. v)
            end
        end
    end
)

---Asserts if a given variable is of the expected type using type().
---
---@param expected_type string
---@param given any
---@param variable_reference_message string displayed when the expectation is not met
local function assert_type(expected_type, given, variable_reference_message, allow_nil)
    local given_type = type(given)
    if given_type ~= expected_type and (allow_nil and given_type ~= 'nil') then
        error('Argument ' .. variable_reference_message .. " must be of type '" .. expected_type .. "', given '" .. given_type .. "'")
    end
end

function Public.register_cutscene_function(identifier, waypoints, func, terminate_func)
    assert_type('string', identifier, 'identifier of function cutscene_controller.register_cutscene_function')
    assert_type('table', waypoints, 'waypoints of function cutscene_controller.register_cutscene_function')
    assert_type('number', func, 'func of function cutscene_controller.register_cutscene_function')
    assert_type('number', terminate_func, 'func of function cutscene_controller.register_cutscene_function', true)

    cutscene_functions[identifier] = {func = func, waypoints = waypoints, update = false, terminate_func = terminate_func}
end

function Public.register_running_cutscene(player_index, identifier, final_transition_time)
    assert_type('number', player_index, 'player_index of function cutscene_controller.register_running_cutscene')
    assert_type('string', identifier, 'identifier of function cutscene_controller.register_running_cutscene')
    assert_type('number', final_transition_time, 'identifier of function cutscene_controller.register_running_cutscene', true)

    local player = game.get_player(player_index)
    if not valid(player) then
        return
    end

    local cutscene_function = cutscene_functions[identifier]
    if not cutscene_function then
        return
    end

    local waypoints = cutscene_function.waypoints
    if not waypoints then
        return
    end

    if running_cutscenes[player_index] then
        player.print({'cutscene_controller.cannot_start_new'})
        return
    end

    running_cutscenes[player_index] = {
        func = cutscene_function.func,
        waypoints = waypoints,
        update = cutscene_function.update,
        final_transition_time = final_transition_time,
        character = player.character,
        terminate_func = cutscene_function.terminate_func,
        rendering = {},
        current_index = -1,
        start_tick = 0
    }
    local running_cutscene = running_cutscenes[player_index]

    if player.controller_type == defines.controllers.cutscene then
        debug_print('' .. player.name .. ' was already in another cutscene not controlled by this module. It has been stopped')
        player.exit_cutscene()
    end
    player.set_controller {type = defines.controllers.ghost}

    final_transition_time = final_transition_time >= 0 and final_transition_time or 60
    running_cutscene.final_transition_time = final_transition_time
    running_cutscene.identifier = identifier
    player.set_controller {
        type = defines.controllers.cutscene,
        waypoints = waypoints,
        final_transition_time = final_transition_time
    }

    local flow = player.gui.top.add {type = 'flow'}
    running_cutscene.btn = flow

    local btn = flow.add {type = 'sprite-button', name = skip_btn_name, caption = 'Skip cutscene'}
    btn.style.minimal_height = 28
    btn.style.minimal_width = 150
    btn.style.font = 'default-large-bold'
    btn.style.font_color = {r = 255, g = 215, b = 0}

    local back_btn = flow.add {type = 'sprite-button', name = backward_btn_name, caption = 'Go back'}
    back_btn.style.minimal_height = 28
    back_btn.style.minimal_width = 100
    back_btn.style.font = 'default-large-bold'
    back_btn.style.font_color = {r = 255, g = 215, b = 0}

    local forward_btn = flow.add {type = 'sprite-button', name = forward_btn_name, caption = 'Go forward'}
    forward_btn.style.minimal_height = 28
    forward_btn.style.minimal_width = 100
    forward_btn.style.font = 'default-large-bold'
    forward_btn.style.font_color = {r = 255, g = 215, b = 0}

    handler({player_index = player_index, waypoint_index = -1, tick = game.tick})
end

local function restart_cutscene(player_index, waypoints, start_index)
    local current_running = running_cutscenes[player_index]
    local final_transition_time = current_running.final_transition_time
    current_running.update = false
    local character = current_running.character

    if not character then
        log('Player index: ' .. player_index .. ' managed to lose their character in a cutscene')
    end

    local end_waypoint = {
        -- end waypoint
        position = character.position,
        transition_time = final_transition_time,
        time_to_wait = 1,
        zoom = 1,
        terminate = true
    }

    table.insert(waypoints, end_waypoint)

    running_cutscenes[player_index] = {
        func = current_running.func,
        waypoints = waypoints,
        update = false,
        final_transition_time = final_transition_time,
        character = character,
        terminate_func = current_running.terminate_func,
        rendering = current_running.rendering,
        btn = current_running.btn,
        current_index = current_running.current_index,
        start_tick = current_running.start_tick
    }

    debug_print('Updating cutscene for player_index ' .. player_index)
    debug_print(running_cutscenes[player_index])

    local player = game.get_player(player_index)
    if not valid(player) then
        return
    end

    if player.controller_type == defines.controllers.cutscene then
        player.exit_cutscene()
        player.set_controller {type = defines.controllers.ghost}
    end

    player.set_controller {
        type = defines.controllers.cutscene,
        waypoints = waypoints,
        final_transition_time = final_transition_time
    }

    if start_index then
        player.jump_to_cutscene_waypoint(start_index + 1)
    else
        start_index = -1
    end

    handler({player_index = player_index, waypoint_index = start_index, tick = game.tick})
end

function Public.inject_waypoint(player_index, waypoint, waypoint_index, override)
    local running_cutscene = running_cutscenes[player_index]
    if not running_cutscene then
        return
    end
    local waypoints = running_cutscene.waypoints
    if not waypoints then
        return
    end
    local copy_waypoints = {}
    for i = 1, #waypoints do
        table.insert(copy_waypoints, waypoints[i])
    end
    if override then
        copy_waypoints[waypoint_index] = waypoint
    else
        table.insert(copy_waypoints, waypoint_index, waypoint)
    end
    running_cutscene.update = copy_waypoints
end

local callback_function =
    Token.register(
    function(params)
        local player_index = params.player_index
        local func_params = params.params
        if waypoint_still_active(func_params.tick, player_index) then
            Token.get(params.func)(player_index, params.waypoint_index, func_params)
        else
            debug_print('Skipping callback function. Cutscene got terminated!')
        end
    end
)

local reconnect_character =
    Token.register(
    function(params)
        local player_index = params.player_index
        local player = game.get_player(player_index)
        local running_cutscene = params.running_cutscene
        local character = running_cutscene.character
        local func = running_cutscene.terminate_func
        if valid(player) and valid(character) then
            player.exit_cutscene()
            player.set_controller {type = defines.controllers.character, character = character}
            if func then
                Token.get(func)(player_index)
            end
            Token.get(remove_renderings)(running_cutscene.rendering)
            running_cutscene.btn.destroy()
            running_cutscenes[player_index] = nil
        end
    end
)

function Public.terminate_cutscene(player_index, ticks)
    local running_cutscene = running_cutscenes[player_index]
    if not running_cutscene then
        return
    end
    ticks = ticks and ticks or 1
    debug_print('Terminating cutscene in ' .. ticks .. ' Ticks')

    set_timeout_in_ticks(
        ticks,
        reconnect_character,
        {
            player_index = player_index,
            running_cutscene = running_cutscene
        }
    )
end

function Public.register_rendering_id(player_index, tick, render_id)
    if type(render_id) ~= 'table' then
        render_id = {render_id}
    end
    local running_cutscene = running_cutscenes[player_index]
    for _, id in pairs(render_id) do
        if rendering.is_valid(id) then
            if not waypoint_still_active(tick, player_index) then
                debug_print('The rendering with id ' .. id .. ' was not added. Destroying it instead')
                rendering.destroy(id)
            else
                table.insert(running_cutscene.rendering, id)
            end
        end
    end
end

function Public.register_replay(identifier, final_transition_time)
    replay.identifier = identifier
    replay.final_transition_time = final_transition_time
    debug_print('Identifier ' .. identifier .. ' registered as replay cutscene')
end

handler = function(event)
    local player_index = event.player_index
    local waypoint_index = event.waypoint_index
    local tick = event.tick

    debug_print('Waypoint_index ' .. waypoint_index .. ' has finished at tick: ' .. tick)

    local running_cutscene = running_cutscenes[player_index]
    if not running_cutscene then
        return
    end
    running_cutscene.current_index = waypoint_index + 1
    running_cutscene.start_tick = tick

    local update = running_cutscene.update
    if update then
        restart_cutscene(player_index, update, waypoint_index)
        return
    end
    local ticks = running_cutscene.waypoints[waypoint_index + 2]
    if ticks then
        ticks = ticks.transition_time
    else
        ticks = running_cutscene.final_transition_time
    end

    local func = running_cutscene.func
    if not func then
        return
    end
    local current_waypoint = running_cutscene.waypoints[waypoint_index + 2]
    if not current_waypoint or current_waypoint.terminate then
        Public.terminate_cutscene(player_index, ticks)
        return
    end
    local params = {
        position = current_waypoint.position,
        time_to_wait = current_waypoint.time_to_wait,
        transition_time = current_waypoint.transition_time,
        zoom = current_waypoint.zoom,
        name = current_waypoint.name,
        tick = tick
    }

    debug_print('Waypoint_index ' .. waypoint_index + 1 .. ' (waypoint #' .. waypoint_index + 2 .. ') callback in ' .. ticks .. ' ticks')

    set_timeout_in_ticks(ticks, callback_function, {func = running_cutscene.func, player_index = player_index, waypoint_index = waypoint_index, params = params})
end

function Public.goTo(player_index, waypoint_index)
    local running_cutscene = running_cutscenes[player_index]
    if waypoint_index < 0 or waypoint_index > #running_cutscene.waypoints - 2 then
        return false
    end
    Token.get(remove_renderings)(running_cutscene.rendering)
    game.get_player(player_index).jump_to_cutscene_waypoint(waypoint_index)
    handler({player_index = player_index, waypoint_index = waypoint_index - 1, tick = game.tick})
    running_cutscene.current_index = waypoint_index
    return true
end

local function restore(event)
    Public.terminate_cutscene(event.player_index)
end

Event.add(defines.events.on_cutscene_waypoint_reached, handler)
Event.add(defines.events.on_pre_player_left_game, restore)
Event.add(defines.events.on_player_joined_game, restore)

local replay_cutscene =
    Token.register(
    function(params)
        Public.register_running_cutscene(params.event.player_index, replay.identifier, replay.final_transition_time)
    end
)

local function replay_handler(_, player)
    if not replay.identifier then
        player.print({'cutscene_controller.cannot_replay'})
        return
    end
    Token.get(replay_cutscene)({event = {player_index = player.index}})
end

Command.add(
    'replay',
    {
        description = {'cutscene_controller.replay'},
        capture_excess_arguments = false,
        allowed_by_server = false
    },
    replay_handler
)

local function skip_cutscene(_, player)
    if not player or not player.valid then
        return
    end
    if player.controller_type == defines.controllers.cutscene then
        Public.terminate_cutscene(player.index)
    end
end

Command.add(
    'skip',
    {
        description = {'cutscene_controller.skip'},
        capture_excess_arguments = false,
        allowed_by_server = false
    },
    skip_cutscene
)

Gui.on_click(
    skip_btn_name,
    function(event)
        skip_cutscene(nil, game.get_player(event.player_index))
    end
)

Gui.on_click(
    backward_btn_name,
    function(event)
        local player_index = event.player_index
        if Public.goTo(player_index, running_cutscenes[player_index].current_index - 1) == false then
            game.get_player(player_index).print("Cutscene: You're already at the beginning")
        end
    end
)

Gui.on_click(
    forward_btn_name,
    function(event)
        local player_index = event.player_index
        if Public.goTo(event.player_index, running_cutscenes[player_index].current_index + 1) == false then
            game.get_player(player_index).print("Cutscene: You're already at the end")
        end
    end
)

return Public
