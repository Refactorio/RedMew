local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Global = require 'utils.global'

local Public = {}
local handler

local cutscene_functions = {}
local running_cutscenes = {}
Global.register(
    {
        cutscene_functions = cutscene_functions,
        running_cutscenes = running_cutscenes
    },
    function(tbl)
        cutscene_functions = tbl.cutscene_functions
        running_cutscenes = tbl.running_cutscenes
    end
)

local function valid(entity)
    return entity and entity.valid
end

local remove_renderings = Token.register(function(renderings)
    for _, v in pairs(renderings) do
        --game.print('before valid: ' .. v)
        if rendering.is_valid(v) then
            --game.print('after valid: ' .. v)
            rendering.destroy(v)
        end
    end
end)

---Asserts if a given variable is of the expected type using type().
---
---@param expected_type string
---@param given any
---@param variable_reference_message string displayed when the expectation is not met
local function assert_type(expected_type, given, variable_reference_message)
    local given_type = type(given)
    if given_type ~= expected_type then
        error('Argument ' .. variable_reference_message .. " must be of type '" .. expected_type .. "', given '" .. given_type .. "'")
    end
end

function Public.register_cutscene_function(identifier, waypoints, func, terminate_func)
    assert_type('string', identifier, 'identifier of function cutscene_controller.register_cutscene_function')
    assert_type('number', func, 'func of function cutscene_controller.register_cutscene_function')
    assert_type('table', waypoints, 'waypoints of function cutscene_controller.register_cutscene_function')

    cutscene_functions[identifier] = {func = func, waypoints = waypoints, update = false, terminate_func = terminate_func}
end

function Public.register_running_cutscene(player_index, identifier, final_transition_time)
    assert_type('number', player_index, 'player_index of function cutscene_controller.register_running_cutscene')
    assert_type('string', identifier, 'identifier of function cutscene_controller.register_running_cutscene')

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

    local running_cutscene = running_cutscenes[player_index]
    if running_cutscene then
        player.print('Can not start cutscene, you need to finish your current one. Try /skip')
        return
    end

    running_cutscenes[player_index] = {
        func = cutscene_function.func,
        waypoints = waypoints,
        update = cutscene_function.update,
        final_transition_time = final_transition_time,
        character = player.character,
        terminate_func = cutscene_function.terminate_func,
        rendering = {}
    }
    if player.controller_type == defines.controllers.cutscene then
        player.exit_cutscene()
    end
    player.set_controller {type = defines.controllers.ghost}

    final_transition_time = final_transition_time >= 0 and final_transition_time or 60
    running_cutscenes[player_index].final_transition_time = final_transition_time
    running_cutscenes[player_index].identifier = identifier
    player.set_controller {
        type = defines.controllers.cutscene,
        waypoints = waypoints,
        final_transition_time = final_transition_time
    }

    handler({player_index = player_index, waypoint_index = -1})
end

local function restart_cutscene(player_index, waypoints, start_index)
    local current_running = running_cutscenes[player_index]
    local final_transition_time = current_running.final_transition_time
    current_running.update = false
    local character = current_running.character

    --game.print(character.position)
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
        rendering = current_running.rendering
    }

    local player = game.get_player(player_index)
    if not valid(player) then
        return
    end

    if player.controller_type == defines.controllers.cutscene then
        player.exit_cutscene()
        player.set_controller {type = defines.controllers.ghost}
    --player.set_controller {type = defines.controllers.character, character = current_running.character}
    end

    player.set_controller {
        type = defines.controllers.cutscene,
        waypoints = waypoints,
        final_transition_time = final_transition_time
    }

    if start_index then
        --game.print('Jumping to: ' .. start_index)
        player.jump_to_cutscene_waypoint(start_index + 1)
    else
        start_index = -1
    end

    handler({player_index = player_index, waypoint_index = start_index})
end

function Public.inject_waypoint(player_index, waypoint, waypoint_index, override)
    local running_cutscene = running_cutscenes[player_index]
    if not running_cutscene then
        --game.print('Error1')
        return
    end
    local waypoints = running_cutscene.waypoints
    if not waypoints then
        --game.print('Error2')
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
    running_cutscenes[player_index].update = copy_waypoints
    --game.print(serpent.block(running_cutscenes[player_index]))
end

local callback_function =
    Token.register(
    function(params)
        Token.get(params.func)(params.player_index, params.waypoint_index, params.params)
    end
)

local reconnect_character =
    Token.register(
    function(params)
        local player_index = params.player_index
        local player = game.get_player(player_index)
        local character = params.character
        local func = params.func
        if valid(player) and valid(character) then
            player.exit_cutscene()
            player.set_controller {type = defines.controllers.character, character = character}
            if func then
                Token.get(func)(player_index)
            end
            Token.get(remove_renderings)(params.rendering)
            running_cutscenes[player_index] = nil
        end
    end
)

function Public.terminate_cutscene(player_index, ticks)
    local running_cutscene = running_cutscenes[player_index]
    if not running_cutscene then
        --game.print("Error terminating!")
        return
    end
    ticks = ticks and ticks or 1

    Task.set_timeout_in_ticks(
        ticks,
        reconnect_character,
        {
            player_index = player_index,
            character = running_cutscene.character,
            func = running_cutscene.terminate_func,
            rendering = running_cutscene.rendering
        }
    )
end

function Public.register_rendering_id(player_index, render_id)
    if type(render_id) ~= 'table' then
        render_id = {render_id}
    end
    local running_cutscene = running_cutscenes[player_index]
    for _, id in pairs(render_id) do
        --game.print('before valid: ' .. id)
        if rendering.is_valid(id) then
            --game.print('after valid: ' .. id)
            if not running_cutscene then
                --game.print('Error adding rendering id! ' .. id)
                rendering.destroy(id)
            else
                table.insert(running_cutscenes[player_index].rendering, id)
            end
        end
    end
end

handler = function(event)
    local player_index = event.player_index
    local waypoint_index = event.waypoint_index

    --game.print('Waypoint: ' .. waypoint_index)

    local running_cutscene = running_cutscenes[player_index]
    if not running_cutscene then
        return
    end
    local final_transition_time = running_cutscene.final_transition_time

    local update = running_cutscene.update
    if update then
        --game.print('Updating!')
        restart_cutscene(player_index, update, waypoint_index)
        return
    end
    local ticks = running_cutscene.waypoints[waypoint_index + 2]
    if ticks then
        ticks = ticks.transition_time
    else
        ticks = final_transition_time
    end

    local func = running_cutscene.func
    if not func then
        return
    end
    local current_waypoint = running_cutscene.waypoints[waypoint_index + 2]
    if not current_waypoint or current_waypoint.terminate then
        --game.print('Not current waypoint! Could be last waypoint, defaulting to index one')
        Public.terminate_cutscene(player_index, ticks)
        running_cutscenes[player_index] = nil
        return
    end
    local params = {
        position = current_waypoint.position,
        time_to_wait = current_waypoint.time_to_wait,
        transition_time = current_waypoint.transition_time,
        zoom = current_waypoint.zoom
    }

    Task.set_timeout_in_ticks(ticks, callback_function, {func = running_cutscene.func, player_index = player_index, waypoint_index = waypoint_index, params = params})
end

local function restore(event)
    Public.terminate_cutscene(event.player_index)
end

Event.add(defines.events.on_cutscene_waypoint_reached, handler)
Event.add(defines.events.on_pre_player_left_game, restore)
Event.add(defines.events.on_player_joined_game, restore)

return Public
