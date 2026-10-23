-- In-game tests for biter drops. These run under _DEBUG via /test-runner on every Danger Ores
-- map with them enabled (the default): a destroyed biter or spitter nest drops fish.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local BiterDrops = require 'map_gen.maps.danger_ores.modules.biter_drops'
local H = require 'map_gen.maps.danger_ores.modules.terrain_test_helper'
local RS = require 'map_gen.shared.redmew_surface'

Declare.module(
    {'map_gen', 'danger ores', 'biter drops'},
    function()
        for name, drop in pairs(BiterDrops.drops) do
            Declare.test(
                'a destroyed ' .. name .. ' drops ' .. drop.count .. ' ' .. drop.name,
                function(context)
                    -- Arrange
                    local surface = RS.get_surface()
                    local p = H.dry_spot(surface, name)
                    Assert.is_true(p ~= nil, 'no room for a ' .. name .. ' near spawn')
                    local nest = surface.create_entity {name = name, position = p, force = 'enemy'}
                    Assert.valid(nest, 'the test ' .. name .. ' was not created')
                    local near = {position = p, radius = 8, name = 'item-on-ground'}
                    local function get_dropped_count()
                        local count = 0
                        for _, item in pairs(surface.find_entities_filtered(near)) do
                            if item.stack.name == drop.name then
                                count = count + item.stack.count
                            end
                        end
                        return count
                    end
                    local before = get_dropped_count()

                    -- Act
                    nest.die()

                    -- the drops are spilled a tick later
                    context:timeout(2, function()
                        -- Assert
                        Assert.equal(drop.count, get_dropped_count() - before, drop.name .. ' dropped by the ' .. name)
                    end)
                end
            )
        end
    end
)
