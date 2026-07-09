-- City Blocks: isolated 4x4-chunk one-ore rooms separated by a paved, rail-only corridor
-- lattice carrying a ready-made double-track network -- ordinary, minable rails: continuous
-- lines ring every room and meet at a signalled RAIL ROUNDABOUT on every corner (geometry
-- decoded from the user's blueprint; native Factorio 2.0 rail pieces). Players
-- may branch their own rails, signals and poles anywhere on the lattice, but nothing else
-- can be built there, and belts cannot span the 32-tile corridors: trains are the only
-- inter-room logistics. Room ores are assigned once in on_init and stored in Global.
local b = require 'map_gen.shared.builders'
local Event = require 'utils.event'
local Generate = require 'map_gen.shared.generate'
local Global = require 'utils.global'
local RS = require 'map_gen.shared.redmew_surface'
local RestrictEntities = require 'map_gen.shared.entity_placement_restriction'
local Token = require 'utils.token'
local table = require 'utils.table'

local floor = math.floor
local random = math.random
local shuffle = table.shuffle_table

local PITCH = 5 -- chunks per room+wall cell
local ROOMS_RADIUS = 12 -- rooms span -R..R on both axes
local RAIL_A = 13 -- track offsets within a corridor chunk: odd (chunk edges are multiples of
local RAIL_B = 19 -- 32, matching the rail grid) and at corridor-center -3/+3, exactly where
-- the corner roundabouts' approach lanes sit; the 4-tile gap still fits signals everywhere

-- The corner roundabout, decoded from the user's blueprint: native 2.0 rail pieces
-- (curved-rail-a/b, half-diagonal-rail), 40x40 centered on the corner chunk's midpoint,
-- so it overhangs a few tiles into each adjacent corridor chunk. Approach lanes sit at
-- center -3/+3 -- exactly the trunk offsets -- and every lane ends with a curved-rail-a
-- at +-20, where the corridor trunk takes over. Rails are listed before signals: each
-- chunk stamps only the pieces inside itself, and every signal has a rail in its own
-- chunk, so signals always find a rail no matter which chunk generates first.
local ROUNDABOUT = {
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

local Public = {}

local data = {
    room_ore = {}, -- ['i/j'] = 1..num_ores
}
Global.register(data, function(tbl)
    data = tbl
end)

local function key(i, j)
    return i .. '/' .. j
end

local function in_bounds(i, j)
    return i >= -ROOMS_RADIUS and i <= ROOMS_RADIUS and j >= -ROOMS_RADIUS and j <= ROOMS_RADIUS
end

-- chunk coord -> room index and local offset (wall iff local offset == PITCH - 1)
local function room_of_chunk(c)
    return floor((c + 2) / PITCH), (c + 2) % PITCH
end

local function neighbours_of(i, j)
    local list = {}
    for _, d in pairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local ni, nj = i + d[1], j + d[2]
        if in_bounds(ni, nj) then
            list[#list + 1] = { ni, nj }
        end
    end
    return list
end

-- Room ore assignment is derived from the ore config passed to register(): any number of
-- ores works, and optional weights (config.room_ore_weights) can bias the distribution.
local num_ores = 1
local ore_weights = nil
local ore_weight_total = 0

local function random_ore()
    if not ore_weights then
        return random(num_ores)
    end
    local r = random(ore_weight_total)
    for ore, weight in ipairs(ore_weights) do
        r = r - weight
        if r <= 0 then
            return ore
        end
    end
    return 1
end

local function assign_ores()
    -- BFS from spawn: the first rooms reached cover every ore once (shuffled)
    local first = {}
    for i = 1, num_ores do
        first[i] = i
    end
    shuffle(first)
    local order = 1
    local spawn_key = key(0, 0)
    local seen = { [spawn_key] = true }
    local queue = { { 0, 0 } }
    local head = 1
    while queue[head] do
        local room = queue[head]
        head = head + 1
        local k = key(room[1], room[2])
        if order <= num_ores and k ~= spawn_key then
            data.room_ore[k] = first[order]
            order = order + 1
        elseif not data.room_ore[k] then
            data.room_ore[k] = random_ore()
        end
        for _, n in pairs(neighbours_of(room[1], room[2])) do
            local nk = key(n[1], n[2])
            if not seen[nk] then
                seen[nk] = true
                queue[#queue + 1] = n
            end
        end
    end
end

-- === chunk rendering =======================================================

local function void_area(surface, area)
    local tiles = {}
    for x = area.left_top.x, area.right_bottom.x - 1 do
        for y = area.left_top.y, area.right_bottom.y - 1 do
            tiles[#tiles + 1] = { name = 'out-of-map', position = { x, y } }
        end
    end
    surface.set_tiles(tiles, true)
end

-- Trunk rails are ordinary player rails: mine them, reroute them, do what you want --
-- the pre-laid network is a head start, not a constraint.
local function lay_rail(surface, x, y, direction)
    surface.create_entity {
        name = 'straight-rail',
        position = { x, y },
        direction = direction,
        force = 'player',
    }
end

-- Trunk tracks run at RAIL_A/RAIL_B relative to each corridor chunk's own edge, so every
-- chunk of a corridor lays the same lines and they join seamlessly across chunk borders --
-- each chunk only ever writes inside itself (generation order can never matter). Odd
-- offsets match Factorio's 2-tile rail grid; the 2-tile gap between tracks and the wide
-- outer margins leave room for signals on BOTH sides of both tracks.

-- Stamp the roundabout pieces that fall inside this chunk (chunk-local writes only);
-- center_x/center_y is the owning corner chunk's midpoint, which may lie outside area.
local function stamp_roundabout(surface, center_x, center_y, area)
    local left, top = area.left_top.x, area.left_top.y
    local right, bottom = area.right_bottom.x, area.right_bottom.y
    for _, e in pairs(ROUNDABOUT) do
        local x = center_x + e.x
        local y = center_y + e.y
        if x >= left and x < right and y >= top and y < bottom then
            surface.create_entity {
                name = e.name,
                position = { x, y },
                direction = e.direction,
                force = 'player',
            }
        end
    end
end

-- The ring's lane-end curves reach 22 tiles out from a corner's midpoint; trunk rails
-- resume at 23 (the next slot on the 2-tile grid) and join the ring seamlessly.
local RING_REACH = 22

-- east-west trunk through a horizontal corridor chunk; near_west/near_east: an adjacent
-- in-bounds corner whose ring overhangs this chunk
local function lay_h_rails(surface, area, near_west, near_east)
    local top = area.left_top.y
    local from = area.left_top.x + 1
    local to = area.right_bottom.x - 1
    if near_west then
        from = area.left_top.x - 16 + RING_REACH + 1
    end
    if near_east then
        to = area.right_bottom.x + 16 - RING_REACH - 1
    end
    for x = from, to, 2 do
        lay_rail(surface, x, top + RAIL_A, defines.direction.east)
        lay_rail(surface, x, top + RAIL_B, defines.direction.east)
    end
end

-- north-south trunk through a vertical corridor chunk
local function lay_v_rails(surface, area, near_north, near_south)
    local left = area.left_top.x
    local from = area.left_top.y + 1
    local to = area.right_bottom.y - 1
    if near_north then
        from = area.left_top.y - 16 + RING_REACH + 1
    end
    if near_south then
        to = area.right_bottom.y + 16 - RING_REACH - 1
    end
    for y = from, to, 2 do
        lay_rail(surface, left + RAIL_A, y, defines.direction.north)
        lay_rail(surface, left + RAIL_B, y, defines.direction.north)
    end
end

-- Rail corridor paving: gravel (stone path) rail beds with concrete curb lanes along both
-- edges and a concrete median between the two tracks; corner crossings are the inverse --
-- a concrete junction square with gravel cross-bands under the rails. Setting tiles does
-- not remove generated entities, so ores/trees/rocks are destroyed explicitly.
local function pave_corridor(surface, area, x_wall, y_wall)
    local left, top = area.left_top.x, area.left_top.y
    local tiles = {}
    for x = left, area.right_bottom.x - 1 do
        local xo = x - left
        for y = top, area.right_bottom.y - 1 do
            local yo = y - top
            local name
            if x_wall and y_wall then
                -- roundabout square: concrete frame around a gravel field under the ring
                if xo < 3 or xo > 28 or yo < 3 or yo > 28 then
                    name = 'concrete'
                else
                    name = 'stone-path'
                end
            else
                local o = y_wall and yo or xo
                if o < 2 or o >= 30 or o == 15 or o == 16 then
                    name = 'concrete' -- curb lanes at the edges, median between the tracks
                else
                    name = 'stone-path'
                end
            end
            tiles[#tiles + 1] = { name = name, position = { x, y } }
        end
    end
    surface.set_tiles(tiles, true)
    for _, entity in pairs(surface.find_entities_filtered { area = area, type = { 'resource', 'tree', 'simple-entity' } }) do
        entity.destroy()
    end
end

local function on_chunk(event)
    local surface = event.surface
    if surface ~= RS.get_surface() then
        return
    end
    local area = event.area
    local cx = floor(area.left_top.x / 32)
    local cy = floor(area.left_top.y / 32)
    local ri, lx = room_of_chunk(cx)
    local rj, ly = room_of_chunk(cy)
    local x_wall = lx == PITCH - 1
    local y_wall = ly == PITCH - 1

    if not in_bounds(ri, rj) then
        void_area(surface, area)
        return
    end
    if not (x_wall or y_wall) then
        return -- room interior: pure ore field, clear your own ground the danger-ores way
    end

    -- the whole wall lattice is a paved, rail-only corridor players can branch into
    pave_corridor(surface, area, x_wall, y_wall)

    if x_wall and y_wall then
        -- corner: a signalled roundabout connects all four corridor approaches
        stamp_roundabout(surface, area.left_top.x + 16, area.left_top.y + 16, area)
        return
    end

    -- continuous trunk lines along every straight corridor chunk; next to a corner the
    -- ring overhangs into this chunk, so stamp its share and shorten the trunk to meet it
    if y_wall then
        local near_west = lx == 0 and in_bounds(ri - 1, rj)
        local near_east = lx == PITCH - 2
        if near_west then
            stamp_roundabout(surface, area.left_top.x - 16, area.left_top.y + 16, area)
        end
        if near_east then
            stamp_roundabout(surface, area.right_bottom.x + 16, area.left_top.y + 16, area)
        end
        lay_h_rails(surface, area, near_west, near_east)
    else
        local near_north = ly == 0 and in_bounds(ri, rj - 1)
        local near_south = ly == PITCH - 2
        if near_south then
            stamp_roundabout(surface, area.left_top.x + 16, area.right_bottom.y + 16, area)
        end
        if near_north then
            stamp_roundabout(surface, area.left_top.x + 16, area.left_top.y - 16, area)
        end
        lay_v_rails(surface, area, near_north, near_south)
    end
end

-- === strip placement rule ==================================================

local ALLOWED_ON_STRIP = {
    ['straight-rail'] = true,
    ['curved-rail-a'] = true,
    ['curved-rail-b'] = true,
    ['half-diagonal-rail'] = true,
    ['rail-ramp'] = true,
    ['rail-support'] = true,
    ['rail-signal'] = true,
    ['rail-chain-signal'] = true,
    ['train-stop'] = true,
    ['electric-pole'] = true,
    ['locomotive'] = true,
    ['cargo-wagon'] = true,
    ['fluid-wagon'] = true,
    ['artillery-wagon'] = true,
}

local function on_wall_chunk(x, y)
    local _, lx = room_of_chunk(floor(x / 32))
    local _, ly = room_of_chunk(floor(y / 32))
    return lx == PITCH - 1 or ly == PITCH - 1
end

-- Corridor rule via the shared entity_placement_restriction module (handles ghosts,
-- refunds and destruction): keep everything off the corridors, and on them only the
-- allowed types (whitelisted by LuaEntity type, not name, for mod compatibility).
local keep_alive_callback = Token.register(function(entity)
    local e_type = entity.type
    if e_type == 'entity-ghost' then
        e_type = entity.ghost_type
    end
    if ALLOWED_ON_STRIP[e_type] then
        return true
    end
    local pos = entity.position
    return not on_wall_chunk(pos.x, pos.y)
end)

local function on_restricted_destroyed(event)
    local player = event.player
    if player and player.valid then
        player.print('Only rail infrastructure (rails, signals, stations, power poles) and trains can be built on the rail corridors!')
    end
end

-- === public ================================================================

function Public.register(config)
    num_ores = #config.main_ores
    ore_weights = config.room_ore_weights
    if ore_weights then
        ore_weight_total = 0
        for _, weight in ipairs(ore_weights) do
            ore_weight_total = ore_weight_total + weight
        end
    end

    RestrictEntities.set_keep_alive_callback(keep_alive_callback)
    RestrictEntities.enable_refund()

    Event.on_init(assign_ores)
    Event.add(Generate.events.on_chunk_generated, on_chunk)
    Event.add(RestrictEntities.events.on_restricted_entity_destroyed, on_restricted_destroyed)
end

-- danger-ores main_ores_builder: per tile, pick the room's dominant-ore shape
function Public.main_ores_builder(config)
    local main_ores = config.main_ores

    return function(tile_builder, ore_builder, spawn_shape, water_shape, _)
        local shapes = {}
        for _, ore_data in ipairs(main_ores) do
            local land = tile_builder(ore_data.tiles)
            local ratios = ore_data.ratios
            local weighted = b.prepare_weighted_array(ratios)
            local ore = ore_builder(ore_data.name, ore_data.start, ratios, weighted)
            shapes[#shapes + 1] = b.apply_entity(land, ore)
        end

        local function rooms(x, y, world)
            local ri = floor((floor(x / 32) + 2) / PITCH)
            local rj = floor((floor(y / 32) + 2) / PITCH)
            if ri == 0 and rj == 0 then
                -- spawn room splits the main ores across its quadrants
                local quadrant = ((x >= 0) and 1 or 0) + ((y >= 0) and 2 or 0)
                return shapes[quadrant % #shapes + 1](x, y, world)
            end
            local ore_index = data.room_ore[ri .. '/' .. rj] or 1
            return shapes[ore_index](x, y, world)
        end

        return b.any { spawn_shape, water_shape, rooms }
    end
end

return Public
