-- In-game tests for City Blocks chunk generation. These run under _DEBUG via /test-runner,
-- and are only discovered when city_blocks.lua is loaded, i.e. when the DO/City-Blocks
-- preset is the active map.
--
-- Everything here drives Public.generate_chunk directly on a scratch surface rather than
-- waiting for real map generation, so a test can pick the exact chunk it wants to inspect.
-- The pure geometry these assertions are compared against is tested separately in
-- city_blocks_layout_tests.lua.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'
local CityBlocks = require 'map_gen.maps.danger_ores.modules.city_blocks'
local Layout = require 'map_gen.maps.danger_ores.modules.city_blocks_layout'

local PITCH = Layout.PITCH

-- Chunk coordinates on the lattice: chunks 2, 7 and -3 are corridors on either axis (local
-- offset PITCH-1), chunk 0 is room interior. Tests take a corridor chunk each, because test
-- order is not defined and generating a chunk twice would leave the previous test's rails
-- behind. None of these sit next to a corner, so their trunks run the full chunk width.
local PAVING_CHUNK = 2
local TRUNK_CHUNK = 7
local CLEARING_CHUNK = -3
local INTERIOR_CHUNK = 0

local function chunk_area(cx, cy)
    return {
        left_top = {x = cx * 32, y = cy * 32},
        right_bottom = {x = cx * 32 + 32, y = cy * 32 + 32}
    }
end

Declare.module(
    {'map_gen', 'city blocks'},
    function()
        local test_surface, teardown

        Declare.module_startup(
            function(context)
                -- Big enough to hold the corridor and corner chunks the tests inspect;
                -- the helper generates the chunks and clears the surface for us. No player
                -- is needed, so these also run headless in CI.
                test_surface, teardown = Helper.create_test_surface(context, {area = {512, 512}})
            end
        )

        Declare.module_teardown(
            function()
                teardown()
            end
        )

        Declare.test(
            'corridor chunk is paved to the layout pattern',
            function()
                -- Arrange
                local surface = test_surface
                local area = chunk_area(PAVING_CHUNK, INTERIOR_CHUNK)

                -- Act
                CityBlocks.generate_chunk(surface, area)

                -- Assert: every tile of the chunk matches what the pure pattern says it
                -- should be, which also pins the curb/median layout end to end.
                local left, top = area.left_top.x, area.left_top.y
                local mismatches = 0
                local first_bad
                for xo = 0, 31 do
                    for yo = 0, 31 do
                        local expected = Layout.corridor_tile(xo, yo, true, false)
                        local actual = surface.get_tile(left + xo, top + yo).name
                        if actual ~= expected then
                            mismatches = mismatches + 1
                            first_bad = first_bad or (xo .. '/' .. yo .. ' was ' .. actual .. ' expected ' .. expected)
                        end
                    end
                end

                Assert.equal(0, mismatches, 'tiles not matching the corridor pattern, first: ' .. (first_bad or 'none'))
            end
        )

        Declare.test(
            'corridor chunks carry both trunk tracks, north-south and east-west',
            function()
                -- Arrange: a north-south corridor (x is the corridor axis) and an east-west one
                local surface = test_surface
                local cases = {
                    {name = 'north-south', area = chunk_area(TRUNK_CHUNK, INTERIOR_CHUNK), vertical = true},
                    {name = 'east-west', area = chunk_area(INTERIOR_CHUNK, TRUNK_CHUNK), vertical = false}
                }
                for _, case in pairs(cases) do
                    local area = case.area
                    local lt, rb = area.left_top, area.right_bottom

                    -- Act
                    CityBlocks.generate_chunk(surface, area)

                    -- Assert: two tracks, one rail every 2 tiles along the chunk.
                    local low, high = lt.y, rb.y
                    if not case.vertical then
                        low, high = lt.x, rb.x
                    end
                    local from, to = Layout.trunk_range(low, high, false, false)
                    local slots = math.floor((to - from) / 2) + 1
                    local actual = surface.count_entities_filtered {area = area, name = 'straight-rail'}
                    Assert.equal(slots * 2, actual, 'trunk rails in the ' .. case.name .. ' corridor chunk')

                    -- ... and they sit on the two track offsets, with clear ground between them.
                    -- band(a, b): the strip from offset a to offset b across the corridor
                    local function band(a, b)
                        if case.vertical then
                            return {{lt.x + a, lt.y}, {lt.x + b, rb.y}}
                        end
                        return {{lt.x, lt.y + a}, {rb.x, lt.y + b}}
                    end
                    for _, offset in pairs({Layout.RAIL_A, Layout.RAIL_B}) do
                        local on_track = surface.count_entities_filtered {area = band(offset - 0.5, offset + 0.5), name = 'straight-rail'}
                        Assert.equal(slots, on_track, 'rails on track offset ' .. offset .. ' of the ' .. case.name .. ' corridor')
                    end

                    local between = surface.count_entities_filtered {area = band(Layout.RAIL_A + 2, Layout.RAIL_B - 2), name = 'straight-rail'}
                    Assert.equal(0, between, 'rails between the two tracks of the ' .. case.name .. ' corridor')
                end
            end
        )

        Declare.test(
            'corner chunk gets the roundabout instead of a trunk',
            function()
                -- Arrange
                local surface = test_surface
                local area = chunk_area(PAVING_CHUNK, PAVING_CHUNK)
                local center_x, center_y = area.left_top.x + 16, area.left_top.y + 16

                -- Act
                CityBlocks.generate_chunk(surface, area)

                -- Assert: every ring piece that falls inside this chunk was placed. Pieces
                -- that overhang into the neighbouring corridor chunks are that chunk's job.
                local missing = 0
                local first_missing
                local expected_pieces = 0
                for _, e in pairs(Layout.ROUNDABOUT) do
                    local x, y = center_x + e.x, center_y + e.y
                    if x >= area.left_top.x and x < area.right_bottom.x
                        and y >= area.left_top.y and y < area.right_bottom.y then
                        expected_pieces = expected_pieces + 1
                        local found = surface.count_entities_filtered {
                            name = e.name,
                            position = {x, y}
                        }
                        if found == 0 then
                            missing = missing + 1
                            first_missing = first_missing or (e.name .. ' at ' .. e.x .. '/' .. e.y)
                        end
                    end
                end

                Assert.is_true(expected_pieces > 0, 'the corner chunk should contain ring pieces')
                Assert.equal(0, missing, 'ring pieces not placed, first: ' .. (first_missing or 'none'))

                -- The corner is ring only: trunk rails stop short and let it take over.
                Assert.equal(0, surface.count_entities_filtered {area = area, name = 'straight-rail'},
                    'no trunk rails on the corner')
            end
        )

        Declare.test(
            'room interior is left untouched',
            function()
                -- Arrange
                local surface = test_surface
                local area = chunk_area(INTERIOR_CHUNK, INTERIOR_CHUNK)
                local before = surface.get_tile(area.left_top.x + 5, area.left_top.y + 5).name

                -- Act
                CityBlocks.generate_chunk(surface, area)

                -- Assert: the room is the danger-ores ore field, generated by the map's
                -- shape builder, so chunk generation must not pave or build anything here.
                Assert.equal(before, surface.get_tile(area.left_top.x + 5, area.left_top.y + 5).name,
                    'interior tile changed')
                Assert.equal(0, surface.count_entities_filtered {area = area, name = 'straight-rail'},
                    'rails built inside a room')
            end
        )

        Declare.test(
            'paving clears whatever the ore field left on the corridor',
            function()
                -- Arrange: setting tiles does not remove entities, so the corridor has to
                -- clear the ore field itself or the rails end up buried in ore.
                local surface = test_surface
                local area = chunk_area(CLEARING_CHUNK, INTERIOR_CHUNK)
                surface.create_entity {
                    name = 'iron-ore',
                    position = {area.left_top.x + 8, area.left_top.y + 8},
                    amount = 100
                }
                Assert.equal(1, surface.count_entities_filtered {area = area, type = 'resource'},
                    'test ore was not placed')

                -- Act
                CityBlocks.generate_chunk(surface, area)

                -- Assert
                Assert.equal(0, surface.count_entities_filtered {area = area, type = 'resource'},
                    'ore left on the corridor')
            end
        )

        Declare.test(
            'chunks past the room radius are voided',
            function(context)
                -- Arrange: the world is finite, so this needs a chunk further out than the
                -- shared test surface reaches. Generating three chunks out there is cheap.
                local far_chunk = (Layout.ROOMS_RADIUS + 1) * PITCH
                local area = chunk_area(far_chunk, 0)
                local name = 'city_blocks_void_test'
                if game.get_surface(name) then
                    game.delete_surface(name)
                end
                local surface = game.create_surface(name)

                context:add_teardown(function()
                    if surface.valid then
                        game.delete_surface(surface)
                    end
                end)

                surface.request_to_generate_chunks({area.left_top.x + 16, area.left_top.y + 16}, 1)
                surface.force_generate_chunk_requests()

                local ri = Layout.room_of_chunk(far_chunk)
                Assert.is_true(not Layout.in_bounds(ri, 0), 'chosen chunk should be out of bounds')

                -- Act
                CityBlocks.generate_chunk(surface, area)

                -- Assert
                Assert.equal('out-of-map', surface.get_tile(area.left_top.x + 5, 5).name,
                    'chunk outside the room radius was not voided')
            end
        )
    end
)

-- Chunk stamping against a surface that only records what it's asked to do, so a test sees
-- everything a chunk writes, including anything outside the chunk that a real surface would
-- take without complaint (and the next chunk would then overwrite).
Declare.module(
    {'map_gen', 'city blocks', 'chunk stamping'},
    function()
        local function recording_surface()
            local s = {tiles = {}, entities = {}}
            function s.set_tiles(tiles)
                for _, t in ipairs(tiles) do
                    s.tiles[t.position[1] .. '/' .. t.position[2]] = t.name
                end
            end
            function s.create_entity(spec)
                s.entities[#s.entities + 1] = {name = spec.name, x = spec.position[1], y = spec.position[2]}
                return s.entities[#s.entities]
            end
            function s.find_entities_filtered()
                return {}
            end
            return s
        end

        local function count(s, name)
            local n = 0
            for _, e in ipairs(s.entities) do
                if e.name == name then
                    n = n + 1
                end
            end
            return n
        end

        local function assert_inside(s, area, what)
            for _, e in ipairs(s.entities) do
                Assert.is_true(e.x >= area.left_top.x and e.x < area.right_bottom.x and e.y >= area.left_top.y and e.y < area.right_bottom.y,
                    what .. ' stamped ' .. e.name .. ' outside itself at ' .. e.x .. ', ' .. e.y)
            end
        end

        Declare.test(
            'a corridor chunk only writes inside itself',
            function()
                -- Arrange
                local s = recording_surface()
                local area = chunk_area(TRUNK_CHUNK, 0)

                -- Act
                CityBlocks.generate_chunk(s, area)

                -- Assert
                Assert.is_true(#s.entities > 0, 'the corridor chunk stamped nothing')
                assert_inside(s, area, 'the corridor chunk')
            end
        )

        Declare.test(
            'a corner chunk stamps exactly the ring pieces inside it',
            function()
                -- Arrange
                local s = recording_surface()
                local area = chunk_area(2, 2)

                -- Act
                CityBlocks.generate_chunk(s, area)

                -- Assert
                local expected_pieces = 0
                for _, e in pairs(Layout.ROUNDABOUT) do
                    local x, y = area.left_top.x + 16 + e.x, area.left_top.y + 16 + e.y
                    if x >= area.left_top.x and x < area.right_bottom.x and y >= area.left_top.y and y < area.right_bottom.y then
                        expected_pieces = expected_pieces + 1
                    end
                end
                Assert.is_true(expected_pieces > 0, 'the corner chunk should contain ring pieces')
                Assert.equal(expected_pieces, #s.entities, 'pieces stamped by the corner chunk')
            end
        )

        Declare.test(
            'a chunk next to a corner shortens its trunk and stamps the ring overhang',
            function()
                -- Arrange
                local s = recording_surface()
                local area = chunk_area(2, 1) -- local offset PITCH-2, so a corner sits to the south

                -- Act
                CityBlocks.generate_chunk(s, area)

                -- Assert
                local from, to = Layout.trunk_range(area.left_top.y, area.right_bottom.y, false, false)
                local full_slots = math.floor((to - from) / 2) + 1
                Assert.is_true(count(s, 'straight-rail') < full_slots * 2,
                    'trunk is not shortened next to a corner: ' .. count(s, 'straight-rail') .. ' rails, ' .. full_slots * 2 .. ' at full width')
                Assert.is_true(count(s, 'curved-rail-a') + count(s, 'curved-rail-b') > 0, 'the ring overhang was not stamped')
                assert_inside(s, area, 'the chunk next to a corner')
            end
        )
    end
)
