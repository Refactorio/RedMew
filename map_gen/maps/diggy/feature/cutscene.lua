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
        play_sound(player, 'ambient/first-light', 1, 400)
        register_rendering(player_index, Rendering.blackout(player, zoom, ttw + 1))
        register_rendering(player_index, draw_text({height = 1440, width = 2560}, 1, zoom, {x = 0, y = -16}, 'Diggy', 10, player, {time_to_live = ttw, color = Color.yellow}, false))
        register_rendering(
            player_index,
            draw_multi_line({height = 1440, width = 2560}, 1, zoom, {x = 0, y = -5}, {{'diggy.cutscene_case_line2', 'Diggy'}, '---------------------', {'diggy.cutscene_case_line4', 'Redmew'}, {'diggy.cutscene_case_line5' ,'www.redmew.com/discord'}}, 5, player, {time_to_live = ttw}, false)
        )
        register_rendering(player_index, draw_text({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 10}, {'diggy.cutscene_case_line6'}, 3, player, {time_to_live = ttw}, false))
        register_rendering(player_index, draw_multi_line({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 13}, {{'diggy.cutscene_case_line7', '/skip'}, {'diggy.cutscene_case_line8', '/replay'}}, 1.5, player, {time_to_live = ttw}, false))
    end
    cases[0] = function()
        register_rendering(player_index, draw_text({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {'diggy.cutscene_case0_line1'}, 2.5, player, {time_to_live = ttw}, true))
        local entity = RS.get_surface().find_entities_filtered {position = {0,0}, radius = 20, name = 'stone-wall', limit = 1}
        if entity[1] then
            local position = entity[1].position
            local waypoint = {
                -- case 1
                position = position,
                transition_time = 120,
                time_to_wait = 300,
                zoom = 5
            }
            Debug.print_position(position, 'position of wall ')
            Cutscene.inject_waypoint(player_index, waypoint, 3, true)
        end
    end
    cases[1] = function()
        play_sound(player, 'utility/build_small', 1, 25)
        register_rendering(player_index, draw_multi_line({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {{'diggy.cutscene_case1_line1'}, '', {'diggy.cutscene_case1_line3'}}, 2.5, player, {time_to_live = ttw}, true))
    end
    cases[2] = function()
        register_rendering(player_index, draw_multi_line({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {{'diggy.cutscene_case2_line1'}, '', {'diggy.cutscene_case2_line3'}}, 2.5, player, {time_to_live = ttw}, true))
    end
    cases[3] = function()
        register_rendering(
            player_index,
            draw_multi_line({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {{'diggy.cutscene_case3_line1'}, '', {'diggy.cutscene_case3_line3'}}, 2.5, player, {time_to_live = ttw}, true)
        )
        local radius = 10
        local entity
        repeat
        entity = RS.get_surface().find_entities_filtered {position = {0,0}, radius = radius, name = 'rock-big', limit = 1}
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
            time_to_wait = 300,
            zoom = way_zoom
        }
        Cutscene.inject_waypoint(player_index, waypoint, 6)
    end
    cases[4] = function()
        play_sound(player, 'utility/axe_mining_ore', 3, 35)
        register_rendering(
            player_index,
            draw_multi_line({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {{'diggy.cutscene_case4_line1'}, '', {'diggy.cutscene_case4_line3'}}, 2.5, player, {time_to_live = ttw}, true)
        )
    end
    cases[5] = function()
        play_sound(player, 'utility/research_completed', 1, 5)
        local exp = 2500
        local text = {'', '[img=item/automation-science-pack] ', {'diggy.float_xp_gained_research', exp}}
        player.create_local_flying_text{position = params.position, text = text, color = Color.light_sky_blue, time_to_live = ttw / 3}
        draw_multi_line({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {{'diggy.cutscene_case5_line1'}, '', {'diggy.cutscene_case5_line3'}}, 2.5, player, {time_to_live = ttw}, true)
    end
    cases[6] = function()
        play_sound(player, 'utility/axe_fighting', 5, 25, 10)
        play_sound(player, 'worm-sends-biters', 1, 70)
        register_rendering(player_index, draw_multi_line({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {{'diggy.cutscene_case6_line1'}, '', {'diggy.cutscene_case6_line3'}}, 2.5, player, {time_to_live = ttw}, true))
    end
    cases[7] = function()
        register_rendering(player_index, draw_multi_line({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {{'diggy.cutscene_case7_line1'}, '', {'diggy.cutscene_case7_line3'}}, 2.5, player, {time_to_live = ttw}, true))
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
        time_to_wait = 400,
        zoom = 0.5
    },
    {
        -- case 0
        position = {x = 0, y = 0},
        transition_time = 120,
        time_to_wait = 300,
        zoom = 1
    },
    {
        -- case 1
        position = {x = 0, y = 0},
        transition_time = 120,
        time_to_wait = 300,
        zoom = 1.5
    },
    {
        -- case 2
        position = {x = 0.5, y = 3.5},
        transition_time = 120,
        time_to_wait = 300,
        zoom = 5
    },
    {
        -- case 3
        position = {x = 0, y = 0},
        transition_time = 120,
        time_to_wait = 300,
        zoom = 2
    },
    -- inserting case 4
    {
        -- case 5
        position = {x = 0, y = -2},
        transition_time = 120,
        time_to_wait = 300,
        zoom = 1.5
    },
    {
        -- case 6
        position = {x = 0, y = 0},
        transition_time = 120,
        time_to_wait = 300,
        zoom = 0.3
    },
    {
        -- case 7
        position = {x = 0, y = 0},
        transition_time = 120,
        time_to_wait = 300,
        zoom = 0.8
    }
}

local function terminate_function(player_index)
    PC.show_start_up(game.get_player(player_index))
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
