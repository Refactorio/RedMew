local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Cutscene = require 'features.cutscene.cutscene_controller'
local CS_Rendering = require 'features.cutscene.rendering'
local Color = require 'resources.color_presets'
local PC = require 'features.player_create'
local register_rendering = Cutscene.register_rendering_id
local play_sound = Cutscene.play_sound
local draw_text = CS_Rendering.draw_text
local draw_multi_line = CS_Rendering.draw_multi_line_text
local rad = math.rad
local Rendering = require 'utils.rendering'

local CrashsiteCutscene = {}

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

local original_resolution = {height = 1440, width = 2560}
local original_zoom = 1

local function cutscene_function_redmew(player_index, waypoint_index, params)
    local player = game.players[player_index]
    if (not valid(player)) then
        return
    end
    local cases = {}
    local ttw = params.time_to_wait
    local zoom = params.zoom
    local tick = params.tick
    local settings = {original_resolution = original_resolution, original_zoom = original_zoom, player_zoom = zoom}

    player.game_view_settings.show_entity_info = true
    if waypoint_index ~= -1 then
        play_sound(tick, player, 'utility/list_box_click', 1)
    end
    cases[-1] = function()
        play_sound(tick, player, 'ambient/pollution', 1, 550)
        register_rendering(player_index, tick, CS_Rendering.blackout(player, zoom, ttw + 10))
        register_rendering(player_index, tick, draw_text(settings, {x = 0, y = -16}, 'Crashsite', player, {scale = 10, time_to_live = ttw, color = Color.red}, false, false))
        register_rendering(
            player_index,
            tick,
            draw_multi_line(settings, {x = 0, y = -5}, {{'crashsite.cutscene1_case_line2', 'Crashsite'}, '---------------------', {'crashsite.cutscene1_case_line4', 'Redmew'}, {'crashsite.cutscene1_case_line5', 'www.redmew.com/discord'}}, player, {scale = 5, time_to_live = ttw}, false)
        )
        draw_text_auto_replacing(tick, settings, {x = 0, y = 10}, {'', {'crashsite.cutscene1_case_line6'}}, player, {scale = 3}, false, false, ttw, 0)
    end
    cases[0] = function()
        register_rendering(player_index, tick, CS_Rendering.blackout(player, zoom, ttw + 1))
        register_rendering(player_index, tick, draw_text(settings, {x = 0, y = 0}, 'Redmew - Crashsite', player, {scale = 10, time_to_live = ttw - 60, color = Color.red}, false, false))
        register_rendering(player_index, tick, draw_text(settings, {x = 0, y = -5}, 'Introduction', player, {scale = 5, time_to_live = ttw - 60}, false, false))

        delayed_function(delayed_draw_arrow, player, tick, {settings = settings, offset = {x = 7, y = 2.5}, params = {rotation = rad(-45), time_to_live = 275 * 3 - 30}, fit_to_edge = true}, 0)

        draw_text_auto_replacing(tick, settings, {x = 8.5, y = 3}, {{'crashsite.cutscene1_case0_line3'}}, player, {scale = 2.5, alignment = 'left'}, false, true, 275)

        draw_text_auto_replacing(tick, settings, {x = 8.5, y = 3}, {'', {'crashsite.cutscene1_case0_line4'}}, player, {scale = 2.5, alignment = 'left'}, false, true, 275 * 2)

        draw_text_auto_replacing(tick, settings, {x = 8.5, y = 3}, {'', '', {'crashsite.cutscene1_case0_line5'}}, player, {scale = 2.5, alignment = 'left'}, false, true, 275 * 3)

        delayed_function(delayed_draw_arrow, player, tick, {settings = settings, offset = {x = 1, y = 2.5}, params = {rotation = rad(-45), time_to_live = 275 - 30}, fit_to_edge = true}, 275 * 3)

        draw_text_auto_replacing(tick, settings, {x = 2.5, y = 3}, {'', '', '', {'crashsite.cutscene1_case0_line6'}}, player, {scale = 2.5, alignment = 'left'}, false, true, 275 * 4)
    end
    cases[1] = function()
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'crashsite.cutscene1_case1_line1'}, {'crashsite.cutscene1_case1_line2'}, {'crashsite.cutscene1_case1_line3'}}, player, {scale = 2.5}, true, false, 400 * 3)
    end
    cases[2] = function()
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'crashsite.cutscene1_case2_line1'}}, player, {scale = 2.5}, true, false, 300)
    end
    cases[3] = function()
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'crashsite.cutscene1_case3_line1'}}, player, {scale = 3}, true, false, 400)
    end
    local case = cases[waypoint_index]
    if case then
        case()
    end
end

local waypoints_redmew = {
    {
        -- case -1
        position = {x = 0, y = 0},
        transition_time = 60,
        time_to_wait = 600,
        zoom = 0.5
    },
    {
        -- case 0
        position = {x = 0, y = 0},
        transition_time = 0,
        time_to_wait = 300 * 4,
        zoom = 0.5
    },
    {
        -- case 1
        position = {x = 0, y = -5},
        transition_time = 120,
        time_to_wait = 400 * 3,
        zoom = 1.2
    },
    {
        -- case 2
        position = {x = -3, y = -5},
        transition_time = 90,
        time_to_wait = 300,
        zoom = 1.6
    },
    {
        -- case 3
        position = {x = 0, y = 0},
        transition_time = 90,
        time_to_wait = 400,
        zoom = 0.2
    }
}

local function cutscene_function_outpost(player_index, waypoint_index, params)
    local player = game.players[player_index]
    if (not valid(player)) then
        return
    end
    local cases = {}
    local zoom = params.zoom
    local tick = params.tick
    local settings = {original_resolution = original_resolution, original_zoom = original_zoom, player_zoom = zoom}

    player.game_view_settings.show_entity_info = true
    if waypoint_index ~= -1 then
        play_sound(tick, player, 'utility/list_box_click', 1)
    end

    cases[-1] = function()
        play_sound(tick, player, 'utility/scenario_message')
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'crashsite.cutscene2_case_line1'}, {'crashsite.cutscene2_case_line2'}}, player, {scale = 2.5, surface = "cutscene"}, true, false, 375 * 2)
    end
    cases[0] = function()
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'crashsite.cutscene2_case0_line1'}, {'crashsite.cutscene2_case0_line2'}}, player, {scale = 2.5, surface = "cutscene"}, true, false, 375 * 2)
    end
    cases[1] = function()
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'crashsite.cutscene2_case1_line1'}}, player, {scale = 2.5, surface = "cutscene"}, true, false, 500)
    end
    cases[2] = function()
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'crashsite.cutscene2_case2_line1'}}, player, {scale = 2.5, surface = "cutscene"}, true, false, 600)
    end
    cases[3] = function()
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'crashsite.cutscene2_case3_line1'}}, player, {scale = 2.5, surface = "cutscene"}, true, false, 500)
    end
    cases[4] = function()
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'crashsite.cutscene2_case4_line1'}}, player, {scale = 2.5, surface = "cutscene"}, true, false, 600)
    end
    cases[5] = function()
        draw_text_auto_replacing(tick, settings, {x = 0, y = 18}, {{'crashsite.cutscene2_case5_line1'}, {'crashsite.cutscene2_case5_line2'}}, player, {scale = 2.5, surface = "cutscene"}, true, false, 400 * 2)
    end
    local case = cases[waypoint_index]
    if case then
        case()
    end
end

local waypoints_outpost = {
    {
        -- case -1
        position = {x = 0, y = 0},
        transition_time = 90,
        time_to_wait = 375 * 2,
        zoom = 0.5
    },
    {
        -- case 0
        position = {x = 0, y = -10},
        transition_time = 120,
        time_to_wait = 375 * 2,
        zoom = 1.5
    },
    {
        -- case 1
        position = {x = 0, y = 0},
        transition_time = 120,
        time_to_wait = 500,
        zoom = 1
    },
    {
        -- case 2
        position = {x = 4, y = 0},
        transition_time = 90,
        time_to_wait = 600,
        zoom = 2.5
    },
    {
        -- case 3
        position = {x = -4, y = 0},
        transition_time = 90,
        time_to_wait = 500,
        zoom = 2.5
    },
    {
        -- case 4
        position = {x = 0, y = 0},
        transition_time = 60,
        time_to_wait = 600,
        zoom = 2
    },
    {
        -- case 5
        position = {x = 0, y = 25},
        transition_time = 60,
        time_to_wait = 400 * 2,
        zoom = 1.5
    }
}

local start_cutscene_outpost =
    Token.register(
        function(player_index)
            local player = game.get_player(player_index)
            if (not valid(player)) then
                return
            end
            local pos = game.surfaces.cutscene.find_non_colliding_position('character', {0, 30}, 0, 1)
            player.teleport(pos, 'cutscene')
            Cutscene.register_running_cutscene(player_index, 'Crashsite_Outpost', 60)
        end
)
local function terminate_function_redmew(player_index,skip_btn_flag)
    if skip_btn_flag then
        local player = game.get_player(player_index)
        if (not valid(player)) then
            return
        end
        PC.show_start_up(player)
        player.print({'crashsite.replay_cutscene', '/replay'}, Color.yellow)
        return
    end
    Task.set_timeout_in_ticks(1, start_cutscene_outpost, player_index)
end

local function terminate_function_outpost(player_index)
    local player = game.get_player(player_index)
    if (not valid(player)) then
        return
    end
    local pos = game.surfaces.redmew.find_non_colliding_position('character', {0, 0}, 0, 1)
    player.teleport(pos, 'redmew')
    PC.show_start_up(player)
    player.print({'crashsite.replay_cutscene', '/replay'}, Color.yellow)
end

Cutscene.register_cutscene_function('Crashsite_Welcome', waypoints_redmew, Token.register(cutscene_function_redmew), Token.register(terminate_function_redmew))
Cutscene.register_cutscene_function('Crashsite_Outpost', waypoints_outpost, Token.register(cutscene_function_outpost), Token.register(terminate_function_outpost))

Cutscene.register_replay('Crashsite_Welcome', 120)

local start_cutscene =
    Token.register(
        function(params)
            Cutscene.register_running_cutscene(params.event.player_index, 'Crashsite_Welcome', 120)
        end
)

function CrashsiteCutscene.on_init()
    global.config.player_create.cutscene = true
    CrashsiteCutscene.on_load()
end

function CrashsiteCutscene.on_load()
    Event.add(
        defines.events.on_player_created,
        function(event)
            Task.set_timeout_in_ticks(60, start_cutscene, {event = event})
        end
    )
end

return CrashsiteCutscene
