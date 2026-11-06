-- Tests for the cutscene controller, discovered when it is loaded (a map with a cutscene is active).
-- Playing a cutscene takes a real player, so these don't run on a headless server. The switch to map
-- view itself only happens in multiplayer, so the test checks the limit that prevents it.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Cutscene = require 'features.cutscene.cutscene_controller'
local Token = require 'utils.token'

local identifier = 'cutscene_controller_tests'
local waypoints = {{position = {x = 0, y = 0}, transition_time = 1, time_to_wait = 600, zoom = 0.5}}
local draw_nothing = Token.register(function() end)

Declare.module({'features', 'cutscene controller'}, function()
    Declare.tags('skip-headless')

    Declare.test('a cutscene stays in the game view at any zoom it uses', function(context)
        -- Arrange
        local player = context.player
        local player_index = player.index
        player.set_zoom_limits(defines.controllers.cutscene, {})
        Cutscene.register_cutscene_function(identifier, waypoints, draw_nothing)

        -- Act
        Cutscene.register_running_cutscene(player_index, identifier, 1)
        local limits = player.zoom_limits

        -- Assert
        Assert.equal(defines.controllers.cutscene, player.controller_type, 'the cutscene did not start')
        Assert.equal(Cutscene.furthest_game_view_zoom, limits.furthest_game_view.zoom, 'the game view limit: ' .. serpent.line(limits))

        context:next(function()
            Cutscene.terminate_cutscene(player_index, 1, true)
        end):wait_until(60, function()
            return player.controller_type ~= defines.controllers.cutscene
        end, 'the cutscene did not end')
    end)
end)
