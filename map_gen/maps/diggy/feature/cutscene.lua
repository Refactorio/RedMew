local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Debug = require 'utils.debug'
local Cutscene = require 'features.cutscene.cutscene_controller'
local Rendering = require 'features.cutscene.renderings'
local RS = require 'map_gen.shared.redmew_surface'
local Color = require 'resources.color_presets'
local PC = require 'features.player_create'
local register_rendering = Cutscene.register_rendering_id
local play_sound = Cutscene.play_sound
local draw_text = Rendering.draw_text
local draw_multi_line = Rendering.draw_multi_line_text

local DiggyCutscene = {}

local delayed_draw_text =
    Token.register(
    function(params)
        if params.play_sound > 1 then
            play_sound(params.player, 'utility/list_box_click', 1)
        end
        register_rendering(params.player.index, draw_text(params.original_resolution, params.original_zoom, params.player_zoom, params.offset, params.text, params.scale, params.player, params.params, params.draw_background))
    end
)

local function draw_text_auto_replacing(original_resolution, original_zoom, player_zoom, offset, texts, scale, player, params, draw_background, time, between_time)
    time = time or 400
    time = time / #texts
    between_time = between_time or 30
    params.time_to_live = time - between_time
    if params.background then
        params.background.time_to_live = time - between_time
    end
    for i = 1, #texts do
        if texts[i] ~= '' then
            Task.set_timeout_in_ticks(
                time * (i - 1),
                delayed_draw_text,
                {original_resolution = original_resolution, original_zoom = original_zoom, player_zoom = player_zoom, offset = offset, text = texts[i], scale = scale, player = player, params = params, draw_background = draw_background, play_sound = i}
            )
        end
    end
end

local function cutscene_function(player_index, waypoint_index, params)
    local cases = {}
    local player = game.players[player_index]
    local ttw = params.time_to_wait
    local zoom = params.zoom
    if waypoint_index ~= -1 then
        play_sound(player, 'utility/list_box_click', 1)
    --play_sound(player, 'utility/inventory_move', 1, 10)
    end
    cases[-1] = function()
        play_sound(player, 'utility/game_won')
        play_sound(player, 'ambient/first-light', 1, 550)
        register_rendering(player_index, Rendering.blackout(player, zoom, ttw + 1))
        register_rendering(player_index, draw_text({height = 1440, width = 2560}, 1, zoom, {x = 0, y = -16}, 'Diggy', 10, player, {time_to_live = ttw, color = Color.yellow}, false))
        register_rendering(
            player_index,
            draw_multi_line({height = 1440, width = 2560}, 1, zoom, {x = 0, y = -5}, {{'diggy.cutscene_case_line2', 'Diggy'}, '---------------------', {'diggy.cutscene_case_line4', 'Redmew'}, {'diggy.cutscene_case_line5', 'www.redmew.com/discord'}}, 5, player, {time_to_live = ttw}, false)
        )
        draw_text_auto_replacing({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 10}, {'', {'diggy.cutscene_case_line6'}}, 3, player, {}, false, ttw, 0)
        draw_text_auto_replacing({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 16}, {'', '', {'diggy.cutscene_case_line7'}}, 1, player, {}, false, ttw, 0)
    end
    cases[0] = function()
        draw_text_auto_replacing({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {{'diggy.cutscene_case0_line1'}, {'diggy.cutscene_case0_line3'}}, 2.5, player, {}, true, ttw)
        local entity = RS.get_surface().find_entities_filtered {position = {0, 0}, radius = 20, name = 'stone-wall', limit = 1}
        if entity[1] then
            local position = entity[1].position
            local waypoint = {
                -- case 1
                position = position,
                transition_time = 120,
                time_to_wait = 275,
                zoom = 5
            }
            Debug.print_position(position, 'position of wall')
            Cutscene.inject_waypoint(player_index, waypoint, 3, true)
        end
    end
    cases[1] = function()
        --play_sound(player, 'utility/build_small', 1, 25)
        draw_text_auto_replacing({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {{'diggy.cutscene_case1_line1'}}, 2.5, player, {}, true, ttw)
    end
    cases[2] = function()
        draw_text_auto_replacing({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {{'diggy.cutscene_case2_line1'}, {'diggy.cutscene_case2_line3'}}, 2.5, player, {}, true, ttw)
    end
    cases[3] = function()
        draw_text_auto_replacing({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {{'diggy.cutscene_case3_line1'}, {'diggy.cutscene_case3_line3'}}, 2.5, player, {}, true, ttw)
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
        if entity[1] then
            position = entity[1].position
            way_zoom = 5
            Debug.print_position(position, 'position of rock')
        end
        local waypoint = {
            -- case 4
            position = position,
            transition_time = 120,
            time_to_wait = 550,
            zoom = way_zoom
        }
        Cutscene.inject_waypoint(player_index, waypoint, 6)
    end
    cases[4] = function()
        play_sound(player, 'utility/axe_mining_ore', 3, 35)
        draw_text_auto_replacing({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {{'diggy.cutscene_case4_line1'}, {'diggy.cutscene_case4_line3'}}, 2.5, player, {}, true, ttw)
    end
    cases[5] = function()
        play_sound(player, 'utility/research_completed', 1, 5)
        local exp = 2500
        local text = {'', '[img=item/automation-science-pack] ', {'diggy.float_xp_gained_research', exp}}
        player.create_local_flying_text {position = params.position, text = text, color = Color.light_sky_blue, time_to_live = ttw / 3}
        draw_text_auto_replacing({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {{'diggy.cutscene_case5_line1'}, {'diggy.cutscene_case5_line3'}}, 2.5, player, {}, true, ttw)
    end
    cases[6] = function()
        play_sound(player, 'utility/axe_fighting', 5, 25, 10)
        play_sound(player, 'worm-sends-biters', 1, 70)
        draw_text_auto_replacing({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {{'diggy.cutscene_case6_line1'}, {'diggy.cutscene_case6_line3'}}, 2.5, player, {}, true, ttw)
    end
    cases[7] = function()
        draw_text_auto_replacing({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {{'diggy.cutscene_case7_line1'}, {'diggy.cutscene_case7_line3'}}, 2.5, player, {}, true, ttw)
        --play_sound(player, 'utility/tutorial_notice', 1)
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
