-- In-game tests for Diggy's scattered resources. These run under _DEBUG via /test-runner on Diggy
-- maps with it enabled: ore turns up in the void that is opened far from spawn.
--
-- The void is opened through Template.insert, the way digging does it.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local RS = require 'map_gen.shared.redmew_surface'
local D = require 'map_gen.maps.diggy.diggy_test_helper'

-- far from spawn, away from the other tests' digging
local FAR = {{-240, -160}, {-176, -96}}

Declare.module(
    {'map_gen', 'diggy', 'scattered resources'},
    function()
        Declare.test(
            'ore turns up in the void opened far from spawn',
            function(context)
                -- Arrange
                local surface = RS.get_surface()
                local before = surface.count_entities_filtered {area = FAR, type = 'resource'}
                context:add_teardown(function()
                    D.clear_enemies(surface, {{FAR[1][1] - 32, FAR[1][2] - 32}, {FAR[2][1] + 32, FAR[2][2] + 32}})
                end)

                -- Act
                D.open(context, surface, FAR, function(opened)
                    -- Assert
                    Assert.is_true(opened >= 3000, 'only ' .. opened .. ' void tiles opened')
                    local ore = surface.count_entities_filtered {area = FAR, type = 'resource'} - before
                    Assert.is_true(ore > 0, 'no ore in ' .. opened .. ' void tiles opened far from spawn')
                end)
            end
        )
    end
)
