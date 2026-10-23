-- In-game tests for the pure City Blocks lattice geometry. These run under _DEBUG via
-- /test-runner, and in CI, whenever city_blocks_layout.lua is loaded, i.e. on the
-- DO/City-Blocks preset. None of them touch the game: they run here, rather than on a
-- standalone Lua, so the arithmetic is checked on Factorio's own Lua (5.2, where every number
-- is a double).
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local L = require 'map_gen.maps.danger_ores.modules.city_blocks_layout'

local PITCH = L.PITCH
local MARGIN = L.ROOM_EDGE_MARGIN

-- Chunk -2 is a room's west-most chunk (local offset 0), so its low-x tiles face a corridor;
-- chunk 1 is its east-most (local offset PITCH-2).
local WEST_CHUNK_X = -2 * 32
local EAST_CHUNK_X = 1 * 32

-- the rooms next to spawn, which the BFS seeding gives every ore
local NEXT_TO_SPAWN = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}

local function fixed_shuffle(t)
    return t -- identity: keeps assertions readable
end

-- A small LCG rather than math.random, so a run is reproducible. The multiplier is kept small
-- on purpose: every number is a double, and a wider one would lose the low bits that carry the
-- randomness.
local function seeded_random(seed)
    local state = seed
    return function(n)
        state = (state * 75 + 74) % 65537
        return state % n + 1
    end
end

-- Each chunk stamps only the pieces that fall inside it.
local function chunk_of(v)
    return math.floor((16 + v) / 32)
end

local function piece_chunk(e)
    return chunk_of(e.x) .. '/' .. chunk_of(e.y)
end

Declare.module(
    {'map_gen', 'city blocks', 'layout'},
    function()
        Declare.test(
            'spawn sits in the middle of room 0',
            function()
                -- Act
                local room, offset = L.room_of_chunk(0)

                -- Assert: the offset of 2 puts spawn in the middle of its room rather than
                -- against a corridor
                Assert.equal(0, room, 'room of chunk 0')
                Assert.equal(2, offset, 'local offset of chunk 0')
            end
        )

        Declare.test(
            'every cell is PITCH-1 chunks of room, then one of corridor',
            function()
                -- Act
                local room_chunks, corridor_chunks = 0, 0
                for c = -2, -2 + PITCH - 1 do
                    local _, offset = L.room_of_chunk(c)
                    if offset == PITCH - 1 then
                        corridor_chunks = corridor_chunks + 1
                    else
                        room_chunks = room_chunks + 1
                    end
                end

                -- Assert
                Assert.equal(1, corridor_chunks, 'corridor chunks in a cell')
                Assert.equal(PITCH - 1, room_chunks, 'room chunks in a cell')
            end
        )

        Declare.test(
            'room numbers go up by one a cell, either side of spawn',
            function()
                -- Act
                local east_room = L.room_of_chunk(3)
                local west_room, west_offset = L.room_of_chunk(-3)

                -- Assert: no gap at the origin
                Assert.equal(1, east_room, 'room of chunk 3, the first chunk of room 1')
                Assert.equal(-1, west_room, 'room of chunk -3')
                Assert.equal(PITCH - 1, west_offset, 'local offset of chunk -3, a corridor chunk')
            end
        )

        Declare.test(
            'a chunk is a corridor if either axis is on the lattice, and a corner if both are',
            function()
                -- Act
                local vertical_x, vertical_y = L.corridor_axes_of_chunk(2, 0)
                local corner_x, corner_y = L.corridor_axes_of_chunk(2, 2)
                local room_x, room_y = L.corridor_axes_of_chunk(0, 0)

                -- Assert
                Assert.is_true(vertical_x and not vertical_y, 'chunk 2/0 is not a vertical corridor')
                Assert.is_true(corner_x and corner_y, 'chunk 2/2 is not a corner')
                Assert.is_true(not room_x and not room_y, 'chunk 0/0 is not room interior')
            end
        )

        Declare.test(
            'a corridor chunk is corridor from its first tile to its last',
            function()
                -- Act
                local first = L.on_corridor_tile(2 * 32, 0)
                local last = L.on_corridor_tile(2 * 32 + 31, 31)
                local before = L.on_corridor_tile(2 * 32 - 1, 0)

                -- Assert
                Assert.is_true(first, 'the first tile of a corridor chunk is not on the corridor')
                Assert.is_true(last, 'the last tile of a corridor chunk is not on the corridor')
                Assert.is_true(not before, 'the tile before a corridor chunk is on the corridor')
            end
        )

        Declare.test(
            'rooms past the radius are out of bounds',
            function()
                -- Act
                local spawn = L.in_bounds(0, 0)
                local corner = L.in_bounds(L.ROOMS_RADIUS, -L.ROOMS_RADIUS)
                local past = L.in_bounds(L.ROOMS_RADIUS + 1, 0)
                local interior_neighbours = #L.neighbours_of(0, 0)
                local corner_neighbours = #L.neighbours_of(L.ROOMS_RADIUS, L.ROOMS_RADIUS)

                -- Assert: in_bounds gates the generated world; outside it chunks are voided
                Assert.is_true(spawn, 'the spawn room is out of bounds')
                Assert.is_true(corner, 'the corner room is out of bounds')
                Assert.is_true(not past, 'a room past the radius is in bounds')
                Assert.equal(4, interior_neighbours, 'neighbours of an interior room')
                Assert.equal(2, corner_neighbours, 'neighbours of a corner room')
            end
        )

        -- Regression cover for the fix that keeps ore off the room edge: without it a fresh room
        -- cannot be automated until a bay has been hand-mined.
        Declare.test(
            'the margin is ' .. MARGIN .. ' tiles deep on the corridor side of a room\'s edge chunks',
            function()
                -- Act
                local west = {}
                for o = 0, 31 do
                    west[o] = L.in_room_margin(WEST_CHUNK_X + o, 0)
                end
                local east = {}
                for o = 0, 31 do
                    east[o] = L.in_room_margin(EAST_CHUNK_X + o, 0)
                end

                -- Assert: the west chunk's low-x tiles face the corridor, its high-x ones the
                -- room's own interior; the east chunk is mirrored
                for o = 0, 31 do
                    Assert.equal(o < MARGIN, west[o], 'margin at offset ' .. o .. ' of the west chunk')
                    Assert.equal(o >= 32 - MARGIN, east[o], 'margin at offset ' .. o .. ' of the east chunk')
                end
            end
        )

        Declare.test(
            'the middle chunks of a room are never margin',
            function()
                -- Act
                local margin = {}
                for _, chunk in ipairs({-1, 0}) do
                    for o = 0, 31 do
                        if L.in_room_margin(chunk * 32 + o, 0) or L.in_room_margin(0, chunk * 32 + o) then
                            margin[#margin + 1] = chunk .. ':' .. o
                        end
                    end
                end

                -- Assert: they touch no corridor
                Assert.equal(0, #margin, 'margin tiles in the middle chunks (chunk:offset): ' .. table.concat(margin, ' '))
            end
        )

        Declare.test(
            'the margin frames the room on both axes, and leaves the corridors out',
            function()
                -- Act
                local corner = L.in_room_margin(WEST_CHUNK_X, -2 * 32)
                local north = L.in_room_margin(0, WEST_CHUNK_X)
                local corridor = L.in_room_margin(2 * 32 + 16, 0)
                local room_tiles = (PITCH - 1) * 32
                local margin_count = 0
                for x = 0, room_tiles - 1 do
                    for y = 0, room_tiles - 1 do
                        if L.in_room_margin(WEST_CHUNK_X + x, WEST_CHUNK_X + y) then
                            margin_count = margin_count + 1
                        end
                    end
                end

                -- Assert: a frame, so the room's area minus the inset area
                Assert.is_true(corner, 'a room corner tile is not margin')
                Assert.is_true(north, 'the north edge has no margin')
                Assert.is_true(not corridor, 'a corridor tile is margin')
                local inset = room_tiles - 2 * MARGIN
                Assert.equal(room_tiles * room_tiles - inset * inset, margin_count, 'tiles in the ' .. MARGIN .. '-tile margin frame')
            end
        )

        Declare.test(
            'every room gets an ore, and all four are next to spawn',
            function()
                -- Act
                local room_ore = L.assign_ores(4, nil, seeded_random(1), fixed_shuffle)

                -- Assert
                local rooms_across = 2 * L.ROOMS_RADIUS + 1
                local count = 0
                for k, ore in pairs(room_ore) do
                    count = count + 1
                    Assert.is_true(ore >= 1 and ore <= 4, 'room ' .. k .. ' has ore index ' .. ore)
                end
                Assert.equal(rooms_across * rooms_across, count, 'rooms with an ore')

                -- so a new base can reach every ore without a long trek
                local near_spawn, distinct = {}, 0
                for _, room in ipairs(NEXT_TO_SPAWN) do
                    local ore = room_ore[L.key(room[1], room[2])]
                    if not near_spawn[ore] then
                        near_spawn[ore] = true
                        distinct = distinct + 1
                    end
                end
                Assert.equal(4, distinct, 'ores in the rooms next to spawn')
            end
        )

        Declare.test(
            'ores are assigned the same for the same RNG',
            function()
                -- Act
                local first = L.assign_ores(4, nil, seeded_random(1), fixed_shuffle)
                local again = L.assign_ores(4, nil, seeded_random(1), fixed_shuffle)

                -- Assert
                for k, ore in pairs(first) do
                    Assert.equal(ore, again[k], 'ore of room ' .. k .. ' with the same RNG')
                end
            end
        )

        Declare.test(
            'an ore with no weight is only placed next to spawn',
            function()
                -- Arrange
                local seeded = {}
                for _, room in ipairs(NEXT_TO_SPAWN) do
                    seeded[L.key(room[1], room[2])] = true
                end

                -- Act
                local room_ore = L.assign_ores(2, {1, 0}, seeded_random(7), fixed_shuffle)

                -- Assert: weights only bias the rooms the guaranteed seeding doesn't place
                for k, ore in pairs(room_ore) do
                    Assert.is_true(ore ~= 2 or seeded[k], 'the zero-weight ore was placed in room ' .. k)
                end
            end
        )

        Declare.test(
            'corridors are curbed and their tracks sit on gravel',
            function()
                -- Act: a vertical corridor's pattern runs across it, so depends on x only, and a
                -- horizontal one on y only
                local vertical, horizontal = {}, {}
                for o = 0, 31 do
                    vertical[o] = L.corridor_tile(o, 5, true, false)
                    horizontal[o] = L.corridor_tile(5, o, false, true)
                end
                local horizontal_ignores_x = L.corridor_tile(0, 5, false, true)

                -- Assert: 2-tile concrete curbs on both edges and a 2-tile concrete median between
                -- the tracks, gravel rail bed everywhere else, the tracks included
                for o = 0, 31 do
                    local expected = (o < 2 or o >= 30 or o == 15 or o == 16) and 'concrete' or 'stone-path'
                    Assert.equal(expected, vertical[o], 'vertical corridor tile at offset ' .. o)
                    Assert.equal(expected, horizontal[o], 'horizontal corridor tile at offset ' .. o)
                end
                Assert.equal('stone-path', horizontal_ignores_x, 'horizontal corridor tile at x 0')
                for _, offset in ipairs({L.RAIL_A, L.RAIL_B}) do
                    Assert.equal('stone-path', vertical[offset], 'tile under the track at ' .. offset)
                end
            end
        )

        Declare.test(
            'a corner is a concrete frame round gravel',
            function()
                -- Act
                local edge = L.corridor_tile(0, 0, true, true)
                local centre = L.corridor_tile(16, 16, true, true)
                local far_edge = L.corridor_tile(31, 31, true, true)

                -- Assert: the inverse of a straight corridor, round the ring's field
                Assert.equal('concrete', edge, 'corner tile at 0,0')
                Assert.equal('stone-path', centre, 'corner tile at 16,16')
                Assert.equal('concrete', far_edge, 'corner tile at 31,31')
            end
        )

        Declare.test(
            'trunks run on the rail grid and stop short of a corner',
            function()
                -- Act
                local from, to = L.trunk_range(64, 96, false, false)
                local near_from, near_to = L.trunk_range(64, 96, true, true)

                -- Assert: with no corner next to it a trunk runs the full width, starting on an
                -- odd tile so the rails land on Factorio's 2-tile grid
                Assert.equal(65, from, 'first rail of a full-width trunk')
                Assert.equal(95, to, 'last rail of a full-width trunk')

                -- next to a corner the ring overhangs, so the trunk stops short of RING_REACH and
                -- picks up again on the next grid slot
                Assert.equal(64 - 16 + L.RING_REACH + 1, near_from, 'first rail after the ring')
                Assert.equal(96 + 16 - L.RING_REACH - 1, near_to, 'last rail before the next ring')
                Assert.equal(0, (near_from - from) % 2, 'grid parity of the shortened trunk')
            end
        )

        Declare.test(
            'every roundabout signal has a rail in its own chunk, listed before it',
            function()
                -- Act: which chunk each piece falls in
                local rails_by_chunk = {}
                local first_signal_index, last_rail_index
                for i, e in ipairs(L.ROUNDABOUT) do
                    if L.SIGNAL_NAMES[e.name] then
                        first_signal_index = first_signal_index or i
                    else
                        last_rail_index = i
                        rails_by_chunk[piece_chunk(e)] = true
                    end
                end

                -- Assert: each chunk stamps only its own pieces, so a signal whose chunk holds no
                -- rail would fail to place when that chunk generates first
                Assert.is_true(first_signal_index > last_rail_index, 'a rail is listed after the first signal')
                for _, e in ipairs(L.ROUNDABOUT) do
                    if L.SIGNAL_NAMES[e.name] then
                        Assert.is_true(rails_by_chunk[piece_chunk(e)], 'the signal at ' .. e.x .. ', ' .. e.y .. ' has no rail in its chunk')
                    end
                end
            end
        )

        Declare.test(
            'the roundabout fits inside RING_REACH and meets the trunks',
            function()
                -- Act
                local max_reach = 0
                local approach = {}
                for _, e in ipairs(L.ROUNDABOUT) do
                    max_reach = math.max(max_reach, math.abs(e.x), math.abs(e.y))
                    if math.abs(e.x) == L.RING_REACH - 2 or math.abs(e.y) == L.RING_REACH - 2 then
                        approach[e.x] = true
                        approach[e.y] = true
                    end
                end

                -- Assert: the trunks are shortened to RING_REACH, so a ring past it would overlap
                -- them, and its approach lanes have to meet the trunk offsets (chunk-local
                -- RAIL_A/RAIL_B, -3/+3 from the corner's middle) for trains to cross
                Assert.is_true(max_reach <= L.RING_REACH, 'the ring reaches ' .. max_reach .. ', past RING_REACH ' .. L.RING_REACH)
                Assert.is_true(approach[L.RAIL_A - 16] and approach[L.RAIL_B - 16],
                    'the ring\'s approach lanes are not on the trunk offsets (' .. (L.RAIL_A - 16) .. '/' .. (L.RAIL_B - 16) .. ')')
            end
        )
    end
)
