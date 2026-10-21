-- Pure geometry and room-ore assignment for the City Blocks map. No Factorio API, no
-- upvalue state: every function here is a function of its arguments only, so it can be
-- unit tested from plain Lua (see city_blocks_layout.test.lua). The Factorio-side module
-- city_blocks.lua consumes this and owns everything that touches a surface.
--
-- The world is a lattice of rooms PITCH-1 chunks wide, each separated from its neighbours
-- by a one-chunk rail corridor. Chunk coordinates are offset by 2 so that room 0/0 is
-- centred on spawn.
local Public = {}

local floor = math.floor

Public.PITCH = 5 -- chunks per room+corridor cell
Public.ROOMS_RADIUS = 12 -- rooms span -R..R on both axes
-- Ore-free band inside each room along its edge with the corridor. Without it the ore starts
-- flush against the corridor and you have to hand-mine a bay before you can place a train stop
-- or an inserter, so nothing in a fresh room can be automated until it has been cleared by hand.
Public.ROOM_EDGE_MARGIN = 3
Public.RAIL_A = 13 -- track offsets within a corridor chunk: odd (chunk edges are multiples of
Public.RAIL_B = 19 -- 32, matching the rail grid) and at corridor-center -3/+3, exactly where
-- the corner roundabouts' approach lanes sit; the 4-tile gap still fits signals everywhere
-- The ring's lane-end curves reach 22 tiles out from a corner's midpoint; trunk rails
-- resume at 23 (the next slot on the 2-tile grid) and join the ring seamlessly.
Public.RING_REACH = 22

local PITCH = Public.PITCH
local ROOMS_RADIUS = Public.ROOMS_RADIUS
local ROOM_EDGE_MARGIN = Public.ROOM_EDGE_MARGIN
local RING_REACH = Public.RING_REACH

-- The corner roundabout, decoded from the user's blueprint: native 2.0 rail pieces
-- (curved-rail-a/b, half-diagonal-rail), 40x40 centered on the corner chunk's midpoint,
-- so it overhangs a few tiles into each adjacent corridor chunk. Approach lanes sit at
-- center -3/+3 -- exactly the trunk offsets -- and every lane ends with a curved-rail-a
-- at +-20, where the corridor trunk takes over. Rails are listed before signals: each
-- chunk stamps only the pieces inside itself, and every signal has a rail in its own
-- chunk, so signals always find a rail no matter which chunk generates first.
Public.ROUNDABOUT = {
    { name = 'curved-rail-a', x = -3, y = -20, direction = 10 },
    { name = 'curved-rail-a', x = 3, y = -20, direction = 8 },
    { name = 'curved-rail-a', x = -2, y = -13, direction = 12 },
    { name = 'curved-rail-a', x = 2, y = -13, direction = 6 },
    { name = 'curved-rail-a', x = -20, y = -3, direction = 4 },
    { name = 'curved-rail-a', x = 20, y = -3, direction = 14 },
    { name = 'curved-rail-a', x = -13, y = -2, direction = 2 },
    { name = 'curved-rail-a', x = 13, y = -2, direction = 0 },
    { name = 'curved-rail-a', x = -13, y = 2, direction = 8 },
    { name = 'curved-rail-a', x = 13, y = 2, direction = 10 },
    { name = 'curved-rail-a', x = -20, y = 3, direction = 6 },
    { name = 'curved-rail-a', x = 20, y = 3, direction = 12 },
    { name = 'curved-rail-a', x = -2, y = 13, direction = 14 },
    { name = 'curved-rail-a', x = 2, y = 13, direction = 4 },
    { name = 'curved-rail-a', x = -3, y = 20, direction = 0 },
    { name = 'curved-rail-a', x = 3, y = 20, direction = 2 },
    { name = 'curved-rail-b', x = -7, y = -11, direction = 12 },
    { name = 'curved-rail-b', x = -7, y = -11, direction = 10 },
    { name = 'curved-rail-b', x = 7, y = -11, direction = 6 },
    { name = 'curved-rail-b', x = 7, y = -11, direction = 8 },
    { name = 'curved-rail-b', x = -11, y = -7, direction = 4 },
    { name = 'curved-rail-b', x = -11, y = -7, direction = 2 },
    { name = 'curved-rail-b', x = 11, y = -7, direction = 0 },
    { name = 'curved-rail-b', x = 11, y = -7, direction = 14 },
    { name = 'curved-rail-b', x = -11, y = 7, direction = 8 },
    { name = 'curved-rail-b', x = -11, y = 7, direction = 6 },
    { name = 'curved-rail-b', x = 11, y = 7, direction = 10 },
    { name = 'curved-rail-b', x = 11, y = 7, direction = 12 },
    { name = 'curved-rail-b', x = -7, y = 11, direction = 14 },
    { name = 'curved-rail-b', x = -7, y = 11, direction = 0 },
    { name = 'curved-rail-b', x = 7, y = 11, direction = 4 },
    { name = 'curved-rail-b', x = 7, y = 11, direction = 2 },
    { name = 'half-diagonal-rail', x = -5, y = -15, direction = 2 },
    { name = 'half-diagonal-rail', x = 5, y = -15, direction = 0 },
    { name = 'half-diagonal-rail', x = -15, y = -5, direction = 4 },
    { name = 'half-diagonal-rail', x = 15, y = -5, direction = 6 },
    { name = 'half-diagonal-rail', x = -15, y = 5, direction = 6 },
    { name = 'half-diagonal-rail', x = 15, y = 5, direction = 4 },
    { name = 'half-diagonal-rail', x = -5, y = 15, direction = 0 },
    { name = 'half-diagonal-rail', x = 5, y = 15, direction = 2 },
    { name = 'rail-signal', x = 5.5, y = -16.5, direction = 7 },
    { name = 'rail-signal', x = -16.5, y = -5.5, direction = 3 },
    { name = 'rail-signal', x = 18.5, y = 4.5, direction = 11 },
    { name = 'rail-signal', x = -5.5, y = 16.5, direction = 15 },
    { name = 'rail-chain-signal', x = -6.5, y = -14.5, direction = 1 },
    { name = 'rail-chain-signal', x = 14.5, y = -6.5, direction = 5 },
    { name = 'rail-chain-signal', x = -14.5, y = 6.5, direction = 13 },
    { name = 'rail-chain-signal', x = 6.5, y = 14.5, direction = 9 },
}

Public.SIGNAL_NAMES = {
    ['rail-signal'] = true,
    ['rail-chain-signal'] = true,
}

-- === room lattice ==========================================================

function Public.key(i, j)
    return i .. '/' .. j
end

function Public.in_bounds(i, j)
    return i >= -ROOMS_RADIUS and i <= ROOMS_RADIUS and j >= -ROOMS_RADIUS and j <= ROOMS_RADIUS
end

-- chunk coord -> room index and local offset (corridor iff local offset == PITCH - 1)
function Public.room_of_chunk(c)
    return floor((c + 2) / PITCH), (c + 2) % PITCH
end

-- tile coord -> room indices on both axes
function Public.room_of_tile(x, y)
    local ri = Public.room_of_chunk(floor(x / 32))
    local rj = Public.room_of_chunk(floor(y / 32))
    return ri, rj
end

function Public.neighbours_of(i, j)
    local list = {}
    for _, d in pairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local ni, nj = i + d[1], j + d[2]
        if Public.in_bounds(ni, nj) then
            list[#list + 1] = { ni, nj }
        end
    end
    return list
end

-- True when the chunk is part of the corridor lattice, plus which axes it runs on.
function Public.corridor_axes_of_chunk(cx, cy)
    local _, lx = Public.room_of_chunk(cx)
    local _, ly = Public.room_of_chunk(cy)
    return lx == PITCH - 1, ly == PITCH - 1
end

-- True for a tile lying anywhere on the corridor lattice.
function Public.on_corridor_tile(x, y)
    local x_wall, y_wall = Public.corridor_axes_of_chunk(floor(x / 32), floor(y / 32))
    return x_wall or y_wall
end

-- True for tiles in the ore-free band along a room's edge with the corridor. Rooms are
-- PITCH-1 chunks wide, so a room's outermost chunks are the ones at local offset 0 and
-- PITCH-2; only those can hold the band, and only on the side facing the corridor.
function Public.in_room_margin(x, y)
    local tx, ty = floor(x), floor(y)
    local _, lx = Public.room_of_chunk(floor(tx / 32))
    local _, ly = Public.room_of_chunk(floor(ty / 32))
    local ox, oy = tx % 32, ty % 32

    if lx == 0 and ox < ROOM_EDGE_MARGIN then
        return true
    end
    if lx == PITCH - 2 and ox >= 32 - ROOM_EDGE_MARGIN then
        return true
    end
    if ly == 0 and oy < ROOM_EDGE_MARGIN then
        return true
    end
    if ly == PITCH - 2 and oy >= 32 - ROOM_EDGE_MARGIN then
        return true
    end
    return false
end

-- === room ore assignment ===================================================

-- BFS from spawn: the first rooms reached cover every ore once (shuffled), the rest are
-- random (optionally weighted by ore_weights). random/shuffle are injected so the caller
-- decides which RNG this runs on, and so tests can make it deterministic.
-- Returns a fresh ['i/j'] = 1..num_ores table.
function Public.assign_ores(num_ores, ore_weights, random, shuffle)
    local weight_total = 0
    if ore_weights then
        for _, weight in ipairs(ore_weights) do
            weight_total = weight_total + weight
        end
    end

    local function random_ore()
        if not ore_weights then
            return random(num_ores)
        end
        local r = random(weight_total)
        for ore, weight in ipairs(ore_weights) do
            r = r - weight
            if r <= 0 then
                return ore
            end
        end
        return 1
    end

    local room_ore = {}
    local first = {}
    for i = 1, num_ores do
        first[i] = i
    end
    shuffle(first)

    local order = 1
    local spawn_key = Public.key(0, 0)
    local seen = { [spawn_key] = true }
    local queue = { { 0, 0 } }
    local head = 1
    while queue[head] do
        local room = queue[head]
        head = head + 1
        local k = Public.key(room[1], room[2])
        if order <= num_ores and k ~= spawn_key then
            room_ore[k] = first[order]
            order = order + 1
        elseif not room_ore[k] then
            room_ore[k] = random_ore()
        end
        for _, n in pairs(Public.neighbours_of(room[1], room[2])) do
            local nk = Public.key(n[1], n[2])
            if not seen[nk] then
                seen[nk] = true
                queue[#queue + 1] = n
            end
        end
    end

    return room_ore
end

-- === corridor surfacing ====================================================

-- Rail corridor paving: gravel (stone path) rail beds with concrete curb lanes along both
-- edges and a concrete median between the two tracks; corner crossings are the inverse --
-- a concrete junction square with gravel cross-bands under the rails. xo/yo are chunk-local
-- tile offsets in 0..31.
function Public.corridor_tile(xo, yo, x_wall, y_wall)
    if x_wall and y_wall then
        -- roundabout square: concrete frame around a gravel field under the ring
        if xo < 3 or xo > 28 or yo < 3 or yo > 28 then
            return 'concrete'
        end
        return 'stone-path'
    end

    local o = y_wall and yo or xo
    if o < 2 or o >= 30 or o == 15 or o == 16 then
        return 'concrete' -- curb lanes at the edges, median between the tracks
    end
    return 'stone-path'
end

-- Trunk tracks run at RAIL_A/RAIL_B relative to each corridor chunk's own edge, so every
-- chunk of a corridor lays the same lines and they join seamlessly across chunk borders --
-- each chunk only ever writes inside itself (generation order can never matter). Odd
-- offsets match Factorio's 2-tile rail grid.
--
-- Given a chunk's low and high edge on the axis the trunk runs along, returns the first and
-- last rail slot. near_low/near_high mean an adjacent corner's ring overhangs this chunk, so
-- the trunk stops short and lets the ring take over.
function Public.trunk_range(low, high, near_low, near_high)
    local from = low + 1
    local to = high - 1
    if near_low then
        from = low - 16 + RING_REACH + 1
    end
    if near_high then
        to = high + 16 - RING_REACH - 1
    end
    return from, to
end

return Public
