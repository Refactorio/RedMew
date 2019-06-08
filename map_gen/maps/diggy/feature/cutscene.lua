local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Cutscene = require 'features.cutscene.cutscene_controller'
local Rendering = require 'features.cutscene.renderings'
local RS = require 'map_gen.shared.redmew_surface'

local DiggyCutscene = {}

local function cutscene_function(player_index, waypoint_index, params)
    local cases = {}
    local player = game.players[player_index]
    --game.print('index: ' .. waypoint_index .. ' | position:' .. serpent.block(params.position) .. ' | trans_time: ' .. params.transition_time .. ' | ttw: ' .. params.time_to_wait .. ' | zoom: ' .. params.zoom)

    cases[-1] = function()
        player.clear_console()
        player.gui.center.clear()
        Rendering.blackout(player, params.zoom, params.time_to_wait + 1)
        Rendering.draw_text({height = 1440, width = 2560}, 1, params.zoom, {x = 0, y = -16}, 'Diggy', 10, params.time_to_wait, player, false)
        Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, params.zoom, {x = 0, y = -5}, {'Welcome to Diggy', '---------------------', 'This is a custom scenario developed by Redmew', 'Join us at www.redmew.com/discord'}, 5, params.time_to_wait, player, false)
        Rendering.draw_text({height = 1440, width = 2560}, 1, params.zoom, {x = 0, y = 10}, 'The following introduction will help you get started!', 3, params.time_to_wait, player, false)
    end
    cases[0] = function()
        Rendering.draw_text({height = 1440, width = 2560}, 1, params.zoom, {x = 0, y = 18}, 'This is the starting area', 2.5, params.time_to_wait, player, true)
        local entity = RS.get_surface().find_entities_filtered {name = 'stone-wall', limit = 1}
        local waypoint = {
            -- case 3
            position = {x = 0, y = 0},
            transition_time = 120,
            time_to_wait = 300,
            zoom = 2
        }
        if entity[1] then
            local position = entity[1].position
            waypoint = {
                -- case 3
                position = position,
                transition_time = 120,
                time_to_wait = 300,
                zoom = 5
            }
        end
        Cutscene.inject_waypoint(player_index, waypoint, 3)
    end
    cases[1] = function()
        Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, params.zoom, {x = 0, y = 18}, {'Expanding the mine is dangerous!', '', 'Walls are used to keep the cave roof from crushing us'}, 2.5, params.time_to_wait, player, true)
    end
    cases[2] = function()
        Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, params.zoom, {x = 0, y = 18}, {'The market provides extra supplies', '', 'You unlock new items when you level up'}, 2.5, params.time_to_wait, player, true)
    end
    cases[3] = function()
        Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, params.zoom, {x = 0, y = 18}, {"Cave ins happens frequently when you don't add supports", '', 'Different types of brick and concrete can reinforce our support pillars!'}, 2.5, params.time_to_wait, player, true)
        local position = RS.get_surface().find_entities_filtered {name = 'rock-big', limit = 1}[1].position
        local waypoint = {
            -- case 4
            position = position,
            transition_time = 120,
            time_to_wait = 300,
            zoom = 5
        }
        Cutscene.inject_waypoint(player_index, waypoint, 6)
    end
    cases[4] = function()
        Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, params.zoom, {x = 0, y = 18}, {'This world contains brittle rocks', '', 'Our tools are too powerful to preserve any resources from destroying them'}, 2.5, params.time_to_wait, player, true)
    end
    cases[5] = function()
        Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, params.zoom, {x = 0, y = 18}, {'The native population is lurking in the dark', '', 'Be wary when digging, always bring along some defences'}, 2.5, params.time_to_wait, player, true)
    end
    cases[6] = function()
        Rendering.draw_multi_line_text({height = 1440, width = 2560}, 1, params.zoom, {x = 0, y = 18}, {'This concludes the introduction', '', 'Have fun and keep digging!'}, 2.5, params.time_to_wait, player, true)
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
        time_to_wait = 300,
        zoom = 1
    },
    {
        -- case 1
        position = {x = 0.5, y = 3.5},
        transition_time = 120,
        time_to_wait = 300,
        zoom = 5
    },
    {
        -- case 2
        position = {x = 0, y = 0},
        transition_time = 120,
        time_to_wait = 300,
        zoom = 2
    },
    -- inserting case 3
    -- inserting case 4
    {
        -- case 5
        position = {x = 0, y = 0},
        transition_time = 120,
        time_to_wait = 300,
        zoom = 0.3
    },
    {
        -- case 6
        position = {x = 0, y = 0},
        transition_time = 120,
        time_to_wait = 300,
        zoom = 0.8
    }
}

Cutscene.register_cutscene_function('Diggy_Welcome', waypoints, Token.register(cutscene_function))

local start_cutscene = Token.register(function(params)
    Cutscene.register_running_cutscene(params.event.player_index, 'Diggy_Welcome', 120)
end)

function DiggyCutscene.register()
    Event.add(
        defines.events.on_player_created,
        function(event)
            Task.set_timeout_in_ticks(60, start_cutscene, {event = event})
        end
    )
end

return DiggyCutscene
