-- City Blocks: isolated 4x4-chunk one-ore rooms separated by a paved, rail-only corridor
-- lattice carrying a ready-made double-track network -- ordinary, minable rails: continuous
-- lines ring every room and meet at a signalled RAIL ROUNDABOUT on every corner (geometry
-- decoded from the user's blueprint; legacy rail pieces, fully functional in 2.0). Players
-- may branch their own rails, signals and poles anywhere on the lattice, but nothing else
-- can be built there, and belts cannot span the 32-tile corridors: trains are the only
-- inter-room logistics. Room ores are assigned once in on_init and stored in Global.
local b = require 'map_gen.shared.builders'
local Event = require 'utils.event'
local Generate = require 'map_gen.shared.generate'
local Global = require 'utils.global'
local RS = require 'map_gen.shared.redmew_surface'
local table = require 'utils.table'

local floor = math.floor
local random = math.random
local shuffle = table.shuffle_table

local PITCH = 5 -- chunks per room+wall cell
local ROOMS_RADIUS = 12 -- rooms span -R..R on both axes
local RAIL_A = 13 -- track offsets within a corridor chunk: odd (chunk edges are multiples of
local RAIL_B = 19 -- 32, matching the rail grid) and at corridor-center -3/+3, exactly where
-- the corner roundabouts' approach lanes sit; the 4-tile gap still fits signals everywhere

-- The corner roundabout, decoded from the user's blueprint (31x31, centered on the corner
-- chunk's midpoint). Legacy rail pieces as in the blueprint -- functional in 2.0, connect
-- to modern rails, and RedMew's allowed-entities list already includes them.
local ROUNDABOUT = {
    { name = 'legacy-curved-rail', x = -4, y = -12, direction = 10 },
    { name = 'legacy-curved-rail', x = 4, y = -12, direction = 8 },
    { name = 'legacy-curved-rail', x = -4, y = -10, direction = 12 },
    { name = 'legacy-curved-rail', x = 4, y = -10, direction = 6 },
    { name = 'legacy-curved-rail', x = -12, y = -4, direction = 4 },
    { name = 'legacy-curved-rail', x = -10, y = -4, direction = 2 },
    { name = 'legacy-curved-rail', x = 10, y = -4, direction = 0 },
    { name = 'legacy-curved-rail', x = 12, y = -4, direction = 14 },
    { name = 'legacy-curved-rail', x = -12, y = 4, direction = 6 },
    { name = 'legacy-curved-rail', x = -10, y = 4, direction = 8 },
    { name = 'legacy-curved-rail', x = 10, y = 4, direction = 10 },
    { name = 'legacy-curved-rail', x = 12, y = 4, direction = 12 },
    { name = 'legacy-curved-rail', x = -4, y = 10, direction = 14 },
    { name = 'legacy-curved-rail', x = 4, y = 10, direction = 4 },
    { name = 'legacy-curved-rail', x = -4, y = 12, direction = 0 },
    { name = 'legacy-curved-rail', x = 4, y = 12, direction = 2 },
    { name = 'legacy-straight-rail', x = -7, y = -9, direction = 6 },
    { name = 'legacy-straight-rail', x = 7, y = -9, direction = 10 },
    { name = 'legacy-straight-rail', x = -9, y = -7, direction = 6 },
    { name = 'legacy-straight-rail', x = -7, y = -7, direction = 14 },
    { name = 'legacy-straight-rail', x = 7, y = -7, direction = 2 },
    { name = 'legacy-straight-rail', x = 9, y = -7, direction = 10 },
    { name = 'legacy-straight-rail', x = -9, y = 7, direction = 2 },
    { name = 'legacy-straight-rail', x = -7, y = 7, direction = 10 },
    { name = 'legacy-straight-rail', x = 7, y = 7, direction = 6 },
    { name = 'legacy-straight-rail', x = 9, y = 7, direction = 14 },
    { name = 'legacy-straight-rail', x = -7, y = 9, direction = 2 },
    { name = 'legacy-straight-rail', x = 7, y = 9, direction = 14 },
    { name = 'rail-signal', x = -4.5, y = -15.5, direction = 0 },
    { name = 'rail-signal', x = 4.5, y = -15.5, direction = 8 },
    { name = 'rail-signal', x = -15.5, y = -4.5, direction = 4 },
    { name = 'rail-signal', x = 15.5, y = -4.5, direction = 4 },
    { name = 'rail-signal', x = -15.5, y = 4.5, direction = 12 },
    { name = 'rail-signal', x = 15.5, y = 4.5, direction = 12 },
    { name = 'rail-signal', x = -4.5, y = 15.5, direction = 0 },
    { name = 'rail-signal', x = 4.5, y = 15.5, direction = 8 },
}

local Public = {}

local data = {
    generated = false,
    room_ore = {}, -- ['i/j'] = 1..4
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

-- room ore weights: iron, copper, coal, stone -- stone rooms are deliberately rare
local ORE_WEIGHTS = { 3, 3, 3, 1 }
local ORE_WEIGHT_TOTAL = 10

local function random_ore()
    local r = random(ORE_WEIGHT_TOTAL)
    for ore, weight in ipairs(ORE_WEIGHTS) do
        r = r - weight
        if r <= 0 then
            return ore
        end
    end
    return 1
end

local function assign_ores()
    -- BFS from spawn: the first four rooms reached cover all four ores (shuffled)
    local first = { 1, 2, 3, 4 }
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
        if order <= 4 and k ~= spawn_key then
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

-- east-west trunk through a horizontal corridor chunk
local function lay_h_rails(surface, area)
    local top = area.left_top.y
    for x = area.left_top.x + 1, area.right_bottom.x - 1, 2 do
        lay_rail(surface, x, top + RAIL_A, defines.direction.east)
        lay_rail(surface, x, top + RAIL_B, defines.direction.east)
    end
end

-- north-south trunk through a vertical corridor chunk
local function lay_v_rails(surface, area)
    local left = area.left_top.x
    for y = area.left_top.y + 1, area.right_bottom.y - 1, 2 do
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
        local center_x = area.left_top.x + 16
        local center_y = area.left_top.y + 16
        for _, e in pairs(ROUNDABOUT) do
            surface.create_entity {
                name = e.name,
                position = { center_x + e.x, center_y + e.y },
                direction = e.direction,
                force = 'player',
            }
        end
        -- no connector straights needed: the ring's curve ends reach the chunk edge and
        -- meet the corridor trunk lines directly
        return
    end

    -- continuous trunk lines along every straight corridor chunk
    if y_wall then
        lay_h_rails(surface, area)
    else
        lay_v_rails(surface, area)
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

local function on_built(event)
    local entity = event.entity
    if not (entity and entity.valid) then
        return
    end
    local e_type = entity.type
    if e_type == 'entity-ghost' then
        e_type = entity.ghost_type
    end
    if ALLOWED_ON_STRIP[e_type] then
        return
    end
    local pos = entity.position
    if not on_wall_chunk(pos.x, pos.y) then
        return
    end
    local items = entity.type ~= 'entity-ghost' and entity.prototype and entity.prototype.items_to_place_this
    local index = event.player_index
    local player = index and game.get_player(index)
    if player and player.valid then
        if items and items[1] then
            player.insert(items[1])
        end
        player.print('Only rail infrastructure (rails, signals, stations, power poles) and trains can be built on the rail corridors!')
    end
    entity.destroy()
end

-- === public ================================================================

function Public.register()
    Event.on_init(function()
        if data.generated then
            return
        end
        data.generated = true
        assign_ores()
    end)

    Event.add(Generate.events.on_chunk_generated, on_chunk)
    Event.add(defines.events.on_built_entity, on_built)
    Event.add(defines.events.on_robot_built_entity, on_built)
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
                -- spawn room carries all four ores, one per quadrant
                local ore_index = ((x >= 0) and 1 or 0) + ((y >= 0) and 2 or 0) + 1
                return shapes[ore_index](x, y, world)
            end
            local ore_index = data.room_ore[ri .. '/' .. rj] or 1
            return shapes[ore_index](x, y, world)
        end

        return b.any { spawn_shape, water_shape, rooms }
    end
end

return Public
