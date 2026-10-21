-- In-game tests for the Maze map. These run under _DEBUG via /test-runner when it is the active
-- map: the world is a maze laid out in whole chunks, land corridors with walls of void one chunk
-- thick, and from spawn the corridors lead on out of the area around it.
local Declare = require 'utils.test.declare'
local MazeTest = require 'map_gen.maps.maze_test_helper'

local RADIUS = 12 -- chunks round spawn to look at

Declare.module(
    {'map_gen', 'maze'},
    function()
        Declare.test(
            'the maze is laid out in whole chunks of land and void',
            function()
                MazeTest.assert_whole_chunks(RADIUS)
            end
        )

        Declare.test(
            'the walls are one chunk thick',
            function()
                MazeTest.assert_thin_walls(RADIUS)
            end
        )

        Declare.test(
            'from spawn the corridors lead out of the area round it',
            function()
                MazeTest.assert_corridors_lead_out(RADIUS)
            end
        )
    end
)
