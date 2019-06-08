local b = require 'map_gen.shared.builders'
local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Global = require 'utils.global'
local CS = require 'map_gen.maps.factoryfield.cutscene_controller'
local Rendering = require 'map_gen.maps.factoryfield.renderings'

local loading = true
Global.register(
    {
        loading = loading
    },
    function(tbl)
        loading = tbl.loading
    end
)

local field = b.circle(512)

local spawn = b.rectangle(32, 32)
spawn = b.translate(spawn, 0, 544)

local function message(x, y)
    --if x == -543.5 and y == 639.5 then
    if x >= 0 and y == 0.5 and loading then
        --game.print('Done!')
        game.speed = 1
        loading = false
    end
end

field = b.any({field, spawn, message})

field = b.translate(field, 0, -544)

local sea = b.tile('deepwater')
local map = b.if_else(field, sea)

local function chart_for_neutral_callback()
    game.speed = 3
    game.forces.player.chart(game.surfaces[2], {lefttop = {x = -544, y = -544 * 2}, rightbottom = {x = 512, y = 64}})
    for _, v in pairs(game.connected_players) do
        CS.register_running_cutscene(v.index, 'loading', 30)
    end
end

local function fading(params)
    Rendering.blackout(params.player, params.params.zoom, params.delay + 1, {r = 0, g = 0, b = 0, a = params.a})
end

local fade = Token.register(fading)

local function func(player_index, waypoint_index, params)
    --game.print('position:' .. serpent.block(params.position) .. ' | trans_time: ' .. params.transition_time .. ' | ttw: ' .. params.time_to_wait .. ' | zoom: ' .. params.zoom)

    if waypoint_index == 0 then
        local delay = 45
        local i = 0
        for a = 1, 0.1, -0.1 do
            Task.set_timeout_in_ticks(delay * i, fade, {player = game.get_player(player_index), params = params, delay = delay, a = a})
            i = i + 1
        end
    elseif waypoint_index == 1 or waypoint_index == 3 then
        Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, params.zoom, {x = 0, y = 18}, {'Hello RedMew!', 'This is a multilined subtitle with more more more text'}, 2.5, params.time_to_wait, game.get_player(player_index), true)
    elseif waypoint_index == 2 then
        Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, params.zoom, {x = 0, y = 18}, {'Hello RedMew!', 'This is subtitles.', 'This is a multilined subtitle with more more more text'}, 2.5, params.time_to_wait, game.get_player(player_index), true)
    end
end

local waypoints = {
    {
        position = {x = 0, y = 0},
        transition_time = 0,
        time_to_wait = 500,
        zoom = 1
    },
    {
        position = {x = 0, y = 0},
        transition_time = 0,
        time_to_wait = 600,
        zoom = 1
    },
    {
        position = {x = 10, y = 0},
        transition_time = 60,
        time_to_wait = 180,
        zoom = 5
    },
    {
        position = {x = 0, y = 0},
        transition_time = 180,
        time_to_wait = 180,
        zoom = 0.025,
        chart_mode_cutoff = 1
    },
    {
        position = {x = -10, y = 0},
        transition_time = 120,
        time_to_wait = 180,
        zoom = 1
    }
}

CS.register_cutscene_function('test', waypoints, func)

local function loading_function(player_index, waypoint_index, params)
    local player = game.get_player(player_index)
    if loading then
        player.jump_to_cutscene_waypoint(0)
        Rendering.blackout(player, params.zoom, 500 + 60)
        return
    end
    func(player_index, waypoint_index, params)
end

CS.register_cutscene_function('loading', waypoints, loading_function)

local callback = Token.register(chart_for_neutral_callback)

local function chart_for_neutral()
    Task.set_timeout_in_ticks(50, callback)
end

Event.on_init(chart_for_neutral)

return map
