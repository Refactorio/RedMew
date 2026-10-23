-- In-game tests for Diggy's coin gathering. These run under _DEBUG via /test-runner on Diggy maps
-- with it enabled: enemies that die drop coins.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local RS = require 'map_gen.shared.redmew_surface'
local D = require 'map_gen.maps.diggy.diggy_test_helper'

-- far from spawn, away from the other tests' digging
local SPOT = {{60, 100}, {76, 116}}
local ALIENS = 30

Declare.module(
    {'map_gen', 'diggy', 'coin gathering'},
    function()
        Declare.test(
            'enemies that die drop coins',
            function(context)
                local surface = RS.get_surface()
                context:add_teardown(function()
                    D.clear_enemies(surface, {{SPOT[1][1] - 32, SPOT[1][2] - 32}, {SPOT[2][1] + 32, SPOT[2][2] + 32}})
                end)

                D.open(context, surface, SPOT, function()
                    local function coins()
                        local count = 0
                        for _, item in pairs(surface.find_entities_filtered {area = SPOT, name = 'item-on-ground'}) do
                            if item.stack.name == 'coin' then
                                count = count + item.stack.count
                            end
                        end
                        return count
                    end
                    local before = coins()
                    for i = 1, ALIENS do
                        local biter = surface.create_entity {name = 'small-biter', position = {SPOT[1][1] + 2 + (i % 6) * 2, SPOT[1][2] + 2 + math.floor(i / 6) * 2}, force = 'enemy'}
                        Assert.valid(biter, 'the test biter was not created')
                        biter.die()
                    end
                    -- each has a 28% chance: none of 30 is about one in twenty thousand
                    Assert.is_true(coins() > before, 'no coins from ' .. ALIENS .. ' dead biters')
                end)
            end
        )
    end
)
