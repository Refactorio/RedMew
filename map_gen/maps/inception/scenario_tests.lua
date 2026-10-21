-- In-game tests for Inception. These run under _DEBUG via /test-runner when it is the active
-- map: the world is a maze laid out in whole chunks, land corridors with walls of void one chunk
-- thick, from spawn the corridors lead on out of the area around it, and there is ore near spawn.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local MazeTest = require 'map_gen.maps.maze_test_helper'
local RS = require 'map_gen.shared.redmew_surface'

local RADIUS = 16 -- chunks round spawn to look at; the maze cells are 5 chunks across

Declare.module(
    {'map_gen', 'inception'},
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

        Declare.test(
            'there is ore near spawn',
            function()
                MazeTest.chunk_map(RADIUS)
                local ore = RS.get_surface().count_entities_filtered {position = {0, 0}, radius = RADIUS * 32, type = 'resource'}
                Assert.is_true(ore > 0, 'no ore within ' .. RADIUS .. ' chunks of spawn')
            end
        )
    end
)
