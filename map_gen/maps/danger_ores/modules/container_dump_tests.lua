-- In-game tests for container dump. These run on every Danger Ores map with it enabled (the
-- default): a chest destroyed with items in it turns them into ore in its place, and an empty
-- one leaves nothing.
--
-- They destroy the chests with die(), near spawn, clearing any ore off the chest's tile first
-- (some maps put ore right up to spawn).
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local RS = require 'map_gen.shared.redmew_surface'

local config = DOC.container_dump
if not config.enabled then
    return
end

local ORE = config.entity_name or 'coal'
-- Permanence leaves a random ore wherever any such building was, so there an empty chest leaves ore too.
local PERMANENCE = package.loaded['__level__/map_gen/maps/danger_ores/modules/permanence.lua'] ~= nil

Declare.module(
    {'map_gen', 'danger ores', 'container dump'},
    function()
        local function spawn_surface()
            local surface = RS.get_surface()
            surface.request_to_generate_chunks({0, 0}, 2)
            surface.force_generate_chunk_requests()
            return surface
        end

        -- A tile near `near` with room for a chest, cleared of any ore on it: the test only
        -- cares about the ore the chest leaves.
        local function clear_spot(surface, near)
            local p = surface.find_non_colliding_position('iron-chest', near, 32, 1)
            if not p then
                return nil
            end
            local x, y = math.floor(p.x), math.floor(p.y)
            for _, ore in pairs(surface.find_entities_filtered {area = {{x, y}, {x + 1, y + 1}}, type = 'resource'}) do
                ore.destroy()
            end
            return {x = x, y = y}
        end

        Declare.test(
            'a destroyed chest with items in it turns them into ore',
            function()
                -- Arrange
                local surface = spawn_surface()
                local position = clear_spot(surface, {x = -30, y = -30})
                Assert.is_true(position ~= nil, 'no room for a chest near spawn')
                local chest = surface.create_entity {name = 'iron-chest', position = {position.x + 0.5, position.y + 0.5}, force = 'player'}
                Assert.valid(chest, 'the test chest was not created')
                chest.insert {name = 'iron-plate', count = 100}
                local spot = {{position.x, position.y}, {position.x + 1, position.y + 1}}
                Assert.equal(0, surface.count_entities_filtered {area = spot, type = 'resource'}, 'ore was already there')

                -- Act
                chest.die()

                -- Assert
                local ore = surface.find_entities_filtered {area = spot, name = ORE}[1]
                Assert.is_true(ore ~= nil, 'no ' .. ORE .. ' where the chest stood')
                Assert.equal(100, ore.amount, ORE .. ' left by a chest of 100 plates')
            end
        )

        if not PERMANENCE then
            Declare.test(
                'a destroyed empty chest leaves no ore',
                function()
                    -- Arrange
                    local surface = spawn_surface()
                    local position = clear_spot(surface, {x = -30, y = 30})
                    Assert.is_true(position ~= nil, 'no room for a chest near spawn')
                    local chest = surface.create_entity {name = 'iron-chest', position = {position.x + 0.5, position.y + 0.5}, force = 'player'}
                    Assert.valid(chest, 'the test chest was not created')

                    -- Act
                    chest.die()

                    -- Assert
                    Assert.equal(0, surface.count_entities_filtered {area = {{position.x, position.y}, {position.x + 1, position.y + 1}}, name = ORE}, ORE .. ' left by an empty chest')
                end
            )
        end
    end
)
