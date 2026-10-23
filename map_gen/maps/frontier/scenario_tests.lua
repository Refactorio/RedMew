-- In-game bootstrap tests for Frontier. These run under _DEBUG via /test-runner, and are only
-- discovered when scenario.lua is loaded, i.e. when Frontier is the active map. They check the
-- ribbon world comes up as the scenario describes it: water to the west, a solid wall to the
-- east, and the rocket silo. Past that, they check the rules of the round: the kraken eats what
-- is built or driven too far west, the silo can't be crafted, and a launched rocket moves the silo east,
-- keeping what was left in it in a chest.
--
-- Rockets are launched by raising the event the way Factorio does, with a stand-in rocket whose
-- cargo pod is an empty chest.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local EventFactory = require 'utils.test.event_factory'
local Helper = require 'utils.test.helper'
local Public = require 'map_gen.maps.frontier.shared.core'

local function generate(x, y, radius)
    local surface = Public.surface()
    surface.request_to_generate_chunks({x, y}, radius)
    surface.force_generate_chunk_requests()
    return surface
end

Declare.module(
    {'map_gen', 'frontier'},
    function()
        Declare.test(
            'the world is a ribbon of the configured height',
            function()
                -- Assert: the scenario set it as it started
                local this = Public.get()
                Assert.equal(this.height * 32, Public.surface().map_gen_settings.height, 'world height in tiles')
            end
        )

        Declare.test(
            'water lies past the west boundary',
            function()
                -- Act
                local this = Public.get()
                local x = -this.left_boundary * 32 - 16
                local surface = generate(x, 0, 3)

                -- Assert
                for _, y in pairs {-64, 0, 64} do
                    local tile = surface.get_tile(x, y)
                    Assert.equal('water', tile.name, 'tile at ' .. x .. ',' .. y)
                end
            end
        )

        Declare.test(
            'a solid wall runs across the world at the east boundary',
            function()
                local this = Public.get()
                local left = this.right_boundary * 32
                local half = this.height * 16
                for y = -half + 16, half - 16, 64 do
                    -- Act
                    local surface = generate(left, y, 1)

                    -- Assert: name what stands in any gap, so a failure says what blocked the wall
                    local gaps = {}
                    for x = left, left + this.wall_width - 1 do
                        if surface.count_entities_filtered {area = {{x, y}, {x + 1, y + 1}}, name = 'stone-wall'} == 0 then
                            local found = {}
                            for _, e in pairs(surface.find_entities_filtered {area = {{x, y}, {x + 1, y + 1}}}) do
                                found[#found + 1] = e.name
                            end
                            gaps[#gaps + 1] = x .. ',' .. y .. ' (' .. surface.get_tile(x, y).name .. (#found > 0 and ', ' .. table.concat(found, ' ') or '') .. ')'
                        end
                    end
                    Assert.is_true(#gaps == 0, 'gaps in the wall: ' .. table.concat(gaps, '; '))
                end
            end
        )

        Declare.test(
            'the rocket silo is placed east of spawn',
            function()
                -- Assert: out in enemy land in a real game; under _DEBUG, which tests run under,
                -- the scenario starts it at x 30 so it is quick to reach
                local this = Public.get()
                local silo = this.rocket_silo
                Assert.is_true(silo ~= nil and silo.valid, 'no rocket silo')
                Assert.is_true(silo.position.x >= this.silo_starting_x, 'the silo is at x ' .. silo.position.x .. ', before ' .. this.silo_starting_x)
            end
        )
        -- Builds `name` at `position` the way a player does: script-created entities don't raise
        -- the build event, so this raises it.
        local function build(surface, name, position)
            local entity = surface.create_entity {name = name, position = position, force = 'player'}
            Assert.valid(entity, 'the test ' .. name .. ' was not created')
            EventFactory.raise {name = defines.events.on_built_entity, tick = game.tick, player_index = 1, entity = entity}
            return entity
        end

        Declare.test(
            'the kraken eats what is built past its line in the west, and nothing short of it',
            function()
                -- Arrange
                local this = Public.get()
                local line = -(this.kraken_distance + this.left_boundary * 32)
                local surface = generate(line, 0, 1)

                -- Act
                local eaten = build(surface, 'small-electric-pole', {line - 4.5, 0.5})
                local spared = build(surface, 'small-electric-pole', {line + 4.5, 0.5})

                -- Assert
                Assert.is_true(not eaten.valid, 'a pole built at x ' .. (line - 4.5) .. ', past the kraken line at ' .. line .. ', is still there')
                Assert.is_true(spared.valid, 'a pole built at x ' .. (line + 4.5) .. ', short of the kraken line, was eaten')
                spared.destroy()
            end
        )

        Declare.test(
            'the kraken eats vehicles past its line, and none short of it',
            function(context)
                -- Arrange: a spidertron walks out over the water; one sent by remote control takes
                -- no player along, so the kraken has to find the vehicle itself
                local this = Public.get()
                local line = -(this.kraken_distance + this.left_boundary * 32)
                local surface = generate(line, 0, 1)

                -- Act
                local eaten = surface.create_entity {name = 'spidertron', position = {line - 6, 0}, force = 'player'}
                local spared = surface.create_entity {name = 'spidertron', position = {line + 6, 0}, force = 'player'}
                Assert.valid(eaten, 'the test spidertron past the line was not created')
                Assert.valid(spared, 'the test spidertron short of the line was not created')
                context:add_teardown(function()
                    if spared.valid then
                        spared.destroy()
                    end
                end)

                -- Assert, after the kraken's next look round, once a second
                context:timeout(70, function()
                    Assert.is_true(not eaten.valid, 'a spidertron at x ' .. (line - 6) .. ', past the kraken line at ' .. line .. ', is still there a second later')
                    Assert.is_true(spared.valid, 'a spidertron at x ' .. (line + 6) .. ', short of the kraken line, was eaten')
                end)
            end
        )

        Declare.test(
            'researching the rocket silo does not let it be crafted',
            function(context)
                -- Arrange
                local force = game.forces.player
                local tech = force.technologies['rocket-silo']
                Assert.is_true(not tech.researched, 'rocket-silo was already researched')
                context:add_teardown(function()
                    tech.researched = false
                end)

                -- Act
                tech.researched = true

                -- Assert
                Assert.is_true(not force.recipes['rocket-silo'].enabled, 'the rocket silo recipe is enabled')
            end
        )

        Declare.test(
            'a launched rocket moves the silo east and leaves what was in it in a chest',
            function(context)
                -- Arrange: a round that needs more than one rocket, so this one doesn't win it
                local this = Public.get()
                local silo = this.rocket_silo
                Assert.valid(silo, 'no rocket silo')
                local old = silo.position
                local to_win, launched = this.rockets_to_win, this.rockets_launched
                this.rockets_to_win = launched + 10
                context:add_teardown(function()
                    this.rockets_to_win = to_win
                end)
                local surface = Public.surface()
                -- a satellite left in the silo's rocket, which it keeps in a chest; an empty chest goes
                -- in the blast that follows
                local left = silo.get_output_inventory().insert {name = 'satellite', count = 1}
                Assert.is_true(left > 0, 'nothing could be left in the silo')
                local pod = surface.create_entity {name = 'steel-chest', position = {old.x, old.y - 20}, force = 'player'}
                context:add_teardown(function()
                    if pod.valid then
                        pod.destroy()
                    end
                end)

                -- Act
                EventFactory.raise {name = defines.events.on_rocket_launched, tick = game.tick, rocket = Helper.fake_lua_object(pod, {cargo_pod = pod}), rocket_silo = silo}

                -- Assert: it is counted and the silo is to go at least a rocket step east...
                Assert.equal(launched + 1, this.rockets_launched, 'rockets launched')
                Assert.is_true(this.x >= old.x + this.rocket_step, 'the silo is to go to x ' .. this.x .. ', from ' .. old.x)
                local target = this.x
                -- ...which it does after its alarm, a minute at most
                local ticks = 4200
                local function moved()
                    local now = this.rocket_silo
                    if now and now.valid and now.position.x ~= old.x then
                        Assert.equal(target, now.position.x, 'x the silo moved to')
                        Assert.is_true(not silo.valid, 'the old silo is still there')
                        local chest = surface.find_entities_filtered {position = old, radius = 2, name = 'steel-chest'}[1]
                        Assert.valid(chest, 'no chest where the old silo stood')
                        Assert.equal(left, chest.get_item_count('satellite'), 'satellites kept in the chest')
                        return
                    end
                    ticks = ticks - 60
                    Assert.is_true(ticks > 0, 'the silo did not move')
                    context:timeout(60, moved)
                end
                context:timeout(60, moved)
            end
        )
    end
)
