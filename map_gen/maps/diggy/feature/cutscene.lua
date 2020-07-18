local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Debug = require 'utils.debug'
local Cutscene = require 'features.cutscene.cutscene_controller'
local CS_Rendering = require 'features.cutscene.rendering'
local RS = require 'map_gen.shared.redmew_surface'
local Color = require 'resources.color_presets'
local PC = require 'features.player_create'
local Experience = require 'map_gen.maps.diggy.feature.experience'
local register_rendering = Cutscene.register_rendering_id
local play_sound = Cutscene.play_sound
local draw_text = CS_Rendering.draw_text
local draw_multi_line = CS_Rendering.draw_multi_line_text
local rad = math.rad
local Rendering = require 'utils.rendering'

local DiggyCutscene = {}

local function valid(entity)
    return entity and entity.valid
end

local delayed_draw_text =
    Token.register(
    function(params)
        local player = params.player
        if (not valid(player)) then
            return
        end
        local tick = params.tick
        if params.play_sound > 1 then
            play_sound(tick, player, 'utility/list_box_click', 1)
        end
        register_rendering(player.index, tick, draw_text(params.settings, params.offset, params.text, params.player, params.params, params.draw_background, params.fit_to_edge))
    end
)

local function draw_text_auto_replacing(tick, settings, offset, texts, player, params, draw_background, fit_to_edge, time, between_time)
    time = time or 400
    time = time / #texts
    between_time = between_time or 30
    params.time_to_live = time - between_time
    if params.background then
        params.background.time_to_live = time - between_time
    end
    for i = 1, #texts do
        if texts[i] ~= '' then
            Task.set_timeout_in_ticks(time * (i - 1), delayed_draw_text, {tick = tick, settings = settings, offset = offset, text = texts[i], player = player, params = params, draw_background = draw_background, fit_to_edge = fit_to_edge, play_sound = i})
        end
    end
end

local delayed_draw_arrow =
    Token.register(
    function(params)
        local player = params.player
        if (not valid(player)) then
            return
        end
        local tick = params.tick
        params = params.params
        local rendering_parmas = params.params
        local id = CS_Rendering.draw_arrow(params.settings, params.offset, player, rendering_parmas, params.fit_to_edge)
        register_rendering(player.index, tick, id)
        Rendering.blink(id, 20, rendering_parmas.time_to_live)
    end
)

local function delayed_function(func, player, tick, params, offset_time)
    if (not valid(player)) then
        return
    end
    Task.set_timeout_in_ticks(offset_time, func, {player = player, tick = tick, params = params})
end

local delayed_fade_blackout =
    Token.register(
    function(params)
        local player = params.player
        if (not valid(player)) then
            return
        end
        local render_params = params.params
        local id = CS_Rendering.blackout(player, render_params.zoom, render_params.time_to_live, render_params.color)
        register_rendering(player.index, params.tick, id)
        Rendering.fade(id, render_params.time_to_live - 1, 10)
    end
)

local original_resolution = {height = 1440, width = 2560}
local original_zoom = 1

local function cutscene_function(player_index, waypoint_index, params)
    local cases = {}

    local player = game.players[player_index]
    local ttw = params.time_to_wait
    local zoom = params.zoom
    local tick = params.tick
    local settings = {original_resolution = original_resolution, original_zoom = original_zoom, player_zoom = zoom}

    if waypoint_index ~= -1 then
        play_sound(tick, player, 'utility/list_box_click', 1)
    --play_sound(tick, player, 'utility/inventory_move', 1, 10)
    end
    cases[-1] = function()
        play_sound(tick, player, 'utility/game_won')
        play_sound(tick, player, 'ambient/first-light', 1, 550)
        register_rendering(player_index, tick, CS_Rendering.blackout(player, zoom, ttw + 1))
        register_rendering(player_index, tick, draw_text(settings, {x = 0, y = -16}, 'Diggy', player, {scale = 10, time_to_live = ttw, color = Color.yellow}, false, false))
        register_rendering(
            player_index,
            tick,
            draw_multi_line(settings, {x = 0, y = -5}, {{'diggy.cutscene_case_line2', 'Diggy'}, '---------------------', {'diggy.cutscene_case_line4', 'Redmew'}, {'diggy.cutscene_case_line5', 'redmew.com/discord'}}, player, {scale = 5, time_to_live = ttw}, false)
        )
        draw_text_auto_replacing(tick, settings, {x = 0, y = 10}, {'', {'diggy.cutscene_case_line6'}}, player, {scale = 3}, false, false, ttw, 0)
        draw_text_auto_replacing(tick, settings, {x = 0, y = 16}, {'', '', {'diggy.cutscene_case_line7'}}, player, {scale = 1}, false, false, ttw, 0)
    end
    cases[0] = function()
        register_rendering(player_index, tick, CS_Rendering.blackout(player, zoom, ttw + 1))
        register_rendering(player_index, tick, draw_text(settings, {x = 0, y = 0}, 'Redmew - Diggy', player, {scale = 10, time_to_live = ttw - 60, color = Color.red}, false, false))
        register_rendering(player_index, tick, draw_text(settings, {x = 0, y = -5}, 'Introduction', player, {scale = 5, time_to_live = ttw - 60}, false, false))

        delayed_function(delayed_draw_arrow, player, tick,  {settings = settings, offset = {x = 7, y = 2.5}, params = {rotation = rad(-45), time_to_live = 275 * 3 - 30}, fit_to_edge = true}, 0)

        draw_text_auto_replacing(tick, settings, {x = 8.5, y = 3}, {'This is our toolbar!'}, player, {scale = 2.5, alignment = 'left'}, false, true, 275)

        draw_text_auto_replacing(tick, settings, {x = 8.5, y = 3}, {'', "Here you'll find a wide range of tools and informations about us!"}, player, {scale = 2.5, alignment = 'left'}, false, true, 275 * 2)

        draw_text_auto_replacing(tick, settings, {x = 8.5, y = 3}, {'', '', 'Hover your mouse over them for more information'}, player, {scale = 2.5, alignment = 'left'}, false, true, 275 * 3)

        delayed_function(delayed_draw_arrow, player, tick,  {settings = settings, offset = {x = 1, y = 2.5}, params = {rotation = rad(-45), time_to_live = 275 - 30}, fit_to_edge = true}, 275 * 3)

        draw_text_auto_replacing(tick, settings, {x = 2.5, y = 3}, {'', '', '', 'You can toggle our toolbar with this button'}, player, {scale = 2.5, alignment = 'left'}, false, true, 275 * 4)

        delayed_function(delayed_draw_arrow, player, tick,  {settings = settings, offset = {x = 3.5, y = 2.5}, params = {rotation = rad(-45), time_to_live = 275 - 30}, fit_to_edge = true}, 275 * 4.5)

        draw_text_auto_replacing(tick, settings, {x = 5, y = 3}, {'', '', '', '', 'This is the Diggy experience menu'}, player, {scale = 2.5, alignment = 'left'}, false, true, 275 * 5.5)

        delayed_function(delayed_draw_arrow, player, tick,  {settings = settings, offset = {x = 15, y = 9}, params = {rotation = rad(-90), time_to_live = 275 - 30}, fit_to_edge = true}, 275 * 5.5)

        Cutscene.toggle_gui(tick, player, Experience, 275 * 5.5, 'left')

        draw_text_auto_replacing(tick, settings, {x = 17, y = 8.7}, {'', '', '', '', '', 'Here you can see the current progress of the mine'}, player, {scale = 2.5, alignment = 'left'}, false, true, 275 * 6.5)

        Cutscene.toggle_gui(tick, player, Experience, 275 * 6.5)

        delayed_function(delayed_fade_blackout, player, tick,  {zoom = zoom, time_to_live = 120 + 61, color = {0, 0, 0, 1}}, ttw - 61)
    end
    cases[1] = function()
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'diggy.cutscene_case0_line1'}, {'diggy.cutscene_case0_line3'}}, player, {scale = 2.5}, true, false, ttw)
        local entity = RS.get_surface().find_entities_filtered {position = {0, 0}, radius = 20, name = 'stone-wall', limit = 1}
        if entity[1] then
            local position = entity[1].position
            local waypoint = {
                -- case 2
                position = position,
                transition_time = 120,
                time_to_wait = 275,
                zoom = 5
            }
            Debug.print_position(position, 'position of wall')
            Cutscene.inject_waypoint(player_index, waypoint, waypoint_index + 3, true)
        end
    end
    cases[2] = function()
        --play_sound(tick, player, 'utility/build_small', 1, 25)
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'diggy.cutscene_case1_line1'}}, player, {scale = 2.5}, true, false, ttw)
    end
    cases[3] = function()
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'diggy.cutscene_case2_line1'}, {'diggy.cutscene_case2_line3'}}, player, {scale = 2.5}, true, false, ttw)
    end
    cases[4] = function()
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'diggy.cutscene_case3_line1'}, {'diggy.cutscene_case3_line3'}}, player, {scale = 2.5}, true, false, ttw)
        local radius = 10
        local entity
        repeat
            entity = RS.get_surface().find_entities_filtered {position = {0, 0}, radius = radius, name = 'rock-big', limit = 1}
            if radius <= 10 then
                radius = 0
            end
            radius = radius + 25
        until entity[1] or radius >= 200
        local position = {0, 3.5}
        local way_zoom = 0.4
        entity = entity[1]
        if entity then
            position = entity.position
            way_zoom = 5
            Debug.print_position(position, 'position of rock')
        end
        local waypoint = {
            -- case 5
            position = position,
            transition_time = 120,
            time_to_wait = 550,
            zoom = way_zoom
        }
        Cutscene.inject_waypoint(player_index, waypoint, waypoint_index + 3)
    end
    cases[5] = function()
        play_sound(waypoint_index, player, 'utility/axe_mining_ore', 3, 35)
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'diggy.cutscene_case4_line1'}, {'diggy.cutscene_case4_line3'}}, player, {scale = 2.5}, true, false, ttw)
    end
    cases[6] = function()
        play_sound(tick, player, 'utility/research_completed', 1, 5)
        local exp = 2500
        local text = {'', '[img=item/automation-science-pack] ', {'diggy.float_xp_gained_research', exp}}
        player.create_local_flying_text {position = params.position, text = text, color = Color.light_sky_blue, time_to_live = ttw / 3}
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'diggy.cutscene_case5_line1'}, {'diggy.cutscene_case5_line3'}}, player, {scale = 2.5}, true, false, ttw)
    end
    cases[7] = function()
        play_sound(tick, player, 'utility/axe_fighting', 5, 25, 10)
        play_sound(tick, player, 'worm-sends-biters', 1, 70)
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'diggy.cutscene_case6_line1'}, {'diggy.cutscene_case6_line3'}}, player, {scale = 2.5}, true, false, ttw)
    end
    cases[8] = function()
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'diggy.cutscene_case7_line1'}, {'diggy.cutscene_case7_line3'}}, player, {scale = 2.5}, true, false, ttw)
        --play_sound(tick, player, 'utility/tutorial_notice', 1)
    end
    local case = cases[waypoint_index]
    if case then
        case()
    end
end

local waypoints = {
    {
        -- case -1
        position = {x = 0, y = 0},
        transition_time = 60,
        time_to_wait = 600,
        zoom = 0.5
    },
    {
        -- case -1.1
        position = {x = 0, y = 0},
        transition_time = 0,
        time_to_wait = 275 * 7,
        zoom = 0.5
    },
    {
        -- case 0
        position = {x = 0, y = 0},
        transition_time = 120,
        time_to_wait = 550,
        zoom = 1
    },
    {
        -- case 1
        position = {x = 0, y = 0},
        transition_time = 120,
        time_to_wait = 275,
        zoom = 1.5
    },
    {
        -- case 2
        position = {x = 0.5, y = 3.5},
        transition_time = 120,
        time_to_wait = 550,
        zoom = 5
    },
    {
        -- case 3
        position = {x = 0, y = 0},
        transition_time = 120,
        time_to_wait = 550,
        zoom = 2
    },
    -- inserting case 4
    {
        -- case 5
        position = {x = 0, y = -2},
        transition_time = 120,
        time_to_wait = 550,
        zoom = 1.8
    },
    {
        -- case 6
        position = {x = 0, y = 0},
        transition_time = 120,
        time_to_wait = 550,
        zoom = 0.3
    },
    {
        -- case 7
        position = {x = 0, y = 0},
        transition_time = 120,
        time_to_wait = 430,
        zoom = 0.8
    }
}

local function terminate_function(player_index)
    local player = game.get_player(player_index)
    PC.show_start_up(player)
    player.print({'diggy.replay_cutscene', '/replay'}, Color.yellow)
end

Cutscene.register_cutscene_function('Diggy_Welcome', waypoints, Token.register(cutscene_function), Token.register(terminate_function))
Cutscene.register_replay('Diggy_Welcome', 120)

local start_cutscene =
    Token.register(
    function(params)
        Cutscene.register_running_cutscene(params.event.player_index, 'Diggy_Welcome', 120)
    end
)

function DiggyCutscene.register()
    global.config.player_create.cutscene = true

    Event.add(
        defines.events.on_player_created,
        function(event)
            Task.set_timeout_in_ticks(60, start_cutscene, {event = event})
        end
    )
end

return DiggyCutscene
