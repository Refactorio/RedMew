-- In-game tests for biter drops. These run under _DEBUG via /test-runner on every Danger Ores
-- map with them enabled (the default): a destroyed biter or spitter nest drops fish.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local H = require 'map_gen.maps.danger_ores.modules.terrain_test_helper'
local RS = require 'map_gen.shared.redmew_surface'

local FISH = 5

Declare.module(
    {'map_gen', 'danger ores', 'biter drops'},
    function()
        for _, name in pairs({'biter-spawner', 'spitter-spawner'}) do
            Declare.test(
                'a destroyed ' .. name .. ' drops fish',
                function(context)
                    local surface = RS.get_surface()
                    local p = H.dry_spot(surface, name)
                    Assert.is_true(p ~= nil, 'no room for a ' .. name .. ' near spawn')
                    local nest = surface.create_entity {name = name, position = p, force = 'enemy'}
                    Assert.valid(nest, 'the test ' .. name .. ' was not created')
                    local near = {position = p, radius = 8, name = 'item-on-ground'}
                    local function fish()
                        local count = 0
                        for _, item in pairs(surface.find_entities_filtered(near)) do
                            if item.stack.name == 'raw-fish' then
                                count = count + item.stack.count
                            end
                        end
                        return count
                    end
                    local before = fish()

                    nest.die()

                    -- the fish are spilled a tick later
                    context:timeout(2, function()
                        Assert.equal(FISH, fish() - before, 'fish dropped by the ' .. name)
                    end)
                end
            )
        end
    end
)
