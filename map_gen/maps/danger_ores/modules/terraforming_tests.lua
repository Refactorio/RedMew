-- In-game tests for terraforming. These run under _DEBUG via /test-runner on every Danger Ores
-- map that has terraforming enabled (the module is always loaded, but only started when enabled).
--
-- The locked chunks they use are far from spawn, so a played save is unlikely to have opened
-- them already. Unlocking a chunk raises the pollution needed for the next one, so that test
-- puts the threshold back when it finishes; the chunk itself stays open on that save.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local RS = require 'map_gen.shared.redmew_surface'
local H = require 'map_gen.maps.danger_ores.modules.terrain_test_helper'

if not DOC.terraforming.enabled then
    return
end

local CHUNK_TILES = 32 * 32

local function void_count(surface, area)
    return surface.count_tiles_filtered {area = area, name = 'out-of-map'}
end

-- Requests a chunk without unlocking it, unlike the helper's generate.
local function request_chunk(cx, cy)
    local surface = RS.get_surface()
    surface.request_to_generate_chunks({cx * 32 + 16, cy * 32 + 16}, 0)
    surface.force_generate_chunk_requests()
    return surface, H.chunk_area(cx, cy)
end

-- Chunks the overlay tests generate the real map in, as {chunk x, chunk y, radius in chunks}:
-- spawn out to ~320 tiles, and the Fault Lines windows further out along the axes.
local OVERLAY_TEST_CHUNKS = {{0, 0, 12}, {8, 0, 4}, {0, 28, 4}, {-60, 0, 4}}

local function near_overlay_tests(cx, cy)
    for _, c in pairs(OVERLAY_TEST_CHUNKS) do
        if math.abs(cx - c[1]) <= c[3] and math.abs(cy - c[2]) <= c[3] then
            return true
        end
    end
    return false
end

-- Finds a generated chunk outside the starting area, far from spawn and from the chunks the
-- overlay tests generate, trying each direction from far to near. A played save is less likely
-- to have opened chunks this far out. Maps can be shaped (3-Way's T, One Direction's ribbon),
-- so it tries several directions. With in_bounds, only chunks terraforming tracks count
-- (inside its bounds shape, the whole map by default), since only those can be unlocked.
-- `offset` shifts the distances tried, so two tests never pick the same chunk.
-- @return LuaSurface, area, chunk x, chunk y; nil if there is none
local function find_far_chunk(directions, in_bounds, offset)
    local bounds = DOC.terraforming.bounds
    local half_start = DOC.terraforming.start_size / 2
    local nearest = math.ceil(half_start / 32) + 2
    for _, d in pairs(directions) do
        for distance = 100 - offset, nearest, -7 do
            local cx, cy = d[1] * distance, d[2] * distance
            local x, y = cx * 32 + 0.5, cy * 32 + 0.5
            local outside_start = math.abs(x) > half_start or math.abs(y) > half_start
            if outside_start and not near_overlay_tests(cx, cy)
                and (not in_bounds or not bounds or bounds(x, y, {x = x, y = y})) then
                local surface, area = request_chunk(cx, cy)
                if surface.is_chunk_generated({cx, cy}) then
                    return surface, area, cx, cy
                end
            end
        end
    end
end

local ALL_DIRECTIONS = {{1, 1}, {-1, 1}, {1, -1}, {-1, -1}, {1, 0}, {0, 1}, {-1, 0}, {0, -1}}

Declare.module(
    {'map_gen', 'danger ores', 'terraforming'},
    function()

        Declare.test(
            'the starting area is open',
            function()
                -- Act: only the spawn chunk: elsewhere in the starting area the map can have void
                -- of its own (3-Way's T, say), which looks just like a locked chunk
                local surface, area = request_chunk(0, 0)

                -- Assert
                Assert.is_true(void_count(surface, area) < CHUNK_TILES, 'the spawn chunk is locked')
            end
        )

        Declare.test(
            'chunks outside the starting area are locked',
            function()
                -- Act
                local surface, area, cx, cy = find_far_chunk(ALL_DIRECTIONS, false, 0)

                -- Assert
                Assert.is_true(surface ~= nil, 'no chunk outside the starting area could be generated')
                Assert.equal(CHUNK_TILES, void_count(surface, area), 'void tiles in chunk ' .. cx .. ',' .. cy)
            end
        )

        Declare.test(
            'a locked chunk opens once its pollution passes the threshold',
            function(context)
                -- Arrange
                local data = _G.terraforming_pollution_data
                local before = data.min_pollution
                context:add_teardown(function()
                    data.min_pollution = before
                end)

                local surface, area, cx, cy = find_far_chunk(ALL_DIRECTIONS, true, 3)
                Assert.is_true(surface ~= nil, 'no chunk inside the terraforming bounds could be generated')
                local name = 'chunk ' .. cx .. ',' .. cy
                Assert.equal(CHUNK_TILES, void_count(surface, area), name .. ' was already open')

                -- Act: keep the pollution up the way a factory would: it spreads out and decays
                -- while terraforming works round to this chunk
                local centre = {area.left_top.x + 16, area.left_top.y + 16}
                local function top_up()
                    local missing = before * 2 - surface.get_pollution(centre)
                    if missing > 0 then
                        surface.pollute(centre, missing)
                    end
                end
                top_up()

                -- Assert: terraforming checks one locked chunk per tick, then queues the chunk for
                -- generation; poll until it has been generated
                local tries = 120
                local function check()
                    if void_count(surface, area) < CHUNK_TILES then
                        local expected = before
                        if before < data.max_pollution then
                            expected = before + data.pollution_increment
                        end
                        Assert.equal(expected, data.min_pollution, 'pollution needed for the next chunk')
                        return
                    end
                    tries = tries - 1
                    top_up()
                    Assert.is_true(tries > 0, name .. ' did not open with ' .. surface.get_pollution(centre) .. ' pollution, threshold ' .. before)
                    context:timeout(30, check)
                end
                context:timeout(30, check)
            end
        )
    end
)
