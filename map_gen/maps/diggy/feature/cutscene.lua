local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Cutscene = require 'features.cutscene.cutscene_controller'
local Rendering = require 'features.cutscene.renderings'
local RS = require 'map_gen.shared.redmew_surface'
local Color = require 'resources.color_presets'
local PC = require 'features.player_create'
local Command = require 'utils.command'

local DiggyCutscene = {}

local play_sound_delayed =
    Token.register(
    function(params)
        params.player.play_sound {path = params.path}
    end
)

local function play_sound(player, path, times, delay, initial_delay)
    if not game.is_valid_sound_path(path) then
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
            Task.set_timeout_in_ticks(initial_delay + delay * i, play_sound_delayed, {player = player, path = path})
        end
    else
        player.play_sound {path = path}
    end
end

local function cutscene_function(player_index, waypoint_index, params)
    local cases = {}
    local player = game.players[player_index]
    local ttw = params.time_to_wait
    local zoom = params.zoom
    --game.print('index: ' .. waypoint_index .. ' | position:' .. serpent.block(params.position) .. ' | trans_time: ' .. params.transition_time .. ' | ttw: ' .. ttw .. ' | zoom: ' .. zoom)
    if waypoint_index ~= -1 then
        play_sound(player, 'utility/list_box_click', 1)
    --play_sound(player, 'utility/inventory_move', 1, 10)
    end
    cases[-1] = function()
        play_sound(player, 'utility/game_won')
        play_sound(player, 'ambient/first-light', 1, 400)
        Cutscene.register_rendering_id(player_index, Rendering.blackout(player, zoom, ttw + 1))
        Cutscene.register_rendering_id(player_index, Rendering.draw_text({height = 1440, width = 2560}, 1, zoom, {x = 0, y = -16}, 'Diggy', 10, player, {time_to_live = ttw, color = Color.yellow}, false))
        Cutscene.register_rendering_id(
            player_index,
            Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, zoom, {x = 0, y = -5}, {'Welcome to Diggy', '---------------------', 'This is a custom scenario developed by Redmew', 'Join us at www.redmew.com/discord'}, 5, player, {time_to_live = ttw}, false)
        )
        Cutscene.register_rendering_id(player_index, Rendering.draw_text({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 10}, 'The following introduction will help you get started!', 3, player, {time_to_live = ttw}, false))
        Cutscene.register_rendering_id(player_index, Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 13}, {'Use the /skip command if you wish to skip this introduction', 'You can always replay this introduction by using the /replay command'}, 1.5, player, {time_to_live = ttw}, false))
    end
    cases[0] = function()
        Cutscene.register_rendering_id(player_index, Rendering.draw_text({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, 'This is the starting area', 2.5, player, {time_to_live = ttw}, true))
        local entity = RS.get_surface().find_entities_filtered {position = {0,0}, radius = 20, name = 'stone-wall', limit = 1}
        if entity[1] then
            --game.print('Found wall')
            local position = entity[1].position
            local waypoint = {
                -- case 1
                position = position,
                transition_time = 120,
                time_to_wait = 300,
                zoom = 5
            }
            Cutscene.inject_waypoint(player_index, waypoint, 3, true)
        end
    end
    cases[1] = function()
        play_sound(player, 'utility/build_small', 1, 25)
        Cutscene.register_rendering_id(player_index, Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {'Expanding the mine is dangerous!', '', 'Walls are used to keep the cave roof from crushing us'}, 2.5, player, {time_to_live = ttw}, true))
    end
    cases[2] = function()
        Cutscene.register_rendering_id(player_index, Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {'The market provides extra supplies in exchange of coins', '', 'You unlock new items when you level up'}, 2.5, player, {time_to_live = ttw}, true))
    end
    cases[3] = function()
        Cutscene.register_rendering_id(
            player_index,
            Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {"Cave ins happens frequently when you don't add supports", '', 'Different types of brick and concrete can reinforce our support pillars!'}, 2.5, player, {time_to_live = ttw}, true)
        )
        local radius = 25
        local entity
        repeat
        entity = RS.get_surface().find_entities_filtered {position = {0,0}, radius = radius, name = 'rock-big', limit = 1}
        radius = radius + 25
        until entity[1] or radius >= 200
        local position = {0, 3.5}
        local way_zoom = 0.4
        if entity[1] then
            position = entity[1].position
            way_zoom = 5
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
        Cutscene.register_rendering_id(
            player_index,
            Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {'This world contains brittle rocks', '', 'Our tools are too powerful to preserve any resources from destroying them'}, 2.5, player, {time_to_live = ttw}, true)
        )
    end
    cases[5] = function()
        local exp = 2500
        local text = {'', '[img=item/automation-science-pack] ', {'diggy.float_xp_gained_research', exp}}
        player.create_local_flying_text{position = params.position, text = text, color = Color.light_sky_blue, time_to_live = ttw / 3}
        Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {'Most actions gives experience!', '', 'The floating text indicates the quantity and cause of the experience'}, 2.5, player, {time_to_live = ttw}, true)
    end
    cases[6] = function()
        play_sound(player, 'utility/axe_fighting', 5, 25, 10)
        play_sound(player, 'worm-sends-biters', 1, 70)
        Cutscene.register_rendering_id(player_index, Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {'The native population is lurking in the dark', '', 'Be wary when digging, always bring along some defences'}, 2.5, player, {time_to_live = ttw}, true))
    end
    cases[7] = function()
        Cutscene.register_rendering_id(player_index, Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, zoom, {x = 0, y = 18}, {'This concludes the introduction', '', 'Have fun and keep digging!'}, 2.5, player, {time_to_live = ttw}, true))
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

local function replay_handler(_, player)
    Token.get(start_cutscene)({event = {player_index = player.index}})
end

Command.add(
    'replay',
    {
        description = 'Replays the introduction cutscene',
        capture_excess_arguments = false,
        allowed_by_server = false
    },
    replay_handler
)


return DiggyCutscene
