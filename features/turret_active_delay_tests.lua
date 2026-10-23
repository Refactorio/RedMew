-- In-game tests for turret_active_delay. These run on every map with it enabled (the default):
-- a new turret stays switched off for its type's delay, then switches on.
--
-- They are under map_gen in the test tree so the headless runs (utils/test/headless.lua) pick
-- them up. Real construction robots build an artillery turret (the shortest delay, and it needs
-- no power) on a scratch surface, so the game raises its own build event. Where the map's
-- placement rules want it, the turret stands on refined concrete (Concrete Jungle) or on ore
-- (Safety Ores).
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'
local Event = require 'utils.event'
local config = require 'config'

local TURRET = 'artillery-turret'
local POSITION = {x = 12, y = 12}

-- maps whose placement rules remove a turret that isn't on refined concrete, or isn't on ore
local function loaded(path)
    return package.loaded['__level__/' .. path .. '.lua'] ~= nil
end

-- robot-built turrets, with the tick they were built
local built = {}
Event.add(defines.events.on_robot_built_entity, function(event)
    local entity = event.entity
    if entity.valid and entity.name == TURRET then
        built[#built + 1] = {entity = entity, tick = event.tick}
    end
end)

Declare.module(
    {'map_gen', 'turret active delay'},
    function()
        Declare.test(
            'a turret robots build stays switched off for its delay, then switches on',
            function(context)
                -- Arrange: robots, and ground the map lets a turret stand on
                local delay = config.turret_active_delay.turret_types[prototypes.entity[TURRET].type]
                Assert.is_true(delay and delay > 0, 'no delay for ' .. TURRET .. 's on this map')
                local surface, delete_surface = Helper.create_test_surface(context)
                context:add_teardown(delete_surface)

                context:timeout(2, function()
                    local _, remove_network = Helper.robot_network(surface, {x = 0, y = 0}, {{name = TURRET, count = 1}})
                    context:add_teardown(remove_network)
                    local footprint = {{POSITION.x - 2, POSITION.y - 2}, {POSITION.x + 2, POSITION.y + 2}}
                    if loaded('map_gen/maps/concrete_jungle') then
                        local tiles = {}
                        for x = footprint[1][1], footprint[2][1] - 1 do
                            for y = footprint[1][2], footprint[2][2] - 1 do
                                tiles[#tiles + 1] = {name = 'refined-concrete', position = {x, y}}
                            end
                        end
                        surface.set_tiles(tiles)
                    end
                    if loaded('map_gen/maps/danger_ores/presets/danger_ore_safety') then
                        surface.create_entity {name = 'iron-ore', position = {POSITION.x - 0.5, POSITION.y - 0.5}, amount = 1000}
                    end
                    local before = #built

                    -- Act: a ghost for the robots to build
                    Assert.valid(surface.create_entity {name = 'entity-ghost', inner_name = TURRET, position = POSITION, force = 'player'}, 'the ghost was not placed')

                    Helper.wait_until(context, 1800, function()
                        return #built > before
                    end, function(ok)
                        -- Assert: off when built, then on after its delay
                        Assert.is_true(ok, 'the robots did not build the ' .. TURRET)
                        local turret, built_at = built[#built].entity, built[#built].tick
                        Assert.is_true(turret.valid, 'the ' .. TURRET .. ' was removed as soon as it was built, by the map\'s placement rules most likely')
                        Assert.is_true(not turret.active, 'the ' .. TURRET .. ' was on as soon as it was built')

                        Helper.wait_until(context, delay + 60, function()
                            return turret.active
                        end, function(on)
                            local after = game.tick - built_at
                            Assert.is_true(on, 'the ' .. TURRET .. ' was still off ' .. after .. ' ticks after it was built, with a delay of ' .. delay)
                            Assert.is_true(after >= delay, 'the ' .. TURRET .. ' switched on after ' .. after .. ' ticks, with a delay of ' .. delay)
                            Assert.is_true(after <= delay + 20, 'the ' .. TURRET .. ' switched on only after ' .. after .. ' ticks, with a delay of ' .. delay)
                        end)
                    end)
                end)
            end
        )
    end
)
