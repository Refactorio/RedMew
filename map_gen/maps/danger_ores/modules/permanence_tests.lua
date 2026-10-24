-- In-game tests for permanence. These run on maps that use it (DO/Permanence): a player
-- building that isn't allowed on ore leaves ore in its footprint when it is mined or destroyed,
-- and one that is allowed on ore leaves none.
--
-- The tests destroy buildings with die(), which raises on_entity_died like any death; mining
-- them would need a player. They build on dry ground in the ore-free spawn circle: the
-- Permanence map's grid lines are water, and ore can't go on water.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local AllowedEntities = require 'map_gen.maps.danger_ores.modules.allowed_entities'
local RS = require 'map_gen.shared.redmew_surface'

Declare.module(
    {'map_gen', 'danger ores', 'permanence'},
    function()
        local function spawn_surface()
            local surface = RS.get_surface()
            surface.request_to_generate_chunks({0, 0}, 2)
            surface.force_generate_chunk_requests()
            return surface
        end

        local function ore_in(surface, entity_area)
            return surface.find_entities_filtered {area = entity_area, type = 'resource'}
        end

        Declare.test(
            'a building not allowed on ore leaves ore where it stood',
            function()
                -- Arrange
                local surface = spawn_surface()
                local position = surface.find_non_colliding_position('assembling-machine-1', {30.5, -29.5}, 24, 1)
                Assert.is_true(position ~= nil, 'no dry ground for the test machine near spawn')
                local machine = surface.create_entity {name = 'assembling-machine-1', position = position, force = 'player'}
                Assert.valid(machine, 'the test machine was not created')
                Assert.is_true(not AllowedEntities.is_allowed(machine), 'assemblers are allowed on ore here, so this test proves nothing')
                local box = machine.bounding_box
                local footprint = {{math.floor(box.left_top.x), math.floor(box.left_top.y)}, {math.floor(box.right_bottom.x) + 1, math.floor(box.right_bottom.y) + 1}}
                local tiles = (footprint[2][1] - footprint[1][1]) * (footprint[2][2] - footprint[1][2])
                local health = machine.prototype.get_max_health(machine.quality)
                Assert.equal(0, #ore_in(surface, footprint), 'ore was already there')

                -- Act
                machine.die()

                -- Assert
                local ores = ore_in(surface, footprint)
                local where = {}
                for _, ore in pairs(ores) do
                    where[#where + 1] = ore.position.x .. ',' .. ore.position.y
                end
                Assert.equal(tiles, #ores, 'ore tiles where the machine stood (' .. footprint[1][1] .. ',' .. footprint[1][2] .. ' to '
                    .. footprint[2][1] .. ',' .. footprint[2][2] .. '): ore at ' .. table.concat(where, ' '))
                Assert.equal(math.max(1, math.floor(health / tiles)), ores[1].amount, 'ore per tile')
            end
        )

        Declare.test(
            'a building allowed on ore leaves none',
            function()
                -- Arrange
                local surface = spawn_surface()
                local position = surface.find_non_colliding_position('transport-belt', {30.5, 29.5}, 24, 1)
                Assert.is_true(position ~= nil, 'no dry ground for the test belt near spawn')
                local belt = surface.create_entity {name = 'transport-belt', position = position, force = 'player'}
                Assert.valid(belt, 'the test belt was not created')
                Assert.is_true(AllowedEntities.is_allowed(belt), 'belts are not allowed on ore here, so this test proves nothing')
                local x, y = math.floor(belt.position.x), math.floor(belt.position.y)

                -- Act
                belt.die()

                -- Assert
                Assert.equal(0, #ore_in(surface, {{x, y}, {x + 1, y + 1}}), 'ore where the belt stood')
            end
        )
    end
)
