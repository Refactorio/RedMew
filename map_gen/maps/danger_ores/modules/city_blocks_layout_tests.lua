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

Declare.module(
    {'map_gen', 'city blocks', 'layout'},
    function()
        Declare.test(
            'rooms and corridors sit on the chunk lattice',
            function()
                -- Spawn sits in room 0/0, and the offset of 2 puts it in the middle of that room
                -- rather than against a corridor.
                local r0, o0 = L.room_of_chunk(0)
                Assert.is_true(r0 == 0 and o0 == 2, 'chunk 0 is room 0 at local offset 2, got ' .. r0 .. '/' .. o0)

                -- Every cell is PITCH chunks: PITCH-1 of room, then exactly one of corridor.
                local room_chunks, corridor_chunks = 0, 0
                for c = -2, -2 + PITCH - 1 do
                    local _, offset = L.room_of_chunk(c)
                    if offset == PITCH - 1 then
                        corridor_chunks = corridor_chunks + 1
                    else
                        room_chunks = room_chunks + 1
                    end
                end
                Assert.equal(1, corridor_chunks, 'one corridor chunk per cell')
                Assert.equal(PITCH - 1, room_chunks, 'room is PITCH-1 chunks wide')

                -- Room indices advance by one per cell, in both directions, without a gap at the
                -- origin.
                Assert.equal(1, select(1, L.room_of_chunk(3)), 'chunk 3 is the first chunk of room 1')
                Assert.equal(-1, select(1, L.room_of_chunk(-3)), 'chunk -3 belongs to room -1')
                Assert.equal(PITCH - 1, select(2, L.room_of_chunk(-3)), 'chunk -3 is a corridor chunk')

                -- Corridor detection: a chunk is corridor if either axis is on the lattice, and a
                -- corner is corridor on both.
                local x_wall, y_wall = L.corridor_axes_of_chunk(2, 0)
                Assert.is_true(x_wall and not y_wall, 'chunk 2/0 is a vertical corridor')
                x_wall, y_wall = L.corridor_axes_of_chunk(2, 2)
                Assert.is_true(x_wall and y_wall, 'chunk 2/2 is a corner')
                x_wall, y_wall = L.corridor_axes_of_chunk(0, 0)
                Assert.is_true(not x_wall and not y_wall, 'chunk 0/0 is room interior')

                Assert.is_true(L.on_corridor_tile(2 * 32, 0), 'first tile of a corridor chunk is on the corridor')
                Assert.is_true(L.on_corridor_tile(2 * 32 + 31, 31), 'last tile of a corridor chunk is on the corridor')
                Assert.is_true(not L.on_corridor_tile(2 * 32 - 1, 0), 'the tile before a corridor chunk is not')
            end
        )

        Declare.test(
            'rooms past the radius are out of bounds',
            function()
                -- in_bounds gates the generated world; outside it chunks are voided.
                Assert.is_true(L.in_bounds(0, 0), 'spawn room is in bounds')
                Assert.is_true(L.in_bounds(L.ROOMS_RADIUS, -L.ROOMS_RADIUS), 'corner room is in bounds')
                Assert.is_true(not L.in_bounds(L.ROOMS_RADIUS + 1, 0), 'one room past the radius is out of bounds')
                Assert.equal(4, #L.neighbours_of(0, 0), 'an interior room has 4 neighbours')
                Assert.equal(2, #L.neighbours_of(L.ROOMS_RADIUS, L.ROOMS_RADIUS), 'a corner room has 2 neighbours')
            end
        )

        -- Regression cover for the fix that keeps ore off the room edge: without it a fresh room
        -- cannot be automated until a bay has been hand-mined.
        Declare.test(
            'a margin frames each room along its corridors',
            function()
                -- Chunk -2 is the room's west-most chunk (local offset 0), so its low-x tiles face
                -- a corridor.
                local west_chunk_x = -2 * 32
                for o = 0, MARGIN - 1 do
                    Assert.is_true(L.in_room_margin(west_chunk_x + o, 0), 'west edge tile at offset ' .. o .. ' is margin')
                end
                Assert.is_true(not L.in_room_margin(west_chunk_x + MARGIN, 0), 'margin is exactly ' .. MARGIN .. ' tiles deep')
                -- ... and its high-x tiles do not: that side faces the room's own interior.
                Assert.is_true(not L.in_room_margin(west_chunk_x + 31, 0), 'inward side of the west chunk is not margin')

                -- Chunk 1 is the room's east-most chunk (local offset PITCH-2), mirrored.
                local east_chunk_x = 1 * 32
                Assert.is_true(L.in_room_margin(east_chunk_x + 31, 0), 'east edge tile is margin')
                Assert.is_true(not L.in_room_margin(east_chunk_x + 32 - MARGIN - 1, 0), 'margin stops ' .. MARGIN .. ' tiles in')
                Assert.is_true(not L.in_room_margin(east_chunk_x, 0), 'inward side of the east chunk is not margin')

                -- The two middle chunks of a room touch no corridor, so they are never margin.
                for _, chunk in ipairs({-1, 0}) do
                    for o = 0, 31 do
                        Assert.is_true(not L.in_room_margin(chunk * 32 + o, 0) and not L.in_room_margin(0, chunk * 32 + o),
                            'interior chunk ' .. chunk .. ' is margin at offset ' .. o)
                    end
                end

                -- The band runs on both axes: a room corner tile is margin from either direction.
                Assert.is_true(L.in_room_margin(west_chunk_x, -2 * 32), 'room corner tile is margin')
                Assert.is_true(L.in_room_margin(0, west_chunk_x), 'north edge produces a margin band too')

                -- A whole room's worth of tiles: the band is a frame, so the count is the room area
                -- minus the inset area.
                local room_tiles = (PITCH - 1) * 32
                local margin_count = 0
                for x = 0, room_tiles - 1 do
                    for y = 0, room_tiles - 1 do
                        if L.in_room_margin(west_chunk_x + x, west_chunk_x + y) then
                            margin_count = margin_count + 1
                        end
                    end
                end
                local expected = room_tiles * room_tiles - (room_tiles - 2 * MARGIN) * (room_tiles - 2 * MARGIN)
                Assert.equal(expected, margin_count, 'tiles in the ' .. MARGIN .. '-tile margin frame')

                -- Corridor tiles are not part of any room, so they are never margin.
                Assert.is_true(not L.in_room_margin(2 * 32 + 16, 0), 'corridor tiles are not margin')
            end
        )

        Declare.test(
            'every room gets an ore, all four next to spawn',
            function()
                local rooms_across = 2 * L.ROOMS_RADIUS + 1
                local room_ore = L.assign_ores(4, nil, seeded_random(1), fixed_shuffle)

                local count = 0
                for k, ore in pairs(room_ore) do
                    count = count + 1
                    Assert.is_true(ore >= 1 and ore <= 4, 'room ' .. k .. ' has ore index ' .. ore)
                end
                Assert.equal(rooms_across * rooms_across, count, 'rooms with an ore')

                -- The BFS seeding guarantees all four ores sit in the ring of rooms closest to
                -- spawn, so a new base can reach every ore without a long trek.
                local near_spawn = {}
                for _, room in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
                    near_spawn[room_ore[L.key(room[1], room[2])]] = true
                end
                local distinct = 0
                for _ in pairs(near_spawn) do
                    distinct = distinct + 1
                end
                Assert.equal(4, distinct, 'ores in the rooms adjacent to spawn')

                -- Same RNG in, same map out: assignment must be reproducible from the seed.
                local again = L.assign_ores(4, nil, seeded_random(1), fixed_shuffle)
                for k, ore in pairs(room_ore) do
                    Assert.equal(ore, again[k], 'ore of room ' .. k .. ' with the same RNG')
                end

                -- Weights bias the rooms that are not part of the guaranteed seeding.
                local weighted = L.assign_ores(2, {1, 0}, seeded_random(7), fixed_shuffle)
                local seeded = {[L.key(1, 0)] = true, [L.key(-1, 0)] = true, [L.key(0, 1)] = true, [L.key(0, -1)] = true}
                for k, ore in pairs(weighted) do
                    Assert.is_true(ore ~= 2 or seeded[k], 'a zero-weight ore was placed in room ' .. k .. ', not by the guaranteed seeding')
                end
            end
        )

        Declare.test(
            'corridors are curbed and their tracks sit on gravel',
            function()
                -- Straight corridor: concrete curbs on both edges, concrete median between the
                -- tracks, gravel rail bed everywhere else. The pattern runs across the corridor, so
                -- for a vertical corridor it depends on x only.
                Assert.equal('concrete', L.corridor_tile(0, 5, true, false), 'corridor edge is curbed')
                Assert.equal('concrete', L.corridor_tile(1, 5, true, false), 'curb is 2 tiles wide')
                Assert.equal('stone-path', L.corridor_tile(2, 5, true, false), 'rail bed is gravel')
                Assert.equal('concrete', L.corridor_tile(15, 5, true, false), 'median between the tracks')
                Assert.equal('concrete', L.corridor_tile(16, 5, true, false), 'median is 2 tiles wide')
                Assert.equal('concrete', L.corridor_tile(31, 5, true, false), 'far edge is curbed')
                -- A horizontal corridor is the same pattern rotated: it depends on y only.
                Assert.equal('concrete', L.corridor_tile(5, 0, false, true), 'horizontal corridor edge is curbed')
                Assert.equal('stone-path', L.corridor_tile(0, 5, false, true), 'horizontal corridor ignores x')

                -- The tracks themselves must sit on rail bed, not on a curb, on both axes.
                for _, offset in ipairs({L.RAIL_A, L.RAIL_B}) do
                    Assert.equal('stone-path', L.corridor_tile(offset, 5, true, false), 'track at ' .. offset .. ' sits on gravel')
                    Assert.equal('stone-path', L.corridor_tile(5, offset, false, true), 'horizontal track at ' .. offset .. ' sits on gravel')
                end

                -- Corner square is the inverse: a concrete frame around the gravel ring field.
                Assert.equal('concrete', L.corridor_tile(0, 0, true, true), 'corner frame is concrete')
                Assert.equal('stone-path', L.corridor_tile(16, 16, true, true), 'corner centre is gravel')
                Assert.equal('concrete', L.corridor_tile(31, 31, true, true), 'far corner is framed too')
            end
        )

        Declare.test(
            'trunks run on the rail grid and stop short of a corner',
            function()
                -- A chunk with no corner next to it runs the full width, starting on an odd tile so
                -- the rails land on Factorio's 2-tile grid.
                local from, to = L.trunk_range(64, 96, false, false)
                Assert.is_true(from == 65 and to == 95, 'full-width trunk spans the chunk, got ' .. from .. '..' .. to)
                Assert.equal(1, from % 2, 'trunk starts on the rail grid')

                -- Next to a corner the ring overhangs, so the trunk stops short of RING_REACH and
                -- picks up again on the next grid slot.
                local near_from, near_to = L.trunk_range(64, 96, true, true)
                Assert.equal(64 - 16 + L.RING_REACH + 1, near_from, 'trunk starts after the ring')
                Assert.equal(96 + 16 - L.RING_REACH - 1, near_to, 'trunk ends before the next ring')
                Assert.is_true(near_from > from and near_to < to, 'a neighbouring corner always shortens the trunk')
                Assert.equal(0, (near_from - from) % 2, 'the shortened trunk stays on the same grid parity')
            end
        )

        Declare.test(
            'the roundabout fits its corner and meets the trunks',
            function()
                -- Each chunk stamps only the pieces that fall inside it, so a signal whose chunk
                -- holds no rail of its own would fail to place when that chunk generates first.
                local rails_by_chunk = {}
                local first_signal_index, last_rail_index
                for i, e in ipairs(L.ROUNDABOUT) do
                    local k = chunk_of(e.x) .. '/' .. chunk_of(e.y)
                    if L.SIGNAL_NAMES[e.name] then
                        first_signal_index = first_signal_index or i
                    else
                        last_rail_index = i
                        rails_by_chunk[k] = (rails_by_chunk[k] or 0) + 1
                    end
                end

                Assert.is_true(first_signal_index > last_rail_index, 'every rail is listed before the first signal')

                for _, e in ipairs(L.ROUNDABOUT) do
                    if L.SIGNAL_NAMES[e.name] then
                        local k = chunk_of(e.x) .. '/' .. chunk_of(e.y)
                        Assert.is_true(rails_by_chunk[k], 'the signal at ' .. e.x .. ', ' .. e.y .. ' has no rail in its chunk')
                    end
                end

                -- The ring must fit inside the reach the trunk rails are shortened to, or the trunk
                -- would overlap it.
                local max_reach = 0
                for _, e in ipairs(L.ROUNDABOUT) do
                    max_reach = math.max(max_reach, math.abs(e.x), math.abs(e.y))
                end
                Assert.is_true(max_reach <= L.RING_REACH, 'the ring fits within RING_REACH, max=' .. max_reach)

                -- Approach lanes must line up with the trunk offsets, or trains cannot cross the
                -- corner. Trunk offsets RAIL_A/RAIL_B are chunk-local; relative to the corner
                -- midpoint they are -3/+3.
                local approach = {}
                for _, e in ipairs(L.ROUNDABOUT) do
                    if math.abs(e.x) == L.RING_REACH - 2 or math.abs(e.y) == L.RING_REACH - 2 then
                        approach[e.x] = true
                        approach[e.y] = true
                    end
                end
                Assert.is_true(approach[L.RAIL_A - 16] and approach[L.RAIL_B - 16],
                    'ring approach lanes sit on the trunk offsets (' .. (L.RAIL_A - 16) .. '/' .. (L.RAIL_B - 16) .. ')')
            end
        )
    end
)
