-- City Blocks: isolated 4x4-chunk one-ore rooms separated by a paved, rail-only corridor
-- lattice carrying a ready-made double-track network -- ordinary, minable rails: continuous
-- lines ring every room and meet at a signalled RAIL ROUNDABOUT on every corner (geometry
-- decoded from the user's blueprint; native Factorio 2.0 rail pieces). Players
-- may branch their own rails, signals, poles and roboports anywhere on the lattice, but
-- nothing else can be built there, and belts cannot span the 32-tile corridors: trains are
-- the bulk inter-room logistics. Room ores are assigned once in on_init and stored in Global.
--
-- The lattice geometry, the ore assignment and the corridor tile pattern live in
-- city_blocks_layout.lua, which is pure Lua and unit tested; this module owns everything
-- that touches a surface.
local b = require 'map_gen.shared.builders'
local Event = require 'utils.event'
local Generate = require 'map_gen.shared.generate'
local Global = require 'utils.global'
local Layout = require 'map_gen.maps.danger_ores.modules.city_blocks_layout'
local RS = require 'map_gen.shared.redmew_surface'
local RestrictEntities = require 'map_gen.shared.entity_placement_restriction'
local Token = require 'utils.token'
local table = require 'utils.table'

local floor = math.floor
local random = math.random
local shuffle = table.shuffle_table

local PITCH = Layout.PITCH
local RAIL_A = Layout.RAIL_A
local RAIL_B = Layout.RAIL_B
local ROUNDABOUT = Layout.ROUNDABOUT
local in_bounds = Layout.in_bounds
local room_of_chunk = Layout.room_of_chunk

local Public = {}

local data = {
    room_ore = {}, -- ['i/j'] = 1..num_ores
}
Global.register(data, function(tbl)
    data = tbl
end)

-- Room ore assignment is derived from the ore config passed to register(): any number of
-- ores works, and optional weights (config.room_ore_weights) can bias the distribution.
local num_ores = 1
local ore_weights = nil

local function assign_ores()
    data.room_ore = Layout.assign_ores(num_ores, ore_weights, random, shuffle)
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

-- east-west trunk through a horizontal corridor chunk; near_west/near_east: an adjacent
-- in-bounds corner whose ring overhangs this chunk
local function lay_h_rails(surface, area, near_west, near_east)
    local top = area.left_top.y
    local from, to = Layout.trunk_range(area.left_top.x, area.right_bottom.x, near_west, near_east)
    for x = from, to, 2 do
        lay_rail(surface, x, top + RAIL_A, defines.direction.east)
        lay_rail(surface, x, top + RAIL_B, defines.direction.east)
    end
end

-- north-south trunk through a vertical corridor chunk
local function lay_v_rails(surface, area, near_north, near_south)
    local left = area.left_top.x
    local from, to = Layout.trunk_range(area.left_top.y, area.right_bottom.y, near_north, near_south)
    for y = from, to, 2 do
        lay_rail(surface, left + RAIL_A, y, defines.direction.north)
        lay_rail(surface, left + RAIL_B, y, defines.direction.north)
    end
end

-- Setting tiles does not remove generated entities, so ores/trees/rocks are destroyed
-- explicitly.
local function pave_corridor(surface, area, x_wall, y_wall)
    local left, top = area.left_top.x, area.left_top.y
    local tiles = {}
    for x = left, area.right_bottom.x - 1 do
        local xo = x - left
        for y = top, area.right_bottom.y - 1 do
            tiles[#tiles + 1] = {
                name = Layout.corridor_tile(xo, y - top, x_wall, y_wall),
                position = { x, y },
            }
        end
    end
    surface.set_tiles(tiles, true)
    for _, entity in pairs(surface.find_entities_filtered { area = area, type = { 'resource', 'tree', 'simple-entity' } }) do
        entity.destroy()
    end
end

-- Stamps one chunk of the lattice. Split out from the event handler so that tests can drive
-- it directly on a scratch surface.
function Public.generate_chunk(surface, area)
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

local function on_chunk(event)
    local surface = event.surface
    if surface ~= RS.get_surface() then
        return
    end
    Public.generate_chunk(surface, event.area)
end

-- === rail corridor placement rule ==========================================

local ALLOWED_ON_CORRIDOR = {
    ['straight-rail'] = true,
    ['curved-rail-a'] = true,
    ['curved-rail-b'] = true,
    ['half-diagonal-rail'] = true,
    ['legacy-straight-rail'] = true,
    ['legacy-curved-rail'] = true,
    ['elevated-straight-rail'] = true,
    ['elevated-curved-rail-a'] = true,
    ['elevated-curved-rail-b'] = true,
    ['elevated-half-diagonal-rail'] = true,
    ['rail-ramp'] = true,
    ['rail-support'] = true,
    ['rail-signal'] = true,
    ['rail-chain-signal'] = true,
    ['train-stop'] = true,
    ['electric-pole'] = true,
    -- Roboports are allowed even though bots can ferry items between rooms, because they can
    -- do that already: a roboport's logistics_radius is 25 and roboports join into one network
    -- when their logistic zones touch, so two placed inside adjacent rooms are within reach
    -- across a 32 tile corridor without anything ever being built on the corridor itself.
    -- Keeping them off it only forced players to give up the tidy placement, not the capability.
    ['roboport'] = true,
    ['locomotive'] = true,
    ['cargo-wagon'] = true,
    ['fluid-wagon'] = true,
    ['artillery-wagon'] = true,
}

Public.ALLOWED_ON_CORRIDOR = ALLOWED_ON_CORRIDOR

-- Corridor rule via the shared entity_placement_restriction module, which handles ghosts,
-- robot placement, refunds and destruction: keep everything off the corridors, and on them
-- only the allowed types (whitelisted by LuaEntity type, not name, for mod compatibility).
local keep_alive_callback = Token.register(function(entity)
    local e_type = entity.type
    if e_type == 'entity-ghost' then
        e_type = entity.ghost_type
    end
    if ALLOWED_ON_CORRIDOR[e_type] then
        return true
    end
    local pos = entity.position
    return not Layout.on_corridor_tile(pos.x, pos.y)
end)

local function on_restricted_destroyed(event)
    local player = event.player
    if player and player.valid then
        player.print('Only rail infrastructure (rails, signals, stations, power poles, roboports) and trains can be built on the rail corridors!')
    end
end

-- === public ================================================================

function Public.register(config)
    num_ores = #config.main_ores
    ore_weights = config.room_ore_weights

    RestrictEntities.set_keep_alive_callback(keep_alive_callback)
    RestrictEntities.enable_refund()

    Event.on_init(assign_ores)
    Event.add(Generate.events.on_chunk_generated, on_chunk)
    Event.add(RestrictEntities.events.on_restricted_entity_destroyed, on_restricted_destroyed)
end

-- danger-ores main_ores_builder: per tile, pick the room's dominant-ore shape
function Public.main_ores_builder(config)
    local main_ores = config.main_ores
    local in_room_margin = Layout.in_room_margin
    local room_of_tile = Layout.room_of_tile

    return function(tile_builder, ore_builder, spawn_shape, water_shape, _)
        local shapes = {}
        -- Same ground, no ore entity: used for the room-edge band so the tiles still look like
        -- the room's ore field but can be built on straight away.
        local bare_shapes = {}
        for _, ore_data in ipairs(main_ores) do
            local land = tile_builder(ore_data.tiles)
            local ratios = ore_data.ratios
            local weighted = b.prepare_weighted_array(ratios)
            local ore = ore_builder(ore_data.name, ore_data.start, ratios, weighted)
            shapes[#shapes + 1] = b.apply_entity(land, ore)
            bare_shapes[#bare_shapes + 1] = land
        end

        local function rooms(x, y, world)
            local ri, rj = room_of_tile(x, y)
            local set = in_room_margin(x, y) and bare_shapes or shapes
            if ri == 0 and rj == 0 then
                -- spawn room splits the main ores across its quadrants
                local quadrant = ((x >= 0) and 1 or 0) + ((y >= 0) and 2 or 0)
                return set[quadrant % #set + 1](x, y, world)
            end
            local ore_index = data.room_ore[Layout.key(ri, rj)] or 1
            return set[ore_index](x, y, world)
        end

        return b.any { spawn_shape, water_shape, rooms }
    end
end

return Public
