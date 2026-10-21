-- Standalone unit tests for the pure City Blocks lattice geometry.
-- Run from the repo root:  lua map_gen/maps/danger_ores/modules/city_blocks_layout.test.lua
package.path = './?.lua;' .. package.path

local L = require 'map_gen.maps.danger_ores.modules.city_blocks_layout'

local failures = 0
local function check(cond, msg)
    if cond then
        print('ok:   ' .. msg)
    else
        failures = failures + 1
        print('FAIL: ' .. msg)
    end
end

local PITCH = L.PITCH
local MARGIN = L.ROOM_EDGE_MARGIN

-- === room lattice ==========================================================

-- Spawn sits in room 0/0, and the offset of 2 puts it in the middle of that room rather
-- than against a corridor.
local r0, o0 = L.room_of_chunk(0)
check(r0 == 0 and o0 == 2, 'chunk 0 is room 0 at local offset 2, got ' .. r0 .. '/' .. o0)

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
check(corridor_chunks == 1, 'one corridor chunk per cell, got ' .. corridor_chunks)
check(room_chunks == PITCH - 1, 'room is PITCH-1 chunks wide, got ' .. room_chunks)

-- Room indices advance by one per cell, in both directions, without a gap at the origin.
check(select(1, L.room_of_chunk(3)) == 1, 'chunk 3 is the first chunk of room 1')
check(select(1, L.room_of_chunk(-3)) == -1, 'chunk -3 belongs to room -1')
check(select(2, L.room_of_chunk(-3)) == PITCH - 1, 'chunk -3 is a corridor chunk')

-- Corridor detection: a chunk is corridor if either axis is on the lattice, and a corner
-- is corridor on both.
local x_wall, y_wall = L.corridor_axes_of_chunk(2, 0)
check(x_wall and not y_wall, 'chunk 2/0 is a vertical corridor')
x_wall, y_wall = L.corridor_axes_of_chunk(2, 2)
check(x_wall and y_wall, 'chunk 2/2 is a corner')
x_wall, y_wall = L.corridor_axes_of_chunk(0, 0)
check(not x_wall and not y_wall, 'chunk 0/0 is room interior')

check(L.on_corridor_tile(2 * 32, 0), 'first tile of a corridor chunk is on the corridor')
check(L.on_corridor_tile(2 * 32 + 31, 31), 'last tile of a corridor chunk is on the corridor')
check(not L.on_corridor_tile(2 * 32 - 1, 0), 'the tile before a corridor chunk is not')

-- in_bounds gates the generated world; outside it chunks are voided.
check(L.in_bounds(0, 0), 'spawn room is in bounds')
check(L.in_bounds(L.ROOMS_RADIUS, -L.ROOMS_RADIUS), 'corner room is in bounds')
check(not L.in_bounds(L.ROOMS_RADIUS + 1, 0), 'one room past the radius is out of bounds')
check(#L.neighbours_of(0, 0) == 4, 'an interior room has 4 neighbours')
check(#L.neighbours_of(L.ROOMS_RADIUS, L.ROOMS_RADIUS) == 2, 'a corner room has 2 neighbours')

-- === room edge margin ======================================================
-- Regression cover for the fix that keeps ore off the room edge: without it a fresh room
-- cannot be automated until a bay has been hand-mined.

-- Chunk -2 is the room's west-most chunk (local offset 0), so its low-x tiles face a corridor.
local west_chunk_x = -2 * 32
for o = 0, MARGIN - 1 do
    check(L.in_room_margin(west_chunk_x + o, 0), 'west edge tile at offset ' .. o .. ' is margin')
end
check(not L.in_room_margin(west_chunk_x + MARGIN, 0), 'margin is exactly ' .. MARGIN .. ' tiles deep')
-- ... and its high-x tiles do not: that side faces the room's own interior.
check(not L.in_room_margin(west_chunk_x + 31, 0), 'inward side of the west chunk is not margin')

-- Chunk 1 is the room's east-most chunk (local offset PITCH-2), mirrored.
local east_chunk_x = 1 * 32
check(L.in_room_margin(east_chunk_x + 31, 0), 'east edge tile is margin')
check(not L.in_room_margin(east_chunk_x + 32 - MARGIN - 1, 0), 'margin stops ' .. MARGIN .. ' tiles in')
check(not L.in_room_margin(east_chunk_x, 0), 'inward side of the east chunk is not margin')

-- The two middle chunks of a room touch no corridor, so they are never margin.
local middle_is_margin = false
for _, chunk in ipairs({ -1, 0 }) do
    for o = 0, 31 do
        if L.in_room_margin(chunk * 32 + o, 0) or L.in_room_margin(0, chunk * 32 + o) then
            middle_is_margin = true
        end
    end
end
check(not middle_is_margin, 'interior chunks of a room are never margin')

-- The band runs on both axes: a room corner tile is margin from either direction.
check(L.in_room_margin(west_chunk_x, -2 * 32), 'room corner tile is margin')
check(L.in_room_margin(0, west_chunk_x), 'north edge produces a margin band too')

-- A whole room's worth of tiles: the band is a frame, so the count is the room area minus
-- the inset area.
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
check(margin_count == expected, 'margin is a ' .. MARGIN .. '-tile frame, got ' .. margin_count .. ' expected ' .. expected)

-- Corridor tiles are not part of any room, so they are never margin.
check(not L.in_room_margin(2 * 32 + 16, 0), 'corridor tiles are not margin')

-- === ore assignment ========================================================

local function fixed_shuffle(t) return t end -- identity: keeps assertions readable
-- A small LCG rather than math.random, so a run is reproducible across Lua versions. The
-- multiplier is kept small on purpose: Factorio runs Lua 5.2, where every number is a
-- double, and a wider one would lose the low bits that carry the randomness.
local function seeded_random(seed)
    local state = seed
    return function(n)
        state = (state * 75 + 74) % 65537
        return state % n + 1
    end
end

local rooms_across = 2 * L.ROOMS_RADIUS + 1
local room_ore = L.assign_ores(4, nil, seeded_random(1), fixed_shuffle)

local count, out_of_range = 0, 0
for _, ore in pairs(room_ore) do
    count = count + 1
    if ore < 1 or ore > 4 then
        out_of_range = out_of_range + 1
    end
end
check(count == rooms_across * rooms_across, 'every in-bounds room gets an ore, got ' .. count)
check(out_of_range == 0, 'every assignment is a valid ore index')

-- The BFS seeding guarantees all four ores sit in the ring of rooms closest to spawn, so a
-- new base can reach every ore without a long trek.
local near_spawn = {}
for _, room in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
    near_spawn[room_ore[L.key(room[1], room[2])]] = true
end
local distinct = 0
for _ in pairs(near_spawn) do distinct = distinct + 1 end
check(distinct == 4, 'all 4 ores appear in the rooms adjacent to spawn, got ' .. distinct)

-- Same RNG in, same map out: assignment must be reproducible from the seed.
local again = L.assign_ores(4, nil, seeded_random(1), fixed_shuffle)
local mismatches = 0
for k, ore in pairs(room_ore) do
    if again[k] ~= ore then
        mismatches = mismatches + 1
    end
end
check(mismatches == 0, 'assignment is deterministic for a given RNG, mismatches=' .. mismatches)

-- Weights bias the rooms that are not part of the guaranteed seeding.
local weighted = L.assign_ores(2, { 1, 0 }, seeded_random(7), fixed_shuffle)
local weighted_second = 0
for k, ore in pairs(weighted) do
    if ore == 2 and k ~= L.key(1, 0) and k ~= L.key(-1, 0) and k ~= L.key(0, 1) and k ~= L.key(0, -1) then
        weighted_second = weighted_second + 1
    end
end
check(weighted_second == 0, 'a zero-weight ore is only placed by the guaranteed seeding, got ' .. weighted_second)

-- === corridor surfacing ====================================================

-- Straight corridor: concrete curbs on both edges, concrete median between the tracks,
-- gravel rail bed everywhere else. The pattern runs across the corridor, so for a vertical
-- corridor it depends on x only.
check(L.corridor_tile(0, 5, true, false) == 'concrete', 'corridor edge is curbed')
check(L.corridor_tile(1, 5, true, false) == 'concrete', 'curb is 2 tiles wide')
check(L.corridor_tile(2, 5, true, false) == 'stone-path', 'rail bed is gravel')
check(L.corridor_tile(15, 5, true, false) == 'concrete', 'median between the tracks')
check(L.corridor_tile(16, 5, true, false) == 'concrete', 'median is 2 tiles wide')
check(L.corridor_tile(31, 5, true, false) == 'concrete', 'far edge is curbed')
-- A horizontal corridor is the same pattern rotated: it depends on y only.
check(L.corridor_tile(5, 0, false, true) == 'concrete', 'horizontal corridor edge is curbed')
check(L.corridor_tile(0, 5, false, true) == 'stone-path', 'horizontal corridor ignores x')

-- The tracks themselves must sit on rail bed, not on a curb, on both axes.
for _, offset in ipairs({ L.RAIL_A, L.RAIL_B }) do
    check(L.corridor_tile(offset, 5, true, false) == 'stone-path', 'track at ' .. offset .. ' sits on gravel')
    check(L.corridor_tile(5, offset, false, true) == 'stone-path', 'horizontal track at ' .. offset .. ' sits on gravel')
end

-- Corner square is the inverse: a concrete frame around the gravel ring field.
check(L.corridor_tile(0, 0, true, true) == 'concrete', 'corner frame is concrete')
check(L.corridor_tile(16, 16, true, true) == 'stone-path', 'corner centre is gravel')
check(L.corridor_tile(31, 31, true, true) == 'concrete', 'far corner is framed too')

-- === trunk ranges ==========================================================

-- A chunk with no corner next to it runs the full width, starting on an odd tile so the
-- rails land on Factorio's 2-tile grid.
local from, to = L.trunk_range(64, 96, false, false)
check(from == 65 and to == 95, 'full-width trunk spans the chunk, got ' .. from .. '..' .. to)
check(from % 2 == 1, 'trunk starts on the rail grid')

-- Next to a corner the ring overhangs, so the trunk stops short of RING_REACH and picks up
-- again on the next grid slot.
local near_from, near_to = L.trunk_range(64, 96, true, true)
check(near_from == 64 - 16 + L.RING_REACH + 1, 'trunk starts after the ring, got ' .. near_from)
check(near_to == 96 + 16 - L.RING_REACH - 1, 'trunk ends before the next ring, got ' .. near_to)
check(near_from > from and near_to < to, 'a neighbouring corner always shortens the trunk')
check((near_from - from) % 2 == 0, 'the shortened trunk stays on the same grid parity')

-- === roundabout data =======================================================

-- Each chunk stamps only the pieces that fall inside it, so a signal whose chunk holds no
-- rail of its own would fail to place when that chunk generates first.
local function chunk_of(v)
    return math.floor((16 + v) / 32)
end

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

check(first_signal_index > last_rail_index, 'every rail is listed before the first signal')

local orphan_signals = 0
for _, e in ipairs(L.ROUNDABOUT) do
    if L.SIGNAL_NAMES[e.name] then
        local k = chunk_of(e.x) .. '/' .. chunk_of(e.y)
        if not rails_by_chunk[k] then
            orphan_signals = orphan_signals + 1
        end
    end
end
check(orphan_signals == 0, 'every signal has a rail in its own chunk, orphans=' .. orphan_signals)

-- The ring must fit inside the reach the trunk rails are shortened to, or the trunk would
-- overlap it.
local max_reach = 0
for _, e in ipairs(L.ROUNDABOUT) do
    max_reach = math.max(max_reach, math.abs(e.x), math.abs(e.y))
end
check(max_reach <= L.RING_REACH, 'the ring fits within RING_REACH, max=' .. max_reach)

-- Approach lanes must line up with the trunk offsets, or trains cannot cross the corner.
-- Trunk offsets RAIL_A/RAIL_B are chunk-local; relative to the corner midpoint they are -3/+3.
local approach = {}
for _, e in ipairs(L.ROUNDABOUT) do
    if math.abs(e.x) == L.RING_REACH - 2 or math.abs(e.y) == L.RING_REACH - 2 then
        approach[e.x] = true
        approach[e.y] = true
    end
end
check(approach[L.RAIL_A - 16] and approach[L.RAIL_B - 16],
    'ring approach lanes sit on the trunk offsets (' .. (L.RAIL_A - 16) .. '/' .. (L.RAIL_B - 16) .. ')')

if failures == 0 then
    print('\nALL PASSED')
else
    print('\n' .. failures .. ' FAILURE(S)')
    os.exit(1)
end
